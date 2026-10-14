import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/medisuivi_app.dart';
import 'package:medisuivi/core/assets/clinical_hero_photo.dart';
import 'package:medisuivi/features/onboarding/medisuivi_welcome_gate.dart';

void main() {
  for (final width in [320.0, 360.0, 390.0]) {
    testWidgets('Sprint 5K: portrait central, thèmes et groupes à ${width.toInt()} px',
        (tester) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final profile = PractitionerPreview();
      addTearDown(profile.dispose);
      profile.update(
        firstName: 'Fatou', lastName: 'Diop',
        email: 'fatou@exemple.test', phone: '',
        specialty: 'Médecine générale',
        photo: base64Decode(clinicalHeroPhotoWebpBase64),
      );

      await tester.pumpWidget(PractitionerPreviewScope(
        controller: profile,
        child: const MediSuiviApp(themeMode: ThemeMode.dark),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dock-réglages')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings-profile-avatar')), findsOneWidget);
      expect(find.text('Fatou Diop'), findsOneWidget);
      expect(find.text('Médecine générale'), findsOneWidget);
      expect(find.byKey(const Key('settings-practitioner-profile')), findsOneWidget);
      final avatar = tester.widget<CircleAvatar>(
        find.byKey(const Key('settings-profile-avatar')));
      expect(avatar.foregroundImage, isA<MemoryImage>());
      expect(find.byKey(const Key('theme-light')), findsOneWidget);
      expect(find.byKey(const Key('theme-dark')), findsOneWidget);
      expect(find.byKey(const Key('theme-system')), findsOneWidget);

      final center = tester.getCenter(find.byKey(const Key('settings-profile-avatar')));
      expect((center.dx - width / 2).abs(), lessThan(2));
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.byKey(const Key('settings-more')), 140,
        scrollable: find.byType(Scrollable).first);
      await tester.drag(find.byKey(const Key('settings-page-list')),
          const Offset(0, -160));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings-more')));
      await tester.pumpAndSettle();
      expect(find.text('Préférences de l’application'), findsOneWidget);
      expect(find.byKey(const Key('more-language')), findsOneWidget);
      await tester.tap(find.byKey(const Key('more-language')));
      await tester.pumpAndSettle();
      expect(find.text('Le français est actuellement la langue disponible.'), findsNothing);
      expect(find.byKey(const Key('settings-language-fr')), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Sprint 5K: profil éditable et notifications réellement navigables',
      (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profile = PractitionerPreview();
    addTearDown(profile.dispose);
    profile.update(firstName: 'Fatou', lastName: 'Diop',
      email: '', phone: '', specialty: '');
    await tester.pumpWidget(PractitionerPreviewScope(
      controller: profile,
      child: const MediSuiviApp(themeMode: ThemeMode.light),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dock-réglages')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-practitioner-profile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('practitioner-first-name')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('practitioner-first-name')), 'Awa');
    final save = find.byKey(const Key('practitioner-save-preview'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Awa Diop'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-notifications')), 130,
      scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byKey(const Key('settings-page-list')),
        const Offset(0, -140));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-notifications')));
    await tester.pumpAndSettle();
    expect(find.text('À surveiller'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-privacy')), 150,
      scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byKey(const Key('settings-page-list')),
        const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-privacy')));
    await tester.pumpAndSettle();
    expect(find.text('Confidentialité et protection'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
