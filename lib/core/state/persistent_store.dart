import 'dart:async';

import 'package:flutter/widgets.dart';

import '../persistence/database.dart' as db;
import '../persistence/dao/patient_dao.dart';
import '../persistence/dao/visit_dao.dart';
import '../persistence/dao/exam_dao.dart';
import '../persistence/dao/followup_dao.dart';
import '../models/medical_models.dart';
import 'clinical_store.dart';

/// Exception spécifique pour les erreurs de base de données SQLite.
class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);
  @override
  String toString() => 'DatabaseException: $message';
}

/// Store persistant utilisant Drift + SQLite3MultipleCiphers
/// Remplace DemoStore tout en conservant la même API publique (synchrone pour compatibilité)
class PersistentStore extends ChangeNotifier implements ClinicalStore {
  final db.AppDatabase _database;

  /// Opérations durables en attente : aucune synchronisation serveur active.
  Future<int> get pendingSyncCount async =>
      (await _database.pendingOperationsDao.getPendingOperations()).length;

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

  // Abonnements streams - nullable car dispose peut arriver avant fin de chargement
  StreamSubscription<List<Patient>>? _patientStreamSubscription;
  StreamSubscription<List<Visit>>? _visitStreamSubscription;
  StreamSubscription<List<LabExam>>? _examStreamSubscription;
  StreamSubscription<List<FollowUpPlan>>? _followUpStreamSubscription;

  // Drapeau pour empêcher les opérations après destruction
  bool _disposed = false;

  // Fin effective de l'annulation des abonnements, distincte de dispose().
  Future<void>? _streamCleanup;

  /// À attendre avant que le propriétaire ne ferme la base SQLite.
  Future<void> get streamsStopped => _streamCleanup ?? Future<void>.value();

  // Future d'initialisation exposé pour attendre le chargement initial
  Future<void>? _initialization;

  PersistentStore(this._database) {
    _patientDao = _database.patientDao;
    _visitDao = _database.visitDao;
    _examDao = _database.examDao;
    _followUpDao = _database.followUpDao;
    _initialization = _loadInitialData();
  }

  /// Future qui se termine quand le chargement initial est fini.
  /// Les erreurs de chargement sont propagées (jamais présentées comme base vide).
  Future<void> get ready => _initialization ?? Future.value();

  /// Charge les données initiales depuis la base et configure les streams réactifs.
  /// Les erreurs de chargement initial sont propagées via rethrow,
  /// jamais présentées comme une base vide valide.
  Future<void> _loadInitialData() async {
    try {
      _patients.addAll(_mapPatients(await _patientDao.getAllPatients()));
      _visits.addAll(_mapVisits(await _visitDao.getVisitsForAllPatients()));
      _exams.addAll(_mapExams(await _examDao.getAllExams()));
      _followUps.addAll(_mapFollowUps(await _followUpDao.getAllFollowUps()));
    } catch (e) {
      // Erreur lors du chargement initial : on relaie l'exception
      // pour qu'elle ne soit pas interprétée comme une base vide valide.
      rethrow;
    }

    // Si le store a été détruit pendant le chargement, ne pas installer les abonnements
    if (_disposed) return;

    // Écouter les changements pour maintenir le cache à jour.
    // Gestion d'erreurs explicite sur chaque stream.
    _patientStreamSubscription =
        _patientDao.watchAllPatients().map(_mapPatients).listen(
              _onPatientChanged,
              onError: (e) => _handleStreamError(e, 'patients'),
            );

    _visitStreamSubscription =
        _visitDao.watchAllVisits().map(_mapVisits).listen(
              _onVisitChanged,
              onError: (e) => _handleStreamError(e, 'visites'),
            );

    _examStreamSubscription = _examDao.watchAllExams().map(_mapExams).listen(
          _onExamChanged,
          onError: (e) => _handleStreamError(e, 'examens'),
        );

    _followUpStreamSubscription =
        _followUpDao.watchAllFollowUps().map(_mapFollowUps).listen(
              _onFollowUpChanged,
              onError: (e) => _handleStreamError(e, 'suivis'),
            );
  }

  /// Gestion centralisée des erreurs de stream.
  /// Ne fait pas notifyListeners après destruction.
  void _handleStreamError(Object error, String streamName) {
    if (_disposed) return;
    // L'erreur est journalisée mais ne casse pas l'UI.
    // En production, envoyer vers un service de logging.
    debugPrint('PersistentStore: erreur stream $streamName: $error');
  }

  // ==================== GESTION DES ABONNEMENTS RÉACTIFS ====================

  void _onPatientChanged(List<Patient> patients) {
    if (_disposed) return;
    _patients
      ..clear()
      ..addAll(patients);
    notifyListeners();
  }

  void _onVisitChanged(List<Visit> visits) {
    if (_disposed) return;
    _visits
      ..clear()
      ..addAll(visits);
    notifyListeners();
  }

  void _onExamChanged(List<LabExam> exams) {
    if (_disposed) return;
    _exams
      ..clear()
      ..addAll(exams);
    notifyListeners();
  }

  void _onFollowUpChanged(List<FollowUpPlan> followUps) {
    if (_disposed) return;
    _followUps
      ..clear()
      ..addAll(followUps);
    notifyListeners();
  }

  // ==================== PATIENTS ====================

