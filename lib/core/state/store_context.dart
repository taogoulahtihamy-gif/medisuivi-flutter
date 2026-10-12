/// Accès unifié au store actif (démo Web ou persistant mobile).
///
/// Les deux implémentations exposent la même API publique
/// synchrone. Cet extension permet aux écrans d'accéder au
/// store via `context.store` sans connaître l'implémentation.
library;

import 'package:flutter/widgets.dart';

import 'demo_store.dart';
import 'persistent_store_stub.dart'
    if (dart.library.io) 'persistent_store.dart';

extension StoreContext on BuildContext {
  /// Store actif : [DemoStore] en mode démonstration/Web,
  /// [PersistentStore] sur mobile.
  ///
  /// L'API publique est identique sur les deux implémentations
  /// (patients, visits, exams, followUps et méthodes métier).
  dynamic get store {
    // dependOnInheritedWidgetOfExactType enregistre la dépendance.
    // Les écrans sont donc reconstruits lors des notifications du store,
    // y compris après une écriture asynchrone Drift.
    final demoScope = dependOnInheritedWidgetOfExactType<DemoScope>();
    if (demoScope != null) return demoScope.notifier!;
    final persistentScope = dependOnInheritedWidgetOfExactType<PersistentScope>();
    if (persistentScope != null) return persistentScope.notifier!;
    throw StateError(
      'Aucun store disponible dans le contexte. '
      'Vérifiez que DemoScope ou PersistentScope enveloppe MaterialApp.',
    );

  }
}