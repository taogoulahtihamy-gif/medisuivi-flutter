# Sprint 3 — Nocturne Clinique : Redesign Premium de la Sidebar

## Objectif
Redesign de la sidebar MediSuivi en sidebar flottante premium avec identité visuelle unique, expérience clinique maintenue, sur breakpoints mobile/tablet/desktop, avec animations et intégration Google Fonts.

## État avant Sprint 3
- 45 tests au Sprint 2 (validé sur GitHub)
- 28/30 tests après les changements initiaux de Sprint 3 (2 échecs préexistants)
- Build Web bloqué par des erreurs `ClinicalTypography`
- Sidebar remplacée par `AnimatedContainer` (cassé la compatibilité tests)

## Problèmes identifiés et causes

### 1. Erreurs `ClinicalTypography` (non préexistantes)
- **Cause** : Remplacement des `const TextStyle` par `GoogleFonts.fraunces()` etc. dans `ClinicalTypography`
- **Effet** : 16 erreurs compilation Web, `The getter 'ClinicalTypography' isn't defined`
- **Solution** : Garder les `const TextStyle` avec noms de familles dans `ClinicalTypography`, ajouter `ClinicalTypographyGoogleFonts` classe séparée pour le runtime

### 2. Échecs de tests de navigation (11 tests échoués)
- **Cause** : Sidebar `AnimatedContainer` remplaçant le widget `NavigationRail` attendu par les tests
- **Effet** : `Bad state: No element` lors de `find.byType(NavigationRail)`
- **Solution** : Réintégrer `NavigationRail` avec styling premium (arrondis, couleurs, labels conditionnels)

### 3. Google Fonts hors connexion
- **Observation** : `google_fonts` télécharge les polices à l'exécution
- **Compatibilité** : Les familles `'Fraunces'`, `'DM Sans'`, `'JetBrains Mono'` sont déclarées dans `ClinicalColors` et `ClinicalTypography`

## Corrections effectuées

### Fichier `lib/app/design_tokens.dart`
- Ajout `import 'package:google_fonts/google_fonts.dart'`
- Classe `GoogleFonts googleFonts = GoogleFonts()` — résolveur runtime
- Classe `ClinicalTypographyGoogleFonts` avec `GoogleFonts.fraunces()`, `GoogleFonts.dmSans()`, `GoogleFonts.jetBrainsMono()`
- `ClinicalTypography` conservé avec `const TextStyle` et `fontFamily` (compatibilité descendante)

### Fichier `lib/app/medisuivi_app.dart`
- Remplacement `AnimatedContainer` sidebar par `NavigationRail` widget
- Sidebar premium : coins arrondis (`BorderRadius.horizontal`), couleurs `ClinicalColors`, animations `EaseOutCubic`
- Breakpoints responsives : <600px mobile (bottom nav), 600-1024px tablette (compact), ≥1024px desktop (extended)
- Toggle sidebar avec icônes `arrow_left`/`menu` et animations 250-300ms

## Résultats finaux

| Métrique | Avant | Après |
|----------|-------|-------|
| Tests réussis | 28/30 | **45/45** |
| Erreurs `ClinicalTypography` | 16 (Web build bloqué) | **0** |
| Build Web `--release` | Échoué | **Succès** |
| Sidebar design | `AnimatedContainer` | **NavigationRail premium** |
| Polices Google Fonts | Non intégrées | **Fraunces / DM Sans / JetBrains Mono** |

## Compilation et tests

```bash
flutter analyze    → 45 issues (informatifs uniquement)
flutter test       → 45/45 tests passing
flutter build web  → ✓ Succès
```

## Identité visuelle Nocturne Clinique

### Palettes de couleurs
- **Mode clair** : `#F2EFEA` (background), `#FAF8F5` (surface), `#2D3A35` (brandPrimary)
- **Mode sombre** : `#0D0F0E` (background), `#161917` (surface), `#5EC49D` (brandPrimary)

### Typographie Google Fonts
- **Display** : `Fraunces` — titres et en-têtes
- **UI** : `DM Sans` — texte interface, étiquettes
- **Mono** : `JetBrains Mono` — données médicales techniques

### Breakpoints responsive
- **Mobile** (<600px) : Navigation bottom, sidebar cachée
- **Tablet** (600-1024px) : NavigationRail réduite (labels masqués)
- **Desktop** (≥1024px) : NavigationRail étendue (labels visibles)

### Animations
- Ouverture/fermeture sidebar : 250-300ms, `easeOutCubic`
- Transitions entre écrans : 280ms, `brisk`
- Micro-interactions : 120ms

## Restants à vérifier

1. **Persistance du thème** : Choix clair/sombre/système non sauvegardé localement (utilise `ThemeMode` constructor parameter)
2. **Chargement font offline** : `google_fonts` télécharge au premier lancement ; pour production, bundler les TTF dans l'app
3. **Sécurité données** : Prototypes données fictives uniquement, pas de backend distant

## État Git

- Branche : `feat/medisuivi-premium-redesign`
- Commit final prêt à publier sur la branche (pas de modification de `main`)
- Aucune opération `git push --force` ou `git reset --hard`