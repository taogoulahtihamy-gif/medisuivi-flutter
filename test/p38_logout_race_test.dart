import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';

DevSession testSession() => DevSession(
  practitioner: const DevPractitioner(
    id: 'synthetic-a', email: 'alpha@medisuvi-ci.org',
    firstName: 'Alpha', lastName: 'Fictif'),
  accessToken: 'access-before-logout',
  refreshToken: 'refresh-before-logout',
);

void main() {
  test('P3.8: a late patient response is rejected after account switch', () async {
    final seenRequest = Completer<void>();
    final delayed = Completer<http.Response>();
    final session = testSession();
    final api = DevAuthApi(Uri.parse('http://127.0.0.1:8027'),
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/patients');
        expect(request.headers['authorization'], 'Bearer access-before-logout');
        if (!seenRequest.isCompleted) seenRequest.complete();
        return delayed.future;
      }));

    final future = api.listPatients(session);
    final assertion = expectLater(future, throwsA(isA<DevApiException>()));
    await seenRequest.future.timeout(const Duration(seconds: 3));
    session.clear();
    delayed.complete(http.Response(jsonEncode([
      {'id': 'patient-a', 'display_name': 'FICTIF A', 'age': 30}
    ]), 200));
    await assertion;
    expect(session.isActive, isFalse);
    expect(session.accessToken, isEmpty);
    expect(session.refreshToken, isEmpty);
    api.close();
  });

  test('P3.8: delayed refresh cannot resurrect credentials after logout', () async {
    final seenRefresh = Completer<void>();
    final lateTokens = Completer<http.Response>();
    final session = testSession();
    var patientCalls = 0;
    final api = DevAuthApi(Uri.parse('http://127.0.0.1:8027'),
      client: MockClient((request) async {
        if (request.url.path == '/api/v1/patients') {
          patientCalls++;
          return http.Response('{}', 401);
        }
        if (request.url.path == '/api/v1/auth/refresh') {
          if (!seenRefresh.isCompleted) seenRefresh.complete();
          return lateTokens.future;
        }
        return http.Response('{}', 404);
      }));

    final future = api.listPatients(session);
    final assertion = expectLater(future, throwsA(isA<DevApiException>()));
    await seenRefresh.future.timeout(const Duration(seconds: 3));
    session.clear();
    lateTokens.complete(http.Response(jsonEncode({
      'access_token': 'must-never-be-restored',
      'refresh_token': 'must-never-be-restored',
    }), 200));
    await assertion;
    expect(session.accessToken, isEmpty);
    expect(session.refreshToken, isEmpty);
    expect(patientCalls, 1, reason: 'No retry once the practitioner logs out');
    api.close();
  });

  test('P3.8: expired session cannot start new patient or clinical requests',
      () async {
    var networkCalls = 0;
    final session = testSession()..clear();
    final api = DevAuthApi(Uri.parse('http://127.0.0.1:8027'),
      client: MockClient((request) async {
        networkCalls++;
        return http.Response('[]', 200);
      }));

    await expectLater(api.listPatients(session),
      throwsA(isA<DevApiException>()));
    await expectLater(api.createSyntheticPatient(session),
      throwsA(isA<DevApiException>()));
    expect(networkCalls, 0, reason: 'A signed-out user never calls the API');
    api.close();
  });

  test('P3.8: late profile-photo upload cannot leak across accounts', () async {
    final uploadStarted = Completer<void>();
    final response = Completer<http.Response>();
    final session = testSession();
    final api = DevAuthApi(Uri.parse('http://127.0.0.1:8027'),
      client: MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/v1/me/avatar');
        if (!uploadStarted.isCompleted) uploadStarted.complete();
        return response.future;
      }));

    final future = api.uploadAvatar(session,
      Uint8List.fromList([137, 80, 78, 71]),
      mimeType: 'image/png');
    final assertion = expectLater(future, throwsA(isA<DevApiException>()));
    await uploadStarted.future.timeout(const Duration(seconds: 3));
    session.clear();
    response.complete(http.Response(jsonEncode({
      'id':'synthetic-a', 'email':'alpha@medisuvi-ci.org',
      'first_name':'Alpha', 'last_name':'Fictif',
      'has_avatar':true,
    }), 200));
    await assertion;
    expect(session.isActive, isFalse);
    api.close();
  });
}
