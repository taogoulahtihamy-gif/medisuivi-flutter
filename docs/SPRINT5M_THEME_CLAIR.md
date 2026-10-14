# Sprint 5M : refonte du thème clair « Sauge & Lin »

## Intention visuelle

Sortir du jaune ivoire lumineux et des cartes de teintes trop similaires. Le clair devient un environnement de travail clinique mat, avec profondeur tonale et moins d'éblouissement, sans devenir un pseudo mode sombre.

| Rôle | Couleur | Usage |
| --- | --- | --- |
| Fond principal | `#E9E8E0` | Fond doux gris-lin |
| Surface | `#F3F2EA` | Groupes, cartes et listes |
| Surface élevée | `#FAF8F2` | Champs, menus, dialogues |
| Texte principal | `#1D3027` | Titres et valeurs |
| Texte secondaire | `#465B50` | Descriptions |
| Texte discret | `#52665A` | Métadonnées visibles |
| Primaire | `#285642` | Actions, navigation sélectionnée |
| Primaire doux | `#DAE9DE` | Chip actif, arrière-plan d'icône |
| Ambre | `#79500B` | Informations attentionnelles |
| Ambre doux | `#F2E5CA` | État attentionnel |
| Bordures de groupe | `#B0BDB0` | Séparation subtile de surface |
| Bordure des champs | `#7C907E` | Contours actifs/inactifs discernables |
| Erreur | `#9C3836` | Messages d'erreur |

## Règles appliquées

1. Les couleurs proviennent de `ClinicalColors` et non d'hex dispersés dans les pages.
2. Palette unique partagée avec `Palette.of(context)`, `MediTheme` et `ClinicalTheme`. Le thème sombre n'est pas retouché.
3. Les éléments interactifs du thème clair (champs, actions, sélections et menus) ont des états plus lisibles.
4. La navigation flottante et la recherche restent légèrement translucides mais gagnent en opacité en mode clair. Les listes gardent le style compact et les séparateurs du Sprint 5L.
5. La photo d'accueil ne change pas ; les photos de l'onboarding restent sombres par choix éditorial, indépendamment du thème clair.
6. Éviter d'utiliser du blanc pur sur de larges surfaces ; conserver le contraste texte/fond avec des teintes sombres.

## Contrôles techniques

- Tests de contraste WCAG pour textes et accents sur les cinq principales surfaces : normal ≥4,5:1.
- Contraste des contours de saisie sur la surface élevée : ≥3:1.
- Texte de premier plan en priorité ≥7:1.
- Widget tests d'accueil et de profil à 320 et 390 px.
- Vérification de la palette du thème sombre et de la navigation.
- Après CI : valider manuellement dans Firefox et sur Android réel les pages Accueil, Patients, Bilans, Suivi, Profil, sous-pages de Paramètres, formulaires et dialogues.

## Références

- [WCAG 2.2 SC 1.4.3 Contraste minimum](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)
- [Flutter Material 3 : surfaces et rôles de couleurs](https://docs.flutter.dev/release/breaking-changes/new-color-scheme-roles)
- [Android Developers : thème de couleurs Material 3](https://developer.android.com/codelabs/m3-design-theming)

La vérification de palettes n'est **pas** une certification d'accessibilité de tous les écrans. Des contrôles sur appareils physiques, textes agrandis et lecteurs d'écran sont nécessaires.
