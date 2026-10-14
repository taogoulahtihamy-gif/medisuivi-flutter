import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'account_scoped_vault.dart';
import 'database.dart';

/// Mobile-only adapter: an entirely NEW private encrypted file and key per
/// authenticated server UUID. Does not import/read/rename/delete medisuivi.db.
///
/// This is an opt-in foundation, NOT wired to the current legacy local store.
/// Before live use, require verified sign-in, device unlock, migration review,
/// full Android/iOS tests, and a documented account recovery procedure.
class MobileAccountVaultBackend implements AccountVaultBackend<AppDatabase> {
  MobileAccountVaultBackend({
    FlutterSecureStorage? secureStorage,
    Future<Directory> Function()? directoryProvider,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  final FlutterSecureStorage _secureStorage;
  final Future<Directory> Function() _directoryProvider;

  @override
  Future<AppDatabase> openFor(String ownerUserId) async {
    final id = AccountVaultIdentity.requireServerUuid(ownerUserId);
    final keyAlias = AccountVaultIdentity.keyAlias(id);
    final directory = await _directoryProvider();
    final file = File('${directory.path}/${AccountVaultIdentity.databaseFilename(id)}');

    // Never create a new key for a previously existing encrypted vault:
    // doing so could permanently strand clinical records.
    var key = await _secureStorage.read(key: keyAlias);
    if (key == null) {
      final existing = await Future.wait([
        file.exists(),
        File('${file.path}-wal').exists(),
        File('${file.path}-shm').exists(),
      ]);
      if (existing.any((present) => present)) {
        throw StateError(
          'Clé du coffre indisponible : restauration sécurisée requise.');
      }
      final random = Random.secure();
      key = List<int>.generate(32, (_) => random.nextInt(256))
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
      await _secureStorage.write(key: keyAlias, value: key);
    }
    if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(key)) {
      throw StateError('Clé chiffrée invalide : ouverture refusée.');
    }

    final database = await openEncryptedDatabase(
      key, databaseFile: file);
    try {
      // SQLCipher must reject a wrong key. Do not assume that an encrypted
      // database is usable just because its file was opened.
      final integrity = await database.customSelect('PRAGMA quick_check').get();
      if (integrity.length != 1 ||
          integrity.single.read<String>('quick_check') != 'ok') {
        throw StateError('Vérification du coffre chiffré échouée.');
      }
      return database;
    } catch (_) {
      await database.close();
      rethrow;
    }
  }

  @override
  Future<void> close(AppDatabase store) => store.close();
}
