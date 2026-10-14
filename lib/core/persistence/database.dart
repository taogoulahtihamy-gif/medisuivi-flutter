/// Base de données Drift chiffrée avec SQLite3MultipleCiphers.
/// Schéma offline-first compatible avec la synchronisation future.
library;

import 'dart:io';
import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

import 'dao/patient_dao.dart';
import 'dao/visit_dao.dart';
import 'dao/exam_dao.dart';
import 'dao/followup_dao.dart';
import 'dao/pending_operations_dao.dart';
import 'persistence_types.dart';

part 'database.g.dart';

/// Version du schéma de base de données.
/// Incrémenter à chaque migration.
const int _schemaVersion = 2;

/// Tables Drift pour la persistance locale chiffrée.

/// Patients table
class Patients extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get age => integer()();
  TextColumn get sex => text()();
  TextColumn get phone => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get allergies => text().withDefault(const Constant('Non renseignées'))();
  TextColumn get medicalHistory => text().withDefault(const Constant('Non renseignés'))();
  BoolColumn get followUp => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Visites/Consultations table
class Visits extends Table {
  TextColumn get id => text()();
  TextColumn get patientId => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get reason => text()();
  RealColumn get temperature => real().nullable()();
  IntColumn get systolic => integer().nullable()();
  IntColumn get diastolic => integer().nullable()();
  IntColumn get pulse => integer().nullable()();
  IntColumn get spo2 => integer().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Examens/Bilans table
class Exams extends Table {
  TextColumn get id => text()();
  TextColumn get patientId => text()();
  TextColumn get title => text()();
  DateTimeColumn get date => dateTime()();
  IntColumn get status => integer()(); // 0 = pending, 1 = complete
  TextColumn get result => text().nullable()();
  DateTimeColumn get resultRecordedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Suivis/Rendez-vous table
class FollowUps extends Table {
  TextColumn get id => text()();
  TextColumn get patientId => text()();
  DateTimeColumn get scheduledAt => dateTime()();
  TextColumn get reason => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  IntColumn get status => integer().withDefault(const Constant(0))(); // 0 = planned, 1 = completed, 2 = cancelled
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Opérations en attente pour la synchronisation future (offline-first)
class PendingOperations extends Table {
  TextColumn get operationId => text()();
  TextColumn get entityType => text()(); // 'patient', 'visit', 'exam', 'followup'
  TextColumn get entityId => text()();
  TextColumn get operationType => text()(); // 'create', 'update', 'delete'
  TextColumn get payload => text()(); // JSON de l'entité
  IntColumn get baseRevision => integer()();
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get status => integer().withDefault(const Constant(0))(); // 0 = pending, 1 = synced, 2 = failed, 3 = conflict
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {operationId};
}

/// Métadonnées de l'application (version schéma, dernier sync, etc.)
class AppMetadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Base de données principale
@DriftDatabase(
  tables: [
    Patients,
    Visits,
    Exams,
    FollowUps,
    PendingOperations,
    AppMetadata,
  ],
  daos: [
    PatientDao,
    VisitDao,
    ExamDao,
    FollowUpDao,
    PendingOperationsDao,
  ],
)
class AppDatabase extends _$AppDatabase implements AppDatabaseInterface {
  AppDatabase._internal(super.executor);

  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._internal(_openConnection());
  
  /// Permet de définir l'instance depuis l'extérieur (pour openEncryptedDatabase)
  static set instanceSetter(AppDatabase? db) => _instance = db;
  
  /// Crée une instance avec un executor personnalisé (pour tests)
  static AppDatabase createWithExecutor(QueryExecutor executor) {
    return AppDatabase._internal(executor);
  }

  @override
  int get schemaVersion => _schemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _createClinicalSupplementTables();
      // Initialiser les métadonnées
      await into(appMetadata).insert(AppMetadataCompanion(
        key: const Value('schema_version'),
        value: Value(_schemaVersion.toString()),
      ));
      await into(appMetadata).insert(AppMetadataCompanion(
        key: const Value('initialized_at'),
        value: Value(DateTime.now().toIso8601String()),
      ));
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Les migrations seront gérées dans migration/schema_migrations.dart
      await _runMigrations(m, from, to);
    },
    beforeOpen: (details) async {
      // Vérifier l'intégrité de la base à l'ouverture
      await customStatement('PRAGMA quick_check;');
      // Configurer les options de performance SQLite3MultipleCiphers
      await customStatement('PRAGMA cipher_page_size = 4096;');
      await customStatement('PRAGMA journal_mode = WAL;');
      await customStatement('PRAGMA synchronous = NORMAL;');
    },
  );

