import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/design_tokens.dart';
import 'package:medisuivi/app/medisuivi_app.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/app/theme_v2.dart';
import 'package:medisuivi/core/widgets/medical_ui.dart';
import 'package:medisuivi/features/onboarding/medisuivi_welcome_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Sprint 5N : typographie DM Sans présente physiquement dans le paquet',
      () async {
    final bytes = await rootBundle.load('assets/fonts/DMSans-Variable.ttf');
    expect(bytes.lengthInBytes, greaterThan(100000));
    expect(ClinicalTypography.fontFamilyDisplay, 'DM Sans');
    expect(ClinicalTypography.fontFamilyUI, 'DM Sans');
    expect(ClinicalTypography.fontFamilyMono, 'DM Sans');
    for (final theme in [MediTheme.light(), MediTheme.dark(),
      ClinicalTheme.light(), ClinicalTheme.dark()]) {
      expect(theme.textTheme.bodyMedium?.fontFamily, 'DM Sans');
      expect(theme.textTheme.titleLarge?.fontFamily, 'DM Sans');
    }
  });

  for (final width in [320.0, 390.0]) {
    testWidgets('Sprint 5N : ouverture équilibrée à ${width.toInt()} px',
        (tester) async {
      tester.view.physicalSize = Size(width, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        theme: ClinicalTheme.dark(),
        home: MediSuiviWelcomeGate(
          isWebDemo: true,
          child: const MediSuiviApp(themeMode: ThemeMode.dark)),
      ));
      await tester.pump();
      final title = find.byKey(const Key('welcome-splash-title'));
      final progress = find.byKey(const Key('welcome-progress'));
      expect(title, findsOneWidget);
      expect(progress, findsOneWidget);
      expect(tester.getCenter(title).dy, lessThan(500));
      expect(tester.getCenter(progress).dy, greaterThan(540));
      expect(tester.getSize(progress).width, greaterThan(width - 80));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Sprint 5N : registres ouverts et typographie à ${width.toInt()} px',
        (tester) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MediSuiviApp(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dock-patients')));
      await tester.pumpAndSettle();
      final patients = find.byKey(const Key('patients-compact-register'));
      expect(patients, findsOneWidget);
      expect(tester.widget<ClinicalGroupedList>(patients).children.length,
        greaterThan(1));
      // Le registre est composé de lignes Material indépendantes.
      expect(find.descendant(of: patients,
        matching: find.byType(Material)), findsWidgets);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('dock-bilans')));
      await tester.pumpAndSettle();
      final exams = find.byKey(const Key('exams-compact-register'));
      expect(exams, findsOneWidget);
      expect(tester.widget<ClinicalGroupedList>(exams).children.length, 3);
      expect(tester.takeException(), isNull);
    });
  }
}
