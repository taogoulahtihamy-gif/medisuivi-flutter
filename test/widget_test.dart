import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/medisuivi_app.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/core/assets/clinical_hero_photo.dart';
import 'package:medisuivi/core/models/medical_models.dart';
import 'package:medisuivi/features/patients/new_patient_screen.dart';
import 'package:medisuivi/features/consultations/new_consultation_screen.dart';

void main() {
  test('Palette clinique et polices lisibles', () {
    expect(Palette.canvas, const Color(0xFFF2EFEA));
    expect(Palette.forest, const Color(0xFF2D3A35));
    expect(Palette.ink, const Color(0xFF1C1A18));
    expect(MediTheme.light().brightness, Brightness.light);
    expect(MediTheme.dark().brightness, Brightness.dark);
    expect(MediTheme.light().textTheme.bodyMedium!.fontSize, 13.5);
  });

  test('Photo panoramique intégrée sans requête réseau', () {
    final bytes = base64Decode(clinicalHeroPhotoWebpBase64);
    expect(bytes.length, greaterThan(2500));
    expect(String.fromCharCodes(bytes.take(4)), 'RIFF');
    expect(String.fromCharCodes(bytes.skip(8).take(4)), 'WEBP');
    final length = bytes[4] |
      (bytes[5] << 8) |
      (bytes[6] << 16) |
      (bytes[7] << 24);
    expect(length + 8, bytes.length);
  });

  test('Initiales patient fictif', () {
    final patient = Patient(id: 'TEST-001', name: 'Aminata Diallo', age: 32,
      sex: 'F', phone: '', createdAt: DateTime(2026, 1, 1));
    expect(patient.initials, 'AD');
  });

  testWidgets('Accueil professionnel sans bandeau répétitif', (tester) async {
    await tester.pumpWidget(const MediSuiviApp());
    expect(find.text('MediSuivi'), findsOneWidget);
    expect(find.textContaining('Démonstration'), findsNothing);
    expect(find.text('Vos dossiers'), findsOneWidget);
    expect(find.text('À consulter'), findsOneWidget);
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

  testWidgets('Accueil à 320 px sans débordement', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MediSuiviApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Vos dossiers'), findsOneWidget);
  });

  testWidgets('Illustrations médicales distinctes et embarquées', (tester) async {
    const illustrations = [
      'assets/illustrations/consultation.svg',
      'assets/illustrations/patient_records.svg',
      'assets/illustrations/laboratory.svg',
      'assets/illustrations/care_calendar.svg',
    ];
    for (final asset in illustrations) {
      final svg = await rootBundle.loadString(asset);
      expect(svg, contains('<svg'), reason: asset);
      expect(svg, contains('<title>'), reason: asset);
    }
  });

  testWidgets('Images contextuelles visibles dans chaque onglet', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MediSuiviApp());
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    for (final tab in ['Patients', 'Bilans', 'Suivi']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(find.byType(SvgPicture), findsOneWidget, reason: tab);
      expect(tester.takeException(), isNull, reason: tab);
    }
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

  testWidgets('Dossier patient et constantes médicales', (tester) async {
    await tester.pumpWidget(const MediSuiviApp());
    await tester.tap(find.text('Patients').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aminata Diallo').first);
    await tester.pumpAndSettle();
    expect(find.text('Dossier médical'), findsOneWidget);
    expect(find.text('Dernières constantes'), findsOneWidget);
    expect(find.text('Informations médicales'), findsOneWidget);
  });
  testWidgets('Dossier médical complet sur écran étroit', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MediSuiviApp());
    await tester.tap(find.text('Patients').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aminata Diallo').first);
    await tester.pumpAndSettle();

    expect(find.text('Dossier médical'), findsOneWidget);
    expect(find.text('Informations médicales'), findsOneWidget);
    expect(find.text('Antécédents médicaux'), findsOneWidget);
    expect(find.text('Bilans et examens'), findsOneWidget);
    expect(find.text('Suivi du patient'), findsOneWidget);
    await tester.ensureVisible(find.text('Suivi du patient'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
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
