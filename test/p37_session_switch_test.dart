import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';
import 'package:medisuivi/features/auth/dev_auth_screens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpAuthenticated(
    WidgetTester tester,
    DevAuthApi api,
    DevSession session, {
    required VoidCallback onSignedOut,
  }) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(MaterialApp(
      theme: MediTheme.dark(),
      home: DevConnectedWorkspace(
        api: api, session: session, onSignedOut: onSignedOut),
    ));
    await tester.pumpAndSettle();
  }

  DevSession session() => DevSession(
    practitioner: const DevPractitioner(
      id: 'synthetic-practitioner-a',
      email: 'doctor.a@medisuvi-ci.org',
      firstName: 'Awa', lastName: 'Fictif',
    ),
    accessToken: 'synthetic-access',
    refreshToken: 'synthetic-refresh',
  );

  testWidgets('P3.7: cancel keeps session; confirm revokes all devices',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final calls = <String>[];
    final api = DevAuthApi(Uri.parse('http://127.0.0.1:8027'),
      client: MockClient((request) async {
        calls.add(request.url.path);
        if (request.url.path == '/api/v1/patients') {
          return http.Response('[]', 200);
        }
        if (request.url.path == '/api/v1/auth/logout-all') {
          expect(request.headers['authorization'], 'Bearer synthetic-access');
          return http.Response('', 204);
        }
        return http.Response('{}', 404);
      }));
    final active = session();
    var signedOut = false;
    await pumpAuthenticated(tester, api, active, onSignedOut: () {
      signedOut = true;
    });
    await tester.tap(find.byKey(const Key('dev-session-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Déconnecter tous les appareils'));
    await tester.pumpAndSettle();
    expect(find.text('Déconnecter tous les appareils ?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dev-session-cancel-all')));
    await tester.pumpAndSettle();
    expect(signedOut, isFalse);
    expect(active.accessToken, isNotEmpty);

    await tester.tap(find.byKey(const Key('dev-session-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Déconnecter tous les appareils'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dev-session-confirm-all')));
    await tester.pumpAndSettle();

    expect(signedOut, isTrue);
    expect(active.accessToken, isEmpty);
    expect(active.refreshToken, isEmpty);
    expect(calls.where((p) => p == '/api/v1/auth/logout-all').length, 1);
    expect(tester.takeException(), isNull);
    api.close();
  });

  testWidgets('P3.7: switching practitioner clears only current session',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final calls = <String>[];
    final api = DevAuthApi(Uri.parse('http://127.0.0.1:8027'),
      client: MockClient((request) async {
        calls.add(request.url.path);
        if (request.url.path == '/api/v1/patients') {
          return http.Response('[]', 200);
        }
        if (request.url.path == '/api/v1/auth/logout') {
          return http.Response('', 204);
        }
        return http.Response('{}', 404);
      }));
    final current = session();
    var signedOut = false;
    await pumpAuthenticated(tester, api, current, onSignedOut: () {
      signedOut = true;
    });
    await tester.tap(find.byKey(const Key('dev-session-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Changer de praticien'));
    await tester.pumpAndSettle();
    expect(signedOut, isTrue);
    expect(current.accessToken, isEmpty);
    expect(current.refreshToken, isEmpty);
    expect(calls.where((p) => p == '/api/v1/auth/logout').length, 1);
    expect(calls.where((p) => p == '/api/v1/auth/logout-all'), isEmpty);
    expect(tester.takeException(), isNull);
    api.close();
  });
}
