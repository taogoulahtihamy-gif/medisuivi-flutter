import 'dart:async';

import 'package:flutter/widgets.dart';
import '../data/demo_data.dart';
import '../models/medical_models.dart';
import 'clinical_store.dart';

/// Etat EN MEMOIRE : perdu à la fermeture de l'application.
/// Interdit à de vraies données patient. Voir docs/SECURITY.md.
class DemoStore extends ChangeNotifier implements ClinicalStore {
  final List<Patient> _patients = [...DemoData.patients];
  final List<Visit> _visits = [...DemoData.visits];
  final List<LabExam> _exams = [...DemoData.exams];
  int _examSequence = 0;
  final List<FollowUpPlan> _followUps = [...DemoData.followUps];
  int _followUpSequence = 0;

  /// Prototype Web : aucune opération distante, aucun stockage durable.
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
  List<FollowUpPlan> followUpsFor(String patientId) =>
      _followUps.where((plan) => plan.patientId == patientId).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  @override
  List<FollowUpPlan> get plannedFollowUps =>
      _followUps.where((plan) => plan.isPlanned).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  @override
  List<FollowUpPlan> get pastFollowUps =>
      _followUps.where((plan) => !plan.isPlanned).toList()
        ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

  /// Patients dont le suivi est signalé, sans prochain rendez-vous daté.
  @override
  List<Patient> get followUpsWithoutDate => _patients.where((patient) =>
    patient.followUp &&
    !_followUps.any((plan) =>
        plan.patientId == patient.id && plan.isPlanned)).toList();

  @override
  List<Patient> get followUpPatients =>
      _patients.where((p) => p.followUp).toList();

  @override
  List<LabExam> get pendingExams =>
      _exams.where((e) => e.status == ExamStatus.pending).toList();

  @override
  int get pendingExamsCount => pendingExams.length;

  @override
  Visit? lastVisitFor(String patientId) {
    final patientVisits = visitsFor(patientId);
    return patientVisits.isEmpty ? null : patientVisits.first;
  }

  @override
  Future<void> scheduleFollowUp({
    required String patientId,
    required DateTime scheduledAt,
    required String reason,
    String notes = '',
  }) async {
    final patient = patientById(patientId);
    if (patient == null) throw StateError('Dossier patient introuvable.');
    if (reason.trim().isEmpty) throw ArgumentError('Motif obligatoire.');
    if (scheduledAt.isBefore(DateTime.now().subtract(const Duration(days: 3650)))) {
      throw ArgumentError('Date de suivi trop ancienne.');
    }
    _followUps.add(FollowUpPlan(
      id: 'FUP-${DateTime.now().microsecondsSinceEpoch}-${++_followUpSequence}',
      patientId: patientId,
      scheduledAt: scheduledAt,
      reason: reason.trim(),
      notes: notes.trim(),
    ));
    await setFollowUp(patientId, toReview: true);
  }

  @override
  Future<void> rescheduleFollowUp({
    required String followUpId,
    required DateTime scheduledAt,
    required String reason,
    String notes = '',
  }) async {
    final index = _followUps.indexWhere((plan) => plan.id == followUpId);
    if (index < 0) throw StateError('Suivi introuvable.');
    if (!_followUps[index].isPlanned) {
      throw StateError('Un suivi terminé ne peut pas être modifié.');
    }
    if (reason.trim().isEmpty) throw ArgumentError('Motif obligatoire.');
    _followUps[index] = _followUps[index].copyWith(
      scheduledAt: scheduledAt, reason: reason.trim(), notes: notes.trim());
    notifyListeners();
  }

  @override
  Future<void> closeFollowUp(String followUpId, {required bool completed}) async {
    final index = _followUps.indexWhere((plan) => plan.id == followUpId);
    if (index < 0) throw StateError('Suivi introuvable.');
    final plan = _followUps[index];
    if (!plan.isPlanned) throw StateError('Ce suivi est déjà clôturé.');
    _followUps[index] = plan.copyWith(
      status: completed ? FollowUpStatus.completed : FollowUpStatus.cancelled,
      completedAt: completed ? DateTime.now() : null,
    );
    final hasOtherPlan = _followUps.any(
      (candidate) => candidate.patientId == plan.patientId && candidate.isPlanned);
    if (!hasOtherPlan) {
      await setFollowUp(plan.patientId, toReview: false);
    } else {
      notifyListeners();
    }
  }


