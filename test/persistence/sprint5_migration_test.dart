/// Migration v1 → v2 de MediSuivi : base chiffrée et outbox atomique.
/// Toutes les personnes et constatations de ce test sont fictives.
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/core/models/clinical_intake.dart';
import 'package:medisuivi/core/persistence/clinical_supplement_repository.dart';
import 'package:medisuivi/core/persistence/database.dart' as db;
import 'package:medisuivi/core/state/demo_store.dart';
import 'package:medisuivi/core/state/clinical_store.dart';
import 'test_encryption_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sprint 5B : migration et sauvegarde chiffrée', () {
    late Directory dir;
    late String key;

    Future<db.AppDatabase> open(String name) async {
      final file = File('${dir.path}/$name.db');
      final executor = NativeDatabase.createInBackground(file, setup: (sqlite) {
        if (sqlite.select('PRAGMA cipher;').isEmpty) {
          throw StateError('SQLite3MultipleCiphers indisponible');
        }
        sqlite.execute('PRAGMA key = "x\'$key\'";');
        sqlite.execute('PRAGMA cipher_page_size = 4096;');
        sqlite.execute('PRAGMA kdf_iter = 256000;');
        sqlite.execute('PRAGMA cipher_hmac_algorithm = HMAC_SHA256;');
        sqlite.execute('PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA256;');
        sqlite.execute('PRAGMA journal_mode = WAL;');
        sqlite.execute('PRAGMA synchronous = NORMAL;');
      });
      db.AppDatabase.instanceSetter = db.AppDatabase.createWithExecutor(executor);
      return db.AppDatabase.instance;
    }

    setUpAll(() async {
      dir = Directory.systemTemp.createTempSync('medisuivi_sprint5b_');
      key = await TestEncryptionService().getSqlCipherKey();
    });

    tearDownAll(() async {
      if (dir.existsSync()) await dir.delete(recursive: true);
    });

    test('v1 → v2 conserve patients, visites, bilans, suivis et outbox', () async {
      final initial = await open('migrated');
      await initial.patientDao.createPatient(
        name: 'Aminata Test', age: 36, sex: 'F', phone: '00000000',
      );
      final patient = (await initial.patientDao.getAllPatients()).single;
      await initial.visitDao.createVisit(
        patientId: patient.id, reason: 'Ancienne consultation fictive',
      );
      final previousVisit = (await initial.visitDao.getVisitsForPatient(patient.id)).single;
      await initial.examDao.createExam(
        patientId: patient.id, title: 'Ancien examen fictif',
      );
      await initial.followUpDao.scheduleFollowUp(
        patientId: patient.id,
        scheduledAt: DateTime.utc(2026, 12, 1),
        reason: 'Ancien suivi',
      );
      final pendingBefore =
          (await initial.pendingOperationsDao.getPendingOperations()).length;
      expect(pendingBefore, 4);

      // Fixture physiquement équivalente au schéma Drift v1 :
      // les tables historiques sont inchangées ; aucune table v2 n'existe.
      await initial.customStatement('DROP TABLE patient_supplements');
      await initial.customStatement('DROP TABLE visit_intakes');
      await initial.customStatement(
        "UPDATE app_metadata SET value = '1' WHERE key = 'schema_version'",
      );
      await initial.customStatement('PRAGMA user_version = 1');
      await initial.close();

      final migrated = await open('migrated');
      expect(migrated.schemaVersion, 2);
      expect((await migrated.customSelect('PRAGMA user_version').get())
          .single.read<int>('user_version'), 2);
      expect((await migrated.patientDao.getAllPatients()).single.id, patient.id);
      expect((await migrated.visitDao.getVisitsForPatient(patient.id))
          .single.id, previousVisit.id);
      expect((await migrated.examDao.getExamsForPatient(patient.id)), hasLength(1));
      expect((await migrated.followUpDao.getFollowUpsForPatient(patient.id)), hasLength(1));
      expect((await migrated.pendingOperationsDao.getPendingOperations()), hasLength(4));
      final repo = ClinicalSupplementRepository(migrated);
      expect(await repo.patientProfile(patient.id), isNull);
      expect(await repo.visitIntake(previousVisit.id), isNull);

      await migrated.patientDao.updatePatientInfo(
        patientId: patient.id,
        phone: '00000001',
        allergies: 'Allergie fictive',
        medicalHistory: 'Antécédent fictif',
        profile: const PatientProfileSupplement(
          neighborhood: 'Quartier test',
          emergencyContactName: 'Contact fictif',
        ),
      );
      await migrated.visitDao.createVisit(
        patientId: patient.id,
        reason: 'Consultation complémentaire fictive',
        intake: const ClinicalIntake(
          weightKg: 68.4,
          associatedSigns: 'Signe fictif',
          physicalExamination: 'Examen saisi',
          careDisposition: CareDisposition.outpatient,
        ),
      );
      final visits = await migrated.visitDao.getVisitsForPatient(patient.id);
      final newVisit = visits.singleWhere((v) => v.id != previousVisit.id);
      expect((await repo.patientProfile(patient.id))?.neighborhood, 'Quartier test');
      expect((await repo.visitIntake(newVisit.id))?.weightKg, 68.4);
      final pending = await migrated.pendingOperationsDao.getPendingOperations();
      expect(pending, hasLength(6));
      final profileOp = pending.firstWhere((o) =>
          o.entityType == 'patient' && o.operationType == 'update');
      expect(jsonDecode(profileOp.payload)['profile']['neighborhood'], 'Quartier test');
      final visitOp = pending.lastWhere((o) => o.entityType == 'visit');
      expect(jsonDecode(visitOp.payload)['intake']['weightKg'], 68.4);
      await migrated.close();

      final reopened = await open('migrated');
      final reopenedRepo = ClinicalSupplementRepository(reopened);
      expect((await reopened.patientDao.getAllPatients()).single.id, patient.id);
      expect((await reopened.visitDao.getVisitsForPatient(patient.id)), hasLength(2));
      expect((await reopened.examDao.getExamsForPatient(patient.id)), hasLength(1));
      expect((await reopened.followUpDao.getFollowUpsForPatient(patient.id)), hasLength(1));
      expect((await reopened.pendingOperationsDao.getPendingOperations()), hasLength(6));
      expect((await reopenedRepo.patientProfile(patient.id))?.neighborhood, 'Quartier test');
      expect((await reopenedRepo.visitIntake(newVisit.id))?.associatedSigns, 'Signe fictif');
      await reopened.close();

      // La base chiffrée ne contient ni les noms ni les signes en clair.
      final bytes = File('${dir.path}/migrated.db').readAsBytesSync();
      final raw = String.fromCharCodes(bytes);
      expect(raw, isNot(contains('Aminata Test')));
      expect(raw, isNot(contains('Quartier test')));
      expect(raw, isNot(contains('Signe fictif')));
    });

    test('échec outbox annule profil et consultation sans écriture partielle', () async {
      final database = await open('rollback');
      await database.patientDao.createPatient(
        name: 'Patient test rollback', age: 44, sex: 'M', phone: '100',
      );
      final patient = (await database.patientDao.getAllPatients()).single;
      final initialCount =
          (await database.pendingOperationsDao.getPendingOperations()).length;
      await database.customStatement('''
        CREATE TRIGGER reject_outbox_sprint5
        BEFORE INSERT ON pending_operations
        BEGIN SELECT RAISE(ABORT, 'outbox refused'); END
      ''');

      await expectLater(
        database.patientDao.updatePatientInfo(
          patientId: patient.id,
          phone: '200',
          allergies: 'Aucune fictive',
          medicalHistory: 'Antécédent fictif',
          profile: const PatientProfileSupplement(neighborhood: 'Test rollback'),
        ),
        throwsA(isA<Exception>()),
      );
      expect((await database.patientDao.getPatientById(patient.id))?.phone, '100');
      expect(
        await ClinicalSupplementRepository(database).patientProfile(patient.id),
        isNull,
      );

      await expectLater(
        database.visitDao.createVisit(
          patientId: patient.id,
          reason: 'Visite fictive rejetée',
          intake: const ClinicalIntake(weightKg: 54.0),
        ),
        throwsA(isA<Exception>()),
      );
      expect(await database.visitDao.getVisitsForPatient(patient.id), isEmpty);
      expect((await database.customSelect('SELECT * FROM visit_intakes').get()), isEmpty);
      expect((await database.pendingOperationsDao.getPendingOperations()),
          hasLength(initialCount));
      await database.close();
    });

    test('contrat DemoStore accepte les compléments et refuse les mesures invalides', () async {
      final ClinicalStore store = DemoStore();
      await store.addPatient(
        name: 'Patiente fictive', age: 33, sex: 'F', phone: '100',
        profile: const PatientProfileSupplement(address: 'Adresse test'),
      );
      final patient = store.patients.first;
      expect((await store.patientProfile(patient.id))?.address, 'Adresse test');

      await store.addVisit(
        patientId: patient.id, reason: 'Consultation fictive',
        intake: const ClinicalIntake(weightKg: 65.2),
      );
      final visit = store.visitsFor(patient.id).first;
      expect((await store.visitIntake(visit.id))?.weightKg, 65.2);
      final count = store.visitsFor(patient.id).length;
      await expectLater(
        store.addVisit(
          patientId: patient.id, reason: 'Invalidé',
          intake: const ClinicalIntake(weightKg: -1),
        ),
        throwsArgumentError,
      );
      expect(store.visitsFor(patient.id), hasLength(count));
    });
  });
}
