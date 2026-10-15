# MediSuivi P5.4 — état technique (15 octobre 2026)

Branche: `feat/medisuivi-p54-patient-save-visibility`; PR #49, base P5.3. Ne pas fusionner directement dans main.

## Implémenté, non validé sur Android
- Formulaire nouveau patient: action Enregistrer le patient dans le formulaire défilant en complément de la barre inférieure, les deux appellent `save()`.
- Navigation `ClinicalBottomDock`: zone active arrondie plus large (46 × 43), déplacement vertical accru, hauteur du dock 76, animations conditionnées par Reduce Motion.

## Constats du code, non résolus
- `backend/app/main.py`: l'environnement production est explicitement refusé.
- Inscription sandbox: header `X-MediSuivi-Sandbox-Invite` et identités `demo-...@example.com` obligatoires.
- Vérification des e-mails: `APP_ENABLE_EMAIL_AUTH` et paramètres SMTP nécessaires. Vérifier que le code est réellement envoyé de manière fiable avant d'ouvrir les inscriptions.
- Patients sandbox: le nom doit commencer par `PATIENT FICTIF`; aucune vraie donnée médicale dans Neon sandbox.
- Sync: distinguer appels CRUD distants, stockage local chiffré, file outbox et vraie réplication bidirectionnelle. Aucun succès cloud ni hors-ligne à présumer sans recette A/B et restauration.
- Photo `assets/images/home_hero_hd.webp`: à remplacer par un fichier net autorisé, aux dimensions/contrastes adaptés.
- Vérifier navigation Android sur 320/360/390 px, clavier et mode accessibilité.

## Critères de clôture
1. CI Flutter et backend vertes sur le commit courant, tests widget/formulaire/navigation et APK généré.
2. Deux comptes fictifs isolés, authentification HTTPS Vercel ↔ Neon, création/lecture après reconnexion et contrôle 404 sur dossiers croisés.
3. Test sans réseau et retour en ligne avec idempotence, conflits, aucune fuite inter-comptes, sauvegarde/restauration démontrée.
4. Confirmation des politiques de confidentialité, conditions légales Sénégal, chiffrement, rotation des secrets, logs sans PHI, anti-abus, SMTP, sauvegardes restaurables et revue indépendante avant exploitation de vraies données de santé.

Aucun secret, patient réel, adresse e-mail personnelle ou token dans ce document.
