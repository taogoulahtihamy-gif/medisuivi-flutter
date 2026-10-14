import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medisuivi/app/medisuivi_app.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';
import 'package:medisuivi/features/auth/original_connected_clinical_gate.dart';
import 'package:medisuivi/features/onboarding/medisuivi_welcome_gate.dart';

void setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 850);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('dock-réglages')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('settings-page-list')), findsOneWidget);
  expect(tester.takeException(), isNull);
}

Future<void> openSettingsItem(
    WidgetTester tester, String key) async {
  await tester.scrollUntilVisible(
    find.byKey(Key(key)), 160,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull,
      reason: 'Le réglage $key doit ouvrir une vraie page Material.');
}

Future<void> backAndVerifySettings(WidgetTester tester) async {
  await tester.pageBack();
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('settings-page-list')), findsOneWidget);
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('P4.9: every principal Settings link opens and returns safely',
      (tester) async {
    setPhoneViewport(tester);
    final profile = PractitionerPreview();
    addTearDown(profile.dispose);
    profile.update(firstName: 'Awa', lastName: 'Fictive',
      email: 'fictive@example.test', phone: '', specialty: '');

    await tester.pumpWidget(PractitionerPreviewScope(
      controller: profile,
      child: const MediSuiviApp(themeMode: ThemeMode.dark),
    ));
    await tester.pumpAndSettle();
    await openSettings(tester);

    for (final key in [
      'settings-practitioner-profile',
      'settings-appearance',
      'settings-notifications',
      'settings-data',
      'settings-synchronization',
      'settings-privacy',
      'settings-more',
      'settings-about',
    ]) {
      await openSettingsItem(tester, key);
      await backAndVerifySettings(tester);
    }

    // Inline theme switches are also interactive.
    await openSettingsItem(tester, 'settings-appearance');
    for (final mode in ['light', 'dark', 'system']) {
      await tester.tap(find.byKey(Key('appearance-option-$mode')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await backAndVerifySettings(tester);
  });

  testWidgets('P4.9: Data, Notifications and More nested links are Material',
      (tester) async {
    setPhoneViewport(tester);
    await tester.pumpWidget(
      const MediSuiviApp(themeMode: ThemeMode.dark),
    );
    await tester.pumpAndSettle();
    await openSettings(tester);

    await openSettingsItem(tester, 'settings-data');
    for (final (key, expected) in [
      ('data-view-patients', 'patients-search'),
      ('data-view-exams', 'clinical-tab-route-scaffold'),
    ]) {
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('clinical-tab-route-scaffold')),
          findsOneWidget);
      expect(find.byKey(Key(expected)), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: '$key doit ouvrir une page Scaffold avec Material.');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('data-view-patients')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await backAndVerifySettings(tester);

    await openSettingsItem(tester, 'settings-notifications');
    await tester.tap(find.textContaining('examen(s) en attente'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('clinical-tab-route-scaffold')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('suivi(s) en retard'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('clinical-tab-route-scaffold')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await backAndVerifySettings(tester);

    await openSettingsItem(tester, 'settings-more');
    for (final key in [
      'more-language', 'more-storage', 'more-privacy', 'more-about',
    ]) {
      await tester.scrollUntilVisible(
        find.byKey(Key(key)), 160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'La sous-page $key ne doit pas perdre Material.');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('more-language')), findsOneWidget);
    }
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-page-list')), findsOneWidget);
  });

  testWidgets('P4.9: account-scoped Settings patient shortcut keeps API owner',
      (tester) async {
    setPhoneViewport(tester);
    final api = DevAuthApi(
      Uri.parse('https://medisuivi-ci.invalid'),
      client: MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer token-A');
        switch (request.url.path) {
          case '/api/v1/patients':
            return http.Response(jsonEncode([
              {'id': 'patient-A',
               'display_name': 'PATIENT FICTIF COMPTE A', 'age': 35},
            ]), 200);
          case '/api/v1/patients/patient-A/visits':
          case '/api/v1/patients/patient-A/exams':
          case '/api/v1/patients/patient-A/followups':
            return http.Response('[]', 200);
        }
        return http.Response('{}', 404);
      }),
    );
    addTearDown(api.close);
    final session = DevSession(
      practitioner: const DevPractitioner(
        id: 'account-A', email: 'a@medisuvi-ci.org',
        firstName: 'Awa', lastName: 'Fictive',
      ),
      accessToken: 'token-A',
    );
    await tester.pumpWidget(MaterialApp(
      theme: MediTheme.dark(),
      home: OriginalConnectedClinicalGate(
        api: api, session: session,
        onSignedOut: () {},
        child: const MainShell(),
      ),
    ));
    await tester.pumpAndSettle();
    await openSettings(tester);
    await openSettingsItem(tester, 'settings-data');
    await tester.tap(find.byKey(const Key('data-view-patients')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('clinical-tab-route-scaffold')),
        findsOneWidget);
    expect(find.text('PATIENT FICTIF COMPTE A'), findsWidgets);
    expect(find.text('Aminata Diallo'), findsNothing,
        reason: 'Les sous-pages ne doivent jamais afficher DemoStore.');
    expect(tester.takeException(), isNull);

    // Opening a detail must retain the account-scoped navigator and store.
    await tester.tap(find.text('PATIENT FICTIF COMPTE A').first);
    await tester.pumpAndSettle();
    expect(find.text('Dossier médical'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
