/// Tests pour le contrat métier ClinicalStore.
///
/// Valide que DemoStore et PersistentStore implémentent correctement
/// l'interface ClinicalStore avec les mêmes comportements attendus.
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/core/persistence/database.dart'
    hide Patient, Visit;
import 'package:medisuivi/core/state/clinical_store.dart';
import 'package:medisuivi/core/state/demo_store.dart';
import 'package:medisuivi/core/state/persistent_store.dart';
import 'package:medisuivi/core/models/medical_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClinicalStore - DemoStore', () {
    late ClinicalStore store;

    setUp(() {
      store = DemoStore();
    });

    test('patients initiaux présents (données fictives)', () {
      expect(store.patients, isNotEmpty);
      expect(store.patients.every((p) => p.id.startsWith('PAT-')), isTrue);
    });

    test('addPatient crée un patient et notifie', () async {
      final initialCount = store.patients.length;
      await store.addPatient(
        name: 'Nouveau Patient',
        age: 40,
        sex: 'M',
        phone: '0600000000',
      );
      expect(store.patients.length, initialCount + 1);
      expect(store.patients.first.name, 'Nouveau Patient');
    });

    test('updatePatientInfo échoue si patient introuvable', () async {
      await expectLater(
        store.updatePatientInfo(
          patientId: 'INEXISTANT',
          phone: '0102030405',
          allergies: 'Aucune',
          medicalHistory: 'Aucun',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('updatePatientInfo met à jour les infos médicales', () async {
      final patient = store.patients.first;
      await store.updatePatientInfo(
        patientId: patient.id,
        phone: '0102030405',
        allergies: 'Pénicilline',
        medicalHistory: 'Hypertension',
      );
      final updated = store.patientById(patient.id);
      expect(updated!.phone, '0102030405');
      expect(updated.allergies, 'Pénicilline');
      expect(updated.medicalHistory, 'Hypertension');
    });

    test('addVisit crée une consultation', () async {
      final patient = store.patients.first;
      final initialCount = store.visitsFor(patient.id).length;
      await store.addVisit(
        patientId: patient.id,
        reason: 'Consultation test',
        systolic: 120,
        diastolic: 80,
      );
      expect(store.visitsFor(patient.id).length, initialCount + 1);
      expect(store.visitsFor(patient.id).first.reason, 'Consultation test');
    });

    test('addExam crée un examen et retourne son ID', () async {
      final patient = store.patients.first;
      final examId = await store.addExam(
        patientId: patient.id,
        title: 'Bilan sanguin',
      );
      expect(examId, startsWith('EXM-'));
      expect(store.examById(examId), isNotNull);
      expect(store.examById(examId)!.title, 'Bilan sanguin');
      expect(store.examById(examId)!.status, ExamStatus.pending);
    });

    test('recordExamResult enregistre un résultat', () async {
      final patient = store.patients.first;
      final examId = await store.addExam(patientId: patient.id, title: 'NFS');
      await store.recordExamResult(examId: examId, result: 'Hémoglobine: 13 g/dl');
      final exam = store.examById(examId);
      expect(exam!.status, ExamStatus.complete);
      expect(exam.result, 'Hémoglobine: 13 g/dl');
    });

    test('recordExamResult échoue si examen déjà complété', () async {
      final patient = store.patients.first;
      final examId = await store.addExam(patientId: patient.id, title: 'NFS');
      await store.recordExamResult(examId: examId, result: 'OK');
      await expectLater(
        store.recordExamResult(examId: examId, result: 'Autre'),
        throwsA(isA<StateError>()),
      );
    });

    test('scheduleFollowUp programme un suivi', () async {
      // Trouver un patient sans suivi existant
      Patient patient;
      for (final candidate in store.patients) {
        if (store.followUpsFor(candidate.id).isEmpty) {
          patient = candidate;
          break;
        }
      }
      late final Patient selectedPatient;
      for (final candidate in store.patients) {
        if (store.followUpsFor(candidate.id).isEmpty) {
          selectedPatient = candidate;
          break;
        }
      }
      patient = selectedPatient;
      final initialCount = store.followUpsFor(patient.id).length;
      final scheduled = DateTime.now().add(const Duration(days: 7));
      await store.scheduleFollowUp(
        patientId: patient.id,
        scheduledAt: scheduled,
        reason: 'Contrôle',
      );
      expect(store.followUpsFor(patient.id).length, initialCount + 1);
      expect(store.followUpsFor(patient.id).first.reason, 'Contrôle');
      expect(store.patientById(patient.id)!.followUp, isTrue);
    });

    test('closeFollowUp clôture un suivi', () async {
      Patient patient;
      for (final candidate in store.patients) {
        if (store.followUpsFor(candidate.id).isEmpty) {
          patient = candidate;
          break;
        }
      }
      late final Patient selectedPatient;
      for (final candidate in store.patients) {
        if (store.followUpsFor(candidate.id).isEmpty) {
          selectedPatient = candidate;
          break;
        }
      }
      patient = selectedPatient;
      final scheduled = DateTime.now().add(const Duration(days: 7));
      await store.scheduleFollowUp(
        patientId: patient.id,
        scheduledAt: scheduled,
        reason: 'Contrôle',
      );
      final followUp = store.followUpsFor(patient.id).first;
      await store.closeFollowUp(followUp.id, completed: true);
      final closed = store.followUpsFor(patient.id).first;
      expect(closed.status, FollowUpStatus.completed);
      expect(closed.completedAt, isNotNull);
      expect((await database.patientDao.getPatientById(patient.id))!.followUp, isFalse);
    });

    test('rescheduleFollowUp modifie la date d\'un suivi planifié', () async {
      Patient patient;
      for (final candidate in store.patients) {
        if (store.followUpsFor(candidate.id).isEmpty) {
          patient = candidate;
          break;
        }
      }
      late final Patient selectedPatient;
      for (final candidate in store.patients) {
        if (store.followUpsFor(candidate.id).isEmpty) {
          selectedPatient = candidate;
          break;
        }
      }
      patient = selectedPatient;
      final scheduled = DateTime.now().add(const Duration(days: 7));
      await store.scheduleFollowUp(
        patientId: patient.id,
        scheduledAt: scheduled,
        reason: 'Contrôle',
      );
      final followUp = store.followUpsFor(patient.id).first;
      final newDate = DateTime.now().add(const Duration(days: 14));
      await store.rescheduleFollowUp(
        followUpId: followUp.id,
        scheduledAt: newDate,
        reason: 'Contrôle reporté',
      );
      final updated = store.followUpsFor(patient.id).first;
      expect(updated.reason, 'Contrôle reporté');
    });

    test('pendingSyncCount retourne 0 sur DemoStore', () async {
      expect(await store.pendingSyncCount, 0);
    });

    test('streams réactifs émettent les valeurs initiales', () async {
      final patientsStream = store.patientsStream;
      final examsStream = store.examsStream;
      final followUpsStream = store.plannedFollowUpsStream;

      final patientsEmission = await patientsStream.first;
      final examsEmission = await examsStream.first;
      final followUpsEmission = await followUpsStream.first;

      expect(patientsEmission, equals(store.patients));
      expect(examsEmission, equals(store.exams));
      expect(followUpsEmission, equals(store.plannedFollowUps));
    });
  });

  group('ClinicalStore - PersistentStore', () {
    late AppDatabase database;
    late PersistentStore persistentStore;
    late ClinicalStore store;

    setUp(() async {
      database = AppDatabase.createWithExecutor(NativeDatabase.memory());
      persistentStore = PersistentStore(database);
      store = persistentStore;
      await persistentStore.ready;
    });

    tearDown(() async {
      persistentStore.dispose();
      await persistentStore.streamsStopped;
      await database.close();
    });

    /// Attend la propagation du stream Drift vers le cache synchrone.
    Future<void> attendreCache(void Function(ClinicalStore) verifier) async {
      final limite = DateTime.now().add(const Duration(seconds: 5));
      while (true) {
        try {
          verifier(store);
          return;
        } catch (_) {
          if (DateTime.now().isAfter(limite)) rethrow;
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      }
    }

    test('initialisation réussie et ready complet', () async {
      expect(store.patients, isA<List<Patient>>());
      expect(store.visits, isA<List<Visit>>());
      expect(store.exams, isA<List<LabExam>>());
      expect(store.followUps, isA<List<FollowUpPlan>>());
    });

    test('addPatient crée un patient en base', () async {
      final initialCount = store.patients.length;
      await store.addPatient(
        name: 'Patient Persistant',
        age: 35,
        sex: 'F',
        phone: '0600000001',
      );
      await attendreCache((s) {
        expect(s.patients.length, initialCount + 1);
      });
      final created =
          store.patients.firstWhere((p) => p.name == 'Patient Persistant');
      expect(created.age, 35);
      expect(created.sex, 'F');
    });

    test('updatePatientInfo met à jour en base', () async {
      await store.addPatient(
        name: 'Patient MAJ',
        age: 30,
        sex: 'M',
        phone: '0600000002',
      );
      await attendreCache((s) {
        expect(s.patients.any((p) => p.name == 'Patient MAJ'), isTrue);
      });
      final patient = store.patients.firstWhere((p) => p.name == 'Patient MAJ');
      await store.updatePatientInfo(
        patientId: patient.id,
        phone: '0708091011',
        allergies: 'Aucune',
        medicalHistory: 'Diabète',
      );
      await attendreCache((s) {
        expect(s.patientById(patient.id)!.phone, '0708091011');
      });
      final updated = store.patientById(patient.id);
      expect(updated!.allergies, 'Aucune');
      expect(updated.medicalHistory, 'Diabète');
    });

    test('addVisit crée une consultation en base', () async {
      await store.addPatient(
        name: 'Patient Visite',
        age: 25,
        sex: 'F',
        phone: '0600000003',
      );
      await attendreCache((s) {
        expect(s.patients.any((p) => p.name == 'Patient Visite'), isTrue);
      });
      final patient = store.patients.firstWhere((p) => p.name == 'Patient Visite');
      await store.addVisit(
        patientId: patient.id,
        reason: 'Suivi diabète',
        temperature: 37.0,
        systolic: 130,
        diastolic: 85,
        pulse: 72,
        spo2: 98,
        notes: 'HbA1c à vérifier',
      );
      await attendreCache((s) {
        expect(s.visitsFor(patient.id).length, 1);
      });
      final visits = store.visitsFor(patient.id);
      expect(visits.first.reason, 'Suivi diabète');
      expect(visits.first.temperature, 37.0);
    });

    test('addExam crée un examen en base et retourne ID', () async {
      await store.addPatient(
        name: 'Patient Examen',
        age: 45,
        sex: 'M',
        phone: '0600000004',
      );
      await attendreCache((s) {
        expect(s.patients.any((p) => p.name == 'Patient Examen'), isTrue);
      });
      final patient = store.patients.firstWhere((p) => p.name == 'Patient Examen');
      final examId = await store.addExam(
        patientId: patient.id,
        title: 'Créatinine',
      );
      expect(examId, isNotEmpty);
      await attendreCache((s) {
        expect(s.examById(examId), isNotNull);
      });
      final exam = store.examById(examId);
      expect(exam!.title, 'Créatinine');
      expect(exam.status, ExamStatus.pending);
    });

    test('recordExamResult enregistre résultat en base', () async {
      await store.addPatient(
        name: 'Patient Résultat',
        age: 50,
        sex: 'F',
        phone: '0600000005',
      );
      await attendreCache((s) {
        expect(s.patients.any((p) => p.name == 'Patient Résultat'), isTrue);
      });
      final patient = store.patients.firstWhere((p) => p.name == 'Patient Résultat');
      final examId = await store.addExam(patientId: patient.id, title: 'Ionogramme');
      await store.recordExamResult(
        examId: examId,
        result: 'Na: 140, K: 4.2, Cl: 102',
      );
      await attendreCache((s) {
        expect(s.examById(examId)!.status, ExamStatus.complete);
      });
      final exam = store.examById(examId);
      expect(exam!.result, 'Na: 140, K: 4.2, Cl: 102');
    });

    test('scheduleFollowUp programme un suivi en base', () async {
      await store.addPatient(
        name: 'Patient Suivi',
        age: 60,
        sex: 'M',
        phone: '0600000006',
      );
      await attendreCache((s) {
        expect(s.patients.any((p) => p.name == 'Patient Suivi'), isTrue);
      });
      final patient = store.patients.firstWhere((p) => p.name == 'Patient Suivi');
      final scheduled = DateTime.now().add(const Duration(days: 14));
      await store.scheduleFollowUp(
        patientId: patient.id,
        scheduledAt: scheduled,
        reason: 'Contrôle tensionnel',
        notes: 'Apporter tensiomètre',
      );
      await attendreCache((s) {
        expect(s.followUpsFor(patient.id).length, 1);
      });
      final followUps = store.followUpsFor(patient.id);
      expect(followUps.first.reason, 'Contrôle tensionnel');
      expect(followUps.first.notes, 'Apporter tensiomètre');
      expect((await database.patientDao.getPatientById(patient.id))!.followUp, isTrue);
    });

    test('closeFollowUp clôture un suivi en base', () async {
      await store.addPatient(
        name: 'Patient Clôture',
        age: 55,
        sex: 'F',
        phone: '0600000007',
      );
      await attendreCache((s) {
        expect(s.patients.any((p) => p.name == 'Patient Clôture'), isTrue);
      });
      final patient = store.patients.firstWhere((p) => p.name == 'Patient Clôture');
      final scheduled = DateTime.now().add(const Duration(days: 7));
      await store.scheduleFollowUp(
        patientId: patient.id,
        scheduledAt: scheduled,
        reason: 'Échographie',
      );
      await attendreCache((s) {
        expect(s.followUpsFor(patient.id).length, 1);
      });
      final followUp = store.followUpsFor(patient.id).first;
      await store.closeFollowUp(followUp.id, completed: true);
      await attendreCache((s) {
        expect(s.followUpsFor(patient.id).first.status, FollowUpStatus.completed);
      });
      final closed = store.followUpsFor(patient.id).first;
      expect(closed.completedAt, isNotNull);
      expect(store.plannedFollowUps.where((f) => f.patientId == patient.id),
          isEmpty);
    });


    test('deux suivis : le drapeau persiste puis se retire', () async {
      await store.addPatient(name: 'Deux suivis', age: 40, sex: 'F', phone: '');
      await attendreCache((s) {
        expect(s.patients.any((p) => p.name == 'Deux suivis'), isTrue);
      });
      final id = store.patients.firstWhere((p) => p.name == 'Deux suivis').id;
      await store.scheduleFollowUp(patientId: id,
          scheduledAt: DateTime.now().add(const Duration(days: 2)),
          reason: 'Premier');
      await store.scheduleFollowUp(patientId: id,
          scheduledAt: DateTime.now().add(const Duration(days: 3)),
          reason: 'Second');
      final plans = await database.followUpDao.getFollowUpsForPatient(id);
      expect(plans, hasLength(2));
      await store.closeFollowUp(plans.first.id, completed: true);
      expect((await database.patientDao.getPatientById(id))!.followUp, isTrue);
      await store.closeFollowUp(plans.last.id, completed: false);
      expect((await database.patientDao.getPatientById(id))!.followUp, isFalse);
      expect((await database.followUpDao.getFollowUpsForPatient(id)).length, 2);
    });

    test('programmation : rollback suivi et outbox après échec patient', () async {
      await store.addPatient(name: 'Rollback création', age: 40, sex: 'F', phone: '');
      await attendreCache((s) {
        expect(s.patients.any((p) => p.name == 'Rollback création'), isTrue);
      });
      final id = store.patients.firstWhere((p) => p.name == 'Rollback création').id;
      final before = (await database.pendingOperationsDao.getPendingOperations()).length;
      await database.customStatement('''
        CREATE TRIGGER fail_patient_update BEFORE UPDATE ON patients
        BEGIN SELECT RAISE(ABORT, 'patient update rejected'); END;
      ''');
      await expectLater(store.scheduleFollowUp(patientId: id,
          scheduledAt: DateTime.now().add(const Duration(days: 4)),
          reason: 'Test fictif'), throwsA(isA<Exception>()));
      expect(await database.followUpDao.getFollowUpsForPatient(id), isEmpty);
      expect((await database.patientDao.getPatientById(id))!.followUp, isFalse);
      expect((await database.pendingOperationsDao.getPendingOperations()).length, before);
    });

    test('clôture : rollback suivi et outbox après échec patient', () async {
      await store.addPatient(name: 'Rollback clôture', age: 40, sex: 'M', phone: '');
      await attendreCache((s) {
        expect(s.patients.any((p) => p.name == 'Rollback clôture'), isTrue);
      });
      final id = store.patients.firstWhere((p) => p.name == 'Rollback clôture').id;
      await store.scheduleFollowUp(patientId: id,
          scheduledAt: DateTime.now().add(const Duration(days: 4)),
          reason: 'Test fictif');
      final plan = (await database.followUpDao.getFollowUpsForPatient(id)).single;
      final before = (await database.pendingOperationsDao.getPendingOperations()).length;
      await database.customStatement('''
        CREATE TRIGGER fail_patient_update BEFORE UPDATE ON patients
        BEGIN SELECT RAISE(ABORT, 'patient update rejected'); END;
      ''');
      await expectLater(store.closeFollowUp(plan.id, completed: true),
          throwsA(isA<Exception>()));
      expect((await database.followUpDao.getFollowUpById(plan.id))!.status, 0);
      expect((await database.patientDao.getPatientById(id))!.followUp, isTrue);
      expect((await database.pendingOperationsDao.getPendingOperations()).length, before);
    });

    test('rescheduleFollowUp modifie un suivi en base', () async {
      await store.addPatient(
        name: 'Patient Report',
        age: 40,
        sex: 'M',
        phone: '0600000008',
      );
      await attendreCache((s) {
        expect(s.patients.any((p) => p.name == 'Patient Report'), isTrue);
      });
      final patient = store.patients.firstWhere((p) => p.name == 'Patient Report');
      final scheduled = DateTime.now().add(const Duration(days: 7));
      await store.scheduleFollowUp(
        patientId: patient.id,
        scheduledAt: scheduled,
        reason: 'Initial',
      );
      await attendreCache((s) {
        expect(s.followUpsFor(patient.id).length, 1);
      });
      final followUp = store.followUpsFor(patient.id).first;
      final newDate = DateTime.now().add(const Duration(days: 21));
      await store.rescheduleFollowUp(
        followUpId: followUp.id,
        scheduledAt: newDate,
        reason: 'Reporté',
      );
      await attendreCache((s) {
        expect(s.followUpsFor(patient.id).first.reason, 'Reporté');
      });
      final updated = store.followUpsFor(patient.id).first;
      // SQLite stocke les dates à la seconde près : comparer sans millisecondes.
      expect(
        updated.scheduledAt.difference(newDate).abs(),
        lessThan(const Duration(seconds: 1)),
      );
    });

    test('setFollowUp active/désactive le drapeau', () async {
      await store.addPatient(
        name: 'Patient Drapeau',
        age: 33,
        sex: 'F',
        phone: '0600000009',
      );
      await attendreCache((s) {
        expect(s.patients.any((p) => p.name == 'Patient Drapeau'), isTrue);
      });
      final patient = store.patients.firstWhere((p) => p.name == 'Patient Drapeau');
      expect(patient.followUp, isFalse);
      await store.setFollowUp(patient.id, toReview: true);
      await attendreCache((s) {
        expect(s.patientById(patient.id)!.followUp, isTrue);
      });
      await store.setFollowUp(patient.id, toReview: false);
      await attendreCache((s) {
        expect(s.patientById(patient.id)!.followUp, isFalse);
      });
    });

    test('propagation des erreurs SQLite via ready', () async {
      await database.customStatement('DROP TABLE IF EXISTS patients;');
      final badStore = PersistentStore(database);
      await expectLater(badStore.ready, throwsA(isA<Exception>()));
      badStore.dispose();
      await badStore.streamsStopped;
    });

    test('streams réactifs fonctionnent après écriture', () async {
      await store.addPatient(
        name: 'Stream Test',
        age: 28,
        sex: 'M',
        phone: '0600000010',
      );
      await attendreCache((s) {
        expect(s.patients.any((p) => p.name == 'Stream Test'), isTrue);
      });
      final patient = store.patients.firstWhere((p) => p.name == 'Stream Test');
      expect(patient, isNotNull);
    });

    test('pendingSyncCount reflète les opérations en attente', () async {
      final initialCount = await store.pendingSyncCount;
      await store.addPatient(
        name: 'Sync Test',
        age: 30,
        sex: 'F',
        phone: '0600000011',
      );
      final afterCount = await store.pendingSyncCount;
      expect(afterCount, initialCount + 1);
    });
  });

  group('ClinicalStore - Compatibilité interface', () {
    test('DemoStore et PersistentStore partagent la même API ClinicalStore',
        () async {
      final demo = DemoStore();
      final db = AppDatabase.createWithExecutor(NativeDatabase.memory());
      final persistent = PersistentStore(db);
      await persistent.ready;

      expect(demo, isA<ClinicalStore>());
      expect(persistent, isA<ClinicalStore>());

      expect(demo.patients, isA<List<Patient>>());
      expect(demo.visits, isA<List<Visit>>());
      expect(demo.exams, isA<List<LabExam>>());
      expect(demo.followUps, isA<List<FollowUpPlan>>());
      expect(demo.plannedFollowUps, isA<List<FollowUpPlan>>());
      expect(demo.pastFollowUps, isA<List<FollowUpPlan>>());
      expect(demo.followUpsWithoutDate, isA<List<Patient>>());
      expect(demo.followUpPatients, isA<List<Patient>>());
      expect(demo.pendingExams, isA<List<LabExam>>());
      expect(demo.pendingExamsCount, isA<int>());

      expect(persistent.patients, isA<List<Patient>>());
      expect(persistent.visits, isA<List<Visit>>());
      expect(persistent.exams, isA<List<LabExam>>());
      expect(persistent.followUps, isA<List<FollowUpPlan>>());
      expect(persistent.plannedFollowUps, isA<List<FollowUpPlan>>());
      expect(persistent.pastFollowUps, isA<List<FollowUpPlan>>());
      expect(persistent.followUpsWithoutDate, isA<List<Patient>>());
      expect(persistent.followUpPatients, isA<List<Patient>>());
      expect(persistent.pendingExams, isA<List<LabExam>>());
      expect(persistent.pendingExamsCount, isA<int>());

      persistent.dispose();
      await persistent.streamsStopped;
      await db.close();
    });

    test('Méthodes d\'écriture retournent des Future sur les deux implémentations',
        () async {
      final demo = DemoStore();
      final db = AppDatabase.createWithExecutor(NativeDatabase.memory());
      final persistent = PersistentStore(db);
      await persistent.ready;
      // Ajouter un patient pour que le stream émette.
      await persistent.addPatient(
          name: 'Base', age: 1, sex: 'M', phone: '');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(
          demo.addPatient(name: 'A', age: 1, sex: 'M', phone: ''),
          isA<Future<void>>());
      expect(
          persistent.addPatient(name: 'B', age: 1, sex: 'M', phone: ''),
          isA<Future<void>>());

      final demoExamId =
          demo.addExam(patientId: demo.patients.first.id, title: 'Test');
      expect(demoExamId, isA<Future<String>>());
      final persExamId = persistent.addExam(
          patientId: persistent.patients.first.id, title: 'Test');
      expect(persExamId, isA<Future<String>>());

      persistent.dispose();
      await persistent.streamsStopped;
      await db.close();
    });
  });
}