  /// Tables additives SQLite. Les tables Drift existantes restent en v1.
  /// Ainsi, aucun ancien patient ni ancienne consultation n'est réécrit.
  Future<void> _createClinicalSupplementTables() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS patient_supplements (
        patient_id TEXT NOT NULL PRIMARY KEY,
        payload TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS visit_intakes (
        visit_id TEXT NOT NULL PRIMARY KEY,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  /// Migration additive et atomique ; pas de suppression de dossiers.
  Future<void> _runMigrations(Migrator m, int from, int to) async {
    if (from == 1 && to == 2) {
      await transaction(() async {
        await _createClinicalSupplementTables();
        await (update(appMetadata)..where((row) => row.key.equals('schema_version')))
            .write(const AppMetadataCompanion(value: Value('2')));
      });
      return;
    }
    throw StateError('Migration SQLite non prise en charge : $from → $to');
  }

  /// Ferme la base de données
  @override
  Future<void> close() async {
    _instance = null;
    await super.close();
  }
}

/// Vérifie que SQLite3MultipleCiphers est disponible (chiffrement activé)
bool _debugCheckHasCipher(Database db) {
  final result = db.select('PRAGMA cipher;');
  return result.isNotEmpty;
}

/// Ouvre la connexion à la base de données (sans chiffrement - pour initialisation/migration)
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File('${dbFolder.path}/medisuivi.db');

    return NativeDatabase.createInBackground(file);
  });
}

/// Fabrique pour ouvrir la base avec une clé de chiffrement
Future<AppDatabase> openEncryptedDatabase(
  String encryptionKey, {File? databaseFile}
) async {
  // SQL never receives an arbitrary interpolated value for PRAGMA key.
  if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(encryptionKey)) {
    throw ArgumentError('Invalid SQLCipher encryption key');
  }
  // Keep legacy medisuivi.db unchanged. Only new vaults pass another file.
  final file = databaseFile ?? File(
    '${(await getApplicationDocumentsDirectory()).path}/medisuivi.db');

  final executor = NativeDatabase.createInBackground(
    file,
    setup: (db) {
      // Vérifier que le chiffrement est disponible (debug only)
      assert(_debugCheckHasCipher(db), 'SQLite3MultipleCiphers non disponible - vérifiez les build hooks');
      
      // Appliquer la clé de chiffrement
      // La clé est déjà dérivée (64 caractères hex) par EncryptionService
      // Syntaxe SQLite3MultipleCiphers: PRAGMA key = "x'hex_key'"
      db.execute('PRAGMA key = "x\'$encryptionKey\'";');
      db.execute('PRAGMA cipher_page_size = 4096;');
      db.execute('PRAGMA kdf_iter = 256000;');
      db.execute('PRAGMA cipher_hmac_algorithm = HMAC_SHA256;');
      db.execute('PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA256;');
      db.execute('PRAGMA journal_mode = WAL;');
      db.execute('PRAGMA synchronous = NORMAL;');
    },
  );

  AppDatabase.instanceSetter = AppDatabase._internal(executor);
  return AppDatabase.instance;
}

/// Génère un nouvel UUID v4
String generateId() => const Uuid().v4();

/// Vérifie si la base de données existe et est accessible
Future<bool> databaseExists() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File('${dbFolder.path}/medisuivi.db');
  return file.existsSync();
}

/// Supprime la base de données (pour reset complet)
Future<void> deleteDatabase() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File('${dbFolder.path}/medisuivi.db');
  if (file.existsSync()) {
    await file.delete();
  }
  // Supprimer aussi les fichiers WAL/SHM
  final walFile = File('${dbFolder.path}/medisuivi.db-wal');
  final shmFile = File('${dbFolder.path}/medisuivi.db-shm');
  if (walFile.existsSync()) await walFile.delete();
  if (shmFile.existsSync()) await shmFile.delete();
}