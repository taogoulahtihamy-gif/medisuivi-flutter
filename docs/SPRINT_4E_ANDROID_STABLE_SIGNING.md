# Sprint 4E · Distribution Android signée et reproductible

## But et situation actuelle

Le workflow classique `.github/workflows/medisuivi-apk-demo.yml` fabrique un **APK debug** avec une signature de débogage potentiellement différente d'un runner GitHub à l'autre. Il est utile pour les vérifications, mais **ne garantit pas des mises à jour installables**.

Le workflow séparé `.github/workflows/medisuivi-stable-demo.yml` fabrique lors d'une publication sur la branche de développement **un APK release signé avec une clé privée conservée uniquement par le propriétaire**, vérifie l'empreinte publique du certificat et teste le démarrage chiffré sur un émulateur Android 10 avant de publier `MediSuivi-V1-Android-Stable-Demo`.

Il ne fusionne pas du code et ne signe rien tant que les secrets manquent. Sans ces secrets, ce workflow échoue explicitement. La validation Flutter et les APK debug restent indépendants.

## Configuration initiale (à faire UNE FOIS, localement et en privé)

Prérequis : Java/JDK avec `keytool` sur ton propre ordinateur. **Ne transmets jamais le keystore, ses mots de passe ou son contenu Base64 dans le chat ni dans un commit.**

1. Générer hors du dépôt un keystore privé PKCS12 et le **sauvegarder durablement hors de GitHub**. Exemple (le mot de passe est demandé par `keytool`) :

   ```bash
   mkdir -p "$HOME/medisuivi-private-signing"
   chmod 700 "$HOME/medisuivi-private-signing"
   keytool -genkeypair -v -storetype PKCS12 \
     -keystore "$HOME/medisuivi-private-signing/medisuivi-demo.p12" \
     -alias medisuivi-demo -keyalg RSA -keysize 3072 -validity 3650 \
     -dname "CN=MediSuivi Demo, OU=Development, O=MediSuivi, C=SN"
   chmod 600 "$HOME/medisuivi-private-signing/medisuivi-demo.p12"
   ```

2. Obtenir l'empreinte SHA-256 **publique** du certificat (la valeur sous `SHA256:`, en retirant les `:` et espaces) :

   ```bash
   keytool -list -v \
     -keystore "$HOME/medisuivi-private-signing/medisuivi-demo.p12" \
     -alias medisuivi-demo
   ```

3. Dans le dépôt GitHub, **Settings → Secrets and variables → Actions → Repository secrets**, ajouter :

   | Nom exact du secret | Valeur |
   | --- | --- |
   | `MEDISUIVI_DEMO_KEYSTORE_BASE64` | Base64 intégral du fichier `.p12` (sans retour à la ligne) |
   | `MEDISUIVI_DEMO_STORE_PASSWORD` | Mot de passe privé du keystore |
   | `MEDISUIVI_DEMO_KEY_ALIAS` | `medisuivi-demo` |
   | `MEDISUIVI_DEMO_KEY_PASSWORD` | Mot de passe privé de la clé (souvent identique au mot de passe du PKCS12) |

   Pour encoder localement le fichier, sans l'envoyer à un service tiers : `base64 -w 0 "$HOME/medisuivi-private-signing/medisuivi-demo.p12"`. Copier directement la sortie dans le champ secret GitHub, sans la partager dans ce chat. Éviter de conserver une copie texte Base64 non protégée.

4. Dans **Repository variables**, ajouter `MEDISUIVI_DEMO_CERT_SHA256` avec les 64 caractères hexadécimaux du certificat, sans `:`.

5. Conserver une sauvegarde chiffrée et hors machine du `.p12` et des mots de passe. **Perdre la clé empêche de publier une mise à jour reconnue comme signée par le même développeur**.

## Générer et récupérer un APK stable

- Le workflow démarre **automatiquement lors d'un push sur** `feat/medisuivi-premium-redesign` (notamment après fusion de sa pull request). Sur GitHub, ouvrir **Actions → MediSuivi signed demo APK**.
- Important : GitHub ne permet pas toujours le déclenchement manuel `workflow_dispatch` d'un workflow absent de `main`. Comme nous ne modifions pas `main`, utiliser le déclenchement `push`. Si la première exécution échoue faute de secrets, terminer la configuration puis utiliser **Re-run all jobs**, ou déclencher un nouveau push approuvé sur la branche d'intégration.
- Le workflow vérifie la signature, le package, le certificat et les ABI ARM64/x86_64. Il **ne doit être fusionné qu'une fois les secrets configurés**, sauf si l'on accepte un premier workflow rouge sans livrable final.
- Il installe l'**APK release exact** sur l'émulateur Android 10 avec PIN fictif, puis exige `MEDISUIVI_BOOT_READY`.
- **Uniquement si tous les jobs passent**, récupérer l'artifact final `MediSuivi-V1-Android-Stable-Demo`.
- Les journaux/captures CI sont des diagnostics de test, pas une preuve de validation sur le Galaxy S9+.

## Mise à jour et conservation des données

- Conserver **le même `applicationId`** (`com.example.medisuivi`) et **exactement le même certificat** à chaque publication.
- Le `versionCode` croît avec le numéro d'exécution du workflow (`10000 + GITHUB_RUN_NUMBER`).
- **Le premier passage d'un APK debug à un APK signé stable ne peut généralement pas être installé comme une mise à jour** si les certificats diffèrent. Android peut afficher `INSTALL_FAILED_UPDATE_INCOMPATIBLE`. Une désinstallation détruit les données locales de l'application : NE PAS désinstaller si des dossiers doivent être conservés.
- La conservation des données SQLite après mise à jour nécessite un test d'intégration distinct (création fictive → fermeture → nouvelle version → réouverture et vérification) ; elle **n'est pas encore démontrée** par le smoke test de démarrage.
- Le refus d'installation observé sur le Samsung Galaxy S9+ ne dispose toujours pas d'une cause racine vérifiée. Il faut mesurer son Android réel, l'erreur du gestionnaire de paquets et la signature installée.
- Android 8 / API 26 **n'est pas validé pour l'authentification** (voir issue #4), même si le manifest autorise l'installation. Ne pas déclarer « Android 8+ validé ».

## Sécurité

- La clé privée reste hors du dépôt et hors des artifacts.
- Si un secret manque ou si l'empreinte ne correspond pas, le workflow échoue et **aucun artifact final** n'est publié.
- Cette V1 reste une **démonstration avec données fictives**, sans backend, comptes utilisateurs réels ni synchronisation.
- Ne pas utiliser avec des données de patients réels avant validation des contrôles d'accès, audit clinique, sauvegarde/récupération et exigences légales.
