#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo 'Flutter introuvable dans le PATH.' >&2
  exit 1
fi

cd "$(dirname "$0")/.."

# Ne jamais régénérer le squelette Flutter lors de chaque bootstrap :
# flutter create peut modifier des fichiers suivis par Git.
missing=()
for platform in android ios web; do
  if [[ ! -d "$platform" ]]; then
    missing+=("$platform")
  fi
done
if (("${#missing[@]}" > 0)); then
  echo "Plateformes absentes : ${missing[*]}" >&2
  echo "Veuillez examiner l'état Git puis générer explicitement les plateformes manquantes." >&2
  exit 1
fi

echo '== Installation des dépendances =='
flutter pub get
echo '== Analyse statique =='
flutter analyze
echo '== Tests =='
flutter test
echo 'Projet prêt. Commandes : flutter devices ; flutter run'
