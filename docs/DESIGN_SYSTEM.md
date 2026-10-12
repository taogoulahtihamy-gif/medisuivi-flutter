# MediSuivi | Identité clinique menthe premium (V0.7)

Référence ergonomique : application métier premium, réutilisation de nos principes
du projet « Analyse du projet sérieux » : composants compacts, navigation mobile
flottante, lisibilité élevée, hiérarchie des actions, animations discrètes.

## Palette : fond menthe affirmé, surfaces ton sur ton

- **Fond principal** : `#62ECA7` (demande couleur).
- **Surfaces cliniques** : `#EAFFF2`, plus aucune grande carte blanche.
- **Champs** : `#F5FFF9`, pour distinguer l'édition.
- **Vert profond / actions** : `#124936`.
- **Texte foncé** : `#10372B`.
- **Texte secondaire** : `#365F4E`.
- **Séparateurs** : `#A0DABA`.
- **État sélectionné** : `#C9F3DA`.
- Boutons et pictogrammes privilégient le contraste, pas des couleurs multiples.

La photo de l'accueil est une **composition panoramique** d'une
professionnelle de santé noire, cadrée plus large. Le WebP est embarqué
dans l'application pour fonctionnement hors connexion.
Le dégradé gauche vers la droite conserve une zone lisible pour les chiffres.

La palette conserve une forte lisibilité : texte foncé sur fond menthe,
contenus sur carte claire et boutons foncés.

## Typographie

Polices système natives, intégrées et disponibles hors connexion :
SF Pro sur iOS, Roboto sur Android. Pas de police téléchargée au lancement.

- Grand titre : 23–27 px, poids 600–700, interlettrage resserré.
- Titre de section : 16–19 px, poids 600–700.
- Corps : 13,5–15 px avec hauteur de ligne aérée.
- Secondaire : 13 px minimum, contraste vérifié sur les surfaces.
- Navigation : 12 px et 22 px pour les icônes.
- Les écrans doivent respecter l’échelle de texte de l’appareil.

## Écrans

- Accueil : sommaire clinique bref, photo embarquée d'une professionnelle de santé noire, actions immédiates, deux accès de suivi,
  puis dossiers récents. **Pas un tableau de bord administratif.**
- Patients : recherche visible, filtres discrets, dossiers en surfaces neutres.
- Dossier : identité lisible, historique des visites, constantes avec unités.
- Bilans : statut textuel clair, séparation résultats disponibles/en attente.
- Suivi : liste actionnable sans indicateurs décoratifs.
- Formulaires : sections `ClinicalFormSection`, validations et unités.
- Barre flottante : fond menthe clair, sélection vert foncé, libellés compacts.

Animation : transitions des onglets 240 ms, apparition du résumé,
Hero de l’avatar fictif ; respecter `MediaQuery.disableAnimationsOf`.

## État du produit

**Démonstration fictive uniquement** : pas de base chiffrée,
pas d’authentification réelle ni de synchronisation médicale.
Aucun nom de patient réel sur GitHub. Les éléments visuels sont embarqués
localement pour rester visibles sans réseau.

Vérification : `flutter pub get`, `flutter analyze`, `flutter test`.
Tester également Android, iOS et la mise à l’échelle des polices.
