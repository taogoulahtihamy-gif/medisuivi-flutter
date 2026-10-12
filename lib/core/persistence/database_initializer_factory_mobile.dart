/// Factory pour créer l'initialiseur de base de données (mobile)
/// Ce fichier n'est utilisé que sur mobile (dart.library.io)
library;

import 'persistence_types.dart';
import 'database_initializer_mobile.dart';

DatabaseInitializer createDatabaseInitializer() => DatabaseInitializerMobile();