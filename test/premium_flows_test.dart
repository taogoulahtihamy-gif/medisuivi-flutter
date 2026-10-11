import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/medisuivi_app.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/core/state/demo_store.dart';
import 'package:medisuivi/core/widgets/floating_bottom_navigation.dart';
import 'package:medisuivi/features/consultations/new_consultation_screen.dart';
import 'package:medisuivi/features/patients/patient_detail_screen.dart';

Finder nav(String label) => find.descendant(
    of: find.byType(FloatingBottomNavigation), matching: find.text(label));
void main() {
  testWidgets('Navigation iOS et texte x2 sur petit écran', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = DemoStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(DemoScope(
        store: store,
        child: MaterialApp(
            theme: AppTheme.light().copyWith(platform: TargetPlatform.iOS),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(2),
                    disableAnimations: true),
                child: child!),
            home: const MainShell())));
    await tester.pumpAndSettle();
    expect(find.byIcon(CupertinoIcons.house_fill), findsOneWidget);
    for (final label in ['Patients', 'Bilans', 'Suivi', 'Accueil']) {
      await tester.tap(nav(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(430, 932),
    const Size(768, 1024)
  ]) {
    testWidgets('Navigation sans overflow à $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MediSuiviApp());
      await tester.pumpAndSettle();
      for (final label in ['Patients', 'Bilans', 'Suivi', 'Accueil']) {
        await tester.tap(nav(label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
  testWidgets('Dossier, consultation et enregistrement temporaire',
      (tester) async {
    await tester.pumpWidget(const MediSuiviApp());
    await tester.tap(nav('Patients'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aminata Diallo'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Nouvelle consultation démo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nouvelle consultation démo'));
    await tester.pumpAndSettle();
    expect(find.byType(NewConsultationScreen), findsOneWidget);
    await tester.enterText(
        find.byType(TextFormField).first, 'Contrôle fictif UI');
    await tester.ensureVisible(find.text('Enregistrer la visite démo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer la visite démo'));
    await tester.pumpAndSettle();
    expect(find.byType(PatientDetailScreen), findsOneWidget);
    expect(find.text('Contrôle fictif UI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Recherche vide et filtre des résultats', (tester) async {
    await tester.pumpWidget(const MediSuiviApp());
    await tester.tap(nav('Patients'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'aucun dossier xyz');
    await tester.pumpAndSettle();
    expect(find.text('Aucun dossier trouvé'), findsOneWidget);
    await tester.tap(nav('Bilans'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Disponibles'));
    await tester.pumpAndSettle();
    expect(find.text('En attente de résultat'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Dossier et formulaire à 320 px, texte x2, animations réduites',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = DemoStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(DemoScope(
        store: store,
        child: MaterialApp(
            theme: AppTheme.light(),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(2),
                    disableAnimations: true),
                child: child!),
            home: PatientDetailScreen(patientId: store.patients.first.id))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Nouvelle consultation démo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nouvelle consultation démo'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Enregistrer la visite démo'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Enregistrer la visite démo'));
    await tester.pumpAndSettle();
    expect(find.text('Indiquez le motif.'), findsOneWidget);
  });
}
