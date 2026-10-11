import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/medisuivi_app.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/core/models/medical_models.dart';

void main() {
  test('Palette Forest Code et Mint Fog', () {
    expect(Palette.forest, const Color(0xFF075E46));
    expect(Palette.mintFog, const Color(0xFFE8FFF2));
    expect(Palette.teal, Palette.forest);
    expect(Palette.tealSoft, Palette.mintFog);
  });

  test('Initiales patient fictif', () {
    final patient = Patient(id: 'TEST-001', name: 'Aminata Diallo', age: 32,
      sex: 'F', phone: '', createdAt: DateTime(2026, 1, 1));
    expect(patient.initials, 'AD');
  });

  testWidgets('Accueil et avertissement de démonstration', (tester) async {
    await tester.pumpWidget(const MediSuiviApp());
    expect(find.text('MediSuivi'), findsOneWidget);
    expect(find.textContaining('Démonstration'), findsWidgets);
    expect(find.text('Vue clinique'), findsOneWidget);
    expect(find.text('Accès rapide'), findsOneWidget);
  });

  testWidgets('Accueil mobile sans débordement et actions accessibles', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MediSuiviApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Nouveau patient'), findsOneWidget);
    expect(find.text('Patients'), findsWidgets);
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
