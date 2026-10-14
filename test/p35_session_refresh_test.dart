import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';

void main() {
  test('P3.5: two accounts remain independent after refresh and logout',
      () async {
    final sessionA = DevSession(
      practitioner: const DevPractitioner(
        id:'owner-a', email:'a@medisuvi-ci.org',
        firstName:'A', lastName:'Fictif'),
      accessToken:'access-a-old', refreshToken:'refresh-a-old');
    final sessionB = DevSession(
      practitioner: const DevPractitioner(
        id:'owner-b', email:'b@medisuvi-ci.org',
        firstName:'B', lastName:'Fictif'),
      accessToken:'access-b', refreshToken:'refresh-b');
    var refreshCount = 0;
    final api = DevAuthApi(Uri.parse('http://127.0.0.1:8027'),
      client: MockClient((request) async {
        final auth = request.headers['authorization'];
        if (request.url.path == '/api/v1/auth/refresh') {
          refreshCount++;
          final body = jsonDecode(request.body) as Map;
          expect(body['refresh_token'], 'refresh-a-old');
          return http.Response(jsonEncode({
            'access_token':'access-a-new',
            'refresh_token':'refresh-a-new'}), 200);
        }
        if (request.url.path == '/api/v1/patients') {
          if (auth == 'Bearer access-a-old') {
            return http.Response('{"detail":"expired"}', 401);
          }
          if (auth == 'Bearer access-a-new') {
            return http.Response(jsonEncode([{
              'id':'patient-a','display_name':'PATIENT FICTIF A','age':30
            }]), 200);
          }
          if (auth == 'Bearer access-b') return http.Response('[]', 200);
        }
        if (request.url.path == '/api/v1/auth/logout') {
          return http.Response('', 204);
        }
        return http.Response('{}', 500);
      }));
    final result = await Future.wait([
      api.listPatients(sessionA),
      api.listPatients(sessionA),
    ]);
    expect(result[0].single.id, 'patient-a');
    expect(result[1].single.id, 'patient-a');
    expect(refreshCount, 1);
    expect(sessionA.accessToken, 'access-a-new');
    expect(sessionA.refreshToken, 'refresh-a-new');
    expect(sessionB.accessToken, 'access-b');
    expect(await api.listPatients(sessionB), isEmpty);
    await api.signOut(sessionA);
    expect(sessionA.accessToken, isEmpty);
    expect(sessionA.refreshToken, isEmpty);
    expect(sessionB.accessToken, isNotEmpty);
    api.close();
  });

  test('P3.5: local credentials are wiped when server logout fails',
      () async {
    final session = DevSession(
      practitioner: const DevPractitioner(
        id:'one', email:'one@medisuvi-ci.org',
        firstName:'Test', lastName:'Fictif'),
      accessToken:'access-volatile', refreshToken:'refresh-volatile');
    final api = DevAuthApi(Uri.parse('http://127.0.0.1:8027'),
      client: MockClient((_) async => http.Response('{}', 503)));
    await expectLater(api.signOut(session), throwsA(isA<DevApiException>()));
    expect(session.accessToken, isEmpty);
    expect(session.refreshToken, isEmpty);
    api.close();
  });
}
