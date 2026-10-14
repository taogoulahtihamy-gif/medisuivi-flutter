import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/medisuivi_app.dart' as demo;
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/core/assets/clinical_hero_photo.dart';
import 'package:medisuivi/features/onboarding/medisuivi_welcome_gate.dart';

Widget _entry({ThemeMode themeMode = ThemeMode.light}) => MaterialApp(
  theme: MediTheme.light(),
  darkTheme: MediTheme.dark(),
  themeMode: themeMode,
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
      expect(find.byKey(const Key('welcome-splash-photo')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 3000));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboarding-pages')), findsOneWidget);
      expect(find.byKey(const Key('onboarding-clinical-image-0')), findsOneWidget);
      expect(find.byKey(const Key('onboarding-title-0')), findsOneWidget);
      final photo0 = tester.widget<Image>(
        find.byKey(const Key('onboarding-clinical-image-0'))).image as AssetImage;
      expect(photo0, isA<AssetImage>());
      await tester.tap(find.byKey(const Key('onboarding-next')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('onboarding-title-1')), findsOneWidget);
      final photo1 = tester.widget<Image>(
        find.byKey(const Key('onboarding-clinical-image-1'))).image as AssetImage;
      expect(photo1, isA<AssetImage>());
      expect(photo0.assetName, isNot(photo1.assetName));
      await tester.tap(find.byKey(const Key('onboarding-next')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('onboarding-title-2')), findsOneWidget);
      final photo2 = tester.widget<Image>(
        find.byKey(const Key('onboarding-clinical-image-2'))).image as AssetImage;
      expect(photo2, isA<AssetImage>());
      expect(photo1.assetName, isNot(photo2.assetName));
      await tester.tap(find.byKey(const Key('onboarding-skip')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('welcome-create')), findsOneWidget);
      expect(find.byKey(const Key('welcome-login')), findsOneWidget);
      expect(find.byKey(const Key('welcome-demo')), findsOneWidget);
      expect(find.byKey(const Key('welcome-access-photo')), findsNothing);
      expect(find.byKey(const Key('welcome-clinical-brand')), findsOneWidget);
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

  testWidgets('5J : contraste et mise en page sombre sur mobile compact',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_entry(themeMode: ThemeMode.dark));
    expect(find.byKey(const Key('welcome-splash-photo')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('onboarding-clinical-image-0')), findsOneWidget);
    expect(find.byKey(const Key('onboarding-title-0')), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('onboarding-title-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('5J : profil rempli visible dans les Réglages et en en-tête',
      (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_entry());
    await tester.pump(const Duration(milliseconds: 3000));
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


  testWidgets('5J : la photo du praticien apparaît dans l’avatar en haut à droite',
      (tester) async {
    final profile = PractitionerPreview();
    addTearDown(profile.dispose);
    profile.update(
      firstName: 'Fatou',
      lastName: 'Diop',
      email: '', phone: '', specialty: '',
      photo: base64Decode(clinicalHeroPhotoWebpBase64),
    );
    await tester.pumpWidget(PractitionerPreviewScope(
      controller: profile,
      child: const demo.MediSuiviApp(themeMode: ThemeMode.light),
    ));
    await tester.pumpAndSettle();

    final avatar = tester.widget<CircleAvatar>(
      find.byKey(const Key('home-practitioner-avatar')));
    expect(avatar.foregroundImage, isA<MemoryImage>());
    expect(tester.takeException(), isNull);

    profile.update(
      firstName: 'Fatou', lastName: 'Diop',
      email: '', phone: '', specialty: '', photo: null);
    await tester.pump();
    final withoutPhoto = tester.widget<CircleAvatar>(
      find.byKey(const Key('home-practitioner-avatar')));
    expect(withoutPhoto.foregroundImage, isNull);
  });
}
