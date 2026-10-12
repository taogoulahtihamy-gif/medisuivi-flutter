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
    final database = AppDatabase.createWithExecutor(NativeDatabase.memory());
    final store = PersistentStore(database);
    await tester.pumpWidget(PersistentScope(
      store: store,
      child: const MaterialApp(home: PatientsScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Mes patients'), findsOneWidget);

    await store.addPatient(
      name: 'Patiente fictive test', age: 30, sex: 'F', phone: '',
    );
    await tester.pumpAndSettle();
    expect(find.text('Patiente fictive test'), findsOneWidget,
      reason: 'InheritedNotifier doit reconstruire l’écran après le commit Drift');
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });
}
