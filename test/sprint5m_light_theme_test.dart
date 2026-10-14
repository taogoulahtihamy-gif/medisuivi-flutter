import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/design_tokens.dart';
import 'package:medisuivi/app/medisuivi_app.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/app/theme_v2.dart';

double contrast(Color a, Color b) {
  final upper = a.computeLuminance();
  final lower = b.computeLuminance();
  final hi = upper > lower ? upper : lower;
  final lo = upper > lower ? lower : upper;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('5M : contraste WCAG AA des textes sur toutes les surfaces', () {
    final surfaces = [
      ClinicalColors.lightBackground,
      ClinicalColors.lightSurface,
      ClinicalColors.lightSurfaceElevated,
      ClinicalColors.lightBrandPrimarySoft,
      ClinicalColors.lightAccentAmberSoft,
    ];
    for (final bg in surfaces) {
      expect(contrast(ClinicalColors.lightInk, bg),
          greaterThanOrEqualTo(7), reason: 'texte principal');
      expect(contrast(ClinicalColors.lightInkMuted, bg),
          greaterThanOrEqualTo(4.5), reason: 'texte secondaire');
      expect(contrast(ClinicalColors.lightInkSubtle, bg),
          greaterThanOrEqualTo(4.5), reason: 'texte discret');
      expect(contrast(ClinicalColors.lightBrandPrimary, bg),
          greaterThanOrEqualTo(4.5), reason: 'action accentuée');
      expect(contrast(ClinicalColors.lightAccentAmber, bg),
          greaterThanOrEqualTo(4.5), reason: 'accent ambre');
      expect(contrast(ClinicalColors.lightCritical, bg),
          greaterThanOrEqualTo(4.5), reason: 'texte d’alerte');
    }
    expect(contrast(ClinicalColors.actionOnDarkFill,
                    ClinicalColors.lightActionFill),
        greaterThanOrEqualTo(7));
    expect(contrast(ClinicalColors.lightBorderStrong,
                    ClinicalColors.lightSurfaceElevated),
        greaterThanOrEqualTo(3), reason: 'contour des champs');
  });

  test('5M : surfaces, saisie et conteneurs Material sont harmonisés', () {
    for (final theme in [MediTheme.light(), ClinicalTheme.light()]) {
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor,
          ClinicalColors.lightBackground);
      expect(theme.colorScheme.surface, ClinicalColors.lightSurface);
      expect(theme.colorScheme.surfaceContainer,
          ClinicalColors.lightSurface);
      expect(theme.colorScheme.surfaceContainerHigh,
          ClinicalColors.lightSurfaceElevated);
      expect(theme.colorScheme.onSurface, ClinicalColors.lightInk);
      final enabled = theme.inputDecorationTheme.enabledBorder!
          as OutlineInputBorder;
      expect(enabled.borderSide.color, ClinicalColors.lightBorderStrong);
      expect(contrast(enabled.borderSide.color,
              theme.inputDecorationTheme.fillColor!),
          greaterThanOrEqualTo(3));
    }
  });

  test('5M : palette sombre inchangée', () {
    expect(ClinicalColors.darkBackground, const Color(0xFF0D0F0E));
    expect(ClinicalColors.darkSurface, const Color(0xFF161917));
    expect(ClinicalColors.darkInk, const Color(0xFFF0EDE8));
    expect(MediTheme.dark().scaffoldBackgroundColor,
        ClinicalColors.darkBackground);
  });

  for (final width in [320.0, 390.0]) {
    testWidgets('5M : accueil et paramètres clairs accessibles à ${width.toInt()} px',
        (tester) async {
      tester.view.physicalSize = Size(width, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MediSuiviApp(themeMode: ThemeMode.light));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-patient-search')), findsOneWidget);
      expect(find.byKey(const Key('clinical-bottom-dock')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('dock-réglages')));
      await tester.pumpAndSettle();
      expect(find.text('Profil et paramètres'), findsOneWidget);
      expect(find.text('Personnalisation'.toUpperCase()), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
