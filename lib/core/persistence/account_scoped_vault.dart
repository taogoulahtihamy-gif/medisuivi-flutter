import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Server-issued UUIDs are the only acceptable owner IDs. Never use email,
/// display name, a user-selected path or a locally-generated demo identity.
abstract final class AccountVaultIdentity {
  static final RegExp _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  static String requireServerUuid(String value) {
    final id = value.toLowerCase();
    if (!_uuid.hasMatch(id)) {
      throw ArgumentError.value(
        value, 'ownerUserId', 'Identifiant de compte serveur invalide');
    }
    return id;
  }

  static String opaqueNamespace(String ownerUserId) {
    final id = requireServerUuid(ownerUserId);
    return sha256.convert(utf8.encode('medisuivi:account-v1:$id')).toString();
  }

  static String databaseFilename(String ownerUserId) =>
      'medisuivi-account-${opaqueNamespace(ownerUserId)}.db';

  static String keyAlias(String ownerUserId) =>
      'medisuivi_account_key_v1_${opaqueNamespace(ownerUserId)}';
}

/// Shared, platform-independent contract used by the account vault.
///
/// Implementations must open a *separate encrypted file with its own key*
/// for every server UUID, and must never read the legacy medisuivi.db file.
abstract class AccountVaultBackend<T> {
  Future<T> openFor(String ownerUserId);
  Future<void> close(T store);
}

/// One account at a time. All commands are serialized so a delayed operation
/// from A cannot return after the application has activated B.
///
/// The store is deliberately never exposed outside [use]. It is not a
/// replacement for API JWT checks or a future biometric unlock gate.
class AccountScopedVault<T> {
  AccountScopedVault(this._backend);

  final AccountVaultBackend<T> _backend;
  Future<void> _tail = Future<void>.value();
  String? _owner;
  T? _store;
  bool _disposed = false;

  String? get activeOwner => _owner;

  Future<R> _queue<R>(Future<R> Function() callback) {
    final result = _tail.then((_) => callback());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> activate(String serverUserId) {
    final account = AccountVaultIdentity.requireServerUuid(serverUserId);
    return _queue(() async {
      if (_disposed) throw StateError('Account vault is closed');
      if (_owner == account && _store != null) return;

      final old = _store;
      _owner = null;
      _store = null;
      if (old != null) await _backend.close(old);

      // Fail closed: an unavailable/corrupt key must NOT create a replacement
      // or fall back to medisuivi.db or an unencrypted/demo database.
      final next = await _backend.openFor(account);
      _owner = account;
      _store = next;
    });
  }

  Future<R> use<R>(String serverUserId, Future<R> Function(T store) action) {
    final account = AccountVaultIdentity.requireServerUuid(serverUserId);
    return _queue(() async {
      if (_disposed || _owner != account || _store == null) {
        throw StateError('Le compte ne possède pas ce coffre local');
      }
      return action(_store as T);
    });
  }

  Future<void> lock() => _queue(() async {
    final previous = _store;
    _store = null;
    _owner = null;
    if (previous != null) await _backend.close(previous);
  });

  Future<void> dispose() => _queue(() async {
    final previous = _store;
    _store = null;
    _owner = null;
    _disposed = true;
    if (previous != null) await _backend.close(previous);
  });
}
