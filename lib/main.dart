import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'app/medisuivi_app.dart';
import 'app/theme_v2.dart';
import 'core/persistence/database_initializer.dart';
import 'core/persistence/persistence_types.dart';
import 'core/state/demo_store.dart';
import 'core/state/persistent_store.dart'
    if (dart.library.html) 'core/state/persistent_store_stub.dart';
import 'core/state/persistent_store_initializer_mobile.dart'
    if (dart.library.html) 'core/state/persistent_store_initializer_stub.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MediSuiviApp());
}

class MediSuiviApp extends StatefulWidget {
  const MediSuiviApp({super.key});

  @override
  State<MediSuiviApp> createState() => _MediSuiviAppState();
}

class _MediSuiviAppState extends State<MediSuiviApp> {
  DemoStore? _demoStore;
  PersistentStore? _persistentStore;
  DatabaseInitResult? _initResult;
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (kIsWeb) {
      // Sur le web : utiliser DemoStore avec données fictives
      _demoStore = DemoStore();
      _initResult = DatabaseInitResult.notSupported;
      _isInitializing = false;
      if (mounted) setState(() {});
      return;
    }

    // Sur mobile : initialiser la base chiffrée
    try {
      final result = await DatabaseProvider.initialize();
      _initResult = result.$1;

      switch (result.$1) {
        case DatabaseInitResult.success:
          _persistentStore = createPersistentStore(result.$2);
          if (_persistentStore != null) {
            try {
              // Attendre la fin du chargement initial des données.
              // Les erreurs sont propagées (rethrow dans _loadInitialData)
              // et déclenchent l'écran d'erreur ci-dessous.
              await _persistentStore!.ready;
            } catch (e) {
              _errorMessage = 'Erreur de chargement des données : $e';
              _initResult = null; // déclenche l'écran d'erreur existant
            }
          }
          break;
        case DatabaseInitResult.wrongKey:
          _errorMessage =
              'Clé de déchiffrement invalide. Veuillez redémarrer l\'application.';
          break;
        case DatabaseInitResult.corruption:
          _errorMessage = 'Base de données corrompue. Contactez le support.';
          break;
        case DatabaseInitResult.unavailable:
          _errorMessage = 'Stockage sécurisé non disponible sur cet appareil.';
          break;
        case DatabaseInitResult.notSupported:
          _errorMessage = 'Plateforme non supportée pour la persistance.';
          break;
      }
    } catch (e) {
      _errorMessage = 'Erreur d\'initialisation : $e';
    } finally {
      _isInitializing = false;
      if (mounted) setState(() {});
    }
  }

  // L'UI ferme son store sans attendre. La base est fermée ensuite,
  // uniquement après la fin effective de l'annulation des flux Drift.
  Future<void> _releaseStorage(PersistentStore? store) async {
    try {
      try {
        if (store != null) {
          // Une fermeture pendant l'initialisation ne doit pas la devancer.
          try {
            await store.ready;
          } catch (_) {
            // L'erreur de lecture est traitée par le bootstrap ; fermer quand même.
          }
          await store.streamsStopped;
        }
      } finally {
        await DatabaseProvider.dispose();
      }
    } catch (_, stack) {
      // Ne jamais journaliser le contenu de données médicales ou SQLite.
      FlutterError.reportError(FlutterErrorDetails(
        exception: StateError('Échec de libération du stockage local.'),
        stack: stack,
        library: 'MediSuivi',
      ));
    }
  }

  @override
  void dispose() {
    _demoStore?.dispose();
    final store = _persistentStore;
    store?.dispose();
    unawaited(_releaseStorage(store));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Écran de chargement / erreur pendant l'initialisation
    if (_isInitializing) {
      return MaterialApp(
        title: 'MediSuivi',
        debugShowCheckedModeBanner: false,
        theme: ClinicalTheme.light(),
        darkTheme: ClinicalTheme.dark(),
        themeMode: ThemeMode.system,
        home: const _LoadingScreen(),
      );
    }

    // Écran d'erreur si initialisation échouée
    if (_initResult != DatabaseInitResult.success &&
        _initResult != DatabaseInitResult.notSupported) {
      return MaterialApp(
        title: 'MediSuivi',
        debugShowCheckedModeBanner: false,
        theme: ClinicalTheme.light(),
        darkTheme: ClinicalTheme.dark(),
        themeMode: ThemeMode.system,
        home: _ErrorScreen(
          message: _errorMessage ?? 'Erreur inconnue',
          onRetry: _initializeApp,
        ),
      );
    }

    // Application principale avec le bon store
    if (kIsWeb || _initResult == DatabaseInitResult.notSupported) {
      // Mode démo Web
      return DemoScope(
        store: _demoStore!,
        child: MaterialApp(
          title: 'MediSuivi',
          debugShowCheckedModeBanner: false,
          theme: ClinicalTheme.light(),
          darkTheme: ClinicalTheme.dark(),
          themeMode: ThemeMode.system,
          home: const MainShell(),
        ),
      );
    }

    // Mode persistant mobile
    return PersistentScope(
      store: _persistentStore!,
      child: MaterialApp(
        title: 'MediSuivi',
        debugShowCheckedModeBanner: false,
        theme: ClinicalTheme.light(),
        darkTheme: ClinicalTheme.dark(),
        themeMode: ThemeMode.system,
        home: const MainShell(),
      ),
    );
  }
}

/// Écran de chargement au démarrage
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Initialisation de MediSuivi...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Écran d'erreur avec bouton de réessai
class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScreen({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Impossible d\'initialiser la base de données',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
