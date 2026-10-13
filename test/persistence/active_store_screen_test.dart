import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/core/persistence/database.dart';
import 'package:medisuivi/core/state/persistent_store.dart';
import 'package:medisuivi/features/patients/patients_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Les écrans patients lisent et mettent à jour PersistentScope',
      (tester) async {
    late final AppDatabase database;
    late final PersistentStore store;

    // Drift utilise des opérations asynchrones réelles.
    await tester.runAsync(() async {
      database = AppDatabase.createWithExecutor(NativeDatabase.memory());
      store = PersistentStore(database);
      await store.ready;
    });

    try {
      await tester.pumpWidget(PersistentScope(
        store: store,
        child: const MaterialApp(home: Scaffold(body: PatientsScreen())),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Mes patients'), findsOneWidget);

      // La transaction SQLite peut finir avant que le stream Drift ait
      // notifié le store. Attendre explicitement le cache dans runAsync.
      await tester.runAsync(() async {
        await store.addPatient(
          name: 'Patiente fictive test',
          age: 30,
          sex: 'F',
          phone: '',
        );

        final limite = DateTime.now().add(const Duration(seconds: 5));
        while (!store.patients.any((p) => p.name == 'Patiente fictive test')) {
          if (DateTime.now().isAfter(limite)) {
            final enBase = await database.patientDao.getAllPatients();
            throw StateError(
              'Le stream Drift n\'a pas actualisé le cache sous 5 s '
              '(patients en base : ${enBase.length}, '
              'patients en cache : ${store.patients.length}).',
            );
          }
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pumpAndSettle();
      expect(find.text('Patiente fictive test'), findsOneWidget,
          reason: 'InheritedNotifier doit reconstruire l\'écran après le commit Drift');
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        store.dispose();
        await store.streamsStopped;
        await database.close();
      });
    }
  });
}