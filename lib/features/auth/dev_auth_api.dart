import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Only a development API. No token is written to preferences or local storage.
/// The account never receives the global DemoStore's patients.
class DevPractitioner {
  const DevPractitioner({
    required this.id, required this.email,
    required this.firstName, required this.lastName,
    this.phone = '', this.specialty = '', this.hasAvatar = false,
  });
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String specialty;
  final bool hasAvatar;
  String get displayName => '$firstName $lastName'.trim();

  factory DevPractitioner.fromJson(Map<String, dynamic> json) =>
      DevPractitioner(
        id: json['id'] as String,
        email: json['email'] as String,
        firstName: json['first_name'] as String,
        lastName: json['last_name'] as String,
        phone: json['phone'] as String? ?? '',
        specialty: json['specialty'] as String? ?? '',
        hasAvatar: json['has_avatar'] as bool? ?? false,
      );
}

class DevSession {
  DevSession({required this.practitioner, required this.accessToken,
    this.refreshToken = ''});
  final DevPractitioner practitioner;
  String accessToken;
  String refreshToken;

  void clear() {
    accessToken = '';
    refreshToken = '';
  }
}

class DevPatient {
  const DevPatient({required this.id, required this.displayName,
      required this.age});
  final String id;
  final String displayName;
  final int age;

  factory DevPatient.fromJson(Map<String, dynamic> json) =>
      DevPatient(id: json['id'] as String,
        displayName: json['display_name'] as String,
        age: json['age'] as int);
}

/// Data returned by the authenticated backend, never by DemoStore.
class DevVisit {
  const DevVisit({required this.id, required this.reason, required this.createdAt});
  final String id;
  final String reason;
  final DateTime createdAt;
  factory DevVisit.fromJson(Map<String, dynamic> data) => DevVisit(
    id: data['id'] as String, reason: data['reason'] as String,
    createdAt: DateTime.parse(data['created_at'] as String));
}

class DevExam {
  const DevExam({required this.id, required this.title, required this.status});
  final String id;
  final String title;
  final String status;
  factory DevExam.fromJson(Map<String, dynamic> data) => DevExam(
    id: data['id'] as String, title: data['title'] as String,
    status: data['status'] as String);
}

class DevFollowUp {
  const DevFollowUp({required this.id, required this.reason,
    required this.status, required this.scheduledAt});
  final String id;
  final String reason;
  final String status;
  final DateTime scheduledAt;
  factory DevFollowUp.fromJson(Map<String, dynamic> data) => DevFollowUp(
    id: data['id'] as String, reason: data['reason'] as String,
    status: data['status'] as String,
    scheduledAt: DateTime.parse(data['scheduled_at'] as String));
}

class DevClinicalBundle {
  const DevClinicalBundle({required this.visits,
      required this.exams, required this.followUps});
  final List<DevVisit> visits;
  final List<DevExam> exams;
  final List<DevFollowUp> followUps;
}

class DevApiException implements Exception {
  const DevApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class DevAuthApi {
  DevAuthApi(Uri baseUri, {http.Client? client})
      : _baseUri = baseUri,
        _client = client ?? http.Client() {
    final allowedHttp = baseUri.scheme == 'http' &&
        const {'localhost', '127.0.0.1', '10.0.2.2'}
            .contains(baseUri.host);
    if (!(baseUri.scheme == 'https' || allowedHttp) ||
        baseUri.userInfo.isNotEmpty ||
        baseUri.hasQuery || baseUri.hasFragment) {
      throw ArgumentError('L’API de développement requiert une URL sûre.');
    }
  }

  static const devBaseUrl = String.fromEnvironment(
    'MEDISUIVI_DEV_API_BASE_URL', defaultValue: '');

  /// Without dart-define the preexisting demo remains the only workflow.
  static DevAuthApi? fromEnvironment() {
    final value = devBaseUrl.trim();
    if (value.isEmpty) return null;
    return DevAuthApi(Uri.parse(value));
  }

  final Uri _baseUri;
  final http.Client _client;
  final Duration _timeout = const Duration(seconds: 10);
  final Map<DevSession, Future<void>> _refreshing = {};

  Uri _url(String path) {
    final prefix = _baseUri.toString().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$prefix$path');
  }

  Future<void> _refreshSession(DevSession session) async {
    final pending = _refreshing[session];
    if (pending != null) return pending;
    final operation = _exchangeRefresh(session);
    _refreshing[session] = operation;
    try {
      await operation;
    } finally {
      _refreshing.remove(session);
    }
  }

  Future<void> _exchangeRefresh(DevSession session) async {
    if (session.refreshToken.isEmpty) {
      throw const DevApiException('Session expirée, reconnectez-vous.');
    }
    try {
      final response = await _request('POST', '/api/v1/auth/refresh',
        body: {'refresh_token': session.refreshToken});
      _ensureSuccess(response);
      final payload = _map(response);
      session.accessToken = payload['access_token'] as String;
      session.refreshToken = payload['refresh_token'] as String;
    } catch (_) {
      // Never retain a rejected refresh secret in the client memory.
      session.clear();
      throw const DevApiException('Session expirée, reconnectez-vous.');
    }
  }

  Future<http.Response> _request(
    String method, String path, {
    Map<String, Object?>? body,
    String? token,
    DevSession? session,
  }) async {
    final effectiveToken = session?.accessToken ?? token;
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (effectiveToken != null && effectiveToken.isNotEmpty)
        'Authorization': 'Bearer $effectiveToken',
    };
    try {
      final url = _url(path);
      final http.Response response;
      switch (method) {
        case 'GET':
          response = await _client.get(url, headers: headers).timeout(_timeout);
          break;
        case 'POST':
          response = await _client.post(url, headers: headers,
              body: body == null ? null : jsonEncode(body)).timeout(_timeout);
          break;
        case 'PUT':
          response = await _client.put(url, headers: headers,
              body: body == null ? null : jsonEncode(body)).timeout(_timeout);
          break;
        case 'DELETE':
          response = await _client.delete(url, headers: headers).timeout(_timeout);
          break;
        default:
          throw ArgumentError('Méthode HTTP inconnue');
      }
      if (response.statusCode == 401 && session != null &&
          session.refreshToken.isNotEmpty) {
        if (session.accessToken == effectiveToken) {
          await _refreshSession(session);
        }
        // Retry once only; cannot recurse into refresh again.
        return await _request(method, path, body: body, token: session.accessToken);
      }
      return response;
    } on TimeoutException {
      throw const DevApiException('Le serveur ne répond pas. Réessayez.');
    } on http.ClientException {
      throw const DevApiException(
        'Impossible de joindre l’API. Vérifiez le serveur local.');
    }
  }

