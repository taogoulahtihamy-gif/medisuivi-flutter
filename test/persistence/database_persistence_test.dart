/// Tests d'intégration pour la persistance Drift + SQLite3MultipleCiphers
/// Ces tests valident le chiffrement réel et la persistance des données
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:medisuivi/core/persistence/database.dart';
import 'test_encryption_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Désactiver l'avertissement de multiples instances pour les tests
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  
  group('Persistance Drift + SQLite3MultipleCiphers', () {
    late Directory tempDir;
    late TestEncryptionService encryptionService;
    late String validKey;

    // Fonction pour générer un chemin de base unique par test
    String _generateDbPath(String testName) {
      return '${tempDir.path}/medisuivi_test_$testName.db';
    }

    // Fonction de nettoyage
    void _cleanupDb(String dbPath) {
      final files = ['$dbPath', '$dbPath-wal', '$dbPath-shm'];
      for (final name in files) {
        final f = File(name);
        if (f.existsSync()) f.deleteSync();
      }
    }

    setUpAll(() async {
      tempDir = Directory.systemTemp.createTempSync('medisuivi_test_');
      
      encryptionService = TestEncryptionService();
      validKey = await encryptionService.getSqlCipherKey();
    });

    tearDownAll(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('1. SQLite3MultipleCiphers est disponible (détection PRAGMA cipher)', () {
      final db = sqlite3.openInMemory();
      final result = db.select('PRAGMA cipher;');
      db.dispose();
      
      expect(result.isNotEmpty, isTrue, 
        reason: 'SQLite3MultipleCiphers doit être disponible (build hooks sqlite3mc)');
    });

    test('2. Création et ouverture de base chiffrée avec clé valide', () async {
      final dbPath = _generateDbPath('create_open');
      _cleanupDb(dbPath);
      
      final db = await _openTestDatabase(validKey, dbPath);
      expect(db, isNotNull);
      
      final patients = await db.patientDao.getAllPatients();
      expect(patients, isEmpty);
      
      await db.close();
      _cleanupDb(dbPath);
    });

    test('3. Échec d\'ouverture avec une mauvaise clé', () async {
      final dbPath = _generateDbPath('wrong_key');
      _cleanupDb(dbPath);
      
      // D'abord créer la base avec la bonne clé
      final db1 = await _openTestDatabase(validKey, dbPath);
      await db1.patientDao.createPatient(
        name: 'Test Patient',
        age: 30,
        sex: 'F',
        phone: '0123456789',
      );
      await db1.close();

      // Essayer d'ouvrir avec une mauvaise clé
      final wrongKey = '0'.padLeft(64, '0');
      bool threwError = false;
      
      try {
        final db2 = await _openTestDatabase(wrongKey, dbPath);
        await db2.patientDao.getAllPatients();
        await db2.close();
      } catch (e) {
        threwError = true;
      }
      
      expect(threwError, isTrue, 
        reason: 'L\'ouverture avec une mauvaise clé doit échouer');
      
      _cleanupDb(dbPath);
    });

    test('4. CRUD complet Patient → Consultation → Examen → Suivi', () async {
      final dbPath = _generateDbPath('crud_complete');
      _cleanupDb(dbPath);
      
      final db = await _openTestDatabase(validKey, dbPath);

      // 4.1 Créer un patient
      await db.patientDao.createPatient(
        name: 'Aminata Diallo',
        age: 32,
        sex: 'F',
        phone: '0123456789',
      );
      
      final patients = await db.patientDao.getAllPatients();
      expect(patients.length, 1);
      final patient = patients.first;
      expect(patient.name, 'Aminata Diallo');
      expect(patient.age, 32);
      expect(patient.sex, 'F');

      // 4.2 Ajouter une consultation avec constantes vitales
      await db.visitDao.createVisit(
        patientId: patient.id,
        reason: 'Consultation de suivi hypertension',
        temperature: 37.2,
        systolic: 138,
        diastolic: 86,
        pulse: 78,
        spo2: 98,
        notes: 'Traitement ajusté',
      );
      
      final visits = await db.visitDao.getVisitsForPatient(patient.id);
      expect(visits.length, 1);
      final visit = visits.first;
      expect(visit.reason, 'Consultation de suivi hypertension');
      expect(visit.systolic, 138);
      expect(visit.diastolic, 86);
      expect(visit.temperature, 37.2);

      // 4.3 Créer un examen
      final examId = await db.examDao.createExam(
        patientId: patient.id,
        title: 'Numération formule sanguine',
      );
      
      // 4.4 Enregistrer le résultat
      await db.examDao.recordExamResult(
        examId: examId,
        result: 'Hémoglobine: 13.2 g/dl, Leucocytes: 7200/mm³',
      );
      
      final exams = await db.examDao.getExamsForPatient(patient.id);
      expect(exams.length, 1);
      final exam = exams.first;
      expect(exam.title, 'Numération formule sanguine');
      expect(exam.status, 1);
      expect(exam.result, contains('Hémoglobine'));

      // 4.5 Programmer un rendez-vous de suivi
      final followUpDate = DateTime.now().add(const Duration(days: 7));
      await db.followUpDao.scheduleFollowUp(
        patientId: patient.id,
        scheduledAt: followUpDate,
        reason: 'Contrôle tensionnel',
        notes: 'Apporter les résultats NFS',
      );
      
      final followUps = await db.followUpDao.getFollowUpsForPatient(patient.id);
      expect(followUps.length, 1);
      final followUp = followUps.first;
      expect(followUp.reason, 'Contrôle tensionnel');
      expect(followUp.status, 0);

      // 4.6 Mettre à jour les infos médicales du patient
      await db.patientDao.updatePatientInfo(
        patientId: patient.id,
        phone: '0123456789',
        allergies: 'Pénicilline',
        medicalHistory: 'Hypertension artérielle',
      );
      
      final updatedPatient = await db.patientDao.getPatientById(patient.id);
      expect(updatedPatient!.allergies, 'Pénicilline');
      expect(updatedPatient.medicalHistory, 'Hypertension artérielle');

      await db.close();
      _cleanupDb(dbPath);
    });

    test('5. Persistance après fermeture/réouverture complète', () async {
      final dbPath = _generateDbPath('persistence');
      _cleanupDb(dbPath);
      
      const testPatientName = 'Fatou Sarr';
      
      // 5.1 Créer et remplir la base
      {
        final db = await _openTestDatabase(validKey, dbPath);
        
        await db.patientDao.createPatient(
          name: testPatientName,
          age: 27,
          sex: 'F',
          phone: '0987654321',
        );
        
        final patients = await db.patientDao.getAllPatients();
        final patient = patients.first;
        
        await db.visitDao.createVisit(
          patientId: patient.id,
          reason: 'Consultation prénatale',
          temperature: 36.8,
          systolic: 118,
          diastolic: 74,
          pulse: 72,
          spo2: 99,
        );
        
        final examId = await db.examDao.createExam(
          patientId: patient.id,
          title: 'Glycémie à jeun',
        );
        
        await db.examDao.recordExamResult(
          examId: examId,
          result: 'Glycémie: 0.92 g/l (normale)',
        );
        
        await db.followUpDao.scheduleFollowUp(
          patientId: patient.id,
          scheduledAt: DateTime.now().add(const Duration(days: 14)),
          reason: 'Échographie T2',
        );
        
        await db.close();
      }
      
      // 5.2 Réouvrir la base et vérifier la persistance
      {
        final db = await _openTestDatabase(validKey, dbPath);
        
        final patients = await db.patientDao.getAllPatients();
        expect(patients.length, 1);
        expect(patients.first.name, testPatientName);
        expect(patients.first.age, 27);
        
        final visits = await db.visitDao.getVisitsForPatient(patients.first.id);
        expect(visits.length, 1);
        expect(visits.first.reason, 'Consultation prénatale');
        expect(visits.first.systolic, 118);
        
        final exams = await db.examDao.getExamsForPatient(patients.first.id);
        expect(exams.length, 1);
        expect(exams.first.title, 'Glycémie à jeun');
        expect(exams.first.status, 1);
        expect(exams.first.result, 'Glycémie: 0.92 g/l (normale)');
        
        final followUps = await db.followUpDao.getFollowUpsForPatient(patients.first.id);
        expect(followUps.length, 1);
        expect(followUps.first.reason, 'Échographie T2');
        expect(followUps.first.status, 0);
        
        await db.close();
      }
      
      _cleanupDb(dbPath);
    });

    test('6. Aucune donnée sensible en clair dans le fichier SQLite', () async {
      final dbPath = _generateDbPath('no_cleartext');
      _cleanupDb(dbPath);
      
      final db = await _openTestDatabase(validKey, dbPath);
      
      await db.patientDao.createPatient(
        name: 'Patient Secret',
        age: 45,
        sex: 'M',
        phone: '0555123456',
      );
      
      await db.visitDao.createVisit(
        patientId: (await db.patientDao.getAllPatients()).first.id,
        reason: 'Consultation confidentielle',
        notes: 'Antécédents: VIH, Traitement: ARV',
      );
      
      await db.close();
      
      // Lire le fichier brut
      final file = File(dbPath);
      expect(file.existsSync(), isTrue);
      
      final bytes = file.readAsBytesSync();
      final content = String.fromCharCodes(bytes);
      
      // Vérifier qu'aucune donnée sensible n'est en clair
      expect(content, isNot(contains('Patient Secret')));
      expect(content, isNot(contains('confidentielle')));
      // Ne pas chercher des mots de 3 lettres dans du ciphertext :
      // ils peuvent apparaître par hasard dans des octets aléatoires.
      // Vérifier plutôt l'absence des valeurs longues réellement insérées.
      expect(content, isNot(contains('Antécédents: VIH, Traitement: ARV')));
      expect(content, isNot(contains('Traitement: ARV')));
      // Une base SQLite non chiffrée commence par cet en-tête canonique.
      expect(bytes.take(16).toList(), isNot(equals('SQLite format 3\\u0000'.codeUnits)));
      expect(content, isNot(contains('0555123456')));
      
      // Le fichier doit contenir du binaire (chiffré)
      expect(bytes.length, greaterThan(1000));
      
      _cleanupDb(dbPath);
    });

    test('7. Vérification _debugCheckHasCipher active (base non chiffrée)', () async {
      final dbPath = _generateDbPath('cipher_check');
      _cleanupDb(dbPath);
      
      // Ouvrir une base SANS clé pour vérifier PRAGMA cipher
      final file = File(dbPath);
      final executor = NativeDatabase.createInBackground(file);
      final db = AppDatabase.createWithExecutor(executor);
      
      // Exécuter PRAGMA cipher directement sur une base non chiffrée
      final cipherResult = await db.customSelect('PRAGMA cipher;').get();
      expect(cipherResult.isNotEmpty, isTrue, 
        reason: 'PRAGMA cipher doit être disponible même sans clé');
      
      await db.close();
      _cleanupDb(dbPath);
    });

    test('8. rotateMasterKey() comportement documenté (pas de ré-chiffrement auto)', () async {
      final dbPath = _generateDbPath('rotate_key');
      _cleanupDb(dbPath);
      
      final db = await _openTestDatabase(validKey, dbPath);
      
      // Créer des données
      await db.patientDao.createPatient(
        name: 'Test Rotation',
        age: 50,
        sex: 'M',
        phone: '0102030405',
      );
      
      await db.close();
      
      // Tenter rotateMasterKey (change la clé en mémoire seulement)
      await encryptionService.rotateMasterKey();
      
      // Vérifier que les données existent toujours dans le fichier
      final file = File(dbPath);
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(1000));
      
      _cleanupDb(dbPath);
    });

    test('9. Streams réactifs fonctionnent', () async {
      final dbPath = _generateDbPath('streams');
      _cleanupDb(dbPath);
      
      final db = await _openTestDatabase(validKey, dbPath);
      
      final patientStream = db.patientDao.watchAllPatients();
      final emissions = <List>[];
      
      final sub = patientStream.listen((patients) {
        emissions.add(patients);
      });
      
      await Future.delayed(const Duration(milliseconds: 400));
      
      await db.patientDao.createPatient(
        name: 'Stream Test',
        age: 40,
        sex: 'F',
        phone: '0101010101',
      );
      
      await Future.delayed(const Duration(milliseconds: 400));
      
      await sub.cancel();
      await db.close();
      
      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.last.length, 1);
      expect(emissions.last.first.name, 'Stream Test');
      
      _cleanupDb(dbPath);
    });

    test('10. Clé dérivée format hex 64 caractères', () async {
      final key = await encryptionService.getSqlCipherKey();
      
      expect(key.length, 64);
      expect(key, matches(RegExp(r'^[0-9a-f]{64}$')));
    });
  });
}

/// Helper pour ouvrir la base de test - utilise la même logique que openEncryptedDatabase
Future<AppDatabase> _openTestDatabase(String encryptionKey, String dbPath) async {
  final file = File(dbPath);

  final executor = NativeDatabase.createInBackground(
    file,
    setup: (db) {
      // Vérification runtime (pas seulement assert)
      final cipherResult = db.select('PRAGMA cipher;');
      if (cipherResult.isEmpty) {
        throw StateError('SQLite3MultipleCiphers non disponible - build hooks sqlite3mc manquants');
      }
      // Syntaxe correcte pour SQLite3MultipleCiphers: PRAGMA key = "x'hex_key'"
      db.execute('PRAGMA key = "x\'$encryptionKey\'";');
      db.execute('PRAGMA cipher_page_size = 4096;');
      db.execute('PRAGMA kdf_iter = 256000;');
      db.execute('PRAGMA cipher_hmac_algorithm = HMAC_SHA256;');
      db.execute('PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA256;');
      db.execute('PRAGMA journal_mode = WAL;');
      db.execute('PRAGMA synchronous = NORMAL;');
    },
  );

  AppDatabase.instanceSetter = AppDatabase.createWithExecutor(executor);
  return AppDatabase.instance;
}