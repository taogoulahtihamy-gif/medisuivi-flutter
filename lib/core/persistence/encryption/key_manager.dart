/// Gestionnaire de clés avec authentification biométrique
library;

import 'dart:ui';

import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'encryption_service.dart';

/// Résultat d'une authentification
enum AuthResult {
  success,
  failed,
  lockedOut,
  notAvailable,
  notEnrolled,
  cancelled,
}

/// Gestionnaire de l'authentification et de l'accès aux clés
class KeyManager {
  final LocalAuthentication _localAuth;
  final EncryptionService _encryptionService;
  final FlutterSecureStorage _secureStorage;

  // Configuration du verrouillage automatique
  static const Duration _defaultAutoLockDelay = Duration(seconds: 30);
  Duration _autoLockDelay = _defaultAutoLockDelay;
  DateTime? _lastActivityTime;
  bool _isUnlocked = false;

  // Callbacks pour l'UI
  VoidCallback? _onLockRequired;
  VoidCallback? _onUnlockRequired;

  KeyManager({
    LocalAuthentication? localAuth,
    EncryptionService? encryptionService,
    FlutterSecureStorage? secureStorage,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _encryptionService = encryptionService ?? EncryptionService(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Initialise le gestionnaire
  Future<void> initialize() async {
    _lastActivityTime = DateTime.now();
    _isUnlocked = false;
  }

  /// Configure le délai de verrouillage automatique
  void setAutoLockDelay(Duration delay) {
    _autoLockDelay = delay;
  }

  /// Définit les callbacks pour l'UI
  void setCallbacks({
    VoidCallback? onLockRequired,
    VoidCallback? onUnlockRequired,
  }) {
    _onLockRequired = onLockRequired;
    _onUnlockRequired = onUnlockRequired;
  }

  /// Vérifie si l'authentification biométrique est disponible
  Future<bool> isBiometricAvailable() async {
    try {
      final available = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return available && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Récupère les types de biométrie disponibles
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Authentifie l'utilisateur (biométrique ou code PIN/pattern)
  Future<AuthResult> authenticate({
    String localizedReason = 'Déverrouiller MediSuivi pour accéder à vos dossiers',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();

      if (!isAvailable) {
        // Fallback vers authentification device credential (PIN/pattern/mot de passe)
        final authenticated = await _localAuth.authenticate(
          localizedReason: localizedReason,
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
            useErrorDialogs: true,
          ),
        );
        if (authenticated) {
          _isUnlocked = true;
          _lastActivityTime = DateTime.now();
          return AuthResult.success;
        }
        return AuthResult.failed;
      }

      // Authentification biométrique
      final authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: stickyAuth,
          useErrorDialogs: useErrorDialogs,
        ),
      );

      if (authenticated) {
        _isUnlocked = true;
        _lastActivityTime = DateTime.now();
        return AuthResult.success;
      }
      return AuthResult.failed;
    } on Exception catch (e) {
      // Gestion des erreurs spécifiques
      if (e.toString().contains('LockedOut') || e.toString().contains('lockout')) {
        return AuthResult.lockedOut;
      }
      if (e.toString().contains('NotEnrolled') || e.toString().contains('not enrolled')) {
        return AuthResult.notEnrolled;
      }
      if (e.toString().contains('Cancelled') || e.toString().contains('cancelled')) {
        return AuthResult.cancelled;
      }
      return AuthResult.failed;
    }
  }

  /// Déverrouille l'accès à la base de données
  /// Retourne la clé SQLCipher si l'authentification réussit
  Future<String?> unlockDatabase({
    String localizedReason = 'Déverrouiller MediSuivi pour accéder à vos dossiers',
  }) async {
    if (_isUnlocked) {
      // Vérifier si le verrouillage auto doit s'appliquer
      if (_shouldAutoLock()) {
        await lockDatabase();
      } else {
        _lastActivityTime = DateTime.now();
        return _encryptionService.getSqlCipherKey();
      }
    }

    final result = await authenticate(localizedReason: localizedReason);
    if (result == AuthResult.success) {
      return _encryptionService.getSqlCipherKey();
    }

    _onUnlockRequired?.call();
    return null;
  }

  /// Verrouille l'accès à la base de données
  Future<void> lockDatabase() async {
    _isUnlocked = false;
    _encryptionService.clearCache();
    _onLockRequired?.call();
  }

  /// Vérifie si le verrouillage automatique doit s'appliquer
  bool _shouldAutoLock() {
    if (_lastActivityTime == null) return true;
    return DateTime.now().difference(_lastActivityTime!) > _autoLockDelay;
  }

  /// Met à jour l'heure de dernière activité
  void updateActivity() {
    _lastActivityTime = DateTime.now();
  }

  /// Vérifie si la base est actuellement déverrouillée
  bool get isUnlocked => _isUnlocked && !_shouldAutoLock();

  /// Récupère la clé SQLCipher sans authentification (pour démarrage si déjà déverrouillé)
  Future<String?> getSqlCipherKeyIfUnlocked() async {
    if (isUnlocked) {
      return _encryptionService.getSqlCipherKey();
    }
    return null;
  }

  /// Configure un verrouillage d'urgence (effacement de la clé en mémoire seulement)
  /// NE SUPPRIME PAS la clé du stockage sécurisé
  Future<void> emergencyLock() async {
    _isUnlocked = false;
    _encryptionService.clearCache();
    _onLockRequired?.call();
  }

  /// Vérifie si une clé maître existe
  Future<bool> hasMasterKey() async {
    final key = await _secureStorage.read(key: 'medisuivi_master_key');
    return key != null;
  }

  /// Exporte la clé maître pour backup (utilisateur doit la stocker sécurisément)
  Future<String?> exportMasterKeyForBackup() async {
    return _encryptionService.exportMasterKey();
  }

  /// Importe une clé maître depuis un backup
  Future<void> importMasterKeyFromBackup(String masterKey) async {
    await _encryptionService.importMasterKey(masterKey);
  }

  /// Réinitialise complètement (pour tests ou reset utilisateur)
  /// ATTENTION: Rend la base illisible sans backup de la clé
  Future<void> resetAllKeys() async {
    await _encryptionService.deleteMasterKey();
    await _secureStorage.delete(key: 'medisuivi_salt');
    _isUnlocked = false;
  }
}