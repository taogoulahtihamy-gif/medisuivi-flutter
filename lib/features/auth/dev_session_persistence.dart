import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Exactly one active mobile account. No clinical data, names or email stored.
/// Only a rotating refresh secret and the owning server UUID are retained.
class SavedDevSession {
  const SavedDevSession({
    required this.api,
    required this.ownerId,
    required this.refreshToken,
  });

  final String api;
  final String ownerId;
  final String refreshToken;

  Map<String, Object> toJson() => {
    'version': 1,
    'api': api,
    'owner_id': ownerId,
    'refresh_token': refreshToken,
  };

  static SavedDevSession? parse(String raw) {
    try {
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic> ||
          data['version'] != 1 ||
          data['api'] is! String ||
          data['owner_id'] is! String ||
          data['refresh_token'] is! String) {
        return null;
      }
      final api = data['api'] as String;
      final owner = data['owner_id'] as String;
      final token = data['refresh_token'] as String;
      // Require server UUID, reject directory traversal or injected account ID.
      final uuid = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
      if (!uuid.hasMatch(owner.toLowerCase()) ||
          api.isEmpty || token.isEmpty || token.length > 500) {
        return null;
      }
      return SavedDevSession(api: api, ownerId: owner, refreshToken: token);
    } catch (_) {
      return null;
    }
  }
}

abstract class DevSessionPersistence {
  Future<SavedDevSession?> read();
  Future<void> save(SavedDevSession credential);
  Future<void> clear();
}

/// Android KeyStore / iOS Keychain storage via flutter_secure_storage.
/// This class MUST NOT be constructed on the web, desktop or demo workflow.
class MobileDevSessionPersistence implements DevSessionPersistence {
  MobileDevSessionPersistence({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _storageKey = 'medisuivi_authenticated_refresh_v1';
  final FlutterSecureStorage _secureStorage;
  Future<void> _tail = Future<void>.value();

  // Preserve operation order: a delayed refresh write must complete before
  // the following explicit logout deletes the protected credential.
  Future<T> _inOrder<T>(Future<T> Function() task) {
    final result = _tail.then((_) => task());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  @override
  Future<SavedDevSession?> read() => _inOrder(() async {
    final value = await _secureStorage.read(key: _storageKey);
    if (value == null) return null;
    final parsed = SavedDevSession.parse(value);
    if (parsed != null) return parsed;
    await _secureStorage.delete(key: _storageKey);
    return null;
  });

  @override
  Future<void> save(SavedDevSession credential) => _inOrder(() =>
      _secureStorage.write(
        key: _storageKey,
        value: jsonEncode(credential.toJson()),
      ));

  @override
  Future<void> clear() => _inOrder(() =>
      _secureStorage.delete(key: _storageKey));
}
