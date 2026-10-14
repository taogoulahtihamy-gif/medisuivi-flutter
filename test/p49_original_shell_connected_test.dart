import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medisuivi/app/medisuivi_app.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/core/state/demo_store.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';
import 'package:medisuivi/features/auth/original_connected_clinical_gate.dart';

void main() {
  testWidgets('P4.9 MainShell original shows only authenticated API patients',
      (tester) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final demo = DemoStore(); // deliberately seeded, must never be selected.
    addTearDown(demo.dispose);
    final api = DevAuthApi(Uri.parse('https://medisuivi-ci.invalid'),
      client: MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer only-account-A');
        if (request.url.path == '/api/v1/patients') {
          return http.Response(jsonEncode([
            {'id':'remote-A', 'display_name':'PATIENT FICTIF SERVEUR A',
             'age':29},
          ]), 200);
        }
        if (request.url.path.startsWith('/api/v1/patients/remote-A/')) {
          return http.Response('[]', 200);
        }
        return http.Response('{}', 404);
      }),
    );
    addTearDown(api.close);
    final session = DevSession(
      practitioner: const DevPractitioner(
        id: 'account-A', email: 'a@medisuvi-ci.org',
        firstName: 'Compte', lastName: 'Fictif',
      ),
      accessToken: 'only-account-A',
    );

    await tester.pumpWidget(DemoScope(
      store: demo,
      child: MaterialApp(
        theme: MediTheme.light(),
        home: OriginalConnectedClinicalGate(
          api: api, session: session, onSignedOut: () {},
          child: const MainShell(),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('medisuivi-home')), findsOneWidget);
    expect(find.text('PATIENT FICTIF SERVEUR A'), findsWidgets);
    expect(find.byKey(const Key('original-connected-signout')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
