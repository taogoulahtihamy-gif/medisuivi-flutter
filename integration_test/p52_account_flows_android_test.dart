import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:medisuivi/app/medisuivi_app.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/core/state/demo_store.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';
import 'package:medisuivi/features/auth/dev_session_persistence.dart';
import 'package:medisuivi/features/auth/original_account_access_screen.dart';
import 'package:medisuivi/features/auth/original_connected_clinical_gate.dart';

/// P5.2 runs on real Android emulators. The identity and clinical data in the
/// first test are HTTP mocks, NOT writes to the publicly hosted Neon database.
/// The second test uses the REAL Android secure-storage plugin / Keystore.
/// The final test probes the public Vercel API with unauthorized requests only.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const origin = 'https://medisuivi-api-staging.vercel.app';
  const accountA = 'e36b384a-c5a5-47cc-a40b-ae58ce1d1243';
  const accountB = '47d4d959-3dbe-45e2-a34b-3b9f2ea7f87a';

  testWidgets('original sign-in -> private dossier A -> logout -> dossier B',
      (tester) async {
    final demo = DemoStore(); // Should never leak into connected accounts.
    addTearDown(demo.dispose);
    final patientTokens = <String>[];

    final api =
        DevAuthApi(Uri.parse(origin), client: MockClient((request) async {
      final path = request.url.path;
      final bearer = request.headers['authorization'] ?? '';
      if (path == '/api/v1/auth/login') {
        final data = jsonDecode(request.body) as Map<String, dynamic>;
        final isA = data['email'] == 'demo-account-a@example.com';
        final isB = data['email'] == 'demo-account-b@example.com';
        if (!isA && !isB) return http.Response('{}', 401);
        return http.Response(
            jsonEncode({
              'access_token': isA ? 'token-A' : 'token-B',
              'refresh_token': isA ? 'refresh-A' : 'refresh-B',
            }),
            200);
      }
      if (path == '/api/v1/me') {
        final isA = bearer == 'Bearer token-A';
        final isB = bearer == 'Bearer token-B';
        if (!isA && !isB) return http.Response('{}', 401);
        return http.Response(
            jsonEncode({
              'id': isA ? accountA : accountB,
              'email': isA
                  ? 'demo-account-a@example.com'
                  : 'demo-account-b@example.com',
              'first_name': 'Compte',
              'last_name': isA ? 'Alpha' : 'Beta',
              'phone': '',
              'specialty': '',
            }),
            200);
      }
      if (path == '/api/v1/patients') {
        patientTokens.add(bearer);
        if (bearer == 'Bearer token-A') {
          return http.Response(
              jsonEncode([
                {
                  'id': 'fictif-A',
                  'display_name': 'PATIENT FICTIF ALPHA',
                  'age': 26
                },
              ]),
              200);
        }
        if (bearer == 'Bearer token-B') {
          return http.Response(
              jsonEncode([
                {
                  'id': 'fictif-B',
                  'display_name': 'PATIENT FICTIF BETA',
                  'age': 33
                },
              ]),
              200);
        }
        return http.Response('{}', 401);
      }
      if (path == '/api/v1/auth/logout') {
        return http.Response(
            '',
            bearer == 'Bearer token-A' || bearer == 'Bearer token-B'
                ? 204
                : 401);
      }
      if (path.startsWith('/api/v1/patients/')) {
        return http.Response('[]', 200);
      }
      return http.Response('{}', 404);
    }));
    addTearDown(api.close);

    DevSession? current;
    await tester.pumpWidget(DemoScope(
      store: demo,
      child: MaterialApp(
        theme: MediTheme.light(),
        home: StatefulBuilder(builder: (context, change) {
          if (current == null) {
            return OriginalAccountAccessScreen(
              api: api,
              isRegister: false,
              onBack: () {},
              onToggle: () {},
              onAuthenticated: (session) => change(() => current = session),
            );
          }
          return OriginalConnectedClinicalGate(
            key: ValueKey(current!.practitioner.id),
            api: api,
            session: current!,
            onSignedOut: () => change(() => current = null),
            child: const MainShell(),
          );
        }),
      ),
    ));
    await tester.pumpAndSettle();

    Future<void> signIn(String email) async {
      await tester.enterText(find.byKey(const Key('dev-auth-email')), email);
      await tester.enterText(
          find.byKey(const Key('dev-auth-password')), 'Synthetic-only-2026');
      await tester.ensureVisible(find.byKey(const Key('dev-auth-submit')));
      await tester.tap(find.byKey(const Key('dev-auth-submit')));
      await tester.pumpAndSettle(const Duration(milliseconds: 250));
    }

    await signIn('demo-account-a@example.com');
    expect(find.byKey(const Key('medisuivi-home')), findsOneWidget);
    expect(find.text('PATIENT FICTIF ALPHA'), findsWidgets);
    expect(find.text('PATIENT FICTIF BETA'), findsNothing);
    expect(current?.practitioner.id, accountA);

    await tester.tap(find.text('Réglages'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const Key('settings-signout')), 300);
    await tester.tap(find.byKey(const Key('settings-signout')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dev-auth-email')), findsOneWidget);
    expect(find.text('PATIENT FICTIF ALPHA'), findsNothing);
    expect(current, isNull);

    await signIn('demo-account-b@example.com');
    expect(find.byKey(const Key('medisuivi-home')), findsOneWidget);
    expect(find.text('PATIENT FICTIF BETA'), findsWidgets);
    expect(find.text('PATIENT FICTIF ALPHA'), findsNothing);
    expect(current?.practitioner.id, accountB);
    expect(patientTokens,
        containsAllInOrder(['Bearer token-A', 'Bearer token-B']));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Android Keystore retains only refresh + owner and erases on logout',
      (tester) async {
    final persistence = MobileDevSessionPersistence();
    // Fresh CI emulator; this is a synthetic value, NEVER a real JWT.
    await persistence.clear();
    addTearDown(() async => persistence.clear());

    final first = const SavedDevSession(
      api: origin,
      ownerId: accountA,
      refreshToken: 'synthetic-rotating-refresh-A',
    );
    await persistence.save(first);
    final readA = await persistence.read();
    expect(readA?.ownerId, accountA);
    expect(readA?.refreshToken, first.refreshToken);
    expect(readA?.api, origin);
    expect(jsonEncode(readA?.toJson()), isNot(contains('patient')));
    expect(jsonEncode(readA?.toJson()), isNot(contains('password')));

    await persistence.save(const SavedDevSession(
      api: origin,
      ownerId: accountB,
      refreshToken: 'synthetic-rotating-refresh-B',
    ));
    final readB = await persistence.read();
    expect(readB?.ownerId, accountB);
    expect(readB?.refreshToken, 'synthetic-rotating-refresh-B');
    expect(readB?.refreshToken, isNot(first.refreshToken));
    await persistence.clear();
    expect(await persistence.read(), isNull);
  });

  testWidgets(
      'Vercel rejects uninvited signup from Android without creating user',
      (tester) async {
    const configured = String.fromEnvironment('MEDISUIVI_DEV_API_BASE_URL');
    expect(configured, origin);
    final client = http.Client();
    try {
      // No invitation, fake address, no real account created.
      final response = await client
          .post(
            Uri.parse('$origin/api/v1/auth/register'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': 'demo-no-invite@example.com',
              'password': 'Do-not-create-this-account-2026',
              'first_name': 'Essai',
              'last_name': 'Fictif',
            }),
          )
          .timeout(const Duration(seconds: 45));
      expect(response.statusCode, 403,
          reason: 'Public sandbox must reject registration without invite.');

      final private = await client.get(
        Uri.parse('$origin/api/v1/patients'),
        headers: const {'Authorization': 'Bearer invalid-synthetic-token'},
      ).timeout(const Duration(seconds: 45));
      expect([401, 403], contains(private.statusCode));
    } finally {
      client.close();
    }
  });
}
