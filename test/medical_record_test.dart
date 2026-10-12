import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/core/models/medical_models.dart';
import 'package:medisuivi/core/state/demo_store.dart';

void main() {
  group('Dossier médical en mémoire', () {
    late DemoStore store;
    setUp(() => store = DemoStore());
    tearDown(() => store.dispose());

    test('antécédents, allergies et contact liés au bon patient', () {
      final id = store.patients.first.id;
      final before = store.patients.length;
      store.updatePatientInfo(
        patientId: id,
        phone: '+221 77 000 00 00',
        allergies: 'Information à vérifier',
        medicalHistory: 'Historique renseigné',
      );
      expect(store.patients.length, before);
      expect(store.patientById(id)!.allergies, 'Information à vérifier');
      expect(store.patientById(id)!.medicalHistory, 'Historique renseigné');
      expect(store.patientById(id)!.phone, '+221 77 000 00 00');
    });

    test('l’indicateur de suivi est modifiable', () {
      final id = store.patients.first.id;
      store.setFollowUp(id, toReview: false);
      expect(store.patientById(id)!.followUp, false);
      store.setFollowUp(id, toReview: true);
      expect(store.patientById(id)!.followUp, true);
    });

    test('une prescription est reliée au patient, puis reçoit un résultat', () {
      final id = store.patients.first.id;
      final before = store.examsFor(id).length;
      store.addExam(patientId: id, title: 'Bilan à vérifier');
      final exams = store.examsFor(id);
      expect(exams.length, before + 1);
      final created = exams.first;
      expect(created.patientId, id);
      expect(created.status, ExamStatus.pending);
      store.recordExamResult(examId: created.id, result: 'Valeur à vérifier');
      final updated = store.examsFor(id)
        .firstWhere((exam) => exam.id == created.id);
      expect(updated.status, ExamStatus.complete);
      expect(updated.result, 'Valeur à vérifier');
    });

    test('consultation nouvellement ajoutée visible dans l’historique', () {
      final id = store.patients.first.id;
      final before = store.visitsFor(id).length;
      store.addVisit(patientId: id, reason: 'Visite de suivi', pulse: 74);
      expect(store.visitsFor(id).length, before + 1);
      expect(store.visitsFor(id).first.pulse, 74);
    });

    test('un bilan ne peut pas être rattaché à un patient introuvable', () {
      expect(() => store.addExam(patientId: 'ABSENT', title: 'Examen'),
        throwsStateError);
      expect(() => store.setFollowUp('ABSENT', toReview: true),
        throwsStateError);
    });
  });
}
