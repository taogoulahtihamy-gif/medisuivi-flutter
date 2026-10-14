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
  const DevSession({required this.practitioner, required this.accessToken});
  final DevPractitioner practitioner;
  final String accessToken;
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

  Uri _url(String path) {
    final prefix = _baseUri.toString().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$prefix$path');
  }

  Future<http.Response> _request(
    String method, String path, {
    Map<String, Object?>? body,
    String? token,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    try {
      final url = _url(path);
      switch (method) {
        case 'GET':
          return await _client.get(url, headers: headers).timeout(_timeout);
        case 'POST':
          return await _client.post(url, headers: headers,
              body: body == null ? null : jsonEncode(body)).timeout(_timeout);
        case 'PUT':
          return await _client.put(url, headers: headers,
              body: body == null ? null : jsonEncode(body)).timeout(_timeout);
        case 'DELETE':
          return await _client.delete(url, headers: headers).timeout(_timeout);
        default:
          throw ArgumentError('Méthode HTTP inconnue');
      }
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
    final token = _map(result)['access_token'] as String;
    final me = await _request('GET', '/api/v1/me', token: token);
    _ensureSuccess(me);
    return DevSession(
      practitioner: DevPractitioner.fromJson(_map(me)), accessToken: token);
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
        token: session.accessToken);
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
      token: session.accessToken,
      body: {
        'first_name': firstName.trim(), 'last_name': lastName.trim(),
        'phone': phone.trim(), 'specialty': specialty.trim(),
      });
    _ensureSuccess(response);
    return DevPractitioner.fromJson(_map(response));
  }

  Future<Uint8List?> loadAvatar(DevSession session) async {
    final response = await _request('GET', '/api/v1/me/avatar',
        token: session.accessToken);
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
    try {
      final response = await _client.put(_url('/api/v1/me/avatar'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': mimeType,
        },
        body: bytes,
      ).timeout(_timeout);
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
      token: session.accessToken);
    _ensureSuccess(response, expected: 204);
  }

  /// Generates a synthetic identity. Users cannot enter actual patient names.
  Future<DevPatient> createSyntheticPatient(DevSession session) async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final result = await _request('POST', '/api/v1/patients',
      token: session.accessToken,
      body: {'display_name': 'PATIENT FICTIF $stamp', 'age': 30});
    _ensureSuccess(result, expected: 201);
    return DevPatient.fromJson(_map(result));
  }

  Future<void> signOut(DevSession session) async {
    final result = await _request('POST', '/api/v1/auth/logout',
      token: session.accessToken);
    _ensureSuccess(result, expected: 204);
  }

  void close() => _client.close();
}
