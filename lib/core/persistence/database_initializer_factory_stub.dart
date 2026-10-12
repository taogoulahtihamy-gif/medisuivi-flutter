/// Factory pour créer l'initialiseur de base de données (web)
/// Ce fichier n'est utilisé que sur le web (dart.library.html)
library;

import 'persistence_types.dart';

DatabaseInitializer createDatabaseInitializer() => WebDatabaseInitializer();