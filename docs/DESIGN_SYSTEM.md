# MediSuivi | Identité clinique premium (V0.6)

Référence ergonomique : application métier premium, réutilisation de nos principes
du projet « Analyse du projet sérieux » : composants compacts, navigation mobile
flottante, lisibilité élevée, hiérarchie des actions, animations discrètes.

## Palette mesurée, non monochrome

- Vert profond (action) : `#164B40`
- Vert de surface forte : `#164B40`
- Vert doux (état sélectionné) : `#E8EFEB`
- Blanc : `#FFFFFF`
- Toile gris pierre : `#F5F5F2`
- Texte principal anthracite : `#1B2421`
- Texte secondaire : `#59635F`
- Séparation : `#E2E4DE`
- États nécessitant une distinction clinique : **libellés + icônes**.
  Les alertes ne reposent jamais uniquement sur la couleur.

**Règle :** majorité de surfaces neutres (pierre et blanc pur) ; vert profond uniquement pour les actions, la navigation active et le bloc photographique de l'accueil.
Les composants métiers ne doivent jamais devenir entièrement verts par défaut.

## Typographie

Polices système natives, intégrées et disponibles hors connexion :
SF Pro sur iOS, Roboto sur Android. Pas de police téléchargée au lancement.

- Grand titre : 27–30 px, poids 700, interlettrage léger.
- Titre de section : 17–21 px, poids 600–700.
- Corps : 14–16 px.
- Secondaire : 13 px minimum (hors micro-labels/metadata).
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
- Barre flottante : fond blanc, sélection vert discret, libellés lisibles.

Animation : transitions des onglets 240 ms, apparition du résumé,
Hero de l’avatar fictif ; respecter `MediaQuery.disableAnimationsOf`.

## État du produit

**Démonstration fictive uniquement** : pas de base chiffrée,
pas d’authentification réelle ni de synchronisation médicale.
Aucun nom de patient réel sur GitHub. Les éléments visuels sont embarqués
localement pour rester visibles sans réseau.

Vérification : `flutter pub get`, `flutter analyze`, `flutter test`.
Tester également Android, iOS et la mise à l’échelle des polices.