  void _ensureSuccess(http.Response response, {int? expected}) {
    final code = response.statusCode;
    if (expected != null ? code == expected : code >= 200 && code < 300) return;
    switch (code) {
      case 401:
        throw const DevApiException('Identifiants invalides ou session expirée.');
      case 403:
        throw const DevApiException(
          'Cette opération est désactivée sur le serveur de développement.');
      case 404:
        throw const DevApiException('Ressource introuvable pour ce compte.');
      case 409:
        throw const DevApiException('Ce compte existe déjà, ou l’action est terminée.');
      case 422:
        throw const DevApiException('Vérifiez les informations saisies.');
      default:
        throw const DevApiException(
          'Le serveur a rencontré une erreur. Réessayez.');
    }
  }

  Map<String, dynamic> _map(http.Response response) =>
      jsonDecode(response.body) as Map<String, dynamic>;

  Future<DevSession> signIn(String email, String password) async {
    final result = await _request('POST', '/api/v1/auth/login',
        body: {'email': email.trim(), 'password': password});
    _ensureSuccess(result);
    final tokens = _map(result);
    final token = tokens['access_token'] as String;
    final me = await _request('GET', '/api/v1/me', token: token);
    _ensureSuccess(me);
    return DevSession(
      practitioner: DevPractitioner.fromJson(_map(me)),
      accessToken: token,
      refreshToken: tokens['refresh_token'] as String? ?? '');
  }

