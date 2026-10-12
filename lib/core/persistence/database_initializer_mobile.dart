/// Implémentation mobile de l'initialisation de la base de données
library;

import 'package:flutter/services.dart';
import 'package:sqlite3/sqlite3.dart';

import 'database.dart';
import 'persistence_types.dart';
import 'encryption/encryption_service.dart';
import 'encryption/key_manager.dart';

/// Implémentation mobile de l'initialisation de la base de données
class DatabaseInitializerMobile implements DatabaseInitializer {
  final EncryptionService _encryptionService;
  final KeyManager _keyManager;
  AppDatabase? _database;

  DatabaseInitializerMobile({
    EncryptionService? encryptionService,
    KeyManager? keyManager,
  })  : _encryptionService = encryptionService ?? EncryptionService(),
        _keyManager = keyManager ?? KeyManager(encryptionService: encryptionService);

  @override
  Future<(DatabaseInitResult, AppDatabaseInterface?)> initialize() async {
    try {
      // Vérifier la disponibilité du stockage sécurisé
      final storageAvailable = await _encryptionService.isSecureStorageAvailable();
      if (!storageAvailable) {
        return (DatabaseInitResult.unavailable, null);
      }

      // Vérifier si SQLite3MultipleCiphers est disponible
      final hasCipher = await _checkCipherSupport();
      if (!hasCipher) {
        return (DatabaseInitResult.unavailable, null);
      }

      // Déverrouiller et obtenir la clé
      final encryptionKey = await _keyManager.unlockDatabase();
      if (encryptionKey == null) {
        return (DatabaseInitResult.wrongKey, null);
      }

      // Ouvrir la base chiffrée
      _database = await openEncryptedDatabase(encryptionKey);
      
      // Vérifier l'intégrité
      await _database!.customStatement('PRAGMA quick_check;');
      
      return (DatabaseInitResult.success, _database!);
    } on PlatformException {
      return (DatabaseInitResult.unavailable, null);
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('unrecognized token') || 
          errorStr.contains('key') ||
          errorStr.contains('cipher')) {
        return (DatabaseInitResult.wrongKey, null);
      }
      if (errorStr.contains('corrupt') ||
          errorStr.contains('malformed')) {
        return (DatabaseInitResult.corruption, null);
      }
      return (DatabaseInitResult.unavailable, null);
    }
  }

  Future<bool> _checkCipherSupport() async {
    try {
      final db = sqlite3.openInMemory();
      final result = db.select('PRAGMA cipher;');
      db.close();
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  AppDatabaseInterface? get database => _database;

  @override
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _keyManager.lockDatabase();
  }

  @override
  Future<void> lock() async {
    await _keyManager.lockDatabase();
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  @override
  Future<(DatabaseInitResult, AppDatabaseInterface?)> unlock() async {
    await close();
    return initialize();
  }
}