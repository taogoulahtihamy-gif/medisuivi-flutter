# Sprint 5N : Splash éditorial, registres libres et typographie unifiée

## Problème observé (captures 14 octobre, 04:46-04:47)

- L'écran de lancement surchargeait la zone médiane de l'image et reléguait les informations importantes à des tailles inconsistantes.
- Les registres Patients et Bilans comportaient de petites lignes dans une grande boîte arrondie. Cela donnait une impression de tableau compact à l'intérieur d'une carte.
- Les polices et tailles variaient entre les modules, notamment dans les en-têtes et les zones éditoriales.

## Correction

1. **Splash** : photo HD locale inchangée, rédaction remontée avec surtitre, titre de taille cohérente, description lisible. La progression devient une vraie ligne à pleine largeur en pied d'écran, dissociée du texte, durée conservée à 2,8 s. Cet indicateur représente une transition visuelle, pas une mesure du chargement technique.
2. **Registres** : `ClinicalGroupedList` conserve l'API pour éviter toute régression, mais ne peint **plus de carte ni de contour autour de toute la liste**. Chaque dossier utilise `ClinicalListRow` comme ligne autonome et tappable avec séparateur discret. Le changement concerne Patients, Bilans, Suivi, Notifications et les pages Réglages qui réutilisent ces composants.
3. **Typographie** : une seule famille, **DM Sans**, pour tous les titres, paragraphes, chiffres, boutons, champs, listes et sous-pages. Police variable et licence OFL incluses dans `assets/fonts/`, déclarées dans `pubspec.yaml`. Aucune requête de police au CDN.
4. **Échelle** : tailles de référence dans `ClinicalTypeScale`, et titres de lignes à 16 points/secondaires à 13,8 points ; espace vertical confortable sans grossir les blocs.
5. **Pas de changement métier** : actions patients, états des bilans, suivi et navigation inchangés. La palette sombre et les thèmes ne changent pas.

## Validation avant fusion

- Analyse Flutter, suite de tests complète, compilation Web.
- Tests spécifiques DM Sans local, splash géométrie à 320/390 px, registres dégroupés.
- Inspection visuelle obligatoire sur navigateur et appareil Android (text scale 1.0 puis 1.2).
- La police est distribuée selon la [licence SIL Open Font License 1.1](https://openfontlicense.org/open-font-license-official-text/), copie dans `assets/fonts/OFL.txt`.

La PR reste en brouillon tant que les captures de la véritable application n'ont pas été revues.
