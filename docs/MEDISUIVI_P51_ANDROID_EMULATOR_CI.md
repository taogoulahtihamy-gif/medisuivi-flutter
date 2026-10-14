# P5.1 — Android connecté à l'API Vercel : tests GitHub

Statut : **en cours de validation**. Un build `Ready` sur Vercel prouve la
publication de FastAPI, **pas** le fonctionnement Android ni la compatibilité
avec un téléphone physique.

## Cible sans hébergement Web

- Interface : MediSuivi Flutter **original**, sans seconde interface.
- Android : APK `com.example.medisuivi.sandbox` (`MediSuivi Test`).
- Backend distant : `https://medisuivi-api-staging.vercel.app`.
- Base : Neon `medisuivi_sandbox`, sans données cliniques réelles.
- Aucune nécessité de déployer Flutter Web ou un serveur sur le PC.

## CI automatisée

Ouvrir `Actions > MediSuivi P5.0 remote HTTPS Android APK`, sélectionner
`feat/medisuivi-p50-vercel-api-neon` et vérifier :

1. **Android APK pointing to Vercel HTTPS** : tests Flutter, production
   de `app-debug.apk`, signature Android debug, permission Internet et
   identifiant de package distinct.
2. **Android 29 HTTPS + original UI** : émulateur Android **10**.
3. **Android 35 HTTPS + original UI** : émulateur Android **15**.

Chaque émulateur installe **l'APK produite dans le même run**, démarre
l'activité Flutter, puis exécute des tests d'intégration Android natifs avec
Flutter `integration_test` :

- Résolution du domaine Vercel, TLS Android et `GET /health` = HTTP 200 ;
- `GET /ready` = HTTP 200, disponibilité de l'API et de la base Neon ;
- `GET /api/v1/me` et `GET /api/v1/patients` sans token refusés (401/403) ;
- démarrage de l'interface **MediSuivi originale** sans erreur Flutter.

Ces requêtes ne créent **aucun compte**, patient, consultation, dossier, mot de
passe ou jeton. Elles ne contournent pas la protection Vercel : l'API de
staging doit être accessible normalement aux applications installées, tout en
protégeant ses ressources par JWT.

Après réussite du workflow : ouvrir le run > **Artifacts** :
- `medisuivi-p50-vercel-connected-android-debug-apk` : APK de test ;
- `medisuivi-android-29-screenshot` : capture de l'émulateur Android 10 ;
- `medisuivi-android-35-screenshot` : capture de l'émulateur Android 15.

L'artefact APK est conservé 7 jours. Une capture est conservée 3 jours.
**Ne pas prendre une ancienne APK « render-connected » pour cette version.**

## Ce que la CI ne démontre pas

- Un émulateur **n'est pas un téléphone physique** : pas de preuve matérielle
  concernant les fabricants, KeyStore/biométrie réels, carte SIM, réseaux
  mobiles, veille/batterie ou conditions de faible débit.
- Les endpoints de santé ne démontrent pas le parcours utilisateur complet.
  Les tests `flutter_test` valident les scénarios d'authentification avec
  réponses simulées, et les tests Android ci-dessus valident **le vrai HTTPS**
  sans identifiants, pas une connexion réelle d'un praticien.
- Une APK debug signée par GitHub Actions peut être incompatible pour une
  mise à jour sur une APK debug signée par une **autre clé**.
- Avant de conclure à la compatibilité réelle : tester sur un Android physique
  (ou appareil distant réel) la création/connexion d'un compte fictif, le
  changement de compte, les dossiers fictifs, l'isolation A/B, la reprise de
  session, le stockage sécurisé et la reconnexion.

**Sécurité** : ne pas placer le mot de passe, les invitations, le JWT ou le
jeton Vercel dans les `--dart-define`, l'APK, les logs, les captures ou le
dépôt. Les secrets apparus dans des captures historiques doivent être
renouvelés avant tout test public.
