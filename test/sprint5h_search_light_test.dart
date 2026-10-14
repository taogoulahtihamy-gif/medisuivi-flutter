import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/design_tokens.dart';
import 'package:medisuivi/app/medisuivi_app.dart';

double _contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  return (a > b ? a + .05 : b + .05) /
      (a > b ? b + .05 : a + .05);
}

void main() {
  test('Palette ivoire : typographie, icônes et accent lisibles', () {
    for (final surface in [
      ClinicalColors.lightBackground,
      ClinicalColors.lightSurface,
      ClinicalColors.lightSurfaceElevated,
    ]) {
      expect(_contrast(ClinicalColors.lightInk, surface),
        greaterThanOrEqualTo(7));
      expect(_contrast(ClinicalColors.lightInkMuted, surface),
        greaterThanOrEqualTo(4.5));
      expect(_contrast(ClinicalColors.lightInkSubtle, surface),
        greaterThanOrEqualTo(4.5));
      expect(_contrast(ClinicalColors.lightBrandPrimary, surface),
        greaterThanOrEqualTo(4.5));
      expect(_contrast(ClinicalColors.lightAccentAmber, surface),
        greaterThanOrEqualTo(4.5));
    }
    expect(_contrast(
      ClinicalColors.lightAccentAmber, ClinicalColors.lightAccentAmberSoft),
      greaterThanOrEqualTo(4.5));
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('Accueil ${mode.name} : recherche à gauche et titre à droite',
        (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MediSuiviApp(themeMode: mode));
      await tester.pumpAndSettle();

      final search = find.byKey(const Key('home-patient-search'));
      final title = find.byKey(const Key('home-greeting-title'));
      expect(search, findsOneWidget);
      expect(title, findsOneWidget);
      expect(find.byKey(const Key('home-greeting-date')), findsOneWidget);
      expect(tester.getTopLeft(title).dx,
        greaterThan(tester.getTopLeft(search).dx));
      expect(tester.takeException(), isNull);

      await tester.enterText(search, 'Aminata');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-search-results')), findsOneWidget);
      final result = find.descendant(
        of: find.byKey(const Key('home-search-results')),
        matching: find.text('Aminata Diallo'));
      expect(result, findsOneWidget);
      await tester.tap(result);
      await tester.pumpAndSettle();
      expect(find.text('Dossier médical'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Recherche effaçable et résultat inconnu explicite',
      (tester) async {
    await tester.pumpWidget(
      const MediSuiviApp(themeMode: ThemeMode.light));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('home-patient-search')), 'zzzz-inconnu');
    await tester.pumpAndSettle();
    expect(find.text('Aucun patient trouvé'), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-clear-search')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-search-results')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
