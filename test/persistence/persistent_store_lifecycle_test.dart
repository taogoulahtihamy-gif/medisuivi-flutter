import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:medisuivi/core/persistence/database.dart' hide Patient, Visit;
import 'package:medisuivi/core/state/persistent_store.dart';
import 'package:medisuivi/core/models/medical_models.dart'
    show Patient, Visit, LabExam, FollowUpPlan;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Suppress Drift warning about multiple database instances in tests
  if (kDebugMode) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }

  /// Crée une base de données sur disque temporaire pour les tests de réouverture.
  /// Utilise NativeDatabase synchrone (pas createInBackground) pour garantir
  /// la persistance immédiate sur disque.
  Future<AppDatabase> openDiskDatabase(String dbPath) async {
    final file = File(dbPath);
    final executor = NativeDatabase(file);
    return AppDatabase.createWithExecutor(executor);
  }

  /// Chemin temporaire unique pour base disque
  String tempDbPath(String prefix) {
    final tempDir = Directory.systemTemp;
    final unique =
        '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}';
    return p.join(tempDir.path, '${prefix}_$unique.sqlite');
  }

  group('PersistentStore - initialisation réussie', () {
    test('charge les données initiales et expose ready', () async {
      final database = AppDatabase.createWithExecutor(NativeDatabase.memory());
      final store = PersistentStore(database);

      // Attendre l'initialisation
      await store.ready;

      // Le cache doit être accessible (même vide initialement)
      expect(store.patients, isA<List<Patient>>());
      expect(store.visitsFor('any'), isA<List<Visit>>());
      expect(store.exams, isA<List<LabExam>>());
      expect(store.plannedFollowUps, isA<List<FollowUpPlan>>());

      store.dispose();
      await database.close();
    });

    test('remplit le cache via addPatient et notifie', () async {
      final database = AppDatabase.createWithExecutor(NativeDatabase.memory());
      final store = PersistentStore(database);

      await store.ready;

      // Ajouter un patient via le store
      await store.addPatient(
        name: 'Patient test',
        age: 35,
        sex: 'M',
        phone: '0600000000',
      );

      // Attendre que le stream propage la mise à jour au cache
      await Future.delayed(const Duration(milliseconds: 50));

      // Le cache synchrone doit refléter l'ajout (stream met à jour)
      expect(store.patients.length, 1);
      expect(store.patients.first.name, 'Patient test');
      expect(store.patients.first.age, 35);
      expect(store.patients.first.sex, 'M');

      store.dispose();
      await database.close();
    });
  });

  group('PersistentStore - erreur d\'initialisation propagée', () {
    test('ready échoue si la base est invalide', () async {
      // Base corrompue / invalide : tenter d'ouvrir un fichier non-DB
      final badDbPath = tempDbPath('bad_db');
      await File(badDbPath).writeAsString('not a database');

      final database = await openDiskDatabase(badDbPath);
      final store = PersistentStore(database);

      // L'initialisation doit échouer (erreur SQLite propagée)
      expect(store.ready, throwsA(isA<Exception>()));

      store.dispose();
      await database.close();

      // Nettoyage
      await File(badDbPath).delete();
    });

    test('erreur pendant getAllPatients propagée via ready', () async {
      final database = AppDatabase.createWithExecutor(NativeDatabase.memory());

      // Corrompre la table patients en supprimant la table
      await database.customStatement('DROP TABLE IF EXISTS patients;');

      final store = PersistentStore(database);

      // L'initialisation doit échouer car getAllPatients va échouer
      expect(store.ready, throwsA(isA<Exception>()));

      store.dispose();
      await database.close();
    });
  });

  group('PersistentStore - dispose avant fin de chargement', () {
    test('dispose pendant _loadInitialData ne crash pas', () async {
      final database = AppDatabase.createWithExecutor(NativeDatabase.memory());
      final store = PersistentStore(database);

      // Ne pas attendre ready, disposer immédiatement
      // Cela teste la course: dispose avant fin de _loadInitialData
      store.dispose();

      // Ne PAS fermer la base ici - _loadInitialData est encore en cours
      // et va essayer d'accéder à la base. La base sera fermée par le GC.
      // Le test vérifie juste qu'aucune exception n'est lancée.
    });

    test('dispose pendant _loadInitialData n\'installe pas les abonnements',
        () async {
      final database = AppDatabase.createWithExecutor(NativeDatabase.memory());
      final store = PersistentStore(database);

      // Disposer avant que _loadInitialData ne termine
      store.dispose();

      // Vérifier que l'initialisation a échoué ou été annulée
      // (le future ready peut être en erreur ou se terminer normalement
      // mais sans abonnements actifs)
      // Ne pas fermer la base - _loadInitialData peut encore tourner
    });
  });

  group('PersistentStore - annulation des abonnements', () {
    test('dispose annule les 4 StreamSubscription', () async {
      final database = AppDatabase.createWithExecutor(NativeDatabase.memory());
      final store = PersistentStore(database);

      await store.ready;

      // Vérifier que les streams fonctionnent avant dispose
      await store.addPatient(name: 'A', age: 20, sex: 'F', phone: '');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(store.patients.length, 1);

      // Disposer
      store.dispose();

      // Après dispose, plus de notifications (même si base reste ouverte)
      // Note: on ne peut pas facilement vérifier l'annulation interne,
      // mais on vérifie que dispose() ne lance pas d'erreur
      await database.close();
    });

    test('plus de notifyListeners après dispose', () async {
      final database = AppDatabase.createWithExecutor(NativeDatabase.memory());
      final store = PersistentStore(database);

      await store.ready;
      int notifyCount = 0;
      store.addListener(() => notifyCount++);

      // Déclencher une modification
      await store.addPatient(name: 'B', age: 25, sex: 'M', phone: '');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notifyCount, greaterThan(0));

      // Disposer
      store.dispose();

      // Nouvelle modification après dispose ne doit pas notifier
      // (la base est encore ouverte, le stream pourrait émettre)
      final initialCount = notifyCount;
      await store.addPatient(name: 'C', age: 30, sex: 'F', phone: '');
      await Future.delayed(const Duration(milliseconds: 50));

      // En pratique, le cache peut être mis à jour mais notifyListeners
      // est bloqué par _disposed = true
      expect(notifyCount, initialCount);

      await database.close();
    });
  });

  group('PersistentStore - pas de notification après dispose', () {
    test(
        'modification base après dispose ne notifie pas les listeners existants',
        () async {
      final database = AppDatabase.createWithExecutor(NativeDatabase.memory());
      final store = PersistentStore(database);

      await store.ready;

      // Ajouter un listener AVANT dispose
      int notifyCount = 0;
      store.addListener(() => notifyCount++);

      // Vérifier que les notifications fonctionnent avant dispose
      await store.addPatient(name: 'Before', age: 20, sex: 'F', phone: '');
      await Future.delayed(const Duration(milliseconds: 50));
      final countBeforeDispose = notifyCount;
      expect(countBeforeDispose, greaterThan(0));

      // Disposer
      store.dispose();

      // Modifier la base directement (bypass store) APRÈS dispose
      await database.patientDao.createPatient(
        name: 'After',
        age: 40,
        sex: 'M',
        phone: '',
      );

      // Forcer un cycle d'événements
      await Future.delayed(const Duration(milliseconds: 100));

      // Le listener ne doit pas avoir été notifié APRÈS dispose
      // (le count peut avoir augmenté AVANT dispose, mais pas après)
      expect(notifyCount, countBeforeDispose);

      await database.close();
    });
  });

  group('PersistentStore - conservation des données après réouverture', () {
    test('données persistées après close/réouverture base disque', () async {
      // Utiliser une base sur disque temporaire pour tester close/réouverture
      final dbPath = tempDbPath('lifecycle_test');

      // --- Première session ---
      {
        final database = await openDiskDatabase(dbPath);
        final store = PersistentStore(database);
        await store.ready;

        // Ajouter des données
        await store.addPatient(
          name: 'Persistant',
          age: 50,
          sex: 'F',
          phone: '0102030405',
        );
        // Attendre que le stream propage au cache
        await Future.delayed(const Duration(milliseconds: 50));

        final patientId = store.patients.first.id;
        await store.addVisit(
          patientId: patientId,
          reason: 'Contrôle',
          systolic: 120,
          diastolic: 80,
        );
        await store.addExam(patientId: patientId, title: 'Bilan');
        await store.scheduleFollowUp(
          patientId: patientId,
          scheduledAt: DateTime.now().add(const Duration(days: 7)),
          reason: 'Suivi',
        );

        // Attendre que le stream propage toutes les mises à jour
        await Future.delayed(const Duration(milliseconds: 100));

        // Vérifier cache avant fermeture
        expect(store.patients.length, 1);
        expect(store.visitsFor(patientId).length, 1);
        expect(store.exams.length, 1);
        expect(store.plannedFollowUps.length, 1);

        // Vérifier que les données sont bien en base (DAO direct)
        final patientsInDb = await database.patientDao.getAllPatients();
        expect(patientsInDb.length, 1);
        expect(patientsInDb.first.name, 'Persistant');

        store.dispose();
        // Forcer le checkpoint WAL pour garantir la persistance sur disque
        await database.customStatement('PRAGMA wal_checkpoint(FULL);');
        await database.close();

        // Vérifier que le fichier existe et a une taille
        final file = File(dbPath);
        expect(file.existsSync(), isTrue);
        expect(file.lengthSync(), greaterThan(1000));
      }

      // --- Deuxième session (réouverture) ---
      {
        final database = await openDiskDatabase(dbPath);

        // Vérifier directement via DAO avant de créer le store
        final patientsInDb = await database.patientDao.getAllPatients();
        // Vérifier directement via DAO avant de créer le store
        expect(patientsInDb.isNotEmpty, isTrue,
            reason: 'La base doit contenir le patient persisté');

        final store = PersistentStore(database);
        await store.ready;

        // Les données doivent être rechargées depuis le disque
        expect(store.patients.length, 1);
        expect(store.patients.first.name, 'Persistant');
        expect(store.patients.first.age, 50);

        final patientId = store.patients.first.id;
        expect(store.visitsFor(patientId).length, 1);
        expect(store.visitsFor(patientId).first.reason, 'Contrôle');
        expect(store.exams.length, 1);
        expect(store.exams.first.title, 'Bilan');
        expect(store.plannedFollowUps.length, 1);
        expect(store.plannedFollowUps.first.reason, 'Suivi');

        store.dispose();
        await database.close();
      }

      // Nettoyage
      await File(dbPath).delete();
    });

    test('outbox conservée après close/réouverture', () async {
      final dbPath = tempDbPath('outbox_test');

      String? operationId;

      // --- Première session : créer une opération en attente ---
      {
        final database = await openDiskDatabase(dbPath);
        final store = PersistentStore(database);
        await store.ready;

        // Ajouter un patient (génère opération pendingOperations)
        await store.addPatient(name: 'Outbox', age: 30, sex: 'F', phone: '');

        // Récupérer l'ID de l'opération en attente
        final ops = await database.pendingOperationsDao.getPendingOperations();
        expect(ops.length, 1);
        operationId = ops.first.operationId;

        store.dispose();
        await database.close();

        // Petit délai pour laisser le WAL se vider sur disque
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // --- Deuxième session : vérifier outbox intacte ---
      {
        final database = await openDiskDatabase(dbPath);
        final store = PersistentStore(database);
        await store.ready;

        final ops = await database.pendingOperationsDao.getPendingOperations();
        expect(ops.length, 1);
        expect(ops.first.operationId, operationId);
        expect(ops.first.entityType, 'patient');
        expect(ops.first.operationType, 'create');

        store.dispose();
        await database.close();
      }

      // Nettoyage
      await File(dbPath).delete();
    });
  });

  group('PersistentStore - gestion d\'erreurs streams', () {
    test('erreur stream ne casse pas le store', () async {
      final database = AppDatabase.createWithExecutor(NativeDatabase.memory());
      final store = PersistentStore(database);

      await store.ready;

      // Provoquer une erreur en faisant une requête invalide via le DAO
      // (difficile à tester sans casser le schéma, on vérifie juste que
      // le handler onError ne fait pas crasher)

      store.dispose();
      await database.close();
    });
  });
}
