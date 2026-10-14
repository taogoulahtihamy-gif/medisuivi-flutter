import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

import 'dev_session_persistence.dart';

/// Development API: mobile-only secure refresh persistence, never browser storage.
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

  // Monotonic session revision. A late HTTP response must never resurrect
  // a logged-out account or return its previous patient's clinical data.
  int _revision = 0;
  int get revision => _revision;
  bool get isActive => accessToken.isNotEmpty;

  void clear() {
    _revision++;
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
  const DevVisit({
    required this.id, required this.reason, required this.createdAt,
    this.temperature, this.systolic, this.diastolic, this.pulse, this.spo2,
  });
  final String id;
  final String reason;
  final DateTime createdAt;
  final double? temperature;
  final int? systolic, diastolic, pulse, spo2;
  factory DevVisit.fromJson(Map<String, dynamic> data) => DevVisit(
    id: data['id'] as String, reason: data['reason'] as String,
    createdAt: DateTime.parse(data['created_at'] as String),
    temperature: (data['temperature'] as num?)?.toDouble(),
    systolic: (data['systolic'] as num?)?.toInt(),
    diastolic: (data['diastolic'] as num?)?.toInt(),
    pulse: (data['pulse'] as num?)?.toInt(),
    spo2: (data['spo2'] as num?)?.toInt(),
  );
}

class DevExam {
  const DevExam({required this.id, required this.title,
    required this.status, this.result, this.resultRecordedAt});
  final String id;
  final String title;
  final String status;
  final String? result;
  final DateTime? resultRecordedAt;
  factory DevExam.fromJson(Map<String, dynamic> data) => DevExam(
    id: data['id'] as String, title: data['title'] as String,
    status: data['status'] as String,
    result: data['result'] as String?,
    resultRecordedAt: data['result_recorded_at'] is String
      ? DateTime.parse(data['result_recorded_at'] as String) : null,
  );
}

class DevFollowUp {
  const DevFollowUp({required this.id, required this.reason,
    required this.status, required this.scheduledAt, this.completedAt});
  final String id;
  final String reason;
  final String status;
  final DateTime scheduledAt;
  final DateTime? completedAt;
  factory DevFollowUp.fromJson(Map<String, dynamic> data) => DevFollowUp(
    id: data['id'] as String, reason: data['reason'] as String,
    status: data['status'] as String,
    scheduledAt: DateTime.parse(data['scheduled_at'] as String),
    completedAt: data['completed_at'] is String
      ? DateTime.parse(data['completed_at'] as String) : null,
  );
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

class DevVerificationRequired extends DevApiException {
  const DevVerificationRequired(this.email)
      : super('Adresse e-mail à confirmer.');
  final String email;
}

class DevAuthApi {
  DevAuthApi(Uri baseUri, {
    http.Client? client,
    DevSessionPersistence? persistence,
  }) : _baseUri = baseUri,
       _client = client ?? http.Client(),
       _persistence = persistence {
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
    final mobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
         defaultTargetPlatform == TargetPlatform.iOS);
    return DevAuthApi(Uri.parse(value),
      persistence: mobile ? MobileDevSessionPersistence() : null);
  }

  final Uri _baseUri;
  final http.Client _client;
  final DevSessionPersistence? _persistence;
  int _restoreGeneration = 0;
  bool get canRestoreSession => _persistence != null;
  String get _audience => _baseUri.toString().replaceAll(RegExp(r'/+$'), '');

  Future<void> _remember(DevSession session) async {
    if (_persistence == null) return;
    final revision = session.revision;
    _assertSession(session, revision);
    if (session.refreshToken.isEmpty) {
      throw const DevApiException('Session non renouvelable sur cet appareil.');
    }
    try {
      await _persistence.save(SavedDevSession(
        api: _audience,
        ownerId: session.practitioner.id,
        refreshToken: session.refreshToken,
      ));
      _assertSession(session, revision);
    } catch (_) {
      session.clear();
      // Best-effort erase any previously persisted account after an unsafe
      // secure-storage write. Never fall back to plaintext preferences.
      try {
        await _persistence.clear();
      } catch (_) {
        // The application will fail closed on subsequent secure-store access.
      }
      throw const DevApiException(
        'Stockage sécurisé indisponible : connexion interrompue.');
    }
  }

  Future<void> forgetSavedSession() async {
    ++_restoreGeneration;
    if (_persistence == null) return;
    try {
      await _persistence.clear();
    } catch (_) {
      throw const DevApiException(
        'Impossible de supprimer la session enregistrée sur cet appareil.');
    }
  }

