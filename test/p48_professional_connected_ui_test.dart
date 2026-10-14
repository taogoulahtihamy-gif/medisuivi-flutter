import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';
import 'package:medisuivi/features/auth/dev_auth_screens.dart';

DevSession _session(String owner) => DevSession(
  practitioner: DevPractitioner(
    id: 'owner-$owner', email: '$owner@medisuvi-ci.org',
    firstName: 'Praticien', lastName: owner,
  ),
  accessToken: 'token-$owner',
);

void main() {
  testWidgets('P4.8 dashboard and followups are loaded from signed-in API',
      (tester) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final requests = <http.Request>[];
    final api = DevAuthApi(Uri.parse('https://medisuivi-staging.invalid'),
      client: MockClient((request) async {
        requests.add(request);
        if (request.headers['authorization'] != 'Bearer token-A') {
          return http.Response('{}', 401);
        }
        final path = request.url.path;
        if (path == '/api/v1/patients') {
          return http.Response(jsonEncode([
            {'id': 'patient-A', 'display_name': 'PATIENT FICTIF A',
              'age': 37},
          ]), 200);
        }
        if (path.endsWith('/visits') || path.endsWith('/exams')) {
          return http.Response('[]', 200);
        }
        if (path.endsWith('/followups')) {
          return http.Response(jsonEncode([
            {'id': 'follow-A', 'reason': 'Rendez-vous de test',
             'status': 'planned',
             'scheduled_at': '2026-11-14T12:00:00Z'},
          ]), 200);
        }
        return http.Response('{}', 404);
      }),
    );

    await tester.pumpWidget(MaterialApp(
      theme: MediTheme.dark(),
      home: DevConnectedWorkspace(
        api: api, session: _session('A'), onSignedOut: () {}),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dev-summary-patient-count')), findsOneWidget);
    expect(find.text('PATIENT FICTIF A'), findsOneWidget);
    expect(find.byKey(const Key('dev-connected-navigation')), findsOneWidget);
    expect(find.byKey(const Key('dev-nav-home')), findsOneWidget);
    expect(find.byKey(const Key('dev-nav-patients')), findsOneWidget);

    await tester.tap(find.byKey(const Key('dev-nav-followups')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dev-tab-followups')), findsOneWidget);
    expect(find.text('Rendez-vous de test'), findsOneWidget);
    expect(find.byKey(const Key('dev-open-followup-follow-A')),
      findsOneWidget);
    expect(requests.every((request) =>
      request.headers['authorization'] == 'Bearer token-A'), isTrue);

    await tester.tap(find.byKey(const Key('dev-nav-account')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dev-account-edit')), findsOneWidget);
    expect(find.byKey(const Key('dev-account-switch')), findsOneWidget);
    expect(tester.takeException(), isNull);
    api.close();
  });

  testWidgets('P4.8 switching user in the same widget discards stale list',
      (tester) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final startedA = Completer<void>();
    final delayedA = Completer<http.Response>();
    final api = DevAuthApi(Uri.parse('https://medisuivi-staging.invalid'),
      client: MockClient((request) async {
        if (request.url.path != '/api/v1/patients') {
          return http.Response('{}', 404);
        }
        if (request.headers['authorization'] == 'Bearer token-A') {
          startedA.complete();
          return delayedA.future;
        }
        if (request.headers['authorization'] == 'Bearer token-B') {
          return http.Response(jsonEncode([
            {'id': 'patient-B', 'display_name': 'PATIENT FICTIF B',
             'age': 39},
          ]), 200);
        }
        return http.Response('{}', 401);
      }),
    );

    const slot = ValueKey('connected-slot');
    await tester.pumpWidget(MaterialApp(
      theme: MediTheme.light(),
      home: DevConnectedWorkspace(
        key: slot, api: api, session: _session('A'),
        onSignedOut: () {}),
    ));
    await startedA.future;

    await tester.pumpWidget(MaterialApp(
      theme: MediTheme.light(),
      home: DevConnectedWorkspace(
        key: slot, api: api, session: _session('B'),
        onSignedOut: () {}),
    ));
    await tester.pumpAndSettle();
    expect(find.text('PATIENT FICTIF B'), findsOneWidget);
    expect(find.text('PATIENT FICTIF A'), findsNothing);
    expect(find.text('Praticien B'), findsOneWidget);

    // A's late response must not replace B's already authenticated list.
    delayedA.complete(http.Response(jsonEncode([
      {'id': 'patient-A', 'display_name': 'PATIENT FICTIF A',
        'age': 30},
    ]), 200));
    await tester.pumpAndSettle();
    expect(find.text('PATIENT FICTIF B'), findsOneWidget);
    expect(find.text('PATIENT FICTIF A'), findsNothing);
    expect(tester.takeException(), isNull);
    api.close();
  });
}
