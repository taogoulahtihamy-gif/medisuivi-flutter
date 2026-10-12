/// Service de chiffrement simplifié pour les tests (sans flutter_secure_storage)
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/digests/sha256.dart';

/// Service de chiffrement pour les tests - stockage en mémoire
class TestEncryptionService {
  static const int _keyLength = 32; // 256 bits
  static const int _iterations = 256000; // PBKDF2 iterations

  String? _masterKey;
  String? _salt;

  /// Récupère ou génère la clé maître
  Future<String> getOrCreateMasterKey() async {
    if (_masterKey != null) {
      return _masterKey!;
    }

    final masterKey = _generateMasterKey();
    _masterKey = masterKey;
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
    if (_salt != null) {
      return _salt!;
    }

    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    _salt = base64UrlEncode(saltBytes);
    return _salt!;
  }

  /// Dérive la clé SQLite3MultipleCiphers à partir de la clé maître
  String deriveSqlCipherKey(String masterKey, String salt) {
    final keyBytes = base64Url.decode(masterKey);
    final saltBytes = base64Url.decode(salt);

    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(saltBytes, _iterations, _keyLength));

    final derivedKey = derivator.process(Uint8List.fromList(keyBytes));

    return bytesToHex(derivedKey);
  }

  /// Obtient la clé de chiffrement prête pour SQLite3MultipleCiphers
  Future<String> getSqlCipherKey() async {
    final masterKey = await getOrCreateMasterKey();
    final salt = await getOrCreateSalt();
    return deriveSqlCipherKey(masterKey, salt);
  }

  /// Change la clé maître (pour tests)
  Future<void> rotateMasterKey() async {
    _masterKey = _generateMasterKey();
    _salt = null; // Nouveau sel = nouvelle dérivation
  }

  /// Réinitialise pour les tests
  void reset() {
    _masterKey = null;
    _salt = null;
  }
}

/// Convertit une liste d'octets en string hexadécimal
String bytesToHex(List<int> bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}