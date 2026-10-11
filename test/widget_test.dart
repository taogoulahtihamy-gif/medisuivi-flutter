import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/medisuivi_app.dart';
import 'package:medisuivi/core/models/medical_models.dart';

void main() {
  test('Initiales patient fictif', () {
    final patient = Patient(id: 'TEST-001', name: 'Aminata Diallo', age: 32,
      sex: 'F', phone: '', createdAt: DateTime(2026, 1, 1));
    expect(patient.initials, 'AD');
  });

  testWidgets('Accueil et avertissement de démonstration', (tester) async {
    await tester.pumpWidget(const MediSuiviApp());
    expect(find.text('MediSuivi'), findsOneWidget);
    expect(find.textContaining('Démonstration'), findsWidgets);
    expect(find.text('Mes dossiers  →'), findsOneWidget);
  });

  testWidgets('Navigation et recherche de patient fictif', (tester) async {
    await tester.pumpWidget(const MediSuiviApp());
    await tester.tap(find.text('Patients').last);
    await tester.pumpAndSettle();
    expect(find.text('Mes patients'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Aminata');
    await tester.pumpAndSettle();
    expect(find.text('Aminata Diallo'), findsOneWidget);
    expect(find.text('Moussa Ndiaye'), findsNothing);
  });

  testWidgets('Dossier et constantes médicales fictives', (tester) async {
    await tester.pumpWidget(const MediSuiviApp());
    await tester.tap(find.text('Patients').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aminata Diallo').first);
    await tester.pumpAndSettle();
    expect(find.text('Dossier patient'), findsOneWidget);
    expect(find.text('Dernières constantes'), findsOneWidget);
  });
}