  /// Stream de tous les patients (réactif)
  Stream<List<Patient>> get patientsStream =>
      _patientDao.watchAllPatients().map(_mapPatients);

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
  List<Patient> get followUpPatients =>
      _patients.where((p) => p.followUp).toList();

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

  /// Stream de toutes les visites
  Stream<List<Visit>> get visitsStream =>
      _visitDao.watchAllVisits().map(_mapVisits);

  /// Liste de toutes les visites (synchrone via cache)
  @override
  List<Visit> get visits => List.unmodifiable(_visits);

  /// Stream des visites d'un patient
  @override
  Stream<List<Visit>> visitsForStream(String patientId) =>
      _visitDao.watchVisitsForPatient(patientId).map(_mapVisits);

  /// Liste des visites d'un patient (synchrone via cache)
  @override
  List<Visit> visitsFor(String patientId) =>
      _visits.where((v) => v.patientId == patientId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  /// Dernière visite d'un patient (synchrone via cache)
  @override
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
  Stream<List<LabExam>> get examsStream =>
      _examDao.watchAllExams().map(_mapExams);

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

  /// Stream de tous les suivis
  Stream<List<FollowUpPlan>> get followUpsStream =>
      _followUpDao.watchAllFollowUps().map(_mapFollowUps);

  /// Liste de tous les suivis (synchrone via cache)
  @override
  List<FollowUpPlan> get followUps => List.unmodifiable(_followUps);

  /// Stream des suivis planifiés
  @override
  Stream<List<FollowUpPlan>> get plannedFollowUpsStream =>
      _followUpDao.watchPlannedFollowUps().map(_mapFollowUps);

  /// Liste des suivis planifiés (synchrone via cache)
  @override
  List<FollowUpPlan> get plannedFollowUps =>
      _followUps.where((f) => f.isPlanned).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  /// Stream des suivis passés (historique)
  @override
  Stream<List<FollowUpPlan>> get pastFollowUpsStream =>
      _followUpDao.watchPastFollowUps().map(_mapFollowUps);

  /// Liste des suivis passés (synchrone via cache)
  @override
  List<FollowUpPlan> get pastFollowUps =>
      _followUps.where((f) => !f.isPlanned).toList()
        ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

  /// Suivis d'un patient (synchrone via cache)
  @override
  List<FollowUpPlan> followUpsFor(String patientId) =>
      _followUps.where((f) => f.patientId == patientId).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  /// Stream des suivis d'un patient
  @override
  Stream<List<FollowUpPlan>> followUpsForStream(String patientId) =>
      _followUpDao.watchFollowUpsForPatient(patientId).map(_mapFollowUps);

  /// Patients avec suivi signalé mais sans RDV programmé (synchrone via cache)
  @override
  List<Patient> get followUpsWithoutDate {
    final patientsWithPlannedFollowUp =
        _followUps.where((f) => f.isPlanned).map((f) => f.patientId).toSet();

    return _patients
        .where((p) => p.followUp && !patientsWithPlannedFollowUp.contains(p.id))
        .toList();
  }

  /// Crée le suivi et active le drapeau patient dans une seule transaction.
  /// Les transactions DAO imbriquées participent à la transaction englobante.
  @override
  Future<void> scheduleFollowUp({
    required String patientId,
    required DateTime scheduledAt,
    required String reason,
    String notes = '',
  }) async {
    await _database.transaction(() async {
      final patient = await _patientDao.getPatientById(patientId);
      if (patient == null) {
        throw StateError('Dossier patient introuvable.');
      }
      await _followUpDao.scheduleFollowUp(
        patientId: patientId,
        scheduledAt: scheduledAt,
        reason: reason,
        notes: notes,
      );
      if (!patient.followUp) {
        await _patientDao.setFollowUp(patientId, toReview: true);
      }
    });
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

  /// Clôture sans suppression, à partir de l'état transactionnel de SQLite.
  /// Le rendez-vous, le drapeau patient et leurs outbox sont atomiques.
  @override
  Future<void> closeFollowUp(String followUpId,
      {required bool completed}) async {
    await _database.transaction(() async {
      final followUp = await _followUpDao.getFollowUpById(followUpId);
      if (followUp == null) {
        throw StateError('Suivi introuvable.');
      }
      await _followUpDao.closeFollowUp(
        followUpId: followUpId,
        completed: completed,
      );

      final hasOtherPlanned =
          await _followUpDao.hasPlannedFollowUpForPatient(followUp.patientId);
      if (!hasOtherPlanned) {
        final patient = await _patientDao.getPatientById(followUp.patientId);
        if (patient == null) {
          throw StateError('Dossier patient introuvable.');
        }
        if (patient.followUp) {
          await _patientDao.setFollowUp(followUp.patientId, toReview: false);
        }
      }
    });
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
    if (_disposed) return;
    _disposed = true;
    // cancel() est asynchrone : le propriétaire attend streamsStopped
    // avant de fermer SQLite. La destruction du ChangeNotifier reste synchrone.
    _streamCleanup = Future.wait<void>([
      if (_patientStreamSubscription != null)
        _patientStreamSubscription!.cancel(),
      if (_visitStreamSubscription != null)
        _visitStreamSubscription!.cancel(),
      if (_examStreamSubscription != null)
        _examStreamSubscription!.cancel(),
      if (_followUpStreamSubscription != null)
        _followUpStreamSubscription!.cancel(),
    ]).then<void>((_) {});
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
