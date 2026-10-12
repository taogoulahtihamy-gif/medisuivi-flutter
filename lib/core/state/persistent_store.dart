/// Store persistant utilisant Drift + SQLite3MultipleCiphers
/// Remplace DemoStore tout en conservant la même API publique (synchrone pour compatibilité)
library;

import 'package:flutter/widgets.dart';

import '../persistence/database.dart' as db;
import '../persistence/dao/patient_dao.dart';
import '../persistence/dao/visit_dao.dart';
import '../persistence/dao/exam_dao.dart';
import '../persistence/dao/followup_dao.dart';
import '../models/medical_models.dart';

/// Store persistant pour la V1 - API compatible avec DemoStore
class PersistentStore extends ChangeNotifier {
  final db.AppDatabase _database;

  // DAOs
  late final PatientDao _patientDao;
  late final VisitDao _visitDao;
  late final ExamDao _examDao;
  late final FollowUpDao _followUpDao;

  // Cache local pour accès synchrone (comme DemoStore)
  final List<Patient> _patients = [];
  final List<Visit> _visits = [];
  final List<LabExam> _exams = [];
  final List<FollowUpPlan> _followUps = [];

  PersistentStore(this._database) {
    _patientDao = _database.patientDao;
    _visitDao = _database.visitDao;
    _examDao = _database.examDao;
    _followUpDao = _database.followUpDao;
    _loadInitialData();
  }

  /// Charge les données initiales depuis la base et configure les streams réactifs
  Future<void> _loadInitialData() async {
    _patients.addAll(_mapPatients(await _patientDao.getAllPatients()));
    _visits.addAll(_mapVisits(await _visitDao.getVisitsForAllPatients()));
    _exams.addAll(_mapExams(await _examDao.getAllExams()));
    _followUps.addAll(_mapFollowUps(await _followUpDao.getAllFollowUps()));

    // Écouter les changements pour maintenir le cache à jour
    _patientDao.watchAllPatients().map(_mapPatients).listen((patients) {
      _patients
        ..clear()
        ..addAll(patients);
      notifyListeners();
    });

    _visitDao.watchAllVisits().map(_mapVisits).listen((visits) {
      _visits
        ..clear()
        ..addAll(visits);
      notifyListeners();
    });

    _examDao.watchAllExams().map(_mapExams).listen((exams) {
      _exams
        ..clear()
        ..addAll(exams);
      notifyListeners();
    });

    _followUpDao.watchAllFollowUps().map(_mapFollowUps).listen((followUps) {
      _followUps
        ..clear()
        ..addAll(followUps);
      notifyListeners();
    });

    notifyListeners();
  }

  // ==================== PATIENTS ====================

  /// Stream de tous les patients (réactif)
  Stream<List<Patient>> get patientsStream => _patientDao.watchAllPatients().map(_mapPatients);

  /// Liste de tous les patients (synchrone via cache)
  List<Patient> get patients => List.unmodifiable(_patients);

  /// Récupère un patient par ID (synchrone via cache)
  Patient? patientById(String id) {
    for (final patient in _patients) {
      if (patient.id == id) return patient;
    }
    return null;
  }

  /// Patients marqués pour suivi (synchrone via cache)
  List<Patient> get followUpPatients => _patients.where((p) => p.followUp).toList();

  /// Stream des patients marqués pour suivi
  Stream<List<Patient>> get followUpPatientsStream =>
      _patientDao.watchPatientsForFollowUp().map(_mapPatients);

  /// Ajoute un nouveau patient
  Future<void> addPatient({
    required String name,
    required int age,
    required String sex,
    required String phone,
  }) async {
    await _patientDao.createPatient(
      name: name,
      age: age,
      sex: sex,
      phone: phone,
    );
    // Le stream mettra à jour le cache automatiquement
  }

  /// Met à jour les infos médicales d'un patient
  Future<void> updatePatientInfo({
    required String patientId,
    required String phone,
    required String allergies,
    required String medicalHistory,
  }) async {
    await _patientDao.updatePatientInfo(
      patientId: patientId,
      phone: phone,
      allergies: allergies,
      medicalHistory: medicalHistory,
    );
  }

