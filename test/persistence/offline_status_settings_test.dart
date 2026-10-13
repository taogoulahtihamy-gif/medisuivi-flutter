import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/core/persistence/database.dart';
import 'package:medisuivi/core/state/persistent_store.dart';
import 'package:medisuivi/features/settings/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Les paramètres affichent les opérations locales non envoyées',
      (tester) async {
    late final AppDatabase database;
    late final PersistentStore store;

    await tester.runAsync(() async {
      database = AppDatabase.createWithExecutor(NativeDatabase.memory());
      store = PersistentStore(database);
      await store.ready;
    });

    // Les requêtes SQLite de FutureBuilder progressent en temps réel,
    // contrairement à l'horloge simulée de testWidgets.
    Future<void> attendreTexte(String attendu) async {
      for (var tentative = 0; tentative < 100; tentative++) {
        await tester.pump();
        if (find.textContaining(attendu).evaluate().isNotEmpty) return;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
      }
      throw TestFailure('Le texte attendu n\'apparaît pas : $attendu');
    }

    try {
      await tester.pumpWidget(
        PersistentScope(
          store: store,
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await attendreTexte('Aucune modification en attente');

      expect(find.text('Modifications à envoyer'), findsOneWidget);
      expect(find.textContaining('Aucune modification en attente. Aucun serveur distant connecté.'),
          findsOneWidget);
      expect(find.textContaining('Non configurée'), findsOneWidget);

      await tester.runAsync(() => store.addPatient(
            name: 'Patient fictif hors connexion',
            age: 29,
            sex: 'F',
            phone: '',
          ));
      await tester.pumpAndSettle();
      await attendreTexte('1 modification(s) conservée(s)');

      expect(find.textContaining('1 modification(s) conservée(s)'),
          findsOneWidget);
      expect(find.textContaining('Aucune transmission automatique'),
          findsOneWidget);
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