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


## Refonte immersive 5J (14 octobre 2026)

- **Splash** : photo médicale différente, plein écran sans cadre, fondu noir-vert ; chargement discret sous l'accroche, et non collé au bas.
- **Onboarding** : 3 photos vraiment distinctes ; textes directement sur le dégradé inférieur ; pagination sobre et bouton conservé.
- **Accès au compte** : cinquième photo plein écran, dégradé sombre pour que les trois actions restent lisibles, aucune carte.
- Sources de la démonstration : Pexels, photos 19957218 (démarrage), 5452252 (dossiers), 5214997 (suivi), 32254527 (examens), 19957215 (accès).
- Licence et usages autorisés : https://www.pexels.com/license/ ; ne pas présenter les personnes photographiées comme des utilisateurs ni comme des partenaires ou professionnels affiliés à MediSuivi.
- **Limite technique actuelle** : les nouvelles photographies sont chargées depuis des URLs publiques et exigent une connexion réseau. Si l'image distante ne charge pas, une photographie clinique de secours intégrée et un dégradé local sont affichés. Pour une véritable édition offline-first, figer et embarquer cinq photos optimisées dans `assets/` avant mise en production.
- Aucune donnée médicale, aucun dossier et aucune identité de patient ne sont ajoutés aux URLs des images. Néanmoins, une requête d'image communique l'adresse IP de l'appareil au CDN tiers : cette dépendance sera supprimée avant tout usage réel avec des données sensibles.


## Sprint 5L : images locales, lisibilité et cohérence des listes (2026-10-14)

- Les cinq portraits Pexels sont maintenant **tous fournis dans le paquet Flutter** sous `assets/images/onboarding/*.webp` (et déclarés dans `pubspec.yaml`). Aucun `Image.network` ni appel CDN depuis l'introduction de l'application en exécution.
- Les cinq originaux restent des scènes distinctes : splash, dossiers, suivi, espace personnel, accès ; une copie optimisée WebP HD est téléchargée par `tools/bundle_onboarding_images.py` avant packaging (script reproductible, utilisation selon https://www.pexels.com/license/).
- Le splash reste visible environ **2,8 secondes** après le démarrage du parcours, avec barrette animée alignée sur cette durée, textes élargis et remontés. Cette barre est une animation de bienvenue et **ne mesure pas le chargement technique réel** de l'appareil.
- `ClinicalGroupedList` et `ClinicalListRow` sont la base des listes Patients, Bilans, Suivi et Notifications : une surface par groupe, séparateurs discrets, densité réglable (compacte/confortable).
- Dans les Paramètres supplémentaires : deux préférences visuelles fonctionnelles, réduction des animations et densité des listes, stockées localement via `flutter_secure_storage` (sans données médicales).
- Les pages Données/Stockage, Synchronisation et Confidentialité présentent des informations locales vérifiables et donnent accès aux registres ou écrans existants. Les fonctions qui exigent un compte authentifié restent indisponibles.
- **Limite actuelle** : l'avatar du praticien reste une prévisualisation en mémoire et ne persiste pas après redémarrage. Les photos de l'onboarding, elles, sont bien persistantes dans l'APK/l'application Web livrée. Le véritable compte et la sauvegarde sécurisée relèvent d'un futur sprint.