  @override
  List<Visit> visitsFor(String patientId) =>
      _visits.where((visit) => visit.patientId == patientId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  @override
  List<LabExam> examsFor(String patientId) =>
      _exams.where((exam) => exam.patientId == patientId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  @override
  Patient? patientById(String id) {
    for (final patient in _patients) {
      if (patient.id == id) return patient;
    }
    return null;
  }

  // ==================== STREAMS RÉACTIFS (in-memory) ====================

  @override
  Stream<List<Patient>> get patientsStream =>
      Stream.value(List.unmodifiable(_patients));

  @override
  Stream<List<Visit>> visitsForStream(String patientId) =>
      Stream.value(visitsFor(patientId));

  @override
  Stream<List<LabExam>> get examsStream =>
      Stream.value(List.unmodifiable(_exams));

  @override
  Stream<List<LabExam>> examsForStream(String patientId) =>
      Stream.value(examsFor(patientId));

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
  Stream<List<FollowUpPlan>> followUpsForStream(String patientId) =>
      Stream.value(followUpsFor(patientId));

  @override
  Stream<List<Patient>> get followUpPatientsStream =>
      Stream.value(followUpPatients);

  @override
  Future<void> addPatient({required String name, required int age, required String sex, required String phone}) async {
    final identifier = DateTime.now().microsecondsSinceEpoch;
    _patients.insert(0, Patient(
      id: 'PAT-$identifier',
      name: name.trim(),
      age: age,
      sex: sex,
      phone: phone.trim().isEmpty ? 'Non renseigné' : phone.trim(),
      createdAt: DateTime.now(),
    ));
    notifyListeners();
  }

  @override
  Future<void> updatePatientInfo({
    required String patientId,
    required String phone,
    required String allergies,
    required String medicalHistory,
  }) async {
    final index = _patients.indexWhere((p) => p.id == patientId);
    if (index < 0) throw StateError('Dossier patient introuvable.');
    _patients[index] = _patients[index].copyWith(
      phone: phone.trim().isEmpty ? 'Non renseigné' : phone.trim(),
      allergies: allergies.trim().isEmpty ? 'Non renseignées' : allergies.trim(),
      medicalHistory: medicalHistory.trim().isEmpty
        ? 'Non renseignés' : medicalHistory.trim(),
    );
    notifyListeners();
  }

  @override
  Future<void> setFollowUp(String patientId, {required bool toReview}) async {
    final index = _patients.indexWhere((p) => p.id == patientId);
    if (index < 0) throw StateError('Dossier patient introuvable.');
    _patients[index] = _patients[index].copyWith(followUp: toReview);
    notifyListeners();
  }

  @override
  LabExam? examById(String examId) {
    for (final exam in _exams) {
      if (exam.id == examId) return exam;
    }
    return null;
  }

  /// Retourne l'identifiant stable afin d'ouvrir immédiatement le bilan créé.
  @override
  Future<String> addExam({required String patientId, required String title}) async {
    if (patientById(patientId) == null) {
      throw StateError('Dossier patient introuvable.');
    }
    if (title.trim().length < 3) {
      throw ArgumentError("Nom d'examen obligatoire.");
    }
    final id = 'EXM-${DateTime.now().microsecondsSinceEpoch}-${++_examSequence}';
    _exams.insert(0, LabExam(
      id: id,
      patientId: patientId,
      title: title.trim(),
      date: DateTime.now(),
      status: ExamStatus.pending,
    ));
    notifyListeners();
    return id;
  }

  /// Un résultat confirmé n'est pas silencieusement écrasé.
  @override
  Future<void> recordExamResult({required String examId, required String result}) async {
    final index = _exams.indexWhere((exam) => exam.id == examId);
    if (index < 0) throw StateError('Examen introuvable.');
    if (_exams[index].status == ExamStatus.complete) {
      throw StateError('Ce bilan possède déjà un résultat.');
    }
    if (result.trim().isEmpty) {
      throw ArgumentError('Le résultat est obligatoire.');
    }
    final exam = _exams[index];
    _exams[index] = LabExam(
      id: exam.id,
      patientId: exam.patientId,
      title: exam.title,
      date: exam.date,
      status: ExamStatus.complete,
      result: result.trim(),
      resultRecordedAt: DateTime.now(),
    );
    notifyListeners();
  }

  @override
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
    _visits.insert(0, Visit(
      id: 'VIS-${DateTime.now().microsecondsSinceEpoch}',
      patientId: patientId,
      date: DateTime.now(),
      reason: reason.trim(),
      temperature: temperature,
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
      spo2: spo2,
      notes: notes.trim(),
    ));
    notifyListeners();
  }
}

class DemoScope extends InheritedNotifier<DemoStore> {
  const DemoScope({super.key, required DemoStore store, required super.child})
      : super(notifier: store);

  static DemoStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DemoScope>();
    assert(scope != null, 'DemoScope not found');
    return scope!.notifier!;
  }
}