  Future<DevSession> createAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final response = await _request('POST', '/api/v1/auth/register', body: {
      'first_name': firstName.trim(), 'last_name': lastName.trim(),
      'email': email.trim(), 'password': password,
    });
    _ensureSuccess(response, expected: 201);
    return signIn(email, password);
  }

  Future<List<DevPatient>> listPatients(DevSession session) async {
    final response = await _request('GET', '/api/v1/patients',
        session: session);
    _ensureSuccess(response);
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => DevPatient.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<DevPractitioner> updateProfile(
    DevSession session, {
    required String firstName,
    required String lastName,
    required String phone,
    required String specialty,
  }) async {
    final response = await _request('PUT', '/api/v1/me',
      session: session,
      body: {
        'first_name': firstName.trim(), 'last_name': lastName.trim(),
        'phone': phone.trim(), 'specialty': specialty.trim(),
      });
    _ensureSuccess(response);
    return DevPractitioner.fromJson(_map(response));
  }

  Future<Uint8List?> loadAvatar(DevSession session) async {
    final response = await _request('GET', '/api/v1/me/avatar',
        session: session);
    if (response.statusCode == 404) return null;
    _ensureSuccess(response);
    return response.bodyBytes;
  }

  Future<DevPractitioner> uploadAvatar(
    DevSession session, Uint8List bytes, {
      required String mimeType,
    }) async {
    if (bytes.isEmpty || bytes.lengthInBytes > 2 * 1024 * 1024) {
      throw const DevApiException('Photo trop volumineuse.');
    }
    if (!const {'image/png', 'image/jpeg', 'image/webp'}.contains(mimeType)) {
      throw const DevApiException('Choisissez une photo PNG, JPEG ou WebP.');
    }
    Future<http.Response> uploadOnce() =>
        _client.put(_url('/api/v1/me/avatar'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${session.accessToken}',
            'Content-Type': mimeType,
          },
          body: bytes,
        ).timeout(_timeout);
    try {
      var response = await uploadOnce();
      if (response.statusCode == 401 && session.refreshToken.isNotEmpty) {
        await _refreshSession(session);
        response = await uploadOnce();
      }
      _ensureSuccess(response);
      return DevPractitioner.fromJson(_map(response));
    } on TimeoutException {
      throw const DevApiException('Le serveur ne répond pas.');
    } on http.ClientException {
      throw const DevApiException('Photo non transmise au serveur.');
    }
  }

  Future<void> removeAvatar(DevSession session) async {
    final response = await _request('DELETE', '/api/v1/me/avatar',
      session: session);
    _ensureSuccess(response, expected: 204);
  }

  /// Generates a synthetic identity. Users cannot enter actual patient names.
  Future<DevPatient> createSyntheticPatient(DevSession session) async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final result = await _request('POST', '/api/v1/patients',
      session: session,
      body: {'display_name': 'PATIENT FICTIF $stamp', 'age': 30});
    _ensureSuccess(result, expected: 201);
    return DevPatient.fromJson(_map(result));
  }

  Future<List<Map<String, dynamic>>> _clinicalList(
      DevSession session, String path) async {
    final response = await _request('GET', path, session: session);
    _ensureSuccess(response);
    return (jsonDecode(response.body) as List<dynamic>)
      .map((data) => data as Map<String, dynamic>).toList(growable: false);
  }

  String _patientPath(DevPatient patient, String kind) =>
      '/api/v1/patients/${Uri.encodeComponent(patient.id)}/$kind';

  Future<DevClinicalBundle> getPatientClinical(
    DevSession session, DevPatient patient,
  ) async {
    // Each query is independently checked against the JWT on the server.
    final visits = await _clinicalList(session, _patientPath(patient, 'visits'));
    final exams = await _clinicalList(session, _patientPath(patient, 'exams'));
    final followUps = await _clinicalList(
        session, _patientPath(patient, 'followups'));
    return DevClinicalBundle(
      visits: visits.map(DevVisit.fromJson).toList(growable: false),
      exams: exams.map(DevExam.fromJson).toList(growable: false),
      followUps: followUps.map(DevFollowUp.fromJson).toList(growable: false),
    );
  }

  /// Synthetic actions ONLY. No free text that could accidentally carry PHI.
  Future<void> createSyntheticVisit(DevSession session, DevPatient patient) async {
    final response = await _request('POST', _patientPath(patient, 'visits'),
      session: session,
      body: {'reason':'Consultation de démonstration',
             'notes':'Donnée entièrement fictive'});
    _ensureSuccess(response, expected: 201);
  }

  Future<void> createSyntheticExam(DevSession session, DevPatient patient) async {
    final response = await _request('POST', _patientPath(patient, 'exams'),
      session: session,
      body: {'title':'Examen de démonstration'});
    _ensureSuccess(response, expected: 201);
  }

  Future<void> recordSyntheticExamResult(DevSession session, DevExam exam) async {
    final response = await _request('PUT',
      '/api/v1/exams/${Uri.encodeComponent(exam.id)}/result',
      session: session,
      body: {'result':'Résultat de démonstration sans valeur médicale'});
    _ensureSuccess(response);
  }

  Future<void> createSyntheticFollowUp(DevSession session, DevPatient patient) async {
    final when = DateTime.now().toUtc().add(const Duration(days: 7));
    final response = await _request('POST', _patientPath(patient, 'followups'),
      session: session, body: {
        'scheduled_at': when.toIso8601String(),
        'reason': 'Contrôle fictif',
      });
    _ensureSuccess(response, expected: 201);
  }

  Future<void> closeSyntheticFollowUp(
      DevSession session, DevFollowUp followUp) async {
    final response = await _request('PUT',
      '/api/v1/followups/${Uri.encodeComponent(followUp.id)}/close',
      session: session, body: {'completed':true});
    _ensureSuccess(response);
  }

  Future<void> signOut(DevSession session) async {
    try {
      final result = await _request('POST', '/api/v1/auth/logout',
        session: session);
      _ensureSuccess(result, expected: 204);
    } finally {
      // Clear volatile credentials even if the server cannot be reached.
      session.clear();
      _refreshing.remove(session);
    }
  }

  Future<void> signOutEverywhere(DevSession session) async {
    try {
      final result = await _request('POST', '/api/v1/auth/logout-all',
        session: session);
      _ensureSuccess(result, expected: 204);
    } finally {
      session.clear();
      _refreshing.remove(session);
    }
  }

  void close() => _client.close();
}
