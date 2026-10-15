import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/core/state/demo_store.dart';
import 'package:medisuivi/core/state/store_context.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';
import 'package:medisuivi/features/auth/original_connected_clinical_gate.dart';
import 'package:medisuivi/features/settings/settings_screen.dart';

void main() {
  for (final offline in [false, true]) {
    testWidgets(
        'P5.3 secondary settings logout locks immediately offline=$offline',
        (tester) async {
      final revoke = Completer<http.Response>();
      var calls = 0;
      final api = DevAuthApi(Uri.parse('https://synthetic.invalid'),
          client: MockClient((request) async {
        if (request.url.path.endsWith('/logout')) {
          calls++;
          return revoke.future;
        }
        if (request.url.path == '/api/v1/patients') {
          return http.Response(
              jsonEncode([
                {'id': 'A', 'display_name': 'PATIENT FICTIF A', 'age': 30}
              ]),
              200);
        }
        return http.Response('[]', 200);
      }));
      addTearDown(api.close);
      final session = DevSession(
          practitioner: const DevPractitioner(
              id: 'A',
              email: 'demo-a@example.com',
              firstName: 'Compte',
              lastName: 'Fictif'),
          accessToken: 'synthetic-A');
      var signedOut = false;
      await tester.pumpWidget(MaterialApp(
          theme: MediTheme.light(),
          home: StatefulBuilder(
              builder: (context, change) => signedOut
                  ? const Scaffold(body: Text('Connexion'))
                  : OriginalConnectedClinicalGate(
                      api: api,
                      session: session,
                      onSignedOut: () => change(() => signedOut = true),
                      child: Builder(
                          builder: (context) => Scaffold(
                                  body: Column(children: [
                                Text(context.store.patients.first.name),
                                TextButton(
                                    onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                            builder: (_) =>
                                                const SettingsScreen())),
                                    child: const Text('Paramètres')),
                              ]))),
                    ))));
      await tester.pumpAndSettle();
      expect(find.text('PATIENT FICTIF A'), findsOneWidget);
      await tester.tap(find.text('Paramètres'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
          find.byKey(const Key('settings-signout')), 300);
      final action = tester
          .widget<ListTile>(find.byKey(const Key('settings-signout')))
          .onTap!;
      action();
      action();
      await tester.pump();
      expect(calls, 1);
      expect(find.byKey(const Key('account-signing-out')), findsOneWidget);
      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.text('PATIENT FICTIF A'), findsNothing);
      if (offline) {
        revoke.completeError(http.ClientException('offline'));
      } else {
        revoke.complete(http.Response('', 204));
      }
      await tester.pumpAndSettle();
      expect(session.isActive, isFalse);
      expect(find.text('Connexion'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('PATIENT FICTIF A'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('P5.3 unauthenticated demo has no signout action',
      (tester) async {
    final demo = DemoStore();
    addTearDown(demo.dispose);
    await tester.pumpWidget(DemoScope(
        store: demo,
        child: MaterialApp(
            theme: MediTheme.light(), home: const SettingsScreen())));
    await tester.pumpAndSettle();
    await tester.drag(
        find.byKey(const Key('settings-page-list')), const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-signout')), findsNothing);
  });
}
