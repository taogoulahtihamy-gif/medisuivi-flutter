import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';
import 'package:medisuivi/features/auth/dev_patient_detail.dart';

void main() {
  testWidgets('P4.3 displays API vitals and sends remote followup reschedule',
      (tester) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String scheduled = '2026-11-03T08:00:00Z';
    var reschedules = 0;
    final api = DevAuthApi(Uri.parse('http://127.0.0.1:8027'),
      client: MockClient((request) async {
        if (request.headers['authorization'] != 'Bearer A-token') {
          return http.Response('{}', 401);
        }
        final path = request.url.path;
        if (path.endsWith('/visits')) {
          return http.Response(jsonEncode([{
            'id': 'visit-1',
            'reason': 'Contrôle clinique fictif avec constantes',
            'created_at': '2026-10-14T12:00:00Z',
            'temperature': 36.8, 'systolic': 120, 'diastolic': 80,
            'pulse': 72, 'spo2': 98,
          }]), 200);
        }
        if (path.endsWith('/exams')) return http.Response('[]', 200);
        if (path.endsWith('/followups')) {
          return http.Response(jsonEncode([{
            'id': 'follow-1', 'reason': 'Contrôle fictif',
            'status': 'planned', 'scheduled_at': scheduled,
          }]), 200);
        }
        if (path.endsWith('/followups/follow-1/reschedule')) {
          expect(request.method, 'PUT');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['reason'], 'Contrôle fictif');
          scheduled = body['scheduled_at'] as String;
          reschedules++;
          return http.Response('{}', 200);
        }
        return http.Response('{}', 404);
      }));

    await tester.pumpWidget(MaterialApp(
      theme: MediTheme.light(),
      home: DevPatientDetail(
        api: api,
        session: DevSession(
          practitioner: const DevPractitioner(
            id: 'A', email: 'a@medisuvi-ci.org',
            firstName: 'A', lastName: 'Fictif'),
          accessToken: 'A-token',
        ),
        patient: const DevPatient(
          id: 'patient-a', displayName: 'PATIENT FICTIF A', age: 32),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('36.8 °C'), findsOneWidget);
    expect(find.textContaining('120/80 mmHg'), findsOneWidget);

    await tester.tap(find.text('Suivi'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dev-followup-options-follow-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reporter de 7 jours'));
    await tester.pumpAndSettle();

    expect(reschedules, 1);
    expect(DateTime.parse(scheduled), DateTime.utc(2026, 11, 10, 8));
    expect(tester.takeException(), isNull);
    api.close();
  });
}
