import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medisuivi/app/medisuivi_app.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/core/state/demo_store.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';
import 'package:medisuivi/features/auth/original_account_access_screen.dart';
import 'package:medisuivi/features/auth/original_connected_clinical_gate.dart';

/// Desktop widget coverage of the same synthetic A/B flow run on Android.
void main() {
  const origin = 'https://medisuivi-api-staging.vercel.app';
  const accountA = 'e36b384a-c5a5-47cc-a40b-ae58ce1d1243';
  const accountB = '47d4d959-3dbe-45e2-a34b-3b9f2ea7f87a';

  testWidgets('original sign-in -> private dossier A -> logout -> dossier B',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
}
