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

### 5B · Migration chiffrée et persistance sans perte (implémentée dans la PR #8, à valider en CI)

- Migration **additive v1 → v2** implémentée par deux tables SQLite auxiliaires `patient_supplements` et `visit_intakes`, sans modifier les tables Drift historiques, leurs colonnes, ni le code `database.g.dart`. Évite de réécrire les anciennes consultations.
- Les tables auxiliaires sont créées via `AppDatabase._createClinicalSupplementTables()` à la création ou lors de l'upgrade 1→2. Le code généré Drift v1 demeure valide puisqu'aucune table déclarée dans `@DriftDatabase` ne change.
- DAO : ajout optionnel `profile` lors de la création/mise à jour patient et `intake` à la création de visite. Écriture des tables auxiliaires + outbox JSON **dans la même transaction**. Les consultations précédentes ne sont pas modifiables ; `INSERT` ne remplace jamais un compte rendu existant.
- Tests ajoutés : reconstitution fidèle du schéma v1 dans une base chiffrée réelle (tables historiques inchangées, tables complémentaires absentes, `user_version=1`), migration vers v2 avec la **même clé**, conservation des patients, visites, examens, suivis et outbox ; nouveau profil/visite rechargés après redémarrage ; échec d'outbox provoque rollback des données et du complément. Validation CI requise avant fusion.
- Pas de renommage `applicationId`, pas de suppression/reconstruction DB, pas de conversion synchronisée artificielle.

### 5C · Interfaces Nocturne Clinique (implémentées sur la branche Sprint 5, validation CI en cours)

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

## Validation Sprint 5B

- Aucune capture de vrai patient, ni données sensibles en GitHub Actions.
- Tests de migration et non-régression : `test/persistence/sprint5_migration_test.dart`.
- **Ne pas installer un APK Sprint 5 avant validation de la migration en CI et sur une copie chiffrée de test**, et sans politique sûre pour l'ancien APK debug du S9+.
- Les nouveaux champs sont désormais accessibles dans les écrans du Sprint 5C de cette branche, mais leur publication sur mobile reste conditionnée aux contrôles CI et aux essais de conservation des dossiers.

## Livraison Sprint 5C : formulaires liés au stockage

- `NewPatientScreen` : coordonnées détaillées (quartier, adresse, contact d'urgence) et antécédents complémentaires saisis à la création, transmis au `ClinicalStore` avec le patient.
- `PatientMedicalInfoScreen` : charge le profil depuis `patientProfile()`, conserve les champs non modifiés et bloque l'enregistrement en cas de chargement échoué, sans remplacer silencieusement les données.
- `PatientDetailScreen` : présente le profil enrichi et ouvre le compte rendu d'une visite.
- `NewConsultationScreen` : histoire et signes, constantes, examen physique, hypothèses, diagnostic, bilan, interprétation, conduite à tenir et décision (ambulatoire, observation, hospitalisation, transfert). Des justifications sont exigées pour hospitalisation/transfert ; les champs non renseignés restent vides.
- `ConsultationDetailScreen` : lecture seule, compatible avec les anciennes visites v1 sans compte rendu complémentaire.
- `test/sprint5c_clinical_forms_test.dart` : tests de formulaires Flutter et du parcours mémoire sur écran étroit.

**Limites :** la rédaction d'un bilan dans une consultation **ne vaut pas** création d'un examen ou confirmation de résultat dans le module Bilans. L'interface ne déclenche aucun diagnostic automatisé. L'authentification et la synchronisation distante ne sont pas réalisées ici. Ces écrans utilisent SQLite chiffré uniquement sur mobile et la mémoire fictive en Web.

**Prudence Galaxy S9+ :** le Sprint 5 ne doit pas être installé par-dessus une version debug aux certificats différents ni après désinstallation de celle-ci ; aucune procédure de migration de signature sans perte des données n'est encore validée. Ne pas utiliser de données patients réels.
