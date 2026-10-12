/// Stub web pour l'initialisation de la base de données
/// Ce fichier n'est utilisé que sur le web (dart.library.html)
library;

import 'persistence_types.dart';

/// Implémentation web de DatabaseInitializer - retourne notSupported
class DatabaseInitializerMobile implements DatabaseInitializer {
  @override
  Future<(DatabaseInitResult, AppDatabaseInterface?)> initialize() async {
    return (DatabaseInitResult.notSupported, null);
  }

  @override
  AppDatabaseInterface? get database => null;

  @override
  Future<void> close() async {}

  @override
  Future<void> lock() async {}

  @override
  Future<(DatabaseInitResult, AppDatabaseInterface?)> unlock() async {
    return (DatabaseInitResult.notSupported, null);
  }
}