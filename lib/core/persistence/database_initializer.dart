/// Service d'initialisation de la base de données persistante (interface commune)
library;

import 'package:flutter/foundation.dart' show kIsWeb;

import 'persistence_types.dart';
import 'database_initializer_factory_mobile.dart'
    if (dart.library.html) 'database_initializer_factory_stub.dart';

/// Fournisseur global pour l'initialisation
class DatabaseProvider {
  static final DatabaseInitializer _initializer = createDatabaseInitializer();
  static AppDatabaseInterface? _database;
  static DatabaseInitResult? _lastResult;
  static bool _isInitializing = false;

  /// Initialise la base (appelé au démarrage de l'app)
  static Future<(DatabaseInitResult, AppDatabaseInterface?)> initialize() async {
    if (_isInitializing) {
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return (_lastResult ?? DatabaseInitResult.unavailable, _database);
    }

    _isInitializing = true;
    try {
      final result = await _initializer.initialize();
      _lastResult = result.$1;
      _database = result.$2;
      return result;
    } finally {
      _isInitializing = false;
    }
  }

  /// Récupère la base (doit être initialisée avant)
  static AppDatabaseInterface? get database => _database;

  /// Résultat de la dernière initialisation
  static DatabaseInitResult? get lastResult => _lastResult;

  /// Verrouille la base
  static Future<void> lock() async {
    await _initializer.lock();
    _database = null;
  }

  /// Déverrouille la base
  static Future<(DatabaseInitResult, AppDatabaseInterface?)> unlock() async {
    return _initializer.unlock();
  }

  /// Ferme proprement
  static Future<void> dispose() async {
    await _initializer.close();
    _database = null;
  }

  /// Vérifie si on est sur le web
  static bool get isWeb => kIsWeb;
}