import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/core/persistence/database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Les suppressions cliniques directes sont bloquées', () async {
    final database = AppDatabase.createWithExecutor(NativeDatabase.memory());
    try {
      await database.patientDao.createPatient(
        name: 'Patient fictif',
        age: 30,
        sex: 'F',
        phone: '',
      );
      final patient = (await database.patientDao.getAllPatients()).single;
      final initialOperations =
          (await database.pendingOperationsDao.getPendingOperations()).length;

      await expectLater(
        database.patientDao.deletePatient(patient.id),
        throwsA(isA<UnsupportedError>()),
      );
      await expectLater(
        database.visitDao.deleteVisit('visite-inconnue'),
        throwsA(isA<UnsupportedError>()),
      );
      await expectLater(
        database.examDao.deleteExam('examen-inconnu'),
        throwsA(isA<UnsupportedError>()),
      );
      await expectLater(
        database.followUpDao.deleteFollowUp('suivi-inconnu'),
        throwsA(isA<UnsupportedError>()),
      );

      expect((await database.patientDao.getAllPatients()).single.id, patient.id);
      expect(
        (await database.pendingOperationsDao.getPendingOperations()).length,
        initialOperations,
        reason: 'Aucune mutation silencieuse ne doit contourner l’outbox.',
      );
    } finally {
      await database.close();
    }
  });

  test('Les remplacements bruts de données médicales sont bloqués', () async {
    final database = AppDatabase.createWithExecutor(NativeDatabase.memory());
    try {
      await expectLater(
        database.visitDao.updateVisit(const VisitsCompanion()),
        throwsA(isA<UnsupportedError>()),
      );
      await expectLater(
        database.examDao.updateExam(const ExamsCompanion()),
        throwsA(isA<UnsupportedError>()),
      );
      expect(await database.pendingOperationsDao.getPendingOperations(), isEmpty);
    } finally {
      await database.close();
    }
  });
}
