# MediSuivi — Sprint 2, Nocturne Clinique

## Périmètre validé sur la branche `feat/medisuivi-premium-redesign`

- **Thèmes réellement activés** : `MediTheme.light()`, `MediTheme.dark()`, `ThemeMode.system` dans l'application Flutter. Une surcharge `themeMode` facultative sert à tester chaque rendu.
- **Navigation mobile** : barre de 64 px intégrée au thème actuel, libellés accessibles, transition courte (réduite à 0 lorsque le système demande moins d'animations).
- **Tablette, dès 600 px** : `NavigationRail` compact, tous les libellés affichés.
- **Desktop, dès 1024 px** : rail étendu avec libellés, contenu principal flexible.
- **Accueil** : actions reconfigurées sous 310 px de largeur disponible pour éviter que les boutons recouvrent la photographie ou débordent.
- **Formulaire de suivi** : date et heure en deux lignes lorsque le bloc est trop étroit ; largeur tactile intacte.
- **Mode sombre sur les fiches médicales** : les composants historiques utilisent `Palette.of(context)` depuis Sprint 1 ; le thème désormais activé diffuse la palette appropriée aux dossiers, bilans, consultations et suivis.
- **Qualité** : branche de refonte incluse dans GitHub Actions. Analyse Flutter (errors + warnings bloquants), tests complets, compilation Web release. Les suggestions de style (`info`) restent à nettoyer progressivement.

## Contrôles de validation

1. Tester un écran de 320 px et de 360 px pour les onglets, l'accueil et le formulaire d'un suivi.
2. Vérifier la navigation tablette à 600 px et desktop à 1100 px.
3. Vérifier le mode clair et le mode sombre depuis les tests indépendants des réglages du système.
4. Confirmer le parcours existant : Patients → Dossier médical → Bilans → Voir le résultat → Retour.
5. Confirmer le parcours Suivi → Programmer → Modifier → Terminer.
6. Refuser tout `RenderFlex overflow` et toute exception Flutter.
7. Ne pas fusionner sans validation CI et revue visuelle sur un appareil réel.

## Limites et décisions

- Pas de modification du backend, de la logique médicale, des DAO Drift, de l'authentification ou du système de chiffrement dans ce sprint.
- Ne jamais utiliser de dossiers patients réels tant que l'authentification, le chiffrement local effectif, les sauvegardes et les tests de sécurité ne sont pas validés.
- Les noms de familles Fraunces / DM Sans / JetBrains Mono figurent dans les tokens ; ils doivent être **réellement embarqués et déclarés dans `pubspec.yaml`** avant de pouvoir affirmer que ces polices sont utilisées hors connexion. Actuellement, le rendu retombe sur les polices système quand une famille n'est pas disponible.
- Le basculement manuel clair/sombre dans les paramètres et les micro-interactions sur téléphone physique restent à évaluer séparément. La valeur par défaut est le thème du système.
