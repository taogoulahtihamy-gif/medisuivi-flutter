# MediSuivi · Flutter

Application de suivi clinique **personnelle pour une seule soignante**, avec interface Flutter Android/iOS. Base de code préparée pour une architecture **offline-first**.

> **V0 : démonstration uniquement.** Données fictives, modifications en mémoire uniquement. Pas encore de connexion, de base locale chiffrée ni de synchronisation réelle. Ne jamais saisir de données patient réelles dans cette version.

## Fonctionnalités de démarrage

- Accueil personnel et indicateurs fictifs.
- Patients : liste, recherche, création temporaire et dossier individuel.
- Constantes et historique des consultations.
- Nouvelle consultation fictive avec validation des valeurs.
- Bilans / résultats et liste des suivis.
- Navigation mobile adaptative : Cupertino iOS et Material 3 Android.
- Icônes officielles, typographies système, transitions légères et thème médical.
- Structure Offline First et contrat de synchronisation (non raccordés).
- Tests widget initiaux et CI GitHub Actions.

## Installation Ubuntu

Avec Flutter déjà installé :

```bash
mkdir -p /mnt/chak/medisuivi-flutter
unzip -oq ~/Téléchargements/medisuivi-flutter-starter.zip -d /mnt/chak/medisuivi-flutter
cd /mnt/chak/medisuivi-flutter
bash scripts/bootstrap.sh
flutter devices
flutter run -d chrome
```

Pour démarrer sur Android utiliser `flutter run -d <ID_ANDROID>`. Pour générer, compiler ou signer iOS, un **Mac avec Xcode** est nécessaire (pas Ubuntu).

## Arborescence

```text
lib/
  main.dart
  app/medisuivi_app.dart      # navigation adaptative
  app/theme.dart              # identité visuelle
  core/models/medical_models.dart
  core/data/demo_data.dart
  core/state/demo_store.dart # mémoire temporaire V0
  core/offline/contracts.dart # base chiffrée / API : interfaces futures
  core/widgets/medical_ui.dart
  features/
    home/ patients/ consultations/ exams/ followup/ settings/
```

Voir `docs/ARCHITECTURE.md`, `docs/OFFLINE_SYNC.md`, `docs/SECURITY.md`, `docs/DESIGN_SYSTEM.md` et `docs/ROADMAP.md`.

## GitHub (après validation de la V0)

Créer un dépôt **privé vide** nommé `medisuivi-flutter` dans le compte `taogoulahtihamy-gif`, sans README ni .gitignore à sa création.

```bash
cd /mnt/chak/medisuivi-flutter
git init
git add .
git commit -m 'feat: initial MediSuivi Flutter prototype'
git branch -M main
git remote add origin https://github.com/taogoulahtihamy-gif/medisuivi-flutter.git
git push -u origin main
```

Pour les mises à jour ultérieures : `git pull --ff-only origin main && flutter pub get`. La synchronisation GitHub des **sources** n'est pas la synchronisation hors ligne des **patients** : cette dernière utilisera une API privée sécurisée.
