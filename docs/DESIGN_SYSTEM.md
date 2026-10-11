# MediSuivi | Design system v0.2

## Identité
Application médicale personnelle : sobre, attentive et élégante, sans fausse promesse clinique.
Direction éditoriale avec illustration originale embarquée dans le binaire : `assets/illustrations/medical_care.svg`.
**Aucune image distante obligatoire**, afin que l'interface reste identique hors connexion.

## Palette officielle : Forest Code × Mint Fog

Couleurs reprises à l'identique de la référence choisie :
- **Forest Code** : `#075E46` — boutons primaires, état actif, liens et accents dominants.
- **Mint Fog** : `#E8FFF2` — arrière-plans doux, tags, avatars fictifs et navigation sélectionnée.
- Fond général : `#F8FCF9`; surfaces : `#FFFFFF`.
- Encre de lecture : `#183A2E`; secondaire : `#627A6E`.
- Vert profond : `#064B39` pour les zones immersives.
- Traits et bordures : `#DDEEE4`.

La palette est centralisée dans `lib/app/theme.dart` (`Palette.forest`, `Palette.mintFog`).
Les anciens noms `Palette.teal` et `Palette.tealSoft` sont des alias de compatibilité.
Le fichier `assets/illustrations/medical_care.svg` utilise maintenant le même vert.
Les couleurs médicales d'alerte restent distinctes : pas de vert pour qualifier un résultat biologique de « normal ».

## Composition
- Répartition volontaire entre illustration d'accueil, raccourcis et données de travail.
- Rayon principal 20–26 px, marges latérales 20 px, grille compacte.
- Listes patients à forte hiérarchie d'information, noms lisibles et identifiants secondaires.
- Onglets inférieurs sur plateau flottant, actions tactiles généreuses.
- Icônes officielles Material sur Android, Cupertino sur iOS.
- Typographie native de chaque OS, sans police téléchargée.

## Motion
- Entrée de l'accueil : fondu + translation verticale 520 ms.
- Changement d'onglet : fondu + très légère translation 290 ms.
- Sélection navigation : fond animé 250 ms.
- Transition Hero pour les initiales des dossiers patients.
- Animations désactivées si `MediaQuery.disableAnimationsOf(context)` est activé.
- Pas d'animations inutiles sur des résultats médicaux sensibles.

## Images et confidentialité
- L'illustration locale représente une soignante fictive, pas une identité médicale réelle.
- Aucun portrait patient réel ou généré ; initiales uniquement.
- Aucun nom, résultat d'examen ou photographie personnelle ne doit être ajouté à GitHub.
- Le prototype affiche l'avertissement « Démonstration · données fictives ».
- Stockage chiffré et synchronisation médicale réelle **non implémentés** dans cette version.

## Validation
```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```
Vérifier Android, iOS, lecteur d'écran, grandes tailles de caractères et petits appareils avant publication.
