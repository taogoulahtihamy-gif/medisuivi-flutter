import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medisuivi/features/auth/dev_auth_api.dart';
import 'package:medisuivi/features/auth/dev_session_persistence.dart';

const alice = '1a2a3361-ed2e-4abe-8e55-661bac905148';
const bob = '5b60b4f7-3af3-49de-9d25-69d25712e1c5';
const apiUrl = 'https://medisuivi-staging.invalid';

class TestSecureStore implements DevSessionPersistence {
  SavedDevSession? saved;
  int deletes = 0;
  int writes = 0;
  bool unavailable = false;
  @override
  Future<SavedDevSession?> read() async {
    if (unavailable) throw StateError('KeyStore unavailable');
    return saved;
  }
  @override
  Future<void> save(SavedDevSession credential) async {
    if (unavailable) throw StateError('KeyStore unavailable');
    saved = credential;
    writes++;
  }
  @override
  Future<void> clear() async {
    if (unavailable) throw StateError('KeyStore unavailable');
    saved = null;
    deletes++;
  }
}

Map<String, Object> identity(String id) => {
  'id': id, 'email': 'fiction@medisuvi-ci.org',
  'first_name': 'Médecin', 'last_name': 'Synthétique',
  'has_avatar': false,
};

void main() {
  test('P4.2 stores only rotating refresh + UUID + backend, never profile/access', () async {
    final storage = TestSecureStore();
    final api = DevAuthApi(Uri.parse(apiUrl), persistence: storage,
      client: MockClient((request) async {
        switch (request.url.path) {
          case '/api/v1/auth/login':
            return http.Response(jsonEncode({
              'access_token': 'access-secret-in-memory',
              'refresh_token': 'refresh-secret-1',
            }), 200);
          case '/api/v1/me':
            return http.Response(jsonEncode(identity(alice)), 200);
          default:
            return http.Response('{}', 404);
        }
      }));
    final session = await api.signIn(
      'fiction@medisuvi-ci.org', 'synthetic-password-2026');
    expect(session.isActive, isTrue);
    final persisted = storage.saved!;
    expect(persisted.api, apiUrl);
    expect(persisted.ownerId, alice);
    expect(persisted.refreshToken, 'refresh-secret-1');
    final encoded = jsonEncode(persisted.toJson());
    expect(encoded, isNot(contains('access-secret-in-memory')));
    expect(encoded, isNot(contains('synthetic-password-2026')));
    expect(encoded, isNot(contains('Médecin')));
    expect(encoded, isNot(contains('fiction@medisuvi-ci.org')));
    api.close();
  });

  test('P4.2 refreshes and checks owner on new app launch', () async {
    final storage = TestSecureStore()
      ..saved = const SavedDevSession(
        api: apiUrl, ownerId: alice, refreshToken: 'first-refresh');
    final requests = <String>[];
    final api = DevAuthApi(Uri.parse(apiUrl), persistence: storage,
      client: MockClient((request) async {
        requests.add(request.url.path);
        switch (request.url.path) {
          case '/api/v1/auth/refresh':
            expect(jsonDecode(request.body)['refresh_token'], 'first-refresh');
            return http.Response(jsonEncode({
              'access_token': 'rotated-access',
              'refresh_token': 'rotated-refresh',
            }), 200);
          case '/api/v1/me':
            expect(request.headers['authorization'], 'Bearer rotated-access');
            return http.Response(jsonEncode(identity(alice)), 200);
          case '/api/v1/patients':
            return http.Response(jsonEncode([
              {'id': 'fictitious-patient', 'display_name':'PATIENT FICTIF','age':30}
            ]), 200);
          default:
            return http.Response('{}', 404);
        }
      }));
    final session = await api.restoreSavedSession();
    expect(session?.practitioner.id, alice);
    expect(storage.saved?.refreshToken, 'rotated-refresh');
    expect((await api.listPatients(session!)).single.displayName, 'PATIENT FICTIF');
    expect(requests, [
      '/api/v1/auth/refresh',
      '/api/v1/me',
      '/api/v1/patients',
    ]);
    api.close();
  });

  test('P4.2 server identity mismatch clears credential and shows no patients',
      () async {
    final storage = TestSecureStore()
      ..saved = const SavedDevSession(
        api: apiUrl, ownerId: alice, refreshToken: 'first-refresh');
    var patientCalls = 0;
    final api = DevAuthApi(Uri.parse(apiUrl), persistence: storage,
      client: MockClient((request) async {
        if (request.url.path == '/api/v1/auth/refresh') {
          return http.Response(jsonEncode({
            'access_token': 'access-b', 'refresh_token': 'refresh-b',
          }), 200);
        }
        if (request.url.path == '/api/v1/me') {
          return http.Response(jsonEncode(identity(bob)), 200);
        }
        if (request.url.path == '/api/v1/patients') patientCalls++;
        return http.Response('{}', 404);
      }));
    expect(await api.restoreSavedSession(), isNull);
    expect(storage.saved, isNull);
    expect(patientCalls, 0);
    api.close();
  });

  test('P4.2 revoked refresh is erased, without trying patient reads', () async {
    final storage = TestSecureStore()
      ..saved = const SavedDevSession(
        api: apiUrl, ownerId: alice, refreshToken: 'revoked-refresh');
    var requests = 0;
    final api = DevAuthApi(Uri.parse(apiUrl), persistence: storage,
      client: MockClient((request) async {
        requests++;
        return http.Response('{}', 401);
      }));
    expect(await api.restoreSavedSession(), isNull);
    expect(storage.saved, isNull);
    expect(requests, 1);
    api.close();
  });

  test('P4.2 offline restart never displays private data, keeps encrypted credential',
      () async {
    final storage = TestSecureStore()
      ..saved = const SavedDevSession(
        api: apiUrl, ownerId: alice, refreshToken: 'still-valid-on-server');
    final api = DevAuthApi(Uri.parse(apiUrl), persistence: storage,
      client: MockClient((request) async {
        throw http.ClientException('offline');
      }));
    await expectLater(api.restoreSavedSession(),
      throwsA(isA<DevApiException>()));
    expect(storage.saved?.refreshToken, 'still-valid-on-server');
    api.close();
  });

  test('P4.2 logout despite network failure clears persisted and in-memory secrets',
      () async {
    final storage = TestSecureStore()
      ..saved = const SavedDevSession(
        api: apiUrl, ownerId: alice, refreshToken: 'refresh-before-logout');
    final api = DevAuthApi(Uri.parse(apiUrl), persistence: storage,
      client: MockClient((request) async {
        throw http.ClientException('no network');
      }));
    final session = DevSession(
      practitioner: DevPractitioner.fromJson(identity(alice)),
      accessToken: 'access-before-logout',
      refreshToken: 'refresh-before-logout',
    );
    await expectLater(api.signOut(session), throwsA(isA<DevApiException>()));
    expect(storage.saved, isNull);
    expect(session.accessToken, isEmpty);
    expect(session.refreshToken, isEmpty);
    api.close();
  });

  test('P4.2 normal auto-refresh also overwrites stored rotating secret',
      () async {
    final storage = TestSecureStore();
    var patientCalls = 0;
    final api = DevAuthApi(Uri.parse(apiUrl), persistence: storage,
      client: MockClient((request) async {
        if (request.url.path == '/api/v1/auth/login') {
          return http.Response(jsonEncode({
            'access_token':'access-old', 'refresh_token':'refresh-old',
          }), 200);
        }
        if (request.url.path == '/api/v1/me') {
          return http.Response(jsonEncode(identity(alice)), 200);
        }
        if (request.url.path == '/api/v1/auth/refresh') {
          expect(jsonDecode(request.body)['refresh_token'], 'refresh-old');
          return http.Response(jsonEncode({
            'access_token':'access-new', 'refresh_token':'refresh-new',
          }), 200);
        }
        if (request.url.path == '/api/v1/patients') {
          patientCalls++;
          return http.Response(patientCalls == 1 ? '{}' : '[]',
            patientCalls == 1 ? 401 : 200);
        }
        return http.Response('{}', 404);
      }));
    final session = await api.signIn(
      'fiction@medisuvi-ci.org', 'synthetic-password-2026');
    expect(storage.saved?.refreshToken, 'refresh-old');
    expect(await api.listPatients(session), isEmpty);
    expect(storage.saved?.refreshToken, 'refresh-new');
    expect(patientCalls, 2);
    api.close();
  });

  test('P4.2 credentials from another backend are not replayed', () async {
    final storage = TestSecureStore()
      ..saved = const SavedDevSession(
        api: 'https://wrong-api.invalid', ownerId: alice, refreshToken: 'xyz');
    var calls = 0;
    final api = DevAuthApi(Uri.parse(apiUrl), persistence: storage,
      client: MockClient((request) async {
        calls++;
        return http.Response('{}', 200);
      }));
    expect(await api.restoreSavedSession(), isNull);
    expect(storage.saved, isNull);
    expect(calls, 0);
    api.close();
  });


  test('P4.2 switching A to B replaces the only saved mobile credential', () async {
    final storage = TestSecureStore()
      ..saved = const SavedDevSession(
        api: apiUrl, ownerId: alice, refreshToken: 'alice-credential');
    final api = DevAuthApi(Uri.parse(apiUrl), persistence: storage,
      client: MockClient((request) async {
        if (request.url.path == '/api/v1/auth/login') {
          return http.Response(jsonEncode({
            'access_token':'b-access', 'refresh_token':'b-refresh',
          }), 200);
        }
        if (request.url.path == '/api/v1/me') {
          return http.Response(jsonEncode(identity(bob)), 200);
        }
        return http.Response('{}', 404);
      }));
    final session = await api.signIn('fiction@medisuvi-ci.org', 'b-secret-test');
    expect(session.practitioner.id, bob);
    expect(storage.saved?.ownerId, bob);
    expect(storage.saved?.refreshToken, 'b-refresh');
    expect(storage.saved?.refreshToken, isNot('alice-credential'));
    api.close();
  });

  test('P4.2 late restart refresh cannot persist after account cancellation',
      () async {
    final storage = TestSecureStore()
      ..saved = const SavedDevSession(
        api: apiUrl, ownerId: alice, refreshToken: 'alice-credential');
    final refreshReceived = Completer<void>();
    final delayedRefresh = Completer<http.Response>();
    var userLookupCount = 0;
    final api = DevAuthApi(Uri.parse(apiUrl), persistence: storage,
      client: MockClient((request) async {
        if (request.url.path == '/api/v1/auth/refresh') {
          refreshReceived.complete();
          return delayedRefresh.future;
        }
        if (request.url.path == '/api/v1/me') userLookupCount++;
        return http.Response('{}', 404);
      }));
    final pending = api.restoreSavedSession();
    await refreshReceived.future.timeout(const Duration(seconds: 3));
    await api.forgetSavedSession();
    delayedRefresh.complete(http.Response(jsonEncode({
      'access_token':'late-access', 'refresh_token':'late-refresh',
    }), 200));
    expect(await pending, isNull);
    expect(storage.saved, isNull);
    expect(userLookupCount, 0);
    api.close();
  });


  test('P4.2 changing password erases protected credential and all local tokens',
      () async {
    final storage = TestSecureStore()
      ..saved = const SavedDevSession(
        api: apiUrl, ownerId: alice, refreshToken: 'before-password-change');
    final session = DevSession(
      practitioner: DevPractitioner.fromJson(identity(alice)),
      accessToken: 'current-access',
      refreshToken: 'before-password-change',
    );
    final api = DevAuthApi(Uri.parse(apiUrl), persistence: storage,
      client: MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/v1/me/password');
        return http.Response('', 204);
      }));
    await api.changePassword(session,
      currentPassword: 'synthetic-before-password',
      newPassword: 'synthetic-after-password-2026');
    expect(storage.saved, isNull);
    expect(session.isActive, isFalse);
    expect(session.refreshToken, isEmpty);
    api.close();
  });

  test('P4.2 global logout invalidates protected session locally', () async {
    final storage = TestSecureStore()
      ..saved = const SavedDevSession(
        api: apiUrl, ownerId: alice, refreshToken: 'before-global-logout');
    final session = DevSession(
      practitioner: DevPractitioner.fromJson(identity(alice)),
      accessToken: 'current-access',
      refreshToken: 'before-global-logout',
    );
    final api = DevAuthApi(Uri.parse(apiUrl), persistence: storage,
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/logout-all');
        return http.Response('', 204);
      }));
    await api.signOutEverywhere(session);
    expect(storage.saved, isNull);
    expect(session.isActive, isFalse);
    api.close();
  });

  test('P4.2 corrupt JSON never creates a session', () {
    expect(SavedDevSession.parse('not-json'), isNull);
    expect(SavedDevSession.parse('{}'), isNull);
    expect(SavedDevSession.parse(jsonEncode({
      'version':1, 'api':apiUrl, 'owner_id':'../../demo.db',
      'refresh_token':'a',
    })), isNull);
  });

  test('P4.2 KeyStore unavailable fails closed on login', () async {
    final storage = TestSecureStore()..unavailable = true;
    final api = DevAuthApi(Uri.parse(apiUrl), persistence: storage,
      client: MockClient((request) async {
        if (request.url.path == '/api/v1/auth/login') {
          return http.Response(jsonEncode({
            'access_token':'access', 'refresh_token':'refresh',
          }), 200);
        }
        return http.Response(jsonEncode(identity(alice)), 200);
      }));
    await expectLater(api.signIn('fiction@medisuvi-ci.org', 'synthetic'),
      throwsA(isA<DevApiException>()));
    expect(storage.writes, 0);
    api.close();
  });
}
