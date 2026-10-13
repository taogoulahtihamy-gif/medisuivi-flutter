/// Types et interfaces partagés pour la persistance (sans dépendances platform-spécifiques)
library;

/// Résultat de l'initialisation de la base
enum DatabaseInitResult {
  success,
  wrongKey,
  authenticationRequired,
  corruption,
  unavailable,
  notSupported,
}

/// Interface abstraite pour la base de données (implémentée par Drift sur mobile)
abstract class AppDatabaseInterface {
  /// Ferme la base de données
  Future<void> close();
}

/// Service d'initialisation de la base de données persistante
abstract class DatabaseInitializer {
  /// Initialise la base de données
  Future<(DatabaseInitResult, AppDatabaseInterface?)> initialize();

  /// Récupère la base initialisée
  AppDatabaseInterface? get database;

  /// Ferme la base proprement
  Future<void> close();

  /// Verrouille la base
  Future<void> lock();

  /// Déverrouille et rouvre la base
  Future<(DatabaseInitResult, AppDatabaseInterface?)> unlock();
}

/// Implémentation par défaut (web) - retourne notSupported
class WebDatabaseInitializer implements DatabaseInitializer {
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