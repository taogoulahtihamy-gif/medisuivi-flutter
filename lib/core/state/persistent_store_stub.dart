/// Stub web pour PersistentStore - ne contient aucune dépendance native
/// Ce fichier n'est utilisé que sur le web (dart.library.html)
library;

import 'package:flutter/widgets.dart';
import 'package:medisuivi/core/state/demo_store.dart';

/// Stub pour PersistentStore sur le web - utilise DemoStore
class PersistentStore extends DemoStore {
  PersistentStore();
}

/// Stub pour PersistentScope sur le web
class PersistentScope extends InheritedNotifier<PersistentStore> {
  const PersistentScope({
    super.key,
    required PersistentStore store,
    required super.child,
  }) : super(notifier: store);

  static PersistentStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PersistentScope>();
    assert(scope != null, 'PersistentScope not found in context');
    return scope!.notifier!;
  }
}