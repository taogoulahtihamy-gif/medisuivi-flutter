# P5.2 — Vérifications Android A/B et API Vercel sur GitHub

**Objectif** : valider les parcours de MediSuivi avec son interface Flutter
originale, sans nouvelle interface, serveur local ou déploiement Web.

## Trois niveaux de preuve (à ne pas confondre)

| Niveau | Environnement | Ce qui est testé |
|---|---|---|
| 1 | CI backend + PostgreSQL `medisuivi_ci` **jetable** | Inscription fictive avec invitation, authentification réelle FastAPI, données distinctes A/B, refus de lecture inter-comptes, sessions |
| 2 | Android 10 (API 29), Android 15 (API 35) sur GitHub Actions | Installation et ouverture de l'APK, interface originale et navigation A→déconnexion→B avec serveur HTTP **simulé**, Android Keystore **réel** |
| 3 | Depuis chaque émulateur vers Vercel + Neon | TLS, santé/disponibilité, refus d'accès aux patients sans JWT, refus d'inscription sans invitation (**aucune écriture distante**) |

Le scénario Android A/B utilise `MockClient` pour contrôler les identités et
réponses serveur et éviter de placer des mots de passe de comptes de test dans
l'APK. Le test **n'affirme pas** qu'une connexion positive avec identifiants
réels sur Vercel a eu lieu. La création de comptes et de dossiers réels sur la
sandbox Neon doit être validée ultérieurement de façon contrôlée.

## Fichiers

- `integration_test/p50_vercel_android_emulator_test.dart` :
  disponibilité HTTPS/Neon et lancement du vrai Flutter original.
- `integration_test/p52_account_flows_android_test.dart` :
  authentification fictive, changement d'utilisateur, absence de données
  croisées, stockage `flutter_secure_storage` sur émulateur physique virtuel,
  inscription distante sans invitation refusée.
- `scripts/ci_p50_android_emulator.sh` : exécute ces deux suites sur chaque
  émulateur avec l'API `https://medisuivi-api-staging.vercel.app`.
- `.github/workflows/medisuivi_p50_remote_android.yml` : compilation de la
  même APK pour les deux suites, émulateurs API 29 et 35, captures anonymes.

## Résultats attendus et règles

- Aucune donnée du `DemoStore` ne doit apparaître une fois connecté au
  store distant simulé.
- Après déconnexion d'A, l'écran connecté d'A disparaît. B voit seulement ses
  propres dossiers. Aucun jeton A ne doit être envoyé à la place d'un jeton B.
- Keystore Android conserve un identifiant UUID de compte serveur, l'URL API,
  et seulement le jeton de renouvellement. Le changement de compte remplace
  ce jeton et la déconnexion l'efface.
- Un visiteur sans invitation ne peut pas créer de compte sur Neon.
- `GET /api/v1/patients` avec un JWT invalide doit être refusé.
- Les tests sans identifiants ne doivent jamais écrire sur Neon ni demander un
  contournement d'authentification Vercel.

## Après un workflow vert

Télécharger depuis les artefacts GitHub :
`medisuivi-p50-vercel-connected-android-debug-apk` et les captures Android
29 et 35. Vérifier le bon thème, la lisibilité et l'affichage du vrai
MediSuivi sans une deuxième interface.

**Limite actuelle** : ni un émulateur, ni un client HTTP simulé ne remplace
un smartphone physique ou un parcours positif complet sur le service public
Vercel. Avant un test distant positif, ajouter une **invitation sandbox
renouvelée** et des identifiants synthétiques via un canal protégé
(GitHub Actions secrets) : ne pas les publier dans Git, l'APK, les logs,
les captures, les `--dart-define` ou ChatGPT.

**Ne pas fusionner sur main ni utiliser de vraies données cliniques** avant
une revue de sécurité et les validations nécessaires.
