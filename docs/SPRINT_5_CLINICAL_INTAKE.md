# MediSuivi · Sprint 5 : dossier et consultation clinique

## Exigence exprimée par le professionnel de santé

Identité du malade (nom, prénom, adresse/quartier/téléphone, âge, sexe) ; paramètres (poids, température) ; motif de consultation ; signes associés ; examen physique (état général, appareils) ; hypothèses diagnostiques ; bilan ; résultats ; conduite à tenir ; traitement ambulatoire ou hospitalisation.

## Audit de l'existant (branche feat/medisuivi-premium-redesign, 13 octobre 2026)

- **Existant** : Patient (nom complet, âge, sexe, téléphone, antécédents, allergies) ; Visit (motif, température, TA, pouls, SpO₂, notes) ; LabExam (demande et résultat) ; FollowUpPlan (suivi).
- **Manquant** : quartier/adresse et contact d'urgence, traitements habituels séparés, poids/taille/fréquence respiratoire, histoire et signes associés, examen général et par appareil, hypothèses diagnostiques, interprétation des résultats, conduite à tenir structurée, décision ambulatoire/observation/hospitalisation/transfert.
- **Point de sûreté** : le schéma Drift est **version 1**, le code généré `database.g.dart` est suivi par Git. Les dossiers créés sur Galaxy S9+ existent déjà ; il est interdit de changer les champs obligatoires ou de supprimer/recréer la base pour simplifier la migration.

## Découpage de livraison

### 5A · Contrat métier typé (présente PR)

- Fichier `lib/core/models/clinical_intake.dart` : `PatientProfileSupplement`, `ClinicalIntake`, `CareDisposition`.
- Contrat de sérialisation versionné (1), typage strict à la lecture et validation purement technique. **Aucun champ n'est encore affiché ni persisté.** C'est volontaire : ne pas promettre une sauvegarde tant que la migration n'est pas éprouvée.
- Tests unitaires de round-trip JSON, décisions d'orientation et refus de formats inconnus.
- Aucune modification de schéma, de la clé SQLite, du système d'authentification, de la signature APK ou de `main`.

### 5B · Migration chiffrée et persistance sans perte (prochaine PR)

- Planifier une **migration additive v1 → v2**, avec colonnes nullable et valeurs par défaut pour les dossiers existants ; ne pas réécrire ni effacer les anciennes consultations.
- Mettre à jour `Patients` et `Visits` ou tables auxiliaires dédiées, régénérer Drift via `build_runner`, garder le code généré versionné.
- DAO : création/mise à jour transactionnelle avec outbox JSON contenant les nouveaux champs ; erreurs outbox = rollback complet. Une consultation clôturée ne s'écrase pas silencieusement.
- Tests obligatoires : ouverture d'une vraie base v1 chiffrée, migration vers v2 avec la **même clé**, nombre de patients/consultations/examens/suivis et outbox inchangé, nouveaux champs enregistrés/retrouvés après réouverture, rétrocompatibilité des anciennes interfaces.
- Pas de renommage `applicationId`, pas de suppression/reconstruction DB, pas de conversion synchronisée artificielle.

### 5C · Interfaces Nocturne Clinique

- Dossier patient : identité + quartier/adresse + téléphone/contact d'urgence, antécédents, allergies, traitements habituels.
- Consultation : motif et histoire de la maladie ; signes associés ; constantes (poids, taille, température, TA, FC, fréquence respiratoire, SpO₂) ; état général et examen des appareils ; hypothèses/diagnostic ; bilans/résultats ; conduite à tenir ; décision ambulatoire/observation/hospitalisation/transfert ; suivi.
- Saisie progressive, sections lisibles sur Galaxy S9+, claviers numériques adaptés, champs facultatifs clairement signalés, validation avant enregistrement.
- Historique clinique inchangé, pas de diagnostic ou traitement automatiquement proposés.
- Distinguer prescription d'examens, résultats reçus et interprétation du soignant ; ne pas marquer un résultat « reçu » sans preuve de saisie.

## Critères de validation et sécurité

1. Les anciens dossiers restent lisibles sur le même appareil et la même clé ; aucun patient réel ne sert aux tests.
2. Chaque écriture mobile est asynchrone et atomique avec sa ligne outbox ; le Web conserve une démonstration fictive.
3. L'interface n'annonce jamais une synchronisation distante inexistante.
4. Aucun conseil médical automatisé ; les actes sont consignés par le praticien.
5. Tests Flutter et Android sur la branche dédiée avant fusion, puis test physique de non-régression sur le S9+ **sans désinstallation**.
6. Aucun stockage de données patient dans les logs, analytics, GitHub, captures d'écran ou artifacts.

**Attention :** cette V1 n'est pas autorisée pour une utilisation clinique avec de vraies données tant que les comptes, permissions, audit, reprise après perte d'appareil et exigences réglementaires n'ont pas été évalués.
