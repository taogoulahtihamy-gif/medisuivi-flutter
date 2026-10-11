import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/medisuivi_app.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/core/models/medical_models.dart';
import 'package:medisuivi/features/patients/new_patient_screen.dart';
import 'package:medisuivi/features/consultations/new_consultation_screen.dart';

void main() {
  test('Palette Night Shift et Laser Lemon exclusivement', () {
    expect(Palette.night, const Color(0xFF10131A));
    expect(Palette.laser, const Color(0xFFEFFF4F));
    expect(Palette.forest, Palette.laser);
    expect(Palette.teal, Palette.laser);
    expect(Palette.canvas, Palette.night);
    expect(Palette.mintFog, Palette.laserVeil);
  });

  test('Les ressources visibles restent strictement bicolores', () {
    final dartFiles = Directory('lib').listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
    final regex = RegExp(r'Color\(0x([0-9a-fA-F]{8})\)');
    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      for (final match in regex.allMatches(source)) {
        final rgb = match.group(1)!.substring(2).toUpperCase();
        expect({'10131A', 'EFFF4F'}.contains(rgb), isTrue,
          reason: 'Teinte interdite dans ${file.path}: #$rgb');
      }
    }
    for (final path in ['assets/illustrations/medical_care.svg', 'web/favicon.svg']) {
      final source = File(path).readAsStringSync();
      for (final match in RegExp(r'#([0-9A-Fa-f]{6})').allMatches(source)) {
        final rgb = match.group(1)!.toUpperCase();
        expect({'10131A', 'EFFF4F'}.contains(rgb), isTrue,
          reason: 'Teinte interdite dans $path: #$rgb');
      }
    }
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
  testWidgets('Formulaire patient sur mobile étroit', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: MediTheme.light(),
      home: const NewPatientScreen(),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Créer un dossier'), findsOneWidget);
  });

  testWidgets('Formulaire de consultation sur mobile étroit', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fictif = Patient(
      id: 'TEST-002', name: 'Patient Démo', age: 31,
      sex: 'F', phone: '', createdAt: DateTime(2026, 1, 1),
    );
    await tester.pumpWidget(MaterialApp(
      theme: MediTheme.light(),
      home: NewConsultationScreen(patient: fictif),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Constantes vitales'), findsOneWidget);
  });

}
