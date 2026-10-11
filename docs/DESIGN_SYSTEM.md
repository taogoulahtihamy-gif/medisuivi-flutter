# MediSuivi — Night Shift × Laser Lemon

Direction artistique reprise de notre projet « Analyse du projet sérieux » :
interface professionnelle compacte, navigation flottante, coins maîtrisés,
typographie lisible, micro-interactions utiles, sans pastilles décoratives.

## Palette strictement bicolore

| Token | Couleur | HEX |
| --- | --- | --- |
| `Palette.night` | Night Shift | `#10131A` |
| `Palette.laser` | Laser Lemon | `#EFFF4F` |

Aucune autre **teinte source** ne doit être introduite, y compris pour les alertes.
Surfaces secondaires, bordures, champs, éléments désactivés et textes secondaires
utilisent seulement ces mêmes RGB avec différentes opacités :
`laserMuted`, `laserBorder`, `laserVeil`.
Les noms historiques `teal`, `forest`, `mintFog`, `amberSoft` existent
uniquement comme **alias de compatibilité** et ne correspondent plus à des
couleurs supplémentaires.

La palette est définie centralement dans `lib/app/theme.dart`, avec un
`ColorScheme` explicite. Ne pas utiliser `ColorScheme.fromSeed`, qui pourrait
générer des teintes supplémentaires.

## Composition des écrans

- **Accueil** : grand résumé jaune citron, chiffres Night Shift, raccourcis
  contrastés, dossiers récents organisés en registre.
- **Patients** : recherche immédiate, état sélectionné jaune, lignes compactes.
- **Dossier** : chronologie et constantes, valeurs médicales lisibles.
- **Bilans** : statut textuel obligatoire ; pas de confusion entre couleur et
  interprétation médicale.
- **Suivi** : liste des patients à revoir, navigation directe.
- **Formulaires** : sections `ClinicalFormSection`, clavier adapté aux mesures,
  unités visibles, validation et sauvegarde démo explicites.
- **Navigation** : dock flottant Night Shift, sélection Laser Lemon, icônes
  Flutter Material sur Android et Cupertino sur iOS.

## Motion et accessibilité

- Courbes `easeOutCubic` ; navigation animée sur 240–250 ms.
- Apparition douce d'une section quand cela aide la lecture.
- Animation Hero sur l'avatar **fictif** lors de l'ouverture d'un dossier.
- Respect de `MediaQuery.disableAnimationsOf(context)`.
- Cibles tactiles confortables ; largeur mobile testée à 360 px.
- Si le jaune sert de couleur d'alerte **et** d'accent, un mot et une icône
  décrivent toujours la situation. Ne pas indiquer « normal/anormal » sans
  règle médicale validée.

## Images et données

- Seul visuel médical SVG embarqué : `assets/illustrations/medical_care.svg`.
  Le SVG utilise exclusivement les deux couleurs approuvées, sans Internet.
- Dossiers patients : initiales fictives, jamais de portraits réels intégrés
  au dépôt.
- **Cette version est une démonstration** sans persistance médicalement sûre.
  Le chiffrement local et la synchronisation offline réelle ne sont pas prêts.
- Ne pas saisir de données réelles et ne pas les publier dans GitHub.

## Vérification

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d web-server --web-hostname=127.0.0.1
```

Les nouvelles fonctionnalités ne doivent pas réintroduire d'autres couleurs,
en dur dans un widget ou générées par un thème tiers.
