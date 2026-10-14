import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/medisuivi_app.dart' as demo;
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/features/onboarding/medisuivi_welcome_gate.dart';

Widget _entry() => MaterialApp(
  theme: MediTheme.light(),
  home: const MediSuiviWelcomeGate(
    isWebDemo: true,
    child: demo.MediSuiviApp(themeMode: ThemeMode.light),
  ),
);

void main() {
  for (final width in [320.0, 360.0, 390.0]) {
    testWidgets('5J : splash, introduction, accès à ${width.toInt()} px',
        (tester) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_entry());
      expect(find.byKey(const Key('welcome-progress')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboarding-pages')), findsOneWidget);
      await tester.tap(find.byKey(const Key('onboarding-skip')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('welcome-create')), findsOneWidget);
      expect(find.byKey(const Key('welcome-login')), findsOneWidget);
      expect(find.byKey(const Key('welcome-demo')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('welcome-login')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Aucun mot de passe'), findsOneWidget);
      await tester.tap(find.byKey(const Key('login-local-access')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('medisuivi-home')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('5J : profil rempli visible dans les Réglages et en en-tête',
      (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_entry());
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-skip')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('welcome-create')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('practitioner-first-name')), 'Fatou');
    await tester.enterText(
      find.byKey(const Key('practitioner-last-name')), 'Diop');
    final save = find.byKey(const Key('practitioner-save-preview'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-practitioner-avatar')), findsOneWidget);
    await tester.tap(find.byKey(const Key('header-profile')));
    await tester.pumpAndSettle();
    expect(find.text('Fatou Diop'), findsOneWidget);
    expect(find.byKey(const Key('settings-practitioner-profile')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
