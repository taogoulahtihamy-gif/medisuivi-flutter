#!/usr/bin/env bash
# GitHub Actions Android emulator runner invokes its "script" one line at a
# time via /bin/sh. Run THIS file as a single shell command so that Bash
# conditionals, loops and multiline Flutter options remain intact.
set -Eeuo pipefail

apk="downloaded-apk/app-debug.apk"
test -s "$apk"
test -n "${MEDISUIVI_API_BASE_URL:-}"
echo "Android device:"
adb wait-for-device
adb devices -l
adb shell getprop ro.build.version.release

# sys.boot_completed is not sufficient for package installation.
# Wait for system_server's package service to become responsive.
ready=0
for attempt in $(seq 1 40); do
  if adb shell 'cmd package list packages android' 2>/dev/null | grep -q 'package:android'; then
    ready=1
    break
  fi
  echo "Waiting for Android package manager ($attempt/40)"
  sleep 3
done
if [ "$ready" -ne 1 ]; then
  echo "::error::Android package manager did not become ready"
  adb devices -l || true
  exit 1
fi

# Cold emulators can intermittently reject ADB streamed installs.
# Retry only an installation transport failure, never bypass Android signing.
installed=0
for attempt in 1 2 3; do
  if adb install --no-streaming -r "$apk"; then
    installed=1
    break
  fi
  echo "APK installation transport failed ($attempt/3)"
  adb reconnect || true
  sleep 5
done
if [ "$installed" -ne 1 ]; then
  echo "::error::MediSuivi APK installation failed"
  exit 1
fi

adb shell pm path com.example.medisuivi.sandbox
adb shell am start -W -n \
  com.example.medisuivi.sandbox/com.example.medisuivi.MainActivity

# The process can take time to start while Flutter initializes.
launched=0
for attempt in $(seq 1 15); do
  if adb shell pidof com.example.medisuivi.sandbox >/dev/null 2>&1; then
    launched=1
    break
  fi
  sleep 2
done
if [ "$launched" -ne 1 ]; then
  echo "::error::MediSuivi Android activity did not stay running"
  exit 1
fi

# CI emulator has no real patient information. Screenshot is for design QA.
sleep 2
adb exec-out screencap -p > "medisuivi-android-${MEDISUIVI_ANDROID_API_LEVEL}.png"

# Execute HTTPS checks *on the Android emulator*, not on the GitHub host.
flutter test integration_test/p50_vercel_android_emulator_test.dart \
  -d emulator-5554 --no-pub \
  --dart-define="MEDISUIVI_DEV_API_BASE_URL=${MEDISUIVI_API_BASE_URL}" \
  --dart-define=MEDISUIVI_REMOTE_SANDBOX=true
