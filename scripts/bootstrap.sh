#!/usr/bin/env bash
set -euo pipefail
if ! command -v flutter >/dev/null 2>&1; then
  echo 'Flutter introuvable dans le PATH.' >&2
  exit 1
fi
cd "$(dirname "$0")/.."
echo '== Génération des plateformes =='
flutter create --platforms=android,ios,web --project-name medisuivi .
echo '== Installation =='
flutter pub get
echo '== Analyse =='
flutter analyze
echo '== Tests =='
flutter test
echo 'Projet prêt. Commandes : flutter devices ; flutter run'
