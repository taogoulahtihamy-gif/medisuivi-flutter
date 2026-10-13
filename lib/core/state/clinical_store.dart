/// Contrat métier unifié pour l'accès aux données cliniques.
///
/// Implémenté par [DemoStore] (Web, synchrone adapté) et
/// [PersistentStore] (mobile, asynchrone natif).
///
/// L'API expose des **Future** pour les écritures afin de normaliser
/// les deux implémentations sans jamais convertir une écriture SQLite
/// asynchrone en opération synchrone.
library;

import '../models/medical_models.dart';

/// Interface métier pour le store clinique.
///
/// Toutes les méthodes d'écriture retournent des [Future] pour
/// garantir la cohérence entre DemoStore (adapté) et
/// PersistentStore (natif async).
abstract class ClinicalStore {
  /// Nombre d'opérations locales en attente de synchronisation.
  Future<int> get pendingSyncCount;

  // ==================== LECTURES SYNCHRONES (cache) ====================

  /// Tous les patients (cache local, lecture synchrone).
  List<Patient> get patients;

  /// Toutes les visites (cache local, lecture synchrone).
  List<Visit> get visits;

  /// Tous les examens (cache local, lecture synchrone).
  List<LabExam> get exams;

  /// Tous les suivis (cache local, lecture synchrone).
  List<FollowUpPlan> get followUps;

  /// Suivis planifiés (cache local).
  List<FollowUpPlan> get plannedFollowUps;

  /// Suivis passés/clôturés (cache local).
  List<FollowUpPlan> get pastFollowUps;

  /// Patients signalés pour suivi sans RDV daté (cache local).
  List<Patient> get followUpsWithoutDate;

  /// Patients marqués pour suivi (cache local).
  List<Patient> get followUpPatients;

  /// Visites d'un patient (cache local, triées date décroissante).
  List<Visit> visitsFor(String patientId);

  /// Examens d'un patient (cache local, triés date décroissante).
  List<LabExam> examsFor(String patientId);

  /// Suivis d'un patient (cache local, triés date croissante).
  List<FollowUpPlan> followUpsFor(String patientId);

  /// Patient par ID (cache local).
  Patient? patientById(String id);

  /// Examen par ID (cache local).
  LabExam? examById(String examId);

  /// Dernière visite d'un patient (cache local).
  Visit? lastVisitFor(String patientId);

  /// Examens en attente (cache local).
  List<LabExam> get pendingExams;

  /// Nombre d'examens en attente (cache local).
  int get pendingExamsCount;

  // ==================== STREAMS RÉACTIFS ====================

  /// Stream de tous les patients.
  Stream<List<Patient>> get patientsStream;

  /// Stream des visites d'un patient.
  Stream<List<Visit>> visitsForStream(String patientId);

  /// Stream de tous les examens.
  Stream<List<LabExam>> get examsStream;

  /// Stream des examens d'un patient.
  Stream<List<LabExam>> examsForStream(String patientId);

  /// Stream des examens en attente.
  Stream<List<LabExam>> get pendingExamsStream;

  /// Stream des suivis planifiés.
  Stream<List<FollowUpPlan>> get plannedFollowUpsStream;

  /// Stream des suivis passés.
  Stream<List<FollowUpPlan>> get pastFollowUpsStream;

  /// Stream des suivis d'un patient.
  Stream<List<FollowUpPlan>> followUpsForStream(String patientId);

  /// Stream des patients marqués pour suivi.
  Stream<List<Patient>> get followUpPatientsStream;

  // ==================== ÉCRITURES (ASYNCHRONES) ====================

  /// Ajoute un patient.
  Future<void> addPatient({
    required String name,
    required int age,
    required String sex,
    required String phone,
  });

  /// Met à jour les infos médicales d'un patient.
  Future<void> updatePatientInfo({
    required String patientId,
    required String phone,
    required String allergies,
    required String medicalHistory,
  });

  /// Active/désactive le drapeau de suivi d'un patient.
  Future<void> setFollowUp(String patientId, {required bool toReview});

  /// Ajoute une consultation (visite).
  Future<void> addVisit({
    required String patientId,
    required String reason,
    double? temperature,
    int? systolic,
    int? diastolic,
    int? pulse,
    int? spo2,
    String notes = '',
  });

  /// Crée un examen (prescription) et retourne son identifiant.
  Future<String> addExam({
    required String patientId,
    required String title,
  });

  /// Enregistre le résultat d'un examen.
  Future<void> recordExamResult({
    required String examId,
    required String result,
  });

  /// Programme un nouveau suivi.
  Future<void> scheduleFollowUp({
    required String patientId,
    required DateTime scheduledAt,
    required String reason,
    String notes = '',
  });

  /// Reporte un suivi existant.
  Future<void> rescheduleFollowUp({
    required String followUpId,
    required DateTime scheduledAt,
    required String reason,
    String notes = '',
  });

  /// Clôture un suivi (terminé ou annulé).
  Future<void> closeFollowUp(String followUpId, {required bool completed});
}