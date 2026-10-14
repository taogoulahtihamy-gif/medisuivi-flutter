import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';
import 'package:medisuivi/features/auth/dev_email_flows.dart';

void main() {
  test('P4.1 registration requires verification, without creating a session',
      () async {
    var loginCalls = 0;
    final api = DevAuthApi(Uri.parse('http://127.0.0.1:8027'),
      client: MockClient((request) async {
        if (request.url.path == '/api/v1/auth/register') {
          return http.Response(jsonEncode({
            'id':'synthetic-user',
            'email':'fictif@medisuvi-ci.org',
            'email_verification_required':true,
          }), 201);
        }
        if (request.url.path == '/api/v1/auth/login') loginCalls++;
        return http.Response('{}', 500);
      }));
    await expectLater(
      api.createAccount(
        firstName:'Awa',lastName:'Essai',email:'fictif@medisuvi-ci.org',
        password:'synthetic-long-password'),
      throwsA(isA<DevVerificationRequired>()
        .having((e) => e.email, 'email', 'fictif@medisuvi-ci.org')),
    );
    expect(loginCalls, 0);
    api.close();
  });

  testWidgets('P4.1: verify email code and return to connection screen',
      (tester) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var verified = false;
    final requests = <http.Request>[];
    final api = DevAuthApi(Uri.parse('http://127.0.0.1:8027'),
      client: MockClient((request) async {
        requests.add(request);
        return http.Response('', 204);
      }));
    await tester.pumpWidget(MaterialApp(
      theme: MediTheme.dark(),
      home: DevEmailVerificationScreen(
        api: api, email: 'fictif@medisuvi-ci.org',
        onVerified: () => verified = true, onBack: () {},
      ),
    ));
    await tester.enterText(find.byKey(const Key('dev-email-code')), '123');
    await tester.tap(find.byKey(const Key('dev-email-verify')));
    await tester.pumpAndSettle();
    expect(find.text('Saisissez les 12 chiffres du code.'), findsOneWidget);
    expect(requests, isEmpty);

    await tester.enterText(
      find.byKey(const Key('dev-email-code')), '123456789012');
    await tester.tap(find.byKey(const Key('dev-email-verify')));
    await tester.pumpAndSettle();
    expect(verified, isTrue);
    expect(requests.single.url.path, '/api/v1/auth/email/verify');
    expect(jsonDecode(requests.single.body)['code'], '123456789012');
    expect(tester.takeException(), isNull);
    api.close();
  });

  testWidgets('P4.1: recovery sends email, validates and resets password',
      (tester) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var finished = false;
    final requests = <http.Request>[];
    final api = DevAuthApi(Uri.parse('http://127.0.0.1:8027'),
      client: MockClient((request) async {
        requests.add(request);
        return http.Response('', request.url.path.endsWith('/forgot') ? 202 : 204);
      }));
    await tester.pumpWidget(MaterialApp(
      theme: MediTheme.light(),
      home: DevPasswordRecoveryScreen(
        api: api, onFinished: () => finished = true, onBack: () {}),
    ));
    await tester.enterText(
      find.byKey(const Key('dev-reset-email')), 'fictif@medisuvi-ci.org');
    await tester.tap(find.byKey(const Key('dev-reset-submit')));
    await tester.pumpAndSettle();
    expect(requests.single.url.path, '/api/v1/auth/password/forgot');
    expect(find.byKey(const Key('dev-reset-code')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('dev-reset-code')),
      '123456789012');
    await tester.enterText(find.byKey(const Key('dev-reset-password')),
      'synthetic-password-2026');
    await tester.enterText(find.byKey(const Key('dev-reset-confirm')),
      'does-not-match');
    await tester.ensureVisible(find.byKey(const Key('dev-reset-submit')));
    await tester.tap(find.byKey(const Key('dev-reset-submit')));
    await tester.pumpAndSettle();
    expect(requests, hasLength(1));

    await tester.enterText(find.byKey(const Key('dev-reset-confirm')),
      'synthetic-password-2026');
    await tester.tap(find.byKey(const Key('dev-reset-submit')));
    await tester.pumpAndSettle();
    expect(requests, hasLength(2));
    expect(requests.last.url.path, '/api/v1/auth/password/reset');
    expect(finished, isTrue);
    expect(tester.takeException(), isNull);
    api.close();
  });
}
