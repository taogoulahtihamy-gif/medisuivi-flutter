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

sleep 20
echo "===== PROCESS STILL ALIVE ====="
adb shell pidof "$APP" | tee "$OUT/process.txt"
test -s "$OUT/process.txt"

echo "APK INSTALLED + PROCESS STARTED. UI/BIOMETRICS/SQLITE UNLOCK STILL UNVERIFIED."
