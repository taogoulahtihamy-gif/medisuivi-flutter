import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';
import 'package:medisuivi/features/auth/dev_change_password.dart';

DevSession _session() => DevSession(
  practitioner: const DevPractitioner(
    id: 'practitioner-synthetic', email: 'alpha@medisuvi-ci.org',
    firstName: 'Awa', lastName: 'Fictif'),
  accessToken: 'synthetic-access-token',
  refreshToken: 'synthetic-refresh-token',
);

void main() {
  test('P3.9: password update sends only current JWT and clears both secrets',
      () async {
    final requests = <http.Request>[];
    final session = _session();
    final api = DevAuthApi(Uri.parse('http://127.0.0.1:8027'),
      client: MockClient((request) async {
        requests.add(request);
        return http.Response('', 204);
      }));
    await api.changePassword(session,
      currentPassword: 'old-synthetic-secret',
      newPassword: 'new-synthetic-secret-2026');
    expect(requests, hasLength(1));
    final request = requests.single;
    expect(request.method, 'PUT');
    expect(request.url.path, '/api/v1/me/password');
    expect(request.headers['authorization'], 'Bearer synthetic-access-token');
    expect(jsonDecode(request.body), {
      'current_password': 'old-synthetic-secret',
      'new_password': 'new-synthetic-secret-2026',
    });
    expect(session.accessToken, isEmpty);
    expect(session.refreshToken, isEmpty);
    await expectLater(api.listPatients(session),
      throwsA(isA<DevApiException>()));
    expect(requests, hasLength(1));
    api.close();
  });

  test('P3.9: failed change never signs user out prematurely', () async {
    final session = _session();
    final api = DevAuthApi(Uri.parse('http://127.0.0.1:8027'),
      client: MockClient((request) async =>
        http.Response(jsonEncode({'detail': 'Incorrect'}), 401)));
    await expectLater(api.changePassword(session,
      currentPassword: 'wrong-synthetic',
      newPassword: 'new-synthetic-secret-2026'),
      throwsA(isA<DevApiException>()));
    expect(session.accessToken, 'synthetic-access-token');
    expect(session.refreshToken, 'synthetic-refresh-token');
    api.close();
  });

  testWidgets('P3.9: password form confirms change and exits to login',
      (tester) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var calls = 0;
    var signedOut = false;
    final session = _session();
    final api = DevAuthApi(Uri.parse('http://127.0.0.1:8027'),
      client: MockClient((request) async {
        calls++;
        expect(request.url.path, '/api/v1/me/password');
        return http.Response('', 204);
      }));

    await tester.pumpWidget(MaterialApp(
      theme: MediTheme.light(),
      home: DevChangePasswordScreen(
        api: api, session: session,
        onPasswordChanged: () => signedOut = true),
    ));
    await tester.enterText(find.byKey(const Key('dev-password-current')),
      'old-synthetic-password');
    await tester.enterText(find.byKey(const Key('dev-password-new')),
      'short');
    await tester.enterText(find.byKey(const Key('dev-password-confirm')),
      'short');
    await tester.ensureVisible(find.byKey(const Key('dev-password-submit')));
    await tester.tap(find.byKey(const Key('dev-password-submit')));
    await tester.pumpAndSettle();
    expect(find.text('12 caractères minimum'), findsOneWidget);
    expect(calls, 0);

    await tester.enterText(find.byKey(const Key('dev-password-new')),
      'new-synthetic-strong-2026');
    await tester.enterText(find.byKey(const Key('dev-password-confirm')),
      'different-value');
    await tester.tap(find.byKey(const Key('dev-password-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Les deux mots de passe sont différents'), findsOneWidget);
    expect(calls, 0);

    await tester.enterText(find.byKey(const Key('dev-password-confirm')),
      'new-synthetic-strong-2026');
    await tester.tap(find.byKey(const Key('dev-password-submit')));
    await tester.pumpAndSettle();
    expect(signedOut, isTrue);
    expect(session.accessToken, isEmpty);
    expect(session.refreshToken, isEmpty);
    expect(calls, 1);
    expect(tester.takeException(), isNull);
    api.close();
  });
}
