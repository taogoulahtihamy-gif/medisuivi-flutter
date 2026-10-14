import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/auth/dev_auth_api.dart';
import '../models/clinical_intake.dart';
import '../models/medical_models.dart';
import 'clinical_store.dart';

/// Account-scoped online implementation of the ORIGINAL ClinicalStore.
///
/// It does not inherit from DemoStore and NEVER uses DemoData. Its only source
/// of clinical data is FastAPI, scoped by a revocable practitioner session.
/// No browser storage is used. Offline writes are not silently queued.
class RemoteClinicalStore extends ChangeNotifier implements ClinicalStore {
  RemoteClinicalStore({required DevAuthApi api, required DevSession session})
      : _api = api, _session = session, _revision = session.revision;

  final DevAuthApi _api;
  final DevSession _session;
  final int _revision;
  bool _closed = false;
  int _generation = 0;

  List<Patient> _patients = [];
  List<Visit> _visits = [];
  List<LabExam> _exams = [];
  List<FollowUpPlan> _followUps = [];
  Map<String, PatientProfileSupplement> _profiles = {};
  Map<String, ClinicalIntake> _intakes = {};

  String get ownerUserId => _session.practitioner.id;

  void _requireAccount() {
    if (_closed || !_session.isActive || _session.revision != _revision) {
      throw StateError('Session praticien inactive. Reconnectez-vous.');
    }
  }

  void _patientOwned(String id) {
    _requireAccount();
    if (!_patients.any((patient) => patient.id == id)) {
      throw StateError('Dossier non accessible depuis ce compte.');
    }
  }

  String _patientForExam(String id) {
    _requireAccount();
    final exam = examById(id);
    if (exam == null) throw StateError('Examen non accessible.');
    _patientOwned(exam.patientId);
    return exam.patientId;
  }

  String _patientForFollowUp(String id) {
    _requireAccount();
    for (final followUp in _followUps) {
      if (followUp.id == id) {
        _patientOwned(followUp.patientId);
        return followUp.patientId;
      }
    }
    throw StateError('Suivi non accessible.');
  }

  /// Atomic refresh: partial HTTP responses never reach any original screen.
  Future<void> reload() async {
    _requireAccount();
    final generation = ++_generation;
    final patients = await _api.listPatients(_session);
    _requireAccount();
    final bundles = await Future.wait(patients.map(
      (patient) => _api.getPatientClinical(_session, patient),
    ));
    _requireAccount();
    if (generation != _generation) return;

    final updatedPatients = <Patient>[];
    final updatedVisits = <Visit>[];
    final updatedExams = <LabExam>[];
    final updatedFollowUps = <FollowUpPlan>[];
    final updatedProfiles = <String, PatientProfileSupplement>{};
    final updatedIntakes = <String, ClinicalIntake>{};

    for (var i = 0; i < patients.length; i++) {
      final source = patients[i];
      updatedPatients.add(Patient(
        id: source.id,
        name: source.displayName,
        age: source.age,
        sex: source.sex,
        phone: source.phone,
        createdAt: source.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        allergies: source.allergies,
        medicalHistory: source.medicalHistory,
        followUp: source.followUp,
      ));
      if (source.profileJson != null) {
        updatedProfiles[source.id] =
          PatientProfileSupplement.fromJson(source.profileJson!);
      }
      final bundle = bundles[i];
      for (final item in bundle.visits) {
        updatedVisits.add(Visit(
          id: item.id, patientId: source.id,
          date: item.createdAt, reason: item.reason,
          temperature: item.temperature, systolic: item.systolic,
          diastolic: item.diastolic, pulse: item.pulse, spo2: item.spo2,
          notes: item.notes,
        ));
        if (item.intakeJson != null) {
          updatedIntakes[item.id] = ClinicalIntake.fromJson(item.intakeJson!);
        }
      }
      for (final item in bundle.exams) {
        updatedExams.add(LabExam(
          id: item.id, patientId: source.id,
          title: item.title,
          date: item.createdAt ??
            item.resultRecordedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          status: item.status == 'complete'
            ? ExamStatus.complete : ExamStatus.pending,
          result: item.result, resultRecordedAt: item.resultRecordedAt,
        ));
      }
      for (final item in bundle.followUps) {
        updatedFollowUps.add(FollowUpPlan(
          id: item.id, patientId: source.id,
          scheduledAt: item.scheduledAt.toLocal(),
          reason: item.reason, notes: item.notes,
          status: switch (item.status) {
            'completed' => FollowUpStatus.completed,
            'cancelled' => FollowUpStatus.cancelled,
            _ => FollowUpStatus.planned,
          },
          completedAt: item.completedAt,
        ));
      }
    }
    // Last check before assigning all account-owned data at once.
    _requireAccount();
    if (generation != _generation) return;
    _patients = List.unmodifiable(updatedPatients);
    _visits = List.unmodifiable(updatedVisits);
    _exams = List.unmodifiable(updatedExams);
    _followUps = List.unmodifiable(updatedFollowUps);
    _profiles = updatedProfiles;
    _intakes = updatedIntakes;
    notifyListeners();
  }

