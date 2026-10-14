import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/clinical_intake.dart';
import '../models/medical_models.dart';
import '../../features/auth/dev_auth_api.dart';
import 'clinical_store.dart';

/// Account-scoped source for the EXISTING Nocturne Clinique screens.
/// Never imports DemoStore. Cached reads are allowed only during an active
/// session and are cleared before emitting a sign-out / account change.
class ConnectedClinicalStore extends ChangeNotifier implements ClinicalStore {
  ConnectedClinicalStore(this.api, this.session);

  final DevAuthApi api;
  final DevSession session;
  final List<Patient> _patients = [];
  final List<Visit> _visits = [];
  final List<LabExam> _exams = [];
  final List<FollowUpPlan> _followUps = [];
  int _epoch = 0;
  bool _disposed = false;
  bool _loaded = false;
  Object? _loadError;

  bool get loaded => _loaded;
  Object? get loadError => _loadError;
  bool get active => !_disposed && session.isActive;

  void _assertActive(int epoch) {
    if (_disposed || !session.isActive || _epoch != epoch) {
      throw StateError('Le compte connecté a changé ou la session a expiré.');
    }
  }

  void _notify() { if (!_disposed) notifyListeners(); }

  void _clear() {
    _patients.clear();
    _visits.clear();
    _exams.clear();
    _followUps.clear();
    _loaded = false;
    _loadError = null;
    _notify();
  }

  void lock() {
    ++_epoch;
    _clear();
  }

  @override
  void dispose() {
    if (_disposed) return;
    ++_epoch;
    _clear();
    _disposed = true;
    super.dispose();
  }

  /// Atomic publication: NEVER show a half-loaded mixed account.
  Future<void> refresh() async {
    final epoch = ++_epoch;
    _clear();
    _assertActive(epoch);
    try {
      final remotePatients = await api.listPatients(session);
      _assertActive(epoch);
      final bundles = <DevClinicalBundle>[];
      for (final patient in remotePatients) {
        final bundle = await api.getPatientClinical(session, patient);
        _assertActive(epoch);
        bundles.add(bundle);
      }
      final patients = <Patient>[];
      final visits = <Visit>[];
      final exams = <LabExam>[];
      final followUps = <FollowUpPlan>[];
      for (var index = 0; index < remotePatients.length; index++) {
        final patient = remotePatients[index];
        final bundle = bundles[index];
        patients.add(Patient(
          id: patient.id, name: patient.displayName, age: patient.age,
          sex: '', phone: '', createdAt: DateTime.now(),
          followUp: bundle.followUps.any((f) => f.status == 'planned'),
        ));
        for (final v in bundle.visits) {
          visits.add(Visit(
            id: v.id, patientId: patient.id, date: v.createdAt,
            reason: v.reason, temperature: v.temperature,
            systolic: v.systolic, diastolic: v.diastolic,
            pulse: v.pulse, spo2: v.spo2,
          ));
        }
        for (final exam in bundle.exams) {
          exams.add(LabExam(
            id: exam.id, patientId: patient.id, title: exam.title,
            date: exam.resultRecordedAt ?? DateTime.now(),
            status: exam.status == 'complete'
              ? ExamStatus.complete : ExamStatus.pending,
            result: exam.result,
            resultRecordedAt: exam.resultRecordedAt,
          ));
        }
        for (final followUp in bundle.followUps) {
          followUps.add(FollowUpPlan(
            id: followUp.id, patientId: patient.id,
            scheduledAt: followUp.scheduledAt, reason: followUp.reason,
            status: switch (followUp.status) {
              'completed' => FollowUpStatus.completed,
              'cancelled' => FollowUpStatus.cancelled,
              _ => FollowUpStatus.planned,
            },
            completedAt: followUp.completedAt,
          ));
        }
      }
      _assertActive(epoch);
      _patients.addAll(patients);
      _visits.addAll(visits);
      _exams.addAll(exams);
      _followUps.addAll(followUps);
      _loaded = true;
      _notify();
    } catch (error) {
      // No cached data is exposed if any request failed.
      if (_epoch == epoch && !_disposed) {
        _clear();
        _loadError = error;
        _notify();
      }
      rethrow;
    }
  }

  List<T> _visible<T>(List<T> data) =>
      active && _loaded ? List<T>.unmodifiable(data) : List<T>.empty();

