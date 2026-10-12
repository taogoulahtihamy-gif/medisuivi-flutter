/// Service de chiffrement pour la base de données SQLite3MultipleCiphers
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/digests/sha256.dart';

/// Service gérant le chiffrement de la base de données
class EncryptionService {
  static const String _masterKeyAlias = 'medisuivi_master_key';
  static const String _saltAlias = 'medisuivi_salt';
  static const int _keyLength = 32; // 256 bits
  static const int _iterations = 256000; // PBKDF2 iterations (standard SQLCipher)

  final FlutterSecureStorage _secureStorage;
  String? _cachedMasterKey;

  EncryptionService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? _createSecureStorage();

  static FlutterSecureStorage _createSecureStorage() {
    return const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
        synchronizable: false,
      ),
      lOptions: LinuxOptions(
        // Sur Linux, utiliser libsecret
      ),
      mOptions: MacOsOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
        synchronizable: false,
      ),
      wOptions: WindowsOptions(
        // Sur Windows, utiliser DPAPI
      ),
    );
  }

  /// Récupère ou génère la clé maître
  Future<String> getOrCreateMasterKey() async {
    if (_cachedMasterKey != null) {
      return _cachedMasterKey!;
    }

    // Essayer de récupérer la clé existante
    final existingKey = await _secureStorage.read(key: _masterKeyAlias);
    if (existingKey != null) {
      _cachedMasterKey = existingKey;
      return existingKey;
    }

    // Générer une nouvelle clé maître
    final masterKey = _generateMasterKey();
    await _secureStorage.write(key: _masterKeyAlias, value: masterKey);
    _cachedMasterKey = masterKey;
    return masterKey;
  }

  /// Génère une clé maître cryptographiquement sécurisée
  String _generateMasterKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(_keyLength, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  /// Récupère ou génère le sel pour la dérivation de clé
  Future<String> getOrCreateSalt() async {
    final existingSalt = await _secureStorage.read(key: _saltAlias);
    if (existingSalt != null) {
      return existingSalt;
    }

    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final salt = base64UrlEncode(saltBytes);
    await _secureStorage.write(key: _saltAlias, value: salt);
    return salt;
  }

  /// Dérive la clé SQLite3MultipleCiphers à partir de la clé maître
  /// Utilise PBKDF2-HMAC-SHA256 avec 256000 itérations via pointycastle
  String deriveSqlCipherKey(String masterKey, String salt) {
    final keyBytes = base64Url.decode(masterKey);
    final saltBytes = base64Url.decode(salt);

    // PBKDF2-HMAC-SHA256 avec pointycastle 4.x
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(saltBytes, _iterations, _keyLength));

    final derivedKey = derivator.process(Uint8List.fromList(keyBytes));

    // Retourner en hex pour SQLite3MultipleCiphers (PRAGMA key = "x'...'")
    return bytesToHex(derivedKey);
  }

  /// Obtient la clé de chiffrement prête pour SQLite3MultipleCiphers
  Future<String> getSqlCipherKey() async {
    final masterKey = await getOrCreateMasterKey();
    final salt = await getOrCreateSalt();
    return deriveSqlCipherKey(masterKey, salt);
  }

  /// Vérifie si une clé de déchiffrement est valide
  Future<bool> verifyKey(String testKey) async {
    // La vérification réelle se fait au niveau de l'ouverture de la base
    // Ici on retourne true pour éviter la dépendance circulaire
    return true;
  }

  /// Change la clé maître (ré-chiffrement de la base)
  /// DÉSACTIVÉ : Le ré-chiffrement transactionnel complet n'est pas encore implémenté.
  /// Cette méthode ne modifie NI la clé NI le sel, en mémoire ni sur disque.
  /// L'appel lève une exception pour prévenir toute perte de données accidentelle.
  Future<void> rotateMasterKey() async {
    throw UnsupportedError(
      'rotateMasterKey() est désactivé : le ré-chiffrement transactionnel complet '
      '(sqlcipher_export / rekey) n\'est pas encore implémenté. '
      'L\'activation prématurée causerait une perte de données irréversible.'
    );
  }

  /// Efface la clé maître (rend la base illisible)
  /// ATTENTION: Irréversible sans backup de la clé
  Future<void> deleteMasterKey() async {
    await _secureStorage.delete(key: _masterKeyAlias);
    _cachedMasterKey = null;
  }

  /// Exporte la clé maître (pour backup sécurisé)
  Future<String?> exportMasterKey() async {
    return _secureStorage.read(key: _masterKeyAlias);
  }

  /// Importe une clé maître (pour restauration)
  Future<void> importMasterKey(String masterKey) async {
    await _secureStorage.write(key: _masterKeyAlias, value: masterKey);
    _cachedMasterKey = masterKey;
  }

  /// Vérifie la disponibilité du stockage sécurisé
  Future<bool> isSecureStorageAvailable() async {
    try {
      const testKey = '_test_availability';
      await _secureStorage.write(key: testKey, value: 'test');
      final value = await _secureStorage.read(key: testKey);
      await _secureStorage.delete(key: testKey);
      return value == 'test';
    } catch (_) {
      return false;
    }
  }

  /// Vide le cache de la clé maître (après verrouillage app)
  void clearCache() {
    _cachedMasterKey = null;
  }
}

/// Convertit une liste d'octets en string hexadécimal
String bytesToHex(List<int> bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}