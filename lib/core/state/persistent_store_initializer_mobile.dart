/// Initialisation mobile du store persistant
/// Ce fichier n'est utilisé que sur mobile (dart.library.io)
library;

import 'package:medisuivi/core/persistence/database.dart';
import 'package:medisuivi/core/persistence/persistence_types.dart';
import 'package:medisuivi/core/state/persistent_store.dart';

/// Crée le PersistentStore depuis une base de données
PersistentStore? createPersistentStore(AppDatabaseInterface? db) {
  if (db == null) return null;
  return PersistentStore(db as AppDatabase);
}