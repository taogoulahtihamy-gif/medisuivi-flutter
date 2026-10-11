# Architecture MediSuivi

## Périmètre

Application mobile **personnelle** d'une soignante autorisée, pour son propre suivi clinique, sans gestion du personnel ni module hospitalier complet.

## Cibles

- Android et iOS via une base de code Flutter.
- V0 démonstration : interfaces et navigation avec données fictives en mémoire.
- V1 clinique : stockage local chiffré + connexion sécurisée + synchronisation.

## Arborescence

```text
lib/
  main.dart
  app/
    medisuivi_app.dart     # point d'entrée, navigation iOS / Android
    theme.dart             # palette, styles, composants Material 3
  core/
    models/medical_models.dart  # Patient, Visit, LabExam
    data/demo_data.dart         # données entièrement fictives
    state/demo_store.dart       # état temporaire en mémoire, V0 uniquement
    offline/contracts.dart      # contrats base locale et passerelle sync (non branchés)
    widgets/medical_ui.dart     # widgets UI communs
  features/
    home/home_screen.dart
    patients/patients_screen.dart
    patients/new_patient_screen.dart
    patients/patient_detail_screen.dart
    consultations/new_consultation_screen.dart
    exams/exams_screen.dart
    followup/followup_screen.dart
    settings/settings_screen.dart
```

## Cible V1

```text
Flutter UI
  -> ViewModels / cas d'utilisation
    -> Repositories métier
      -> DB locale SQLCipher (source de vérité de l'UI)
      -> Outbox durable + moteur de synchro
        -> API HTTPS FastAPI
          -> PostgreSQL + stockage documents chiffré
```

Les modèles Patient, Consultation, Constante, PrescriptionExamen, RésultatExamen, Document, AuditEvent, SyncOperation devront être séparés en V1. `patient.id` doit être un identifiant aléatoire généré localement (UUID v4/v7) pour éviter les collisions hors ligne. L'âge affiché ne devra pas être l'attribut de référence : utiliser la date de naissance (si disponible) et l'information « âge estimé » si nécessaire.

## Règles métiers importantes

- Une consultation est un événement distinct du patient ; pas d'écrasement de l'historique.
- Mesures horodatées, avec unités et professionnel à l'origine de la saisie.
- Prescriptions et résultats sont des objets distincts (statut + pièce jointe).
- Dates en UTC côté stockage, affichées en heure locale.
- Correction d'erreurs traçable : ne pas modifier silencieusement un diagnostic ou un résultat validé.
- Données de patients visibles uniquement après authentification et déverrouillage.
- Ne pas afficher de nom de patient dans les notifications de synchronisation.
- Saisie adaptable aux unités et procédures définies par la clinique.

## Décisions produit

- Design : sobre, contrasté, sans chiffres décoratifs ni badges artificiels.
- Icônes : Material et Cupertino officielles.
- Animations : transitions courtes respectant l'option « réduire les animations ».
- Validation médicale et confidentialité : à réaliser avant usage sur vrais patients.
