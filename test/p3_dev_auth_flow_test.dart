import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';
import 'package:medisuivi/features/onboarding/medisuivi_welcome_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final accounts = <String, Map<String, dynamic>>{
    'alpha@medisuvi-ci.org': {
      'id': 'alpha-id', 'email': 'alpha@medisuvi-ci.org',
      'first_name': 'Awa', 'last_name': 'Test',
    },
    'beta@medisuvi-ci.org': {
      'id': 'beta-id', 'email': 'beta@medisuvi-ci.org',
      'first_name': 'Moussa', 'last_name': 'Test',
    },
  };

  test('P3: HTTP API does not retain credentials and isolates remote lists',
      () async {
    final calls = <http.Request>[];
    final api = DevAuthApi(Uri.parse('http://127.0.0.1:8027'),
      client: MockClient((req) async {
        calls.add(req);
        if (req.url.path == '/api/v1/auth/login') {
          final email = (jsonDecode(req.body) as Map)['email'];
          return http.Response(jsonEncode({'access_token': email == 'alpha@medisuvi-ci.org'
              ? 'token-alpha' : 'token-beta'}), 200);
        }
        if (req.url.path == '/api/v1/me') {
          return http.Response(jsonEncode(
            req.headers['authorization'] == 'Bearer token-alpha'
                ? accounts['alpha@medisuvi-ci.org']
                : accounts['beta@medisuvi-ci.org']), 200);
        }
        if (req.url.path == '/api/v1/patients') {
          return http.Response(jsonEncode(
            req.headers['authorization'] == 'Bearer token-alpha'
                ? [{'id':'patient-alpha', 'display_name':'PATIENT FICTIF A','age':30}]
                : []), 200);
        }
        return http.Response('{}', 404);
      }));

    final a = await api.signIn('alpha@medisuvi-ci.org', 'secret-alpha');
    final b = await api.signIn('beta@medisuvi-ci.org', 'secret-beta');
    expect(a.practitioner.displayName, 'Awa Test');
    expect(b.practitioner.displayName, 'Moussa Test');
    expect((await api.listPatients(a)).single.displayName, 'PATIENT FICTIF A');
    expect(await api.listPatients(b), isEmpty);
    final aAccess = calls.where((x) =>
      x.url.path == '/api/v1/patients' &&
      x.headers['authorization'] == 'Bearer token-alpha');
    final bAccess = calls.where((x) =>
      x.url.path == '/api/v1/patients' &&
      x.headers['authorization'] == 'Bearer token-beta');
    expect(aAccess.length, 1);
    expect(bAccess.length, 1);
    api.close();
  });

  testWidgets('P3: login from welcome gate opens only authenticated workspace',
      (tester) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var revoked = false;
    var fakePatientCreated = false;

    final api = DevAuthApi(Uri.parse('http://127.0.0.1:8027'),
      client: MockClient((req) async {
        if (req.url.path == '/api/v1/auth/login') {
          final body = jsonDecode(req.body) as Map;
          if (body['password'] != 'test-password-1234') {
            return http.Response('{}', 401);
          }
          return http.Response(jsonEncode({'access_token':'token-alpha'}), 200);
        }
        if (req.url.path == '/api/v1/me') {
          return http.Response(jsonEncode(accounts['alpha@medisuvi-ci.org']), 200);
        }
        if (req.url.path == '/api/v1/patients' && req.method == 'GET') {
          return http.Response(jsonEncode(fakePatientCreated ? [{
            'id': 'synthetic-1', 'display_name':'PATIENT FICTIF 1234','age':30
          }] : []), 200);
        }
        if (req.url.path == '/api/v1/patients' && req.method == 'POST') {
          fakePatientCreated = true;
          expect(req.headers['authorization'], 'Bearer token-alpha');
          expect(req.body, contains('PATIENT FICTIF'));
          return http.Response(jsonEncode({
            'id':'synthetic-1','display_name':'PATIENT FICTIF 1234','age':30}), 201);
        }
        if (req.url.path == '/api/v1/auth/logout') {
          revoked = true;
          return http.Response('', 204);
        }
        return http.Response('{}', 404);
      }));

    await tester.pumpWidget(MaterialApp(
      theme: MediTheme.light(),
      home: MediSuiviWelcomeGate(
        isWebDemo: true, developmentAuthApi: api,
        child: const Text('DEMO STORE MUST NEVER BE SHOWN')),
    ));
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-skip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('welcome-login')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('original-account-test-warning')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('dev-auth-email')), 'alpha@medisuvi-ci.org');
    await tester.enterText(
      find.byKey(const Key('dev-auth-password')), 'test-password-1234');
    await tester.tap(find.byKey(const Key('dev-auth-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dev-authenticated-workspace')), findsOneWidget);
    expect(find.byKey(const Key('original-connected-shell')), findsOneWidget);
    expect(find.byKey(const ValueKey('medisuivi-home')), findsOneWidget);
    expect(find.byKey(const Key('clinical-bottom-dock')), findsOneWidget);
    expect(find.text('DEMO STORE MUST NEVER BE SHOWN'), findsNothing);

    await tester.tap(find.byKey(const Key('dock-réglages')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-connected-signout')),
      250,
      scrollable: find.descendant(
        of: find.byKey(const Key('settings-page-list')),
        matching: find.byType(Scrollable),
      ),
    );
    // The original translucent dock overlaps the last ~75 px.
    // Scroll the settings action above it before issuing the tap.
    await tester.drag(
      find.byKey(const Key('settings-page-list')),
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-connected-signout')));
    await tester.pumpAndSettle();
    expect(revoked, isTrue);
    expect(find.byKey(const Key('welcome-login')), findsOneWidget);
    expect(find.byKey(const Key('medisuivi-home')), findsNothing);
    expect(tester.takeException(), isNull);
    api.close();
  });
}
