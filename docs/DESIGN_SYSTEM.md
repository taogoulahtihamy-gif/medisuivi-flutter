# MediSuivi | Design system v0.2

## Identité
Application médicale personnelle : sobre, attentive et élégante, sans fausse promesse clinique.
Direction éditoriale avec illustration originale embarquée dans le binaire : `assets/illustrations/medical_care.svg`.
**Aucune image distante obligatoire**, afin que l'interface reste identique hors connexion.

## Palette
- Canvas `#F5F7F8`, surface `#FFFFFF`.
- Encre `#142D39`, secondaire `#697F88`.
- Teal actif `#087A78`, teal profond `#0C4C58`.
- Marine `#123E52`, aqua `#DCF5EF`.
- Accents limités : bleu pâle `#EAF1FD`, lavande `#F1EDFA`.
- Les couleurs des cartes de statistiques ne qualifient jamais une donnée médicale comme « normale ».

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
