import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';
import 'package:medisuivi/features/auth/dev_patient_detail.dart';

void main() {
  const practitioner = DevPractitioner(
    id: 'alpha-owner', email: 'alpha@medisuvi-ci.org',
    firstName: 'Awa', lastName: 'Fictive');
  const session = DevSession(
    practitioner: practitioner, accessToken: 'valid-account-alpha');
  const patient = DevPatient(
    id: 'patient-alpha', displayName: 'PATIENT FICTIF A', age: 30);

  testWidgets('P3.3 : dossier patient authentifié, trois modules et actions',
      (tester) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final calls = <http.Request>[];
    var hasVisit = false;
    var hasExam = false;
    var examCompleted = false;
    var hasFollowUp = false;
    var followUpCompleted = false;

    final api = DevAuthApi(Uri.parse('http://127.0.0.1:8027'),
      client: MockClient((request) async {
        calls.add(request);
        if (request.headers['authorization'] !=
              'Bearer valid-account-alpha') {
          return http.Response('{}', 401);
        }
        if (request.url.path.contains('/patient-beta/')) {
          return http.Response('{}', 404);
        }
        final url = request.url.path;
        if (url.endsWith('/visits')) {
          if (request.method == 'POST') {
            hasVisit = true;
            return http.Response('{}', 201);
          }
          return http.Response(jsonEncode(hasVisit ? [{
            'id': 'visit-alpha', 'reason':'Consultation de démonstration',
            'created_at':'2026-10-14T10:00:00Z',
          }] : []), 200);
        }
        if (url.endsWith('/exams')) {
          if (request.method == 'POST') {
            hasExam = true;
            return http.Response('{}', 201);
          }
          return http.Response(jsonEncode(hasExam ? [{
            'id':'exam-alpha','title':'Examen de démonstration',
            'status':examCompleted ? 'complete' : 'pending',
          }] : []), 200);
        }
        if (url.endsWith('/exams/exam-alpha/result')) {
          examCompleted = true;
          return http.Response('{}', 200);
        }
        if (url.endsWith('/followups')) {
          if (request.method == 'POST') {
            hasFollowUp = true;
            return http.Response('{}', 201);
          }
          return http.Response(jsonEncode(hasFollowUp ? [{
            'id':'follow-alpha','reason':'Contrôle fictif',
            'scheduled_at':'2026-10-21T10:00:00Z',
            'status':followUpCompleted ? 'completed' : 'planned'
          }] : []), 200);
        }
        if (url.endsWith('/followups/follow-alpha/close')) {
          followUpCompleted = true;
          return http.Response('{}', 200);
        }
        return http.Response('{}', 404);
      }));

    await tester.pumpWidget(MaterialApp(theme:MediTheme.dark(),
      home: DevPatientDetail(api:api, session: session, patient: patient),
    ));
    await tester.pumpAndSettle();

    expect(find.text('PATIENT FICTIF A'), findsOneWidget);
    expect(find.text('Consultations'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dev-add-synthetic-visit')));
    await tester.pumpAndSettle();
    expect(find.text('Consultation de démonstration'), findsOneWidget);

    await tester.tap(find.text('Bilans'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dev-add-synthetic-exam')));
    await tester.pumpAndSettle();
    expect(find.text('Examen de démonstration'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dev-exam-exam-alpha')));
    await tester.pumpAndSettle();
    expect(find.text('Résultat fictif enregistré'), findsOneWidget);

    await tester.tap(find.text('Suivi'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dev-add-synthetic-followup')));
    await tester.pumpAndSettle();
    expect(find.text('Contrôle fictif'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dev-followup-follow-alpha')));
    await tester.pumpAndSettle();
    expect(find.text('Suivi fictif clôturé'), findsOneWidget);
    expect(calls.where((r) => r.method == 'POST').length, 3);
    expect(calls.where((r) => r.method == 'PUT').length, 2);
    expect(calls.every((r) =>
      r.headers['authorization'] == 'Bearer valid-account-alpha'), isTrue);
    expect(tester.takeException(), isNull);
    api.close();
  });
}
