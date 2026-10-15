# MediSuivi P5.3 — authentification et déconnexion

Branche dédiée : `feat/medisuivi-p53-auth-settings`, basée sur `442f72e`.
Travail isolé dans `/tmp/medisuivi-p53`. Les fichiers locaux modifiés des
worktrees P4.4 et P5.0 sont conservés sans modification.

## Changements

- Accueil vertical : identité compacte en haut, titre à gauche, actions en bas.
- Connexion et inscription sans carte englobante, palette existante, défilement,
  adaptation au clavier et au texte agrandi, erreurs annoncées aux lecteurs d’écran.
- Invitation sandbox conservée, jamais fournie par le code ou le binaire.
- Suppression de `original-connected-signout`. Action `settings-signout` dans
  les paramètres, disponible uniquement sous le scope authentifié.
- Le scope transporte un callback uniquement. La procédure de déconnexion reste
  unique : verrouillage immédiat, retrait du navigateur du compte, révocation,
  nettoyage des jetons via DevAuthApi et retour à la connexion.
- Nettoyage rédactionnel dans l’ensemble de lib/ : suppression des pieds de page
  répétitifs et des explications internes, y compris dans les anciens écrans auth.
- Corrections mécaniques de lint (const, override, accolades, imports) nécessaires
  pour exécuter `flutter analyze` strictement dans la CI.
- `pubspec.lock` remis en cohérence par `flutter pub get` avec les dépendances déjà
  déclarées (image_picker, integration_test, http). Aucune nouvelle dépendance.

## Audit rédactionnel

Recherches dans tous les fichiers Dart de lib/ : démo/demo, fictif, sandbox,
développement, prévisualisation, backend, stockage local et version de test.
Chaque occurrence restante appartient à l’une de ces catégories :

- code, noms de classes, commentaires, paramètres et contrôles de sécurité ;
- données synthétiques et noms `PATIENT FICTIF`, nécessaires à leur identification ;
- validations d’identité fictive, invitation et contraintes du compte de test ;
- confidentialité, À propos, limites de stockage et disponibilité hors ligne ;
- action explicite d’entrée dans la démonstration locale sans compte.

Les indications répétitives ont été retirées des formulaires médicaux, alertes,
profil, connexion et paramètres. Les restrictions réelles de l’environnement
restent actives. Aucun changement des ressources Neon ou Vercel, aucun déploiement
Web ou Render, aucune utilisation clinique réelle autorisée.

## Validation

Résultats locaux :
- `flutter pub get` réussi ; formatage vérifié (0 changement au second passage).
- `flutter analyze` : aucun diagnostic.
- `flutter test` : 253 tests réussis.
- Invitation P5.0 : 2 tests réussis avec `MEDISUIVI_REMOTE_SANDBOX=true`.
- Matrice P5.3 avec invitation activée : 17 tests réussis supplémentaires.
- Navigation des trois écrans : 8 tests ; revue visuelle Web locale à 390×844
  et 320×640, bouton de création accessible par défilement.
- Vercel réel : health 200, ready 200, me/patients anonymes 401.

Backend : [run réussi](https://github.com/taogoulahtihamy-gif/medisuivi-flutter/actions/runs/38662036426),
40 tests API et 7 gardes Vercel ; job PostgreSQL et invitation sandbox réussi.
L’essai local backend ne pouvait pas collecter les tests (FastAPI absent).

[PR P5.3](https://github.com/taogoulahtihamy-gif/medisuivi-flutter/pull/48).
Les résultats Android et l’APK se trouvent dans le workflow
`medisuivi_p50_remote_android.yml`, artefact
`medisuivi-p53-vercel-connected-android-debug-apk`.
Le bilan de livraison de la PR précise le run final et l’empreinte de l’APK.
Les tests PostgreSQL utilisent uniquement le service PostgreSQL jetable GitHub.
Les scénarios Android A/B utilisent des réponses HTTP simulées et des identités
synthétiques ; les contrôles HTTPS Vercel sont réels et anonymes. Ils ne prouvent
pas une connexion authentifiée de bout en bout contre Neon.

L’APK est un debug sandbox, pas une publication Play Store ni une version certifiée.
iOS et Android physique ne sont pas disponibles dans cet environnement.
