import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';
import 'package:medisuivi/features/auth/original_account_access_screen.dart';

void main() {
  testWidgets('P5.0 remote registration sends private invitation ONLY as header',
      (tester) async {
    if (!const bool.fromEnvironment('MEDISUIVI_REMOTE_SANDBOX')) return;
    const invite = 'synthetic-test-invitation-code-1234567890';
    final requests = <http.Request>[];
    final api = DevAuthApi(
      Uri.parse('https://medisuivi-api-staging.onrender.com'),
      client: MockClient((request) async {
        requests.add(request);
        switch (request.url.path) {
          case '/api/v1/auth/register':
            return http.Response(jsonEncode({
              'id': 'fake-account',
              'email': 'demo-android@example.com',
              'email_verification_required': false,
            }), 201);
          case '/api/v1/auth/login':
            return http.Response(jsonEncode({
              'access_token': 'fake-access',
              'refresh_token': 'fake-refresh',
            }), 200);
          case '/api/v1/me':
            return http.Response(jsonEncode({
              'id': 'fake-account',
              'email': 'demo-android@example.com',
              'first_name': 'Praticien',
              'last_name': 'Fictif',
              'phone': '',
              'specialty': '',
            }), 200);
        }
        return http.Response('{}', 404);
      }),
    );
    addTearDown(api.close);
    DevSession? authenticated;
    await tester.pumpWidget(MaterialApp(
      theme: MediTheme.dark(),
      home: OriginalAccountAccessScreen(
        api: api,
        isRegister: true,
        onBack: () {},
        onToggle: () {},
        onAuthenticated: (session) => authenticated = session,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sandbox-invite-code')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('dev-register-first-name')), 'Praticien');
    await tester.enterText(
      find.byKey(const Key('dev-register-last-name')), 'Fictif');
    await tester.enterText(
      find.byKey(const Key('dev-auth-email')), 'demo-android@example.com');
    await tester.enterText(
      find.byKey(const Key('dev-auth-password')),
      'Synthetic-staging-password-2026');
    await tester.enterText(
      find.byKey(const Key('sandbox-invite-code')), invite);
    await tester.ensureVisible(find.byKey(const Key('dev-auth-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dev-auth-submit')));
    await tester.pumpAndSettle();

    expect(authenticated?.practitioner.id, 'fake-account');
    expect(requests.length, 3);
    expect(requests.first.headers['x-medisuivi-sandbox-invite'], invite);
    expect(requests[1].headers.containsKey('x-medisuivi-sandbox-invite'),
        false);
    expect(requests[2].headers.containsKey('x-medisuivi-sandbox-invite'),
        false);
    expect(requests.first.body.contains(invite), false,
        reason: 'Invitation may only be in the HTTPS request header.');
    expect(tester.takeException(), isNull);
  });

  testWidgets('P5.0 invite is never shown on existing account login',
      (tester) async {
    final api = DevAuthApi(
      Uri.parse('https://medisuivi-api-staging.onrender.com'));
    addTearDown(api.close);
    await tester.pumpWidget(MaterialApp(
      theme: MediTheme.light(),
      home: OriginalAccountAccessScreen(
        api: api, isRegister: false,
        onBack: () {}, onToggle: () {}, onAuthenticated: (_) {},
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sandbox-invite-code')), findsNothing);
    expect(find.byKey(const Key('dev-auth-password')), findsOneWidget);
  });
}
