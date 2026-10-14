# Sprint P4.2 : session mobile chiffrée, restauration en ligne

**Statut** : base de développement et comptes synthétiques uniquement.

Cette PR se base sur P4.1 (#34), sans fusion dans `main`, aucun hébergement.

## Comportement

- `flutter_secure_storage` sur Android KeyStore / iOS Keychain conserve **un seul enregistrement actif** : la version, l'URL exacte du backend, l'UUID du praticien et le dernier *refresh token*. Aucune donnée patient, e-mail, photo, mot de passe ni jeton d'accès n'y est enregistré.
- Flutter Web et les applications desktop n'utilisent **aucune persistance** d'authentification.
- Après le splash, une application Android/iOS peut restaurer la session uniquement via `POST /api/v1/auth/refresh` puis `GET /api/v1/me`, en comparant l'identifiant serveur avec celui du stockage local.
- Le jeton renouvelé remplace le précédent après connexion et lors de chaque renouvellement automatique.
- Une révocation serveur ou un compte différent supprime la session enregistrée.
- En cas de réseau indisponible, aucun dossier privé n'est affiché. L'utilisateur peut réessayer ou demander une nouvelle connexion ; l'erreur réseau ne détruit pas immédiatement le jeton enregistré.
- Une déconnexion volontaire, la déconnexion de tous les appareils et le changement de mot de passe suppriment les identifiants de la mémoire et du stockage protégé. En cas d'erreur du stockage protégé, la restauration est refusée.
- L'ancien `medisuivi.db` et le `DemoStore` ne sont jamais lus comme des données d'un compte authentifié.

## Tester sur Android

D'abord valider les tests automatisés et démarrer l'API de **développement** sur une machine accessible au téléphone. Un émulateur Android peut utiliser le pont localhost `10.0.2.2`, mais un téléphone physique utilisera **une URL HTTPS** pour ce test, jamais une adresse de localhost inaccessible ni un certificat non fiable.

Construire une application **de développement** configurée explicitement :
```bash
flutter run -d <ANDROID_DEVICE_ID> \\
  --dart-define=MEDISUIVI_DEV_API_BASE_URL=https://API_TEST_HTTPS_EXEMPLE
```
L'adresse ci-dessus est un exemple, pas un serveur déployé.

Scénarios physiques :
1. Se connecter avec le praticien fictif A, puis fermer complètement et rouvrir l'application. La session doit être restaurée en ligne et son identité contrôlée.
2. Interrompre Internet, tuer puis relancer l'application. Aucun dossier ne doit être accessible hors connexion.
3. Réactiver Internet et réessayer. La restauration doit fonctionner si la session serveur est encore valide.
4. Changer de praticien et se connecter avec B. Fermer et rouvrir : seul B doit être restauré, sans dossier A.
5. Déconnecter tous les appareils, puis relancer : aucune session révoquée ne doit être restaurée.
6. Modifier le mot de passe : les anciennes sessions doivent devenir inutilisables.

## Blocages avant production

- Tests physiques Android/iOS du stockage KeyStore/Keychain et sauvegarde/restauration après migration d'appareil.
- Isoler le stockage clinique offline par compte et éviter d'ouvrir la base historique partagée avant l'authentification (P4.0 est encore expérimental).
- Durcissement réseau (détection de vol/rejeu et protection des jetons), contrôle d'identité et authentification forte adaptés à la santé, vérification e-mail avec vrai fournisseur.
- Sauvegardes PostgreSQL, audit, conformité sénégalaise/CDP, revue humaine, tests d'intrusion et architecture de production.

**Aucune donnée de santé réelle ni exposition publique permise.**
