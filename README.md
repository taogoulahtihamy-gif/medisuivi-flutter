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
- Identité **clinique sobre** : vert hospitalier `#16624F`, surfaces neutres, texte graphite, typographies système natives et animations courtes.
- Visuels SVG embarqués et écrans de démarrage Android/iOS adaptés au thème médical.
- Structure Offline First et contrat de synchronisation (non raccordés).
- Tests widget initiaux et CI GitHub Actions.

## Développement Ubuntu

Le dépôt existe déjà sur GitHub :
`https://github.com/taogoulahtihamy-gif/medisuivi-flutter`.

```bash
cd /mnt/chak/medisuivi-flutter
export PATH="$HOME/snap/flutter/common/flutter/bin:$PATH"
git switch main
git pull --ff-only origin main
flutter pub get
flutter analyze
flutter test
flutter run -d web-server --web-hostname=127.0.0.1
```

Ouvrir l'URL locale affichée par Flutter dans Firefox.
Pour exécuter sur un Android connecté : `flutter devices`, puis
`flutter run -d <ID_ANDROID>`.
La compilation et la signature iOS nécessitent macOS avec Xcode.
Si la branche locale est divergente, ne pas faire de `reset --hard` :
sauvegarder les modifications puis changer de branche explicitement.

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

## GitHub et sécurité

La branche de développement de référence est `main`. Les propositions Codex
peuvent exister dans des branches indépendantes ; ne pas fusionner sans revue.
La synchronisation du **code source** avec GitHub est totalement distincte
de la future synchronisation **des dossiers patients**, qui exigera une API
sécurisée, un stockage local chiffré et des politiques de confidentialité.

**Dépôt de démonstration uniquement : ne jamais y publier de données patients réelles.**
