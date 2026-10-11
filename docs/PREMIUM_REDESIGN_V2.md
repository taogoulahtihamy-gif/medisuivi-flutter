# MediSuivi — refonte premium V2

## Livraison

La branche `feature/premium-redesign-v2` existait au début de cette intervention, avec des modifications locales du thème, des composants, de l’accueil, des patients et de l’illustration. Elles ont été conservées et complétées.

- Identité Forest Code `#075E46` / Mint Fog `#E8FFF2`, Material 3, polices système et illustration SVG embarquée. Provenance : `assets/illustrations/README.md`.
- Tokens : `lib/app/design_system.dart`, thème et alias historiques : `lib/app/theme.dart`.
- Composants : `lib/core/widgets/premium_components.dart`, `medical_ui.dart`, `floating_bottom_navigation.dart`, `temperature_trend.dart`.
- Écrans : accueil, recherche patients, dossier à six sections avec raccourcis, création de patient, consultation, bilans filtrables, suivi chronologique.
- Navigation adaptative Material/Cupertino, SafeArea, cibles tactiles, titres et champs qui se réorganisent selon la largeur et le facteur de texte.
- Animations : navigation 160 ms, transitions Android fondu/glissement, transitions natives iOS, apparition 400 ms, Hero des initiales vers le dossier. Réduction des animations prise en compte ; aucune attente artificielle.
- Formulaires : labels persistants, claviers numériques, unités, messages explicites. Bornes métier conservées. Correction de la cohérence entre validation et parsing numérique ; rejet de NaN/Infinity.
- Graphique de température uniquement à partir d’au moins deux mesures enregistrées, dates et valeurs accessibles en texte ; aucune interprétation clinique.

Les modèles métier sont inchangés. Les changements de `demo_data.dart`, `demo_store.dart`, `offline/contracts.dart` et des paramètres sont uniquement dus au formatage demandé. Les consultations conservent le champ existant `notes` pour les observations et notes complémentaires.

## Validation

```sh
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run
```

- Analyse statique : aucun problème.
- 14 tests automatisés : 6 tests existants conservés et 8 nouveaux tests.
- Tailles logiques : 320×640, 390×844, 430×932, 768×1024.
- Navigation iOS simulée et texte ×2 sur 320×740 ; dossier et formulaire avec réduction des animations.
- Parcours : Accueil → Patients → Dossier → Nouvelle consultation → enregistrement fictif ; Accueil → Bilans ; Accueil → Suivi.
- Recherche sans résultat et filtre des résultats disponibles.
- Captures temporaires des quatre onglets examinées avec les polices/icônes du SDK, uniquement des données fictives, hors dépôt. Ce contrôle ne remplace pas une validation sur appareil.

## Limites explicites

- Pas de compilation/signature iOS, test sur appareils physiques, audit VoiceOver/TalkBack ou profilage 60 FPS pendant cette intervention.
- Données de démonstration en mémoire, perdues à la fermeture. Ni chiffrement, authentification ni synchronisation réelle.
- Les modèles actuels ne contiennent pas d’antécédents structurés ni de statut distinct « prescrit » : tous les bilans existants sont des examens prescrits, répartis entre attente et résultat disponible.
- Recherche synchrone : pas d’état de chargement réseau ni d’erreur réseau artificiels. Le composant LoadingSkeleton est réservé aux futurs chargements réels ; les dossiers introuvables et recherches vides ont des états dédiés.
- À développer séparément : stockage chiffré, synchronisation, authentification, antécédents structurés, gestion des prescriptions/résultats et états asynchrones branchés aux dépôts réels.
