import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';

void main() {
  test('P4.3 reads clinical API JSON with vitals, results and followup status',
      () async {
    final calls = <http.Request>[];
    final api = DevAuthApi(Uri.parse('http://127.0.0.1:8027'),
      client: MockClient((r) async {
        calls.add(r);
        if (r.headers['authorization'] != 'Bearer practitioner-A') {
          return http.Response('{}', 401);
        }
        if (r.url.path.endsWith('/visits') && r.method == 'GET') {
          return http.Response(jsonEncode([{
            'id': 'visit-1', 'reason': 'Contrôle fictif',
            'created_at': '2026-10-14T12:00:00Z',
            'temperature': 36.8, 'systolic': 120, 'diastolic': 80,
            'pulse': 72, 'spo2': 98,
          }]), 200);
        }
        if (r.url.path.endsWith('/exams') && r.method == 'GET') {
          return http.Response(jsonEncode([{
            'id': 'exam-1', 'title': 'Examen fictif', 'status': 'complete',
            'result': 'Résultat de démonstration sans valeur médicale',
            'result_recorded_at': '2026-10-14T13:00:00Z',
          }]), 200);
        }
        if (r.url.path.endsWith('/followups') && r.method == 'GET') {
          return http.Response(jsonEncode([{
            'id': 'follow-1', 'reason': 'Contrôle fictif', 'status': 'planned',
            'scheduled_at': '2026-10-21T10:00:00Z',
          }]), 200);
        }
        return http.Response('{}', 200);
      }));
    final session = DevSession(
      practitioner: const DevPractitioner(
        id: 'owner-A', email: 'a@medisuvi-ci.org',
        firstName: 'A', lastName: 'Fictif'),
      accessToken: 'practitioner-A',
    );
    const patient = DevPatient(
      id: 'patient-A', displayName: 'PATIENT FICTIF A', age: 30);
    final bundle = await api.getPatientClinical(session, patient);
    expect(bundle.visits.single.temperature, 36.8);
    expect(bundle.visits.single.systolic, 120);
    expect(bundle.visits.single.spo2, 98);
    expect(bundle.exams.single.result,
      'Résultat de démonstration sans valeur médicale');
    expect(bundle.exams.single.resultRecordedAt, isNotNull);
    expect(bundle.followUps.single.scheduledAt.year, 2026);

    await api.createSyntheticVisit(session, patient, withVitals: true);
    final post = calls.last;
    expect(post.method, 'POST');
    final payload = jsonDecode(post.body) as Map<String, dynamic>;
    expect(payload['temperature'], 36.8);
    expect(payload['spo2'], 98);
    expect(payload['reason'], contains('fictif'));
    expect(post.headers['authorization'], 'Bearer practitioner-A');
    api.close();
  });

  test('P4.3 followup reschedule and cancellation use remote authenticated PUT',
      () async {
    final calls = <http.Request>[];
    final api = DevAuthApi(Uri.parse('http://127.0.0.1:8027'),
      client: MockClient((r) async {
        calls.add(r);
        return http.Response('{}', 200);
      }));
    final session = DevSession(
      practitioner: const DevPractitioner(
        id: 'A', email: 'a@medisuvi-ci.org',
        firstName: 'A', lastName: 'Fictif'),
      accessToken: 'token-A',
    );
    final follow = DevFollowUp(
      id: 'follow-A', reason: 'Contrôle fictif', status: 'planned',
      scheduledAt: DateTime.utc(2026, 11, 1, 8),
    );
    await api.rescheduleSyntheticFollowUp(session, follow);
    await api.cancelSyntheticFollowUp(session, follow);
    expect(calls.map((r) => r.url.path), [
      '/api/v1/followups/follow-A/reschedule',
      '/api/v1/followups/follow-A/close',
    ]);
    expect(DateTime.parse((jsonDecode(calls.first.body)
        as Map<String, dynamic>)['scheduled_at'] as String),
      DateTime.utc(2026, 11, 8, 8));
    expect((jsonDecode(calls.last.body) as Map<String, dynamic>)['completed'],
      false);
    expect(calls.every((r) =>
      r.headers['authorization'] == 'Bearer token-A'), isTrue);
    api.close();
  });
}
