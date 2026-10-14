import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medisuivi/core/state/remote_clinical_store.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';

const ownerA = '1a2a3361-ed2e-4abe-8e55-661bac905148';
const ownerB = '5b60b4f7-3af3-49de-9d25-69d25712e1c5';
const patientA = '1f56ab00-23bd-429f-8c42-7fd4e116a051';

DevSession session(String id, String token) => DevSession(
  practitioner: DevPractitioner(
    id: id, email: '$token@medisuvi-ci.org',
    firstName: 'TEST', lastName: 'FICTIF',
  ),
  accessToken: token,
);

void main() {
  test('P4.9 original ClinicalStore hydrates owner-only visits/exams/followups',
      () async {
    final requests = <http.Request>[];
    final api = DevAuthApi(Uri.parse('https://medisuivi.invalid'),
      client: MockClient((req) async {
        requests.add(req);
        if (req.headers['authorization'] != 'Bearer token-A') {
          return http.Response('{}', 401);
        }
        switch (req.url.path) {
          case '/api/v1/patients':
            return http.Response(jsonEncode([{
              'id': patientA, 'display_name': 'PATIENT FICTIF',
              'age': 27, 'sex': 'F', 'phone': '000000000',
              'allergies': 'AUCUNE', 'medical_history': 'FICTIF',
              'follow_up': true, 'created_at': '2026-10-14T12:00:00Z',
              'profile_json': {
                'neighborhood': 'QUARTIER FICTIF',
                'address': '', 'emergencyContactName': '',
                'emergencyContactPhone': '', 'currentMedications': '',
                'surgicalHistory': '', 'familyHistory': '',
              },
            }]), 200);
          case '/api/v1/patients/$patientA/visits':
            return http.Response(jsonEncode([{
              'id': 'visit-A', 'created_at': '2026-10-14T12:01:00Z',
              'reason': 'CONSULTATION FICTIVE', 'notes': 'NOTE FICTIVE',
              'temperature': 37.0, 'pulse': 73,
              'intake_json': {
                'schemaVersion': 1, 'diagnosis': 'FICTIF',
                'careDisposition': 'undecided',
              },
            }]), 200);
          case '/api/v1/patients/$patientA/exams':
            return http.Response(jsonEncode([{
              'id': 'exam-A', 'title': 'EXAMEN FICTIF',
              'status': 'pending', 'result': null,
              'created_at': '2026-10-14T12:02:00Z',
            }]), 200);
          case '/api/v1/patients/$patientA/followups':
            return http.Response(jsonEncode([{
              'id': 'follow-A', 'reason': 'SUIVI FICTIF',
              'scheduled_at': '2026-11-14T12:00:00Z',
              'status': 'planned', 'notes': 'NOTE FICTIVE',
            }]), 200);
        }
        return http.Response('{}', 404);
      }),
    );
    final s = session(ownerA, 'token-A');
    final store = RemoteClinicalStore(api: api, session: s);
    await store.reload();
    expect(store.ownerUserId, ownerA);
    expect(store.patients.single.id, patientA);
    expect(store.patients.single.name, 'PATIENT FICTIF');
    expect(store.patients.single.sex, 'F');
    expect(store.visitsFor(patientA).single.notes, 'NOTE FICTIVE');
    expect(store.examsFor(patientA).single.title, 'EXAMEN FICTIF');
    expect(store.plannedFollowUps.single.id, 'follow-A');
    expect((await store.patientProfile(patientA))!.neighborhood,
        'QUARTIER FICTIF');
    expect((await store.visitIntake('visit-A'))!.diagnosis, 'FICTIF');
    expect(store.pendingExamsCount, 1);
    expect(await store.pendingSyncCount, 0);
    expect(requests.length, 4);

    // Prevent accidental cross-account mutations before HTTP.
    final callsBefore = requests.length;
    await expectLater(
      store.addExam(patientId: 'not-owned', title: 'INTRUSION'),
      throwsStateError,
    );
    expect(requests.length, callsBefore);

    store.lock();
    expect(store.patients, isEmpty);
    expect(store.visits, isEmpty);
    expect(store.followUps, isEmpty);
    await expectLater(store.reload(), throwsStateError);
    store.dispose();
    api.close();
  });

  test('P4.9 rejected stale A reply cannot populate B cache', () async {
    final waiting = Completer<http.Response>();
    final started = Completer<void>();
    final api = DevAuthApi(Uri.parse('https://medisuivi.invalid'),
      client: MockClient((req) async {
        if (req.headers['authorization'] == 'Bearer token-A') {
          started.complete();
          return waiting.future;
        }
        return http.Response('[]', 200);
      }),
    );
    final a = session(ownerA, 'token-A');
    final b = session(ownerB, 'token-B');
    final storeA = RemoteClinicalStore(api: api, session: a);
    final storeB = RemoteClinicalStore(api: api, session: b);
    final staleLoad = storeA.reload();
    final rejected = expectLater(staleLoad, throwsA(isA<DevApiException>()));
    await started.future;

    storeA.lock();
    a.clear();
    await storeB.reload();
    expect(storeB.patients, isEmpty);

    waiting.complete(http.Response(jsonEncode([{
      'id': patientA, 'display_name': 'STALE A', 'age': 20,
    }]), 200));
    await rejected;
    expect(storeA.patients, isEmpty);
    expect(storeB.patients, isEmpty);
    storeA.dispose();
    storeB.dispose();
    api.close();
  });
}
