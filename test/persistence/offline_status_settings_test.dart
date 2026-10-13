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
    final database = AppDatabase.createWithExecutor(NativeDatabase.memory());
    final store = PersistentStore(database);
    try {
      await tester.pumpWidget(
        PersistentScope(
          store: store,
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Modifications à envoyer'), findsOneWidget);
      expect(find.textContaining('Aucune modification en attente'), findsOneWidget);
      expect(find.textContaining('Non configurée'), findsOneWidget);

      await store.addPatient(
        name: 'Patient fictif hors connexion',
        age: 29,
        sex: 'F',
        phone: '',
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('1 modification(s) conservée(s)'), findsOneWidget);
      expect(find.textContaining('Aucune transmission automatique'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
      await database.close();
    }
  });
}
