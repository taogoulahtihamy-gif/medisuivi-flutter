import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medisuivi/core/state/connected_clinical_store.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';

DevSession session(String owner) => DevSession(
  practitioner: DevPractitioner(
    id: owner, email: '$owner@medisuvi-ci.org',
    firstName: 'Compte', lastName: owner,
  ),
  accessToken: 'token-$owner',
);

void main() {
  test('original ClinicalStore loads patients, visits, exams, followups',
      () async {
    final calls = <http.Request>[];
    final api = DevAuthApi(Uri.parse('https://medisuivi-staging.invalid'),
      client: MockClient((req) async {
        calls.add(req);
        if (req.headers['authorization'] != 'Bearer token-A') {
          return http.Response('{}', 401);
        }
        final path = req.url.path;
        if (path == '/api/v1/patients') {
          return http.Response(jsonEncode([
            {'id': 'patient-A', 'display_name': 'PATIENT FICTIF A', 'age': 41},
          ]), 200);
        }
        if (path.endsWith('/visits')) {
          return http.Response(jsonEncode([
            {'id': 'visit-A', 'reason': 'Consultation fictive',
             'created_at': '2026-10-14T12:00:00Z',
             'temperature': 37, 'pulse': 77},
          ]), 200);
        }
        if (path.endsWith('/exams')) {
          return http.Response(jsonEncode([
            {'id': 'exam-A', 'title': 'Examen fictif',
             'status': 'pending'},
          ]), 200);
        }
        if (path.endsWith('/followups')) {
          return http.Response(jsonEncode([
            {'id': 'followup-A', 'reason': 'Suivi fictif',
             'status': 'planned',
             'scheduled_at': '2026-11-14T12:00:00Z'},
          ]), 200);
        }
        return http.Response('{}', 404);
      }),
    );
    final store = ConnectedClinicalStore(api, session('A'));
    expect(store.patients, isEmpty);
    await store.refresh();
    expect(store.loaded, isTrue);
    expect(store.patients.single.name, 'PATIENT FICTIF A');
    expect(store.lastVisitFor('patient-A')?.pulse, 77);
    expect(store.pendingExamsCount, 1);
    expect(store.followUpsFor('patient-A').single.reason, 'Suivi fictif');
    expect(store.followUpPatients.single.id, 'patient-A');
    expect(calls.length, 4);
    store.dispose();
    expect(store.patients, isEmpty);
    api.close();
  });

  test('failed server request cannot expose a partially loaded account',
      () async {
    final api = DevAuthApi(Uri.parse('https://medisuivi-staging.invalid'),
      client: MockClient((request) async {
        if (request.url.path == '/api/v1/patients') {
          return http.Response(jsonEncode([
            {'id': 'patient-A', 'display_name': 'PATIENT FICTIF A', 'age': 30},
          ]), 200);
        }
        return http.Response('{}', 503);
      }),
    );
    final store = ConnectedClinicalStore(api, session('A'));
    await expectLater(store.refresh(), throwsA(isA<DevApiException>()));
    expect(store.loaded, isFalse);
    expect(store.patients, isEmpty);
    expect(store.visits, isEmpty);
    expect(store.exams, isEmpty);
    expect(store.followUps, isEmpty);
    store.dispose();
    api.close();
  });

  test('late response cannot reopen data after account signout', () async {
    final entered = Completer<void>();
    final delayed = Completer<http.Response>();
    final api = DevAuthApi(Uri.parse('https://medisuivi-staging.invalid'),
      client: MockClient((request) async {
        entered.complete();
        return delayed.future;
      }),
    );
    final user = session('A');
    final store = ConnectedClinicalStore(api, user);
    final refresh = store.refresh();
    final rejected = expectLater(refresh, throwsA(isA<Object>()));
    await entered.future;
    user.clear();
    store.lock();
    delayed.complete(http.Response(jsonEncode([
      {'id': 'patient-A', 'display_name': 'PATIENT FICTIF A', 'age': 30},
    ]), 200));
    await rejected;
    expect(store.patients, isEmpty);
    expect(store.loaded, isFalse);
    store.dispose();
    api.close();
  });
}
