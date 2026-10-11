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
      _exams.where((exam) => exam.patientId == patientId).toList();
  Patient? patientById(String id) {
    for (final patient in _patients) {
      if (patient.id == id) return patient;
    }
    return null;
  }

  void addPatient(
      {required String name,
      required int age,
      required String sex,
      required String phone}) {
    final identifier = DateTime.now().microsecondsSinceEpoch;
    _patients.insert(
        0,
        Patient(
          id: 'DEMO-$identifier',
          name: name.trim(),
          age: age,
          sex: sex,
          phone: phone.trim().isEmpty ? 'Non renseigné' : phone.trim(),
          createdAt: DateTime.now(),
        ));
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
    _visits.insert(
        0,
        Visit(
          id: 'DEMO-${DateTime.now().microsecondsSinceEpoch}',
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
