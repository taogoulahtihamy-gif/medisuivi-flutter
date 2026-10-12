import 'package:flutter/widgets.dart';
import '../data/demo_data.dart';
import '../models/medical_models.dart';

/// Etat EN MEMOIRE : perdu à la fermeture de l'application.
/// Interdit à de vraies données patient. Voir docs/SECURITY.md.
class DemoStore extends ChangeNotifier {
  final List<Patient> _patients = [...DemoData.patients];
  final List<Visit> _visits = [...DemoData.visits];
  final List<LabExam> _exams = [...DemoData.exams];

  List<Patient> get patients => List.unmodifiable(_patients);
  List<Visit> get visits => List.unmodifiable(_visits);
  List<LabExam> get exams => List.unmodifiable(_exams);

  List<Visit> visitsFor(String patientId) =>
      _visits.where((visit) => visit.patientId == patientId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
  List<LabExam> examsFor(String patientId) =>
      _exams.where((exam) => exam.patientId == patientId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
  Patient? patientById(String id) {
    for (final patient in _patients) {
      if (patient.id == id) return patient;
    }
    return null;
  }

  void addPatient({required String name, required int age, required String sex, required String phone}) {
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

  void updatePatientInfo({
    required String patientId,
    required String phone,
    required String allergies,
    required String medicalHistory,
  }) {
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

  void setFollowUp(String patientId, {required bool toReview}) {
    final index = _patients.indexWhere((p) => p.id == patientId);
    if (index < 0) throw StateError('Dossier patient introuvable.');
    _patients[index] = _patients[index].copyWith(followUp: toReview);
    notifyListeners();
  }

  void addExam({required String patientId, required String title}) {
    if (patientById(patientId) == null) {
      throw StateError('Dossier patient introuvable.');
    }
    _exams.insert(0, LabExam(
      id: 'EXM-${DateTime.now().microsecondsSinceEpoch}',
      patientId: patientId,
      title: title.trim(),
      date: DateTime.now(),
      status: ExamStatus.pending,
    ));
    notifyListeners();
  }

  void recordExamResult({required String examId, required String result}) {
    final index = _exams.indexWhere((exam) => exam.id == examId);
    if (index < 0) throw StateError('Examen introuvable.');
    final exam = _exams[index];
    _exams[index] = LabExam(
      id: exam.id,
      patientId: exam.patientId,
      title: exam.title,
      date: exam.date,
      status: ExamStatus.complete,
      result: result.trim(),
    );
    notifyListeners();
  }

  void addVisit({
    required String patientId,
    required String reason,
    double? temperature,
    int? systolic,
    int? diastolic,
    int? pulse,
    int? spo2,
    String notes = '',
  }) {
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
