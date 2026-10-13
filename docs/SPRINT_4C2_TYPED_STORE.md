# Sprint 4C.2 — Contrat métier typé ClinicalStore

## Objectif

Remplacer `dynamic` dans `context.store` par une API métier
fortement typée, compatible Web (DemoStore) et mobile
(PersistentStore).

## Architecture retenue

```
context.store : ClinicalStore  (interface commune)
       │
       ├── DemoStore       (Web, in-memory, écritures adaptées en Future)
       │     └── implements ClinicalStore
       │
       └── PersistentStore (mobile, Drift + SQLite chiffré, écritures async natives)
             └── implements ClinicalStore
```

### Contrat métier : `lib/core/state/clinical_store.dart`

Interface abstraite `ClinicalStore` couvrant :

| Domaine | Lectures synchrones (cache) | Écritures asynchrones |
|---------|----------------------------|----------------------|
| **Patients** | `patients`, `patientById`, `followUpPatients`, `followUpsWithoutDate` | `addPatient`, `updatePatientInfo`, `setFollowUp` |
| **Consultations** | `visits`, `visitsFor`, `lastVisitFor` | `addVisit` |
| **Examens** | `exams`, `examsFor`, `examById`, `pendingExams`, `pendingExamsCount` | `addExam` (retourne `Future<String>`), `recordExamResult` |
| **Suivis** | `followUps`, `followUpsFor`, `plannedFollowUps`, `pastFollowUps` | `scheduleFollowUp`, `rescheduleFollowUp`, `closeFollowUp` |
| **Statut local** | — | `pendingSyncCount` (`Future<int>`) |

### Flux réactifs

`ClinicalStore` expose également les streams Drift :
`patientsStream`, `visitsForStream`, `examsStream`,
`examsForStream`, `pendingExamsStream`, `plannedFollowUpsStream`,
`pastFollowUpsStream`, `followUpsForStream`, `followUpPatientsStream`.

## Adaptateurs

### DemoStore (Web)

