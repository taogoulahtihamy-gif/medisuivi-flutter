# MediSuivi P4.6 : essais Android physiques avec FastAPI local

**Périmètre : développement et données entièrement fictives.** Aucun dossier de santé réel. Ne pas publier ni considérer ce build comme une application clinique homologuée.

## Architecture sécurisée

- FastAPI tourne sur Ubuntu : `http://127.0.0.1:8027` ; PostgreSQL MediSuivi reste sous le projet Docker `medisuivi`.
- Le téléphone USB utilise `adb reverse tcp:8027 tcp:8027`. Android peut alors contacter le même `http://127.0.0.1:8027` sans exposition de l'API sur le réseau Wi-Fi.
- **Seul le manifeste Android debug** autorise HTTP sur les hôtes explicites `127.0.0.1`, `localhost` et `10.0.2.2`. Toute autre destination HTTP reste bloquée.
- Les builds installés non-debug déclarent INTERNET mais n'activent pas d'exception HTTP. Un hébergement distant devra fournir HTTPS avec certificat valide.
- `android:allowBackup=false`, `android:fullBackupContent=false` et les règles Android 12+ excluent les fichiers de l'application des sauvegardes/transferts automatiques. Le stockage sécurisé des jetons de session n'est pas censé être restauré sur un autre appareil.
- Le mode connecté utilise `MEDISUIVI_DEV_API_BASE_URL` et ne doit jamais ouvrir automatiquement l'ancienne base locale `medisuivi.db`.
- Les comptes authentifiés sont validés par JWT côté FastAPI, sans réutilisation des dossiers d'un autre praticien.

## Préparation du poste

Sur Ubuntu, vérifier les deux routes avant tout essai :

```bash
curl --noproxy '*' -fsS http://127.0.0.1:8027/health
curl --noproxy '*' -fsS http://127.0.0.1:8027/ready
```

Les réponses attendues sont `{"status":"ok","environment":"non-production"}` et `{"ready":true}`.

Pour ne pas modifier les fichiers locaux non committés du dépôt principal, créer un worktree P4.6 :

```bash
cd /mnt/chak/medisuivi-flutter
git fetch origin feat/medisuivi-p46-android-device-staging
git worktree add --detach /mnt/chak/medisuivi-p46-android \
  origin/feat/medisuivi-p46-android-device-staging
cd /mnt/chak/medisuivi-p46-android
flutter pub get
python3 scripts/check_android_p46_security.py
flutter test test/p42_secure_session_resume_test.dart \
  test/p42_session_gate_test.dart \
  test/p45_clinical_session_race_test.dart
```

Si le worktree existe déjà, vérifier son contenu ; ne pas le supprimer aveuglément.

## Connexion du téléphone

Utiliser un **téléphone de test** avec débogage USB autorisé, ou un appareil/profil contenant uniquement des données fictives. Une APK de debug peut avoir le même identifiant de paquet que la précédente version de démonstration. **Ne pas désinstaller** une application déjà installée pour contourner un échec de signature : cela efface ses données locales. Demander un traitement explicite de l'ancienne installation.

```bash
cd /mnt/chak/medisuivi-p46-android
bash scripts/p46_android_usb_preflight.sh
```

Le script vérifie la disponibilité de FastAPI, un seul appareil Android physique autorisé, configure le tunnel USB et détecte la présence de l'ancienne application **sans rien installer**.

Si le téléphone est prêt et qu'aucune installation incompatible n'est présente :

```bash
flutter devices
flutter run --debug --dart-define=MEDISUIVI_DEV_API_BASE_URL=http://127.0.0.1:8027
```

Au besoin préciser `-d <identifiant_adb>` (affiché localement par `adb devices -l`). Aucun secret de connexion ne doit être passé dans `--dart-define`. Les identifiants des comptes fictifs sont saisis dans l'application.

**Attention :** le tunnel `adb reverse` n'est pas permanent. Le recréer après déconnexion USB, redémarrage d'ADB ou du téléphone. Une application installée hors USB n'accédera pas à `127.0.0.1:8027` sur ton ordinateur. Ne pas utiliser `0.0.0.0` ni ouvrir le port 8027 sur Internet pour contourner cette limitation.

## Recette sur Android physique (avec données fictives)

1. Tester `/health` et `/ready` sur Ubuntu et le script de prévol USB.
2. Inscrire un praticien de test A ou se connecter à un compte de test dédié. Ne jamais saisir de vrais identifiants médicaux.
3. Créer un dossier fictif A, puis visite, examen et suivi. Noter uniquement le **nombre de dossiers** et les réponses de l'application, sans recopier de jetons ni dossiers dans les logs.
4. Fermer complètement et rouvrir l'application. Vérifier que le renouvellement de session utilise le stockage sécurisé et la confirmation serveur avant d'afficher les dossiers.
5. Déconnecter A, se connecter à B et confirmer que les dossiers de A n'apparaissent pas, y compris après un redémarrage.
6. Couper le tunnel USB (`adb reverse --remove tcp:8027`) pour simuler l'indisponibilité réseau. Vérifier qu'aucune donnée clinique mise en cache n'apparaît depuis la session précédente.
7. Recréer le tunnel et vérifier que le chargement repart depuis l'API avec le compte courant.
8. Vérifier le refus des opérations anonymes et le comportement des sessions invalidées. Ne pas réutiliser de jetons dans un fichier de logs.

**État réel :** les tests simulés Flutter et PostgreSQL valident les garde-fous, mais les scénarios ci-dessus ne deviennent « validés sur Android » qu'après exécution sur un téléphone.

## CI

Le workflow `.github/workflows/medisuivi_p46_android_ci.yml` :
- vérifie les manifestes et les règles de transfert Android ;
- exécute les tests de restauration de session et de réponses cliniques tardives ;
- construit une APK **debug** reliée à l'API loopback ;
- vérifie son archive, sa signature debug et sa permission INTERNET ;
- conserve l'APK comme artefact temporaire pour les essais sur un téléphone de test.

Cette APK n'est pas signée pour diffusion, n'intègre pas de données de santé et **n'est pas** une release de production. Avant tout hébergement, il reste à assurer HTTPS public, fournisseur e-mail, audits de sécurité, politique de sauvegarde/restauration et conformité CDP sénégalaise.

## Données à préserver

- PostgreSQL MediSuivi actuel `medisuivi_pgdata`, port 5437 ;
- ancien volume `backend_pgdata` et sauvegarde `/mnt/chak/medisuivi-local-backups/medisuivi-before-p44-compose.dump` ;
- ERP `erp_postgres_data` et services ERP/Chak.

Ne jamais lancer `docker compose down -v`, `--remove-orphans`, ni `adb uninstall` pendant cette recette.
