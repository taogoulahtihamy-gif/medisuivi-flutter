# GitHub ↔ Ubuntu

- Projet : MediSuivi Flutter, dépot GitHub privé `taogoulahtihamy-gif/medisuivi-flutter` (à créer).
- Dossier local : `/mnt/chak/medisuivi-flutter`.
- Code : branches `main`, `feature/...`, PR et CI Flutter.
- Ne jamais pousser de bases, captures ou exports contenant des patients réels.

## Première publication

```bash
cd /mnt/chak/medisuivi-flutter
git init
git add .
git commit -m 'feat: initial MediSuivi Flutter prototype'
git branch -M main
git remote add origin https://github.com/taogoulahtihamy-gif/medisuivi-flutter.git
git push -u origin main
```

## Mise à jour en local

```bash
cd /mnt/chak/medisuivi-flutter
git pull --ff-only origin main
flutter pub get
flutter analyze
flutter test
flutter run
```

Attention : le dépôt ne doit jamais devenir un lieu de stockage des dossiers médicaux. La future synchronisation clinique sera réalisée via le backend dédié, pas via GitHub.