- Lectures : synchrones (listes en mémoire), conformes au contrat.
- Écritures : méthodes internes synchrones **enveloppées en `Future`**
  pour satisfaire le contrat. Aucune écriture SQLite n'est convertie
  en synchrone (il n'y a pas de SQLite sur Web).
- Streams : `Stream.value(...)` émettant l'état courant.
- `pendingSyncCount` : retourne toujours `0` (prototype sans serveur).

### PersistentStore (mobile)

- Lectures : synchrones via cache local alimenté par les streams Drift.
- Écritures : **asynchrones natives** (DAO Drift). Aucune conversion
  synchrone.
- Streams : streams Drift réactifs (`watchAllPatients`, etc.).
- `pendingSyncCount` : nombre réel d'opérations dans `pending_operations`.

### Règle clé respectée

> Aucune écriture SQLite asynchrone n'est convertie en opération
> synchrone. Le contrat utilise `Future` comme dénominateur commun,
> et DemoStore adapte ses écritures en mémoire vers `Future`.

## Compatibilité Web / mobile

- **Web** : `DemoStore` via `DemoScope`, `PersistentStore` stub
  (`persistent_store_stub.dart`) hérite de `DemoStore`.
- **Mobile** : `PersistentStore` via `PersistentScope`, base SQLite
  chiffrée (SQLite3MultipleCiphers).
- `context.store` retourne `ClinicalStore` dans les deux cas.

## Fichiers modifiés

| Fichier | Modification |
|---------|-------------|
| `lib/core/state/clinical_store.dart` | **Créé** — contrat métier `ClinicalStore` |
| `lib/core/state/demo_store.dart` | `implements ClinicalStore`, écritures en `Future`, streams ajoutés |
| `lib/core/state/persistent_store.dart` | `implements ClinicalStore`, getters `visits`/`followUps` ajoutés, `@override` |
| `lib/core/state/store_context.dart` | `context.store` retourne `ClinicalStore` (plus `dynamic`) |
| `lib/features/home/home_screen.dart` | Casts `as List<...>` supprimés (typage inféré) |
| `lib/features/settings/settings_screen.dart` | Cast `as Future<int>` supprimé |
| `test/persistence/clinical_store_typed_test.dart` | **Créé** — 28 tests du contrat typé |

## Tests ajoutés (28)

### DemoStore (12 tests)
- Patients initiaux présents (données fictives)
- `addPatient` crée un patient et notifie
- `updatePatientInfo` échoue si patient introuvable
- `updatePatientInfo` met à jour les infos médicales
- `addVisit` crée une consultation
- `addExam` crée un examen et retourne son ID
- `recordExamResult` enregistre un résultat
- `recordExamResult` échoue si examen déjà complété
- `scheduleFollowUp` programme un suivi
- `closeFollowUp` clôture un suivi
- `rescheduleFollowUp` modifie la date d'un suivi planifié
- `pendingSyncCount` retourne 0
- Streams réactifs émettent les valeurs initiales

### PersistentStore (13 tests)
- Initialisation réussie et `ready` complet
- `addPatient` crée un patient en base
- `updatePatientInfo` met à jour en base
- `addVisit` crée une consultation en base
- `addExam` crée un examen en base et retourne ID
- `recordExamResult` enregistre résultat en base
- `scheduleFollowUp` programme un suivi en base
- `closeFollowUp` clôture un suivi en base
- `rescheduleFollowUp` modifie un suivi en base
- `setFollowUp` active/désactive le drapeau
- Propagation des erreurs SQLite via `ready`
- Streams réactifs fonctionnent après écriture
- `pendingSyncCount` reflète les opérations en attente

### Compatibilité interface (3 tests)
- DemoStore et PersistentStore partagent la même API `ClinicalStore`
- Méthodes d'écriture retournent des `Future` sur les deux implémentations

## Résultats de validation

| Commande | Résultat |
|----------|----------|
| `flutter analyze --no-fatal-infos` | ✅ 0 erreur, 0 avertissement |
| `flutter test --no-pub --concurrency=1` | ✅ **93 tests passent** (65 existants + 28 nouveaux) |
| `flutter build web --release` | ✅ Réussi |
| `git diff --check` | ✅ OK (aucun whitespace error) |

## Limitations restantes

- **Différence de comportement documentée** : `PersistentStore.scheduleFollowUp`
  ne met pas à jour le drapeau `followUp` du patient (contrairement à
  `DemoStore`). C'est un comportement préexistant, conservé pour ne pas
  altérer les mécanismes 4A/4B/4C.1. Les tests ne vérifient donc pas
  ce drapeau sur PersistentStore.
- **Précision des dates** : SQLite stocke les dates à la seconde près.
  Les comparaisons de `scheduledAt` sur PersistentStore utilisent une
  tolérance de 1 seconde.
- **Streams DemoStore** : émettent l'état courant via `Stream.value`,
  sans notification reactive temps réel (suffisant pour le prototype Web).
- **Web** : reste en mode démonstration avec `DemoStore` (données fictives,
  aucune persistance). Aucune donnée médicale réelle.

## États du Sprint

| Item | Statut |
|------|--------|
| Contrat `ClinicalStore` créé | ✅ Terminé |
| `context.store` typé (plus `dynamic`) | ✅ Terminé |
| DemoStore `implements ClinicalStore` | ✅ Terminé |
| PersistentStore `implements ClinicalStore` | ✅ Terminé |
| Écritures en `Future` (adaptateur DemoStore) | ✅ Terminé |
| Aucune conversion synchrone SQLite | ✅ Respecté |
| 65 tests Sprint 4C.1 préservés | ✅ Tous passent |
| 28 nouveaux tests contrat typé | ✅ Tous passent |
| Analyse Flutter | ✅ Propre |
| Build Web | ✅ Réussi |
| `git diff --check` | ✅ OK |
| Aucun changement visuel | ✅ Respecté |
| Chiffrement SQLite préservé | ✅ Respecté |
| Commit/Push | ❌ Non effectué (attente validation) |