  /// Restore only after server refresh and /me identity verification.
  /// Never show saved patient data when offline.
  Future<DevSession?> restoreSavedSession() async {
    if (_persistence == null) return null;
    final generation = _restoreGeneration;
    final SavedDevSession? saved;
    try {
      saved = await _persistence.read();
    } catch (_) {
      throw const DevApiException('Stockage sécurisé du téléphone indisponible.');
    }
    if (generation != _restoreGeneration) return null;
    if (saved == null) return null;
    if (saved.api != _audience) {
      await forgetSavedSession();
      return null;
    }
    final response = await _request('POST', '/api/v1/auth/refresh',
      body: {'refresh_token': saved.refreshToken});
    if (generation != _restoreGeneration) return null;
    if (response.statusCode == 401 || response.statusCode == 403) {
      await forgetSavedSession();
      return null;
    }
    _ensureSuccess(response);
    final payload = _map(response);
    final access = payload['access_token'] as String;
    final rotated = payload['refresh_token'] as String;
    final me = await _request('GET', '/api/v1/me', token: access);
    if (generation != _restoreGeneration) return null;
    if (me.statusCode == 401 || me.statusCode == 403) {
      await forgetSavedSession();
      return null;
    }
    _ensureSuccess(me);
    final practitioner = DevPractitioner.fromJson(_map(me));
    if (practitioner.id != saved.ownerId) {
      await forgetSavedSession();
      return null;
    }
    final session = DevSession(
      practitioner: practitioner,
      accessToken: access,
      refreshToken: rotated,
    );
    if (generation != _restoreGeneration) return null;
    await _remember(session);
    return session;
  }

  final Duration _timeout = const Duration(seconds: 10);
  final Map<DevSession, Future<void>> _refreshing = {};

