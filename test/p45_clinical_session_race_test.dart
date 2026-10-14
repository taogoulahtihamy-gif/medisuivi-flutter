import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';

DevSession fakeSession(String owner, String token) => DevSession(
  practitioner: DevPractitioner(
    id: owner,
    email: '$owner@medisuvi-ci.org',
    firstName: 'Praticien',
    lastName: 'Fictif',
  ),
  accessToken: token,
);

void main() {
  test('P4.5 clinical replies from logged-out A cannot contaminate B', () async {
    final startedA = Completer<void>();
    final delayedA = Completer<http.Response>();
    final calls = <String>[];

    final api = DevAuthApi(
      Uri.parse('https://medisuivi-staging.invalid'),
      client: MockClient((request) async {
        final auth = request.headers['authorization'];
        final path = request.url.path;
        calls.add('$auth:$path');

        if (auth == 'Bearer token-A' &&
            path == '/api/v1/patients/patient-A/visits') {
          startedA.complete();
          return delayedA.future;
        }

        if (auth == 'Bearer token-B' &&
            path.startsWith('/api/v1/patients/patient-B/')) {
          if (path.endsWith('/visits')) {
            return http.Response(jsonEncode([{
              'id': 'visit-B', 'reason': 'Visite synthétique B',
              'created_at': '2026-10-14T12:00:00Z',
            }]), 200);
          }
          if (path.endsWith('/exams')) {
            return http.Response(jsonEncode([{
              'id': 'exam-B', 'title': 'Examen fictif B',
              'status': 'pending', 'result': null,
            }]), 200);
          }
          if (path.endsWith('/followups')) {
            return http.Response(jsonEncode([{
              'id': 'follow-B', 'reason': 'Suivi fictif B',
              'status': 'planned',
              'scheduled_at': '2026-11-14T12:00:00Z',
            }]), 200);
          }
        }

        return http.Response('{}', 401);
      }),
    );

    final sessionA = fakeSession('owner-A', 'token-A');
    final sessionB = fakeSession('owner-B', 'token-B');
    const patientA = DevPatient(
      id: 'patient-A', displayName: 'PATIENT FICTIF A', age: 31,
    );
    const patientB = DevPatient(
      id: 'patient-B', displayName: 'PATIENT FICTIF B', age: 42,
    );

    final staleRequest = api.getPatientClinical(sessionA, patientA);
    final staleRejected = expectLater(
      staleRequest, throwsA(isA<DevApiException>()),
    );
    await startedA.future;

    // Session A is closed while its first HTTP request is in flight.
    sessionA.clear();
    final bundleB = await api.getPatientClinical(sessionB, patientB);
    expect(bundleB.visits.single.id, 'visit-B');
    expect(bundleB.exams.single.id, 'exam-B');
    expect(bundleB.followUps.single.id, 'follow-B');

    // Even a successful late A response cannot deliver A's records.
    delayedA.complete(http.Response(jsonEncode([{
      'id': 'visit-A', 'reason': 'STALE A',
      'created_at': '2026-10-14T12:00:00Z',
    }]), 200));
    await staleRejected;

    expect(calls.where((call) => call.contains('Bearer token-A')).length, 1,
      reason: 'After sign-out, no follow-up A exams/followups calls may run');
    expect(calls.where((call) => call.contains('Bearer token-B')).length, 3);
    api.close();
  });

  test('P4.5 patient register refuses A response after account switch', () async {
    final startedA = Completer<void>();
    final delayedA = Completer<http.Response>();
    final api = DevAuthApi(
      Uri.parse('https://medisuivi-staging.invalid'),
      client: MockClient((request) async {
        if (request.url.path != '/api/v1/patients') {
          return http.Response('{}', 404);
        }
        if (request.headers['authorization'] == 'Bearer token-A') {
          startedA.complete();
          return delayedA.future;
        }
        if (request.headers['authorization'] == 'Bearer token-B') {
          return http.Response(jsonEncode([{
            'id': 'only-B', 'display_name': 'PATIENT FICTIF B', 'age': 42,
          }]), 200);
        }
        return http.Response('{}', 401);
      }),
    );

    final sessionA = fakeSession('owner-A', 'token-A');
    final sessionB = fakeSession('owner-B', 'token-B');

    final staleRequest = api.listPatients(sessionA);
    final staleRejected = expectLater(
      staleRequest, throwsA(isA<DevApiException>()),
    );
    await startedA.future;
    sessionA.clear();

    final current = await api.listPatients(sessionB);
    expect(current.map((patient) => patient.id), ['only-B']);

    delayedA.complete(http.Response(jsonEncode([{
      'id': 'only-A', 'display_name': 'PATIENT FICTIF A', 'age': 31,
    }]), 200));
    await staleRejected;
    api.close();
  });
}
