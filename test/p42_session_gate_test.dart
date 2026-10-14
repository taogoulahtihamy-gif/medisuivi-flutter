import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';
import 'package:medisuivi/features/auth/dev_session_persistence.dart';
import 'package:medisuivi/features/onboarding/medisuivi_welcome_gate.dart';

const owner = '1a2a3361-ed2e-4abe-8e55-661bac905148';
const endpoint = 'https://medisuivi-staging.invalid';

class InMemoryKeychain implements DevSessionPersistence {
  SavedDevSession? saved;
  int clearCount = 0;
  @override Future<SavedDevSession?> read() async => saved;
  @override Future<void> save(SavedDevSession item) async { saved = item; }
  @override Future<void> clear() async { saved = null; clearCount++; }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {});

  testWidgets('P4.2: restart restores only authenticated workspace, not DemoStore',
      (tester) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = InMemoryKeychain()
      ..saved = const SavedDevSession(api: endpoint,
          ownerId: owner, refreshToken: 'old-refresh');
    final api = DevAuthApi(Uri.parse(endpoint), persistence: storage,
      client: MockClient((request) async {
        if (request.url.path == '/api/v1/auth/refresh') {
          return http.Response(jsonEncode({
            'access_token': 'new-access', 'refresh_token': 'new-refresh',
          }), 200);
        }
        if (request.url.path == '/api/v1/me') {
          return http.Response(jsonEncode({
            'id': owner, 'email': 'test@medisuvi-ci.org',
            'first_name': 'Awa', 'last_name': 'Fictif',
          }), 200);
        }
        if (request.url.path == '/api/v1/patients') {
          return http.Response('[]', 200);
        }
        return http.Response('{}', 404);
      }));
    await tester.pumpWidget(MaterialApp(
      theme: MediTheme.dark(),
      home: MediSuiviWelcomeGate(
        developmentAuthApi: api,
        isWebDemo: true,
        child: const Text('FORBIDDEN SHARED DEMO STORE'),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dev-authenticated-workspace')),
      findsOneWidget);
    expect(find.text('Awa Fictif'), findsOneWidget);
    expect(find.text('FORBIDDEN SHARED DEMO STORE'), findsNothing);
    expect(storage.saved?.refreshToken, 'new-refresh');
    api.close();
  });

  testWidgets('P4.2: offline startup never opens medical workspace;'
      ' user can explicitly clear saved account', (tester) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final storage = InMemoryKeychain()
      ..saved = const SavedDevSession(api: endpoint,
          ownerId: owner, refreshToken: 'valid-but-offline');
    final api = DevAuthApi(Uri.parse(endpoint), persistence: storage,
      client: MockClient((request) async =>
        throw http.ClientException('offline')));
    await tester.pumpWidget(MaterialApp(
      theme: MediTheme.light(),
      home: MediSuiviWelcomeGate(
        developmentAuthApi: api,
        isWebDemo: true,
        child: const Text('FORBIDDEN SHARED DEMO STORE'),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dev-session-restoring')),
      findsOneWidget);
    expect(find.byKey(const ValueKey('dev-authenticated-workspace')),
      findsNothing);
    expect(storage.saved?.refreshToken, 'valid-but-offline');

    await tester.tap(find.byKey(const Key('dev-resume-other-account')));
    await tester.pumpAndSettle();
    expect(storage.saved, isNull);
    expect(find.byKey(const ValueKey('dev-signin')), findsOneWidget);
    expect(find.text('FORBIDDEN SHARED DEMO STORE'), findsNothing);
    api.close();
  });
}