  void _assertSession(DevSession session, int revision) {
    if (!session.isActive || session.revision != revision) {
      throw const DevApiException(
        'Session fermée. Reconnectez-vous pour accéder aux dossiers.');
    }
  }

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
    final revision = session.revision;
    _assertSession(session, revision);
    if (session.refreshToken.isEmpty) {
      throw const DevApiException('Session expirée, reconnectez-vous.');
    }
    try {
      final response = await _request('POST', '/api/v1/auth/refresh',
        body: {'refresh_token': session.refreshToken});
      _assertSession(session, revision);
      _ensureSuccess(response);
      final payload = _map(response);
      final access = payload['access_token'] as String;
      final refresh = payload['refresh_token'] as String;
      _assertSession(session, revision);
      session.accessToken = access;
      session.refreshToken = refresh;
      await _remember(session);
    } catch (_) {
      // If another action already signed out, leave the cleared session
      // untouched. Otherwise reject the damaged refresh secret.
      if (session.revision == revision) session.clear();
      throw const DevApiException('Session expirée, reconnectez-vous.');
    }
  }

  Future<http.Response> _request(
    String method, String path, {
    Map<String, Object?>? body,
    String? token,
    DevSession? session,
  }) async {
    final revision = session?.revision;
    if (session != null) _assertSession(session, revision!);
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
      if (session != null) _assertSession(session, revision!);
      if (response.statusCode == 401 && session != null &&
          session.refreshToken.isNotEmpty) {
        if (session.accessToken == effectiveToken) {
          await _refreshSession(session);
        }
        _assertSession(session, revision!);
        // Retry once only; then check that sign-out did not occur in-flight.
        final retried = await _request(method, path, body: body,
          token: session.accessToken);
        _assertSession(session, revision);
        return retried;
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
      case 400:
        throw const DevApiException('Mot de passe actuel incorrect.');
      case 401:
        throw const DevApiException('Identifiants invalides ou session expirée.');
      case 429:
        throw const DevApiException(
          'Trop de tentatives. Patientez quelques minutes avant de réessayer.');
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
    ++_restoreGeneration;
    final result = await _request('POST', '/api/v1/auth/login',
        body: {'email': email.trim(), 'password': password});
    if (result.statusCode == 403) {
      try {
        if (_map(result)['detail'] == 'Adresse e-mail non vérifiée') {
          throw DevVerificationRequired(email.trim());
        }
      } on FormatException {
        // The generic error handler below will report unexpected responses.
      }
    }
    _ensureSuccess(result);
    final tokens = _map(result);
    final token = tokens['access_token'] as String;
    final me = await _request('GET', '/api/v1/me', token: token);
    _ensureSuccess(me);
    final session = DevSession(
      practitioner: DevPractitioner.fromJson(_map(me)),
      accessToken: token,
      refreshToken: tokens['refresh_token'] as String? ?? '');
    await _remember(session);
    return session;
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
    final payload = _map(response);
    if (payload['email_verification_required'] == true) {
      throw DevVerificationRequired(email.trim());
    }
    return signIn(email, password);
  }

  Future<void> verifyEmail(String email, String code) async {
    final response = await _request('POST', '/api/v1/auth/email/verify',
      body: {'email': email.trim(), 'code': code.trim()});
    if (response.statusCode == 400) {
      throw const DevApiException('Code incorrect ou expiré.');
    }
    _ensureSuccess(response, expected: 204);
  }

  Future<void> resendEmailCode(String email) async {
    final response = await _request('POST', '/api/v1/auth/email/resend',
      body: {'email': email.trim()});
    _ensureSuccess(response, expected: 202);
  }

  Future<void> requestPasswordReset(String email) async {
    final response = await _request('POST', '/api/v1/auth/password/forgot',
      body: {'email': email.trim()});
    _ensureSuccess(response, expected: 202);
  }

  Future<void> resetForgottenPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await _request('POST', '/api/v1/auth/password/reset',
      body: {
        'email': email.trim(), 'code': code.trim(),
        'new_password': newPassword,
      });
    if (response.statusCode == 400) {
      throw const DevApiException('Code incorrect ou expiré.');
    }
    _ensureSuccess(response, expected: 204);
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
    final revision = session.revision;
    _assertSession(session, revision);
    Future<http.Response> uploadOnce() {
      _assertSession(session, revision);
      return _client.put(_url('/api/v1/me/avatar'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${session.accessToken}',
            'Content-Type': mimeType,
          },
          body: bytes,
        ).timeout(_timeout);
    }
    try {
      var response = await uploadOnce();
      _assertSession(session, revision);
      if (response.statusCode == 401 && session.refreshToken.isNotEmpty) {
        await _refreshSession(session);
        _assertSession(session, revision);
        response = await uploadOnce();
        _assertSession(session, revision);
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
  Future<void> createSyntheticVisit(DevSession session, DevPatient patient,
      {bool withVitals = false}) async {
    final response = await _request('POST', _patientPath(patient, 'visits'),
      session: session,
      body: {
        'reason': withVitals
            ? 'Contrôle clinique fictif avec constantes'
            : 'Consultation de démonstration',
        if (withVitals) ...{
          'temperature': 36.8,
          'systolic': 120,
          'diastolic': 80,
          'pulse': 72,
          'spo2': 98,
        },
        'notes':'Donnée entièrement fictive',
      });
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

  Future<void> rescheduleSyntheticFollowUp(
      DevSession session, DevFollowUp followUp) async {
    if (followUp.status != 'planned') {
      throw const DevApiException('Ce suivi fictif est déjà clôturé.');
    }
    final next = followUp.scheduledAt.toUtc().add(const Duration(days: 7));
    final response = await _request('PUT',
      '/api/v1/followups/${Uri.encodeComponent(followUp.id)}/reschedule',
      session: session,
      body: {
        'scheduled_at': next.toIso8601String(),
        'reason': followUp.reason,
        'notes': 'Report de démonstration, aucune donnée réelle',
      });
    _ensureSuccess(response);
  }

  Future<void> cancelSyntheticFollowUp(
      DevSession session, DevFollowUp followUp) async {
    if (followUp.status != 'planned') {
      throw const DevApiException('Ce suivi fictif est déjà clôturé.');
    }
    final response = await _request('PUT',
      '/api/v1/followups/${Uri.encodeComponent(followUp.id)}/close',
      session: session, body: {'completed':false});
    _ensureSuccess(response);
  }

  Future<void> closeSyntheticFollowUp(
      DevSession session, DevFollowUp followUp) async {
    final response = await _request('PUT',
      '/api/v1/followups/${Uri.encodeComponent(followUp.id)}/close',
      session: session, body: {'completed':true});
    _ensureSuccess(response);
  }

  /// Changes the current practitioner's password on the server.
  /// A successful change invalidates ALL of their devices immediately.
  /// Nothing is persisted in browser storage.
  Future<void> changePassword(DevSession session, {
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < 12 || newPassword.length > 128 ||
        currentPassword.isEmpty || currentPassword.length > 128) {
      throw const DevApiException('Mot de passe invalide (12 caractères minimum).');
    }
    final response = await _request('PUT', '/api/v1/me/password',
        session: session, body: {
          'current_password': currentPassword,
          'new_password': newPassword,
        });
    _ensureSuccess(response, expected: 204);
    session.clear();
    _refreshing.remove(session);
    await forgetSavedSession();
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
      await forgetSavedSession();
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
      await forgetSavedSession();
    }
  }

  void close() => _client.close();
}