  @override
  Future<int> get pendingSyncCount async => 0;
  @override
  List<Patient> get patients => _visible(_patients);
  @override
  List<Visit> get visits => _visible(_visits);
  @override
  List<LabExam> get exams => _visible(_exams);
  @override
  List<FollowUpPlan> get followUps => _visible(_followUps);
  @override
  List<FollowUpPlan> get plannedFollowUps =>
    _visible(_followUps.where((f) => f.isPlanned).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)));
  @override
  List<FollowUpPlan> get pastFollowUps =>
    _visible(_followUps.where((f) => !f.isPlanned).toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt)));
  @override
  List<Patient> get followUpPatients =>
    _visible(_patients.where((p) => p.followUp).toList());
  @override
  List<Patient> get followUpsWithoutDate => _visible(_patients.where((p) =>
    p.followUp && !_followUps.any((f) =>
        f.patientId == p.id && f.isPlanned)).toList());
  @override
  List<LabExam> get pendingExams =>
    _visible(_exams.where((e) => e.status == ExamStatus.pending).toList());
  @override
  int get pendingExamsCount => pendingExams.length;
  @override
  List<Visit> visitsFor(String patientId) =>
    _visible(_visits.where((v) => v.patientId == patientId).toList()
      ..sort((a, b) => b.date.compareTo(a.date)));
  @override
  List<LabExam> examsFor(String patientId) =>
    _visible(_exams.where((e) => e.patientId == patientId).toList()
      ..sort((a, b) => b.date.compareTo(a.date)));
  @override
  List<FollowUpPlan> followUpsFor(String patientId) =>
    _visible(_followUps.where((f) => f.patientId == patientId).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)));
  @override
  Patient? patientById(String id) {
    for (final p in patients) {
      if (p.id == id) return p;
    }
    return null;
  }
  @override
  LabExam? examById(String id) {
    for (final e in exams) {
      if (e.id == id) return e;
    }
    return null;
  }
  @override
  Visit? lastVisitFor(String patientId) {
    final items = visitsFor(patientId);
    return items.isEmpty ? null : items.first;
  }
  @override
  Stream<List<Patient>> get patientsStream => Stream.value(patients);
  @override
  Stream<List<Visit>> visitsForStream(String id) =>
    Stream.value(visitsFor(id));
  @override
  Stream<List<LabExam>> get examsStream => Stream.value(exams);
  @override
  Stream<List<LabExam>> examsForStream(String id) =>
    Stream.value(examsFor(id));
  @override
  Stream<List<LabExam>> get pendingExamsStream =>
    Stream.value(pendingExams);
  @override
  Stream<List<FollowUpPlan>> get plannedFollowUpsStream =>
    Stream.value(plannedFollowUps);
  @override
  Stream<List<FollowUpPlan>> get pastFollowUpsStream =>
    Stream.value(pastFollowUps);
  @override
  Stream<List<FollowUpPlan>> followUpsForStream(String id) =>
    Stream.value(followUpsFor(id));
  @override
  Stream<List<Patient>> get followUpPatientsStream =>
    Stream.value(followUpPatients);

  Future<void> _commit(Future<void> Function() action) async {
    final epoch = _epoch;
    _assertActive(epoch);
    await action();
    _assertActive(epoch);
    await refresh();
  }

  @override
  Future<void> addPatient({
    required String name, required int age, required String sex,
    required String phone, PatientProfileSupplement? profile,
  }) async {
    if (sex.trim().isNotEmpty || phone.trim().isNotEmpty || profile != null) {
      throw UnsupportedError(
        'Le backend ne gère pas encore les informations complémentaires.');
    }
    await _commit(() async {
      await api.createClinicalPatient(session, name, age);
    });
  }

  @override
  Future<PatientProfileSupplement?> patientProfile(String id) async {
    if (!active) throw StateError('Session fermée.');
    return null; // API patient profile not available. Never synthesize data.
  }
  @override
  Future<ClinicalIntake?> visitIntake(String id) async {
    if (!active) throw StateError('Session fermée.');
    return null;
  }
  @override
  Future<void> updatePatientInfo({
    required String patientId, required String phone,
    required String allergies, required String medicalHistory,
    PatientProfileSupplement? profile,
  }) => Future<void>.error(UnsupportedError(
    'Modification du dossier indisponible tant que l’API ne la prend pas en charge.'));
  @override
  Future<void> setFollowUp(String id, {required bool toReview}) =>
    Future<void>.error(UnsupportedError(
      'Le drapeau de suivi devra être ajouté au backend.'));
  @override
  Future<void> addVisit({
    required String patientId, required String reason,
    double? temperature, int? systolic, int? diastolic, int? pulse,
    int? spo2, String notes = '', ClinicalIntake? intake,
  }) async {
    if (intake != null) throw UnsupportedError(
      'Les compléments cliniques nécessitent une API dédiée.');
    await _commit(() async {
      await api.createClinicalVisit(session, patientId,
        reason: reason, temperature: temperature, systolic: systolic,
        diastolic: diastolic, pulse: pulse, spo2: spo2, notes: notes);
    });
  }
  @override
  Future<String> addExam({
    required String patientId, required String title,
  }) async {
    final epoch = _epoch;
    _assertActive(epoch);
    final exam = await api.createClinicalExam(session, patientId, title);
    _assertActive(epoch);
    await refresh();
    return exam.id;
  }
  @override
  Future<void> recordExamResult({
    required String examId, required String result,
  }) => _commit(() async {
    await api.submitClinicalExamResult(session, examId, result);
  });
  @override
  Future<void> scheduleFollowUp({
    required String patientId, required DateTime scheduledAt,
    required String reason, String notes = '',
  }) => _commit(() async {
    await api.createClinicalFollowUp(session, patientId,
      scheduledAt: scheduledAt, reason: reason, notes: notes);
  });
  @override
  Future<void> rescheduleFollowUp({
    required String followUpId, required DateTime scheduledAt,
    required String reason, String notes = '',
  }) => _commit(() async {
    await api.updateClinicalFollowUp(session, followUpId,
      scheduledAt: scheduledAt, reason: reason, notes: notes);
  });
  @override
  Future<void> closeFollowUp(
      String followUpId, {required bool completed}) =>
    _commit(() async {
      await api.completeClinicalFollowUp(session, followUpId, completed);
    });
}

/// Provides [ConnectedClinicalStore] to the untouched original screens.
class ConnectedClinicalScope extends InheritedNotifier<ConnectedClinicalStore> {
  const ConnectedClinicalScope({
    super.key, required ConnectedClinicalStore store,
    required super.child,
  }) : super(notifier: store);
}
