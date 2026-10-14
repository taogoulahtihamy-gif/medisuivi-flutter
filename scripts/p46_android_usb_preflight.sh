#!/usr/bin/env bash
# P4.6 preflight. No APK install, no app data reads, no Docker operations.
set -euo pipefail

command -v adb >/dev/null || {
  echo "Android platform-tools (adb) not installed" >&2
  exit 1
}
command -v curl >/dev/null || exit 1

echo "===== MediSuivi FastAPI local ====="
for path in /health /ready; do
  curl --noproxy '*' --fail --silent --show-error     --connect-timeout 3 --max-time 8     "http://127.0.0.1:8027$path" >/dev/null
done
echo "API locale : OK"

echo "===== Android USB ====="
mapfile -t devices < <(adb devices -l | awk 'NR > 1 && $2 == "device" {print $1}')
if [[ "${#devices[@]}" -ne 1 ]]; then
  echo "Brancher exactement un appareil Android autorisé (USB debugging)." >&2
  echo "Vérifier : adb devices -l" >&2
  exit 1
fi
device="${devices[0]}"
is_emulator="$(adb -s "$device" shell getprop ro.kernel.qemu | tr -d '\r')"
if [[ "$is_emulator" == "1" ]]; then
  echo "Ce contrôle exige un téléphone physique, pas un émulateur." >&2
  exit 1
fi

# Reverse tunneling exposes ONLY the workstation's local API to this device.
adb -s "$device" reverse tcp:8027 tcp:8027
adb -s "$device" reverse --list | grep -F 'tcp:8027 tcp:8027' >/dev/null
echo "USB reverse vers API 8027 : OK"

echo "===== Application déjà présente ====="
if adb -s "$device" shell pm path com.example.medisuivi |
   grep -q 'package:'; then
  echo "ATTENTION : com.example.medisuivi est déjà installé."
  echo "Ne pas désinstaller ou écraser sans vérifier les données locales."
else
  echo "Aucune installation précédente détectée."
fi

echo "===== PRET POUR LES ESSAIS SYNTHETIQUES ====="
echo "Sur un téléphone de test autorisé, utiliser :"
echo "flutter run -d '$device' --debug --dart-define=MEDISUIVI_DEV_API_BASE_URL=http://127.0.0.1:8027"
echo "Cette étape de prévol n'a installé aucune application."
