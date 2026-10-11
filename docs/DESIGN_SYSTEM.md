# Direction artistique mobile : MediSuivi

## Principes

Clinique, lisible, rapide, sans décoration superflue. L'utilisateur doit identifier un patient et son historique plus vite qu'avec une pile de papiers.

## Couleurs

- Fond : `#F5F7F6`
- Blanc : `#FFFFFF`
- Texte principal : `#17323A`
- Texte secondaire : `#687A80`
- Vert profond : `#0F5559`
- Vert action : `#146C70`
- Vert clair : `#E6F2F0`
- Bordures : `#E1E9E7`
- Alerte neutre / données démo : `#FFF3E3`

Le vert est un accent d'identité, jamais une confirmation implicite qu'un résultat médical est « normal ». Les résultats anormaux doivent dépendre de références explicites et être évalués par un professionnel.

## Composants

- Surface 20 px de rayon, bordure légère, sans ombre ostentatoire.
- Boutons ≥ 48 px, cible tactile confortable sur Android et iOS.
- Marges latérales 22 px, contenu max. 720 px tablette.
- Polices système : Roboto (Android), San Francisco (iOS), pas de police distribuée.
- Icônes officielles `Icons.*` (Material) et `CupertinoIcons.*` sur iOS.
- Transitions 220 ms, désactivées lorsque l'OS demande la réduction des animations.
- Accessibilité : contraste, zoom texte et lecteurs d'écran à auditer en V1.

## Parcours prioritaires

Accueil -> Recherche patient -> Fiche patient -> Consultation -> Constantes -> Historique -> Bilans.

## Version actuelle

Interfaces natives Flutter avec quelques transitions légères et données fictives ; reste à réaliser : accessibilité et adaptativité complète testées sur appareils réels, graphiques de tendance, pièces jointes, synchronisation réelle.
