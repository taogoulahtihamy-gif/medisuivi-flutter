/// Stub web pour l'initialisation du store persistant
/// Ce fichier n'est utilisé que sur le web (dart.library.html)
library;

import 'persistent_store_stub.dart';

/// Sur le web, pas de store persistant - utilise la fonction du stub
PersistentStore? createPersistentStore(dynamic db) {
  return null;
}