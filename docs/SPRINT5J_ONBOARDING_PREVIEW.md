# Sprint 5J : Démarrage, onboarding et prévisualisation praticien

## Livré dans cette branche

- Écran MediSuivi avec barre horizontale de progression animée (~1,2 seconde après la préparation réelle des ressources).
- Onboarding en trois pages, transitions horizontales, indicateur de progression et fonction « Passer ».
- Choix « Créer un compte », « Se connecter », ou accès explicite aux données locales/démonstration.
- Formulaire de prévisualisation : prénom, nom, e-mail, téléphone, spécialité, photo de galerie facultative (redimensionnée côté client).
- Avatar sélectionné visible en haut à droite, modification du profil de prévisualisation dans Réglages.
- Respect du thème clair/sombre et de MediaQuery.disableAnimations.
- Pas de modification du ClinicalStore, SQLite chiffré, outbox ou signature Android.

## Limite de sécurité impérative

**Cette itération ne crée aucun compte réel, n'authentifie pas un utilisateur et ne synchronise rien.**

Les informations de prévisualisation, y compris la photo, sont conservées uniquement en mémoire et disparaissent après fermeture/redémarrage. La page « Se connecter » ne demande **aucun mot de passe** sans serveur. Le parcours permet un accès clairement identifié à la démo Web (patients fictifs) ou, sur Android, aux dossiers déjà protégés localement. Aucun faux jeton ni session n'est créé.

## Compte réel à livrer séparément

- API FastAPI + PostgreSQL : identité, inscription vérifiée, connexions, sessions, réinitialisation, protection anti-bruteforce.
- Un compte correspond à un praticien unique ; les dossiers des patients sont strictement rattachés à cet utilisateur côté serveur.
- Authentification et autorisation contrôlées systématiquement par l'API et la base.
- Photo chiffrée et persistante, gestion de suppression et confidentialité.
- Séparation données réelles/démonstration et rattachement explicite d'une base locale existante.
- Synchronisation offline-first, restauration sécurisée et audit clinique sans écrasement silencieux.
- Tests de cloisonnement entre praticiens et d'accès non autorisé.

## Contrôles

- flutter pub get ; flutter analyze --no-fatal-infos ; flutter test ; flutter build web
- Firefox 320 / 360 / 390 px en clair et sombre.
- Android réel : déverrouillage chiffré puis onboarding, galerie, avatar, Réglages, fermeture et redémarrage.

**PR Draft sur la branche 5I ; aucune fusion automatique.**