  /// Local logout purges every in-memory clinical reference.
  void lock() {
    if (_closed) return;
    _generation++;
    _patients = [];
    _visits = [];
    _exams = [];
    _followUps = [];
    _profiles = {};
    _intakes = {};
    _closed = true;
    notifyListeners();
  }

  @override
  void dispose() {
    lock();
    super.dispose();
  }

  @override
  Future<int> get pendingSyncCount async => 0;

  @override
  List<Patient> get patients => List.unmodifiable(_patients);
  @override
  List<Visit> get visits => List.unmodifiable(_visits);
  @override
  List<LabExam> get exams => List.unmodifiable(_exams);
  @override
  List<FollowUpPlan> get followUps => List.unmodifiable(_followUps);

  @override
  List<FollowUpPlan> get plannedFollowUps =>
    followUps.where((f) => f.isPlanned).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  @override
  List<FollowUpPlan> get pastFollowUps =>
    followUps.where((f) => !f.isPlanned).toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

  @override
  List<Patient> get followUpsWithoutDate =>
    patients.where((p) => p.followUp &&
      !plannedFollowUps.any((f) => f.patientId == p.id)).toList();

  @override
  List<Patient> get followUpPatients =>
    patients.where((p) => p.followUp).toList();

  @override
  List<Visit> visitsFor(String patientId) =>
    visits.where((v) => v.patientId == patientId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

  @override
  List<LabExam> examsFor(String patientId) =>
    exams.where((e) => e.patientId == patientId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

  @override
  List<FollowUpPlan> followUpsFor(String patientId) =>
    followUps.where((f) => f.patientId == patientId).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  @override
  Patient? patientById(String id) {
    for (final patient in patients) {
      if (patient.id == id) return patient;
    }
    return null;
  }

  @override
  LabExam? examById(String examId) {
    for (final exam in exams) {
      if (exam.id == examId) return exam;
    }
    return null;
  }

  @override
  Visit? lastVisitFor(String patientId) {
    final records = visitsFor(patientId);
    return records.isEmpty ? null : records.first;
  }

  @override
  List<LabExam> get pendingExams =>
    exams.where((e) => e.status == ExamStatus.pending).toList();

  @override
  int get pendingExamsCount => pendingExams.length;

  Stream<T> _stream<T>(T Function() select) => Stream.multi((controller) {
    controller.add(select());
    void emit() => controller.add(select());
    addListener(emit);
    controller.onCancel = () => removeListener(emit);
  });

  @override
  Stream<List<Patient>> get patientsStream => _stream(() => patients);
  @override
  Stream<List<Visit>> visitsForStream(String id) => _stream(() => visitsFor(id));
  @override
  Stream<List<LabExam>> get examsStream => _stream(() => exams);
  @override
  Stream<List<LabExam>> examsForStream(String id) => _stream(() => examsFor(id));
  @override
  Stream<List<LabExam>> get pendingExamsStream => _stream(() => pendingExams);
  @override
  Stream<List<FollowUpPlan>> get plannedFollowUpsStream =>
    _stream(() => plannedFollowUps);
  @override
  Stream<List<FollowUpPlan>> get pastFollowUpsStream =>
    _stream(() => pastFollowUps);
  @override
  Stream<List<FollowUpPlan>> followUpsForStream(String id) =>
    _stream(() => followUpsFor(id));
  @override
  Stream<List<Patient>> get followUpPatientsStream =>
    _stream(() => followUpPatients);

  @override
  Future<PatientProfileSupplement?> patientProfile(String id) async {
    _patientOwned(id);
    return _profiles[id];
  }

  @override
  Future<ClinicalIntake?> visitIntake(String id) async {
    _requireAccount();
    if (!_visits.any((visit) => visit.id == id)) {
      throw StateError('Consultation non accessible.');
    }
    return _intakes[id];
  }

  @override
  Future<void> addPatient({
    required String name, required int age, required String sex,
    required String phone, PatientProfileSupplement? profile,
  }) async {
    _requireAccount();
    await _api.createPatient(_session, name: name, age: age,
      sex: sex, phone: phone, profile: profile?.toJson());
    await reload();
  }

  @override
  Future<void> updatePatientInfo({
    required String patientId, required String phone,
    required String allergies, required String medicalHistory,
    PatientProfileSupplement? profile,
  }) async {
    _patientOwned(patientId);
    await _api.updatePatient(_session, patientId,
      phone: phone, allergies: allergies, medicalHistory: medicalHistory,
      profile: profile?.toJson());
    await reload();
  }

  @override
  Future<void> setFollowUp(String id, {required bool toReview}) async {
    _patientOwned(id);
    await _api.setPatientFollowUp(_session, id, toReview: toReview);
    await reload();
  }

  @override
  Future<void> addVisit({
    required String patientId, required String reason,
    double? temperature, int? systolic, int? diastolic,
    int? pulse, int? spo2, String notes = '', ClinicalIntake? intake,
  }) async {
    _patientOwned(patientId);
    final errors = intake?.validate() ?? [];
    if (errors.isNotEmpty) throw ArgumentError(errors.join(' '));
    await _api.createVisit(_session, patientId,
      reason: reason, temperature: temperature, systolic: systolic,
      diastolic: diastolic, pulse: pulse, spo2: spo2, notes: notes,
      intake: intake?.toJson());
    await reload();
  }

  @override
  Future<String> addExam({
    required String patientId, required String title,
  }) async {
    _patientOwned(patientId);
    final result = await _api.createExam(_session, patientId, title);
    await reload();
    return result.id;
  }

  @override
  Future<void> recordExamResult({
    required String examId, required String result,
  }) async {
    _patientForExam(examId);
    await _api.saveExamResult(_session, examId, result);
    await reload();
  }

  @override
  Future<void> scheduleFollowUp({
    required String patientId, required DateTime scheduledAt,
    required String reason, String notes = '',
  }) async {
    _patientOwned(patientId);
    await _api.createFollowUp(_session, patientId,
      scheduledAt: scheduledAt, reason: reason, notes: notes);
    await _api.setPatientFollowUp(_session, patientId, toReview: true);
    await reload();
  }

  @override
  Future<void> rescheduleFollowUp({
    required String followUpId, required DateTime scheduledAt,
    required String reason, String notes = '',
  }) async {
    _patientForFollowUp(followUpId);
    await _api.updateFollowUp(_session, followUpId,
      scheduledAt: scheduledAt, reason: reason, notes: notes);
    await reload();
  }

  @override
  Future<void> closeFollowUp(String id, {required bool completed}) async {
    final patientId = _patientForFollowUp(id);
    await _api.finishFollowUp(_session, id, completed: completed);
    await reload();
    if (!plannedFollowUps.any((follow) => follow.patientId == patientId)) {
      await _api.setPatientFollowUp(_session, patientId, toReview: false);
      await reload();
    }
  }
}