  /// Active/désactive le drapeau de suivi
  Future<void> setFollowUp(String patientId, {required bool toReview}) async {
    await _patientDao.setFollowUp(patientId, toReview: toReview);
  }

  // ==================== VISITES ====================

  /// Stream des visites d'un patient
  Stream<List<Visit>> visitsForStream(String patientId) =>
      _visitDao.watchVisitsForPatient(patientId).map(_mapVisits);

  /// Liste des visites d'un patient (synchrone via cache)
  List<Visit> visitsFor(String patientId) =>
      _visits.where((v) => v.patientId == patientId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  /// Dernière visite d'un patient (synchrone via cache)
  Visit? lastVisitFor(String patientId) {
    final patientVisits = visitsFor(patientId);
    return patientVisits.isEmpty ? null : patientVisits.first;
  }

  /// Ajoute une nouvelle visite
  Future<void> addVisit({
    required String patientId,
    required String reason,
    double? temperature,
    int? systolic,
    int? diastolic,
    int? pulse,
    int? spo2,
    String notes = '',
  }) async {
    await _visitDao.createVisit(
      patientId: patientId,
      reason: reason,
      temperature: temperature,
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
      spo2: spo2,
      notes: notes,
    );
  }

  // ==================== EXAMENS ====================

  /// Stream de tous les examens
  Stream<List<LabExam>> get examsStream => _examDao.watchAllExams().map(_mapExams);

  /// Liste de tous les examens (synchrone via cache)
  List<LabExam> get exams => List.unmodifiable(_exams);

  /// Stream des examens d'un patient
  Stream<List<LabExam>> examsForStream(String patientId) =>
      _examDao.watchExamsForPatient(patientId).map(_mapExams);

  /// Liste des examens d'un patient (synchrone via cache)
  List<LabExam> examsFor(String patientId) =>
      _exams.where((e) => e.patientId == patientId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  /// Examen par ID (synchrone via cache)
  LabExam? examById(String examId) {
    for (final exam in _exams) {
      if (exam.id == examId) return exam;
    }
    return null;
  }

  /// Examens en attente (synchrone via cache)
  List<LabExam> get pendingExams =>
      _exams.where((e) => e.status == ExamStatus.pending).toList();

  /// Stream des examens en attente
  Stream<List<LabExam>> get pendingExamsStream =>
      _examDao.watchPendingExams().map(_mapExams);

  /// Nombre d'examens en attente (synchrone via cache)
  int get pendingExamsCount => pendingExams.length;

  /// Crée un nouvel examen (prescription)
  Future<String> addExam({
    required String patientId,
    required String title,
  }) async {
    final id = await _examDao.createExam(
      patientId: patientId,
      title: title,
    );
    return id;
  }

  /// Enregistre le résultat d'un examen
  Future<void> recordExamResult({
    required String examId,
    required String result,
  }) async {
    await _examDao.recordExamResult(
      examId: examId,
      result: result,
    );
  }

  // ==================== SUIVIS ====================

  /// Stream des suivis planifiés
  Stream<List<FollowUpPlan>> get plannedFollowUpsStream =>
      _followUpDao.watchPlannedFollowUps().map(_mapFollowUps);

  /// Liste des suivis planifiés (synchrone via cache)
  List<FollowUpPlan> get plannedFollowUps =>
      _followUps.where((f) => f.isPlanned).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  /// Stream des suivis passés (historique)
  Stream<List<FollowUpPlan>> get pastFollowUpsStream =>
      _followUpDao.watchPastFollowUps().map(_mapFollowUps);

  /// Liste des suivis passés (synchrone via cache)
  List<FollowUpPlan> get pastFollowUps =>
      _followUps.where((f) => !f.isPlanned).toList()
        ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

  /// Suivis d'un patient (synchrone via cache)
  List<FollowUpPlan> followUpsFor(String patientId) =>
      _followUps.where((f) => f.patientId == patientId).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  /// Stream des suivis d'un patient
  Stream<List<FollowUpPlan>> followUpsForStream(String patientId) =>
      _followUpDao.watchFollowUpsForPatient(patientId).map(_mapFollowUps);

  /// Patients avec suivi signalé mais sans RDV programmé (synchrone via cache)
  List<Patient> get followUpsWithoutDate {
    final patientsWithPlannedFollowUp = _followUps
        .where((f) => f.isPlanned)
        .map((f) => f.patientId)
        .toSet();

    return _patients.where((p) => p.followUp && !patientsWithPlannedFollowUp.contains(p.id)).toList();
  }

  /// Programme un nouveau suivi
  Future<void> scheduleFollowUp({
    required String patientId,
    required DateTime scheduledAt,
    required String reason,
    String notes = '',
  }) async {
    await _followUpDao.scheduleFollowUp(
      patientId: patientId,
      scheduledAt: scheduledAt,
      reason: reason,
      notes: notes,
    );
  }

  /// Reporte un suivi
  Future<void> rescheduleFollowUp({
    required String followUpId,
    required DateTime scheduledAt,
    required String reason,
    String notes = '',
  }) async {
    await _followUpDao.rescheduleFollowUp(
      followUpId: followUpId,
      scheduledAt: scheduledAt,
      reason: reason,
      notes: notes,
    );
  }

  /// Clôture un suivi
  Future<void> closeFollowUp(String followUpId, {required bool completed}) async {
    await _followUpDao.closeFollowUp(
      followUpId: followUpId,
      completed: completed,
    );
  }

  // ==================== MAPPERS ====================

  List<Patient> _mapPatients(List<db.Patient> dbPatients) {
    return dbPatients.map(_mapPatient).toList();
  }

  Patient _mapPatient(db.Patient dbPatient) {
    return Patient(
      id: dbPatient.id,
      name: dbPatient.name,
      age: dbPatient.age,
      sex: dbPatient.sex,
      phone: dbPatient.phone,
      createdAt: dbPatient.createdAt,
      allergies: dbPatient.allergies,
      medicalHistory: dbPatient.medicalHistory,
      followUp: dbPatient.followUp,
    );
  }

  List<Visit> _mapVisits(List<db.Visit> dbVisits) {
    return dbVisits.map(_mapVisit).toList();
  }

  Visit _mapVisit(db.Visit dbVisit) {
    return Visit(
      id: dbVisit.id,
      patientId: dbVisit.patientId,
      date: dbVisit.date,
      reason: dbVisit.reason,
      temperature: dbVisit.temperature,
      systolic: dbVisit.systolic,
      diastolic: dbVisit.diastolic,
      pulse: dbVisit.pulse,
      spo2: dbVisit.spo2,
      notes: dbVisit.notes,
    );
  }

  List<LabExam> _mapExams(List<db.Exam> dbExams) {
    return dbExams.map(_mapExam).toList();
  }

  LabExam _mapExam(db.Exam dbExam) {
    return LabExam(
      id: dbExam.id,
      patientId: dbExam.patientId,
      title: dbExam.title,
      date: dbExam.date,
      status: dbExam.status == 0 ? ExamStatus.pending : ExamStatus.complete,
      result: dbExam.result,
      resultRecordedAt: dbExam.resultRecordedAt,
    );
  }

  List<FollowUpPlan> _mapFollowUps(List<db.FollowUp> dbFollowUps) {
    return dbFollowUps.map(_mapFollowUp).toList();
  }

  FollowUpPlan _mapFollowUp(db.FollowUp dbFollowUp) {
    return FollowUpPlan(
      id: dbFollowUp.id,
      patientId: dbFollowUp.patientId,
      scheduledAt: dbFollowUp.scheduledAt,
      reason: dbFollowUp.reason,
      notes: dbFollowUp.notes,
      status: _mapFollowUpStatus(dbFollowUp.status),
      completedAt: dbFollowUp.completedAt,
    );
  }

  FollowUpStatus _mapFollowUpStatus(int status) {
    switch (status) {
      case 0:
        return FollowUpStatus.planned;
      case 1:
        return FollowUpStatus.completed;
      case 2:
        return FollowUpStatus.cancelled;
      default:
        return FollowUpStatus.planned;
    }
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }
}

/// Scope pour fournir le PersistentStore via InheritedNotifier
class PersistentScope extends InheritedNotifier<PersistentStore> {
  const PersistentScope({
    super.key,
    required PersistentStore store,
    required super.child,
  }) : super(notifier: store);

  static PersistentStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PersistentScope>();
    assert(scope != null, 'PersistentScope not found in context');
    return scope!.notifier!;
  }
}