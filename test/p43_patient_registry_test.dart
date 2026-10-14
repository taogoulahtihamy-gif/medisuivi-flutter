import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';
import 'package:medisuivi/features/auth/dev_auth_screens.dart';

void main() {
  testWidgets('P4.3 patient register searches only authenticated API rows',
      (tester) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final requests = <http.Request>[];
    final api = DevAuthApi(Uri.parse('http://127.0.0.1:8027'),
      client: MockClient((request) async {
        requests.add(request);
        if (request.headers['authorization'] != 'Bearer practitioner-A') {
          return http.Response('{}', 401);
        }
        if (request.url.path == '/api/v1/patients') {
          return http.Response(jsonEncode([
            {'id': 'a1', 'display_name': 'PATIENT FICTIF ALPHA', 'age': 33},
            {'id': 'a2', 'display_name': 'PATIENT FICTIF BETA', 'age': 44},
          ]), 200);
        }
        return http.Response('{}', 404);
      }));
    final session = DevSession(
      practitioner: const DevPractitioner(
        id: 'owner-A', email: 'a@medisuvi-ci.org',
        firstName: 'A', lastName: 'Fictif'),
      accessToken: 'practitioner-A',
    );
    await tester.pumpWidget(MaterialApp(
      theme: MediTheme.light(),
      home: DevConnectedWorkspace(
        api: api, session: session, onSignedOut: () {}),
    ));
    await tester.pumpAndSettle();
    expect(find.text('PATIENT FICTIF ALPHA'), findsOneWidget);
    expect(find.text('PATIENT FICTIF BETA'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('dev-search-patients')), 'beta');
    await tester.pumpAndSettle();
    expect(find.text('PATIENT FICTIF ALPHA'), findsNothing);
    expect(find.text('PATIENT FICTIF BETA'), findsOneWidget);
    expect(find.text('1 dossier(s) fictif(s)'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('dev-search-patients')), 'absent');
    await tester.pumpAndSettle();
    expect(find.text('Aucun dossier fictif ne correspond à cette recherche.'),
      findsOneWidget);
    expect(requests.length, 1,
      reason: 'Searching must not trigger extra API calls or load shared demo data');
    expect(tester.takeException(), isNull);
    api.close();
  });
}
