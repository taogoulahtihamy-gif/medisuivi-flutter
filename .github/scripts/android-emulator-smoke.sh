#!/usr/bin/env bash
# Android emulator smoke test: installation, startup, and diagnostics.
# Called as ONE Bash process by reactivecircus/android-emulator-runner.
set -euo pipefail

APP="com.example.medisuivi"
APK="apk/app-debug.apk"
OUT="test-output"
mkdir -p "$OUT"

collect_diagnostics() {
  local status=$?
  set +e
  adb logcat -d -v threadtime 2>/dev/null \
    | grep -Ei 'AndroidRuntime|Flutter|medisuivi|sqlite|cipher|biometric|Keystore|local_auth|FATAL EXCEPTION' \
    | tail -n 700 > "$OUT/relevant-logcat.txt"
  adb exec-out screencap -p > "$OUT/screen.png" 2>/dev/null
  echo "$status" > "$OUT/test-exit-code.txt"
}
trap collect_diagnostics EXIT

test -s "$APK"
adb wait-for-device
adb shell getprop ro.build.version.release | tee "$OUT/android-version.txt"
adb shell getprop ro.product.cpu.abilist | tee "$OUT/cpu-abi.txt"

# Configure only the disposable emulator. This is a dummy PIN, never a
# production credential. Device authentication remains mandatory.
TEST_PIN="2468"
echo "===== SET EMULATOR DEVICE CREDENTIAL ====="
if ! adb shell locksettings set-pin "$TEST_PIN" > "$OUT/device-credential-setup.txt" 2>&1; then
  echo "ERROR: Could not configure screen-lock credential on emulator." >&2
  exit 1
fi
echo "Emulator lock credential configured."

# Android 8 emulators may reject clearing system logs; this is non-fatal.
if ! adb logcat -c > "$OUT/logcat-reset.txt" 2>&1; then
  echo "Warning: logcat clear unavailable; continuing without log reset."
fi

echo "===== APK INSTALL ====="
adb install -r -t "$APK" 2>&1 | tee "$OUT/installation.txt"
grep -qE '^Success[[:space:]]*$' "$OUT/installation.txt"

echo "===== PACKAGE PRESENT ====="
adb shell pm path "$APP" | tee "$OUT/package-path.txt"
grep -q '^package:' "$OUT/package-path.txt"

echo "===== START ACTIVITY ====="
adb shell input keyevent KEYCODE_WAKEUP || true
adb shell wm dismiss-keyguard || true
adb shell am start -W -n "$APP/.MainActivity" 2>&1 | tee "$OUT/launch.txt"
if grep -qE 'Error type|does not exist|SecurityException|Permission Denial' "$OUT/launch.txt"; then
  echo "ERROR: Activity launch rejected by Android" >&2
  exit 1
fi

# Android 8 may open ConfirmDeviceCredentialActivity later than Android 10.
# Wait for the SYSTEM credential prompt before typing; never send a PIN blindly.
sleep 4
adb exec-out screencap -p > "$OUT/before-auth-screen.png" 2>/dev/null || true
pin_attempts=0
ui_retries=0
for attempt in $(seq 1 18); do
  if adb logcat -d -v brief 2>/dev/null | grep -q 'MEDISUIVI_BOOT_READY'; then
    break
  fi
  focus="$(adb shell dumpsys window windows 2>/dev/null | grep -E 'mCurrentFocus=|mFocusedApp=' | tail -n 2 || true)"
  resumed="$(adb shell dumpsys activity activities 2>/dev/null | grep -E 'mResumedActivity|topResumedActivity' | tail -n 1 || true)"
  printf 'Attempt %s focus: %s | %s\n' "$attempt" "$focus" "$resumed" >> "$OUT/ui-focus.txt"
  if [[ "$focus $resumed" == *ConfirmLockPassword* ||
        "$focus $resumed" == *ConfirmDeviceCredential* ||
        "$focus $resumed" == *ConfirmLockPattern* ]]; then
    if (( pin_attempts < 3 )); then
      echo "===== CONFIRM ANDROID CREDENTIAL (attempt $((pin_attempts+1))) ====="
      adb shell input text "$TEST_PIN" || true
      adb shell input keyevent KEYCODE_ENTER || true
      pin_attempts=$((pin_attempts+1))
    fi
  elif [[ "$focus $resumed" == *"$APP"* ]] &&
       adb logcat -d -v brief 2>/dev/null | grep -q 'MEDISUIVI_BOOT_RESULT=authenticationRequired' &&
       (( ui_retries < 2 )); then
    # Retry button on the test-only 1080x1920 Flutter error screen.
    # This triggers another normal local_auth challenge; no bypass.
    echo "===== RE-REQUEST AUTHENTICATION ====="
    adb shell input tap 540 1220 || true
    ui_retries=$((ui_retries+1))
  fi
  sleep 4
done

echo "===== PROCESS STILL ALIVE ====="
adb shell pidof "$APP" | tee "$OUT/process.txt"
test -s "$OUT/process.txt"

# Le processus peut rester actif tout en affichant un écran d'erreur.
# N'approuver le démarrage que lorsque Flutter confirme le store prêt.
adb logcat -d -v brief 2>/dev/null > "$OUT/bootstrap-logcat.txt" || true
if ! grep -q 'MEDISUIVI_BOOT_READY' "$OUT/bootstrap-logcat.txt"; then
  echo "ERROR: MediSuivi installed but encrypted storage was not initialized." >&2
  grep -E 'MEDISUIVI_BOOT_RESULT=|MEDISUIVI_BOOT_READY' "$OUT/bootstrap-logcat.txt" || true
  exit 1
fi

echo "APK INSTALLED + CLINICAL STORE READY. Android biometrics and real-device compatibility still need testing."
