# Sprint 4D · Compatibilité APK Android, Samsung Galaxy S9+

## Constats de départ

- Le premier APK debug s'installait sur un Samsung Galaxy S9+, mais l'application affichait une erreur d'initialisation de la clé au démarrage.
- Le correctif Android (commit `3919a8d`) introduit `FlutterFragmentActivity`, la permission biométrique et le repli vers l'authentification par code de l'appareil.
- Un APK ultérieur construit sur GitHub a été refusé par le téléphone avec « Application non installée », même après désinstallation déclarée de la version antérieure.
- Aucun message `INSTALL_FAILED_...` ni logcat du Galaxy S9+ n'a été obtenu : **la cause réelle du refus d'installation n'est pas connue**.
- Le SDK Android manque sur l'Ubuntu local et le téléphone n'est pas accessible pour le moment.

## Banc de test CI

Workflow : `.github/workflows/android-compatibility.yml`, isolé sur la branche `fix/medisuivi-4d-android-compat`.

1. Compiler un APK debug avec Flutter 3.47.7 et Java 17, sans modifier le code médical.
2. Vérifier l'intégrité ZIP, la signature `apksigner`, l'alignement `zipalign`, les métadonnées `aapt`, le package `com.example.medisuivi`, les bibliothèques `libflutter.so` ARM64 et x86_64.
3. Installer exactement cet APK sur les émulateurs x86_64 Android API 29 (Android 10) et API 26 (Android 8).
4. Enregistrer le retour d'`adb install`, lancer `MainActivity`, attendre 20 secondes, vérifier que le processus est présent, fournir capture d'écran et journaux Android filtrés.
5. Publier les diagnostics comme artifacts CI pour analyse.

## Limites et sécurité

- Un émulateur x86_64 n'est **pas** un Galaxy S9+ ARM64/One UI. La vérification statique ARM64 ne remplace pas un essai sur appareil physique.
- `adb install` réussi signifie seulement « installation acceptée ». Le maintien du processus ne prouve pas que la base SQLite est déverrouillée ni que les pages cliniques sont accessibles.
- La biométrie et le PIN d'un Galaxy S9+ ne sont pas reproduits fidèlement. Une capture d'écran peut montrer l'écran d'erreur malgré un processus actif.
- Aucune donnée de patient réel, aucun contournement de l'authentification, aucune suppression de base et aucune modification du chiffrement.
- La signature debug peut différer entre runners GitHub éphémères. Une signature stable sera étudiée après diagnostic et nécessite une clé privée conservée hors Git ; ne pas en générer ici.
- L'APK inspecté ne peut pas être considéré comme **validé sur Galaxy S9+** avant un essai sur l'appareil et une analyse de l'éventuelle erreur d'installation.
- Ce document décrit un protocole. Les résultats des jobs GitHub seront ajoutés uniquement après leur exécution réelle.

## Prochaines vérifications

- Consulter `medisuivi-apk-inspection`, `medisuivi-android-api-29-diagnostics` et `medisuivi-android-api-26-diagnostics`.
- Si les émulateurs installent l'APK, analyser les captures du premier écran et les logs afin de distinguer erreur d'authentification, SQLite et crash.
- Dès que le téléphone redevient accessible, capturer le statut d'installation exact via ADB ou Android Package Installer.

## Exécutions intermédiaires du banc de test

- Première exécution : l'émulateur démarre mais l'action exécute `set -euo pipefail` dans `/bin/sh`, qui refuse `pipefail`. **Aucune installation testée**.
- Deuxième exécution (commit `312f3f7`) : Android 10 / API 29 accepte l'APK avec `adb install` → `Success`. Le `script: |` était néanmoins exécuté en commandes séparées par l'action, ce qui perdait la variable `APP` avant le lancement. Android 8 / API 26 échouait sur un `adb logcat -c` non essentiel. **Démarrage non validé**.
- Correctif suivant : script Bash autonome `.github/scripts/android-emulator-smoke.sh`, exécuté en une seule commande ; purge logcat facultative ; validation explicite de `Success`, du paquet et du processus. Les résultats complets devront être confirmés par une nouvelle CI.
