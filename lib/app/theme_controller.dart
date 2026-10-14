import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Préférence d'affichage uniquement. Aucune information médicale n'est lue
/// ou enregistrée par ce contrôleur.
class ThemeModeController extends ValueNotifier<ThemeMode> {
  ThemeModeController({
    ThemeMode initial = ThemeMode.system,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage(), super(initial);

  static const _key = 'medisuivi_theme_mode_v1';
  final FlutterSecureStorage _storage;

  Future<void> load() async {
    try {
      final saved = await _storage.read(key: _key);
      if (saved == 'light') value = ThemeMode.light;
      if (saved == 'dark') value = ThemeMode.dark;
      if (saved == 'system') value = ThemeMode.system;
    } catch (_) {
      // Une préférence visuelle ne doit jamais bloquer l'ouverture de l'app.
    }
  }

  Future<void> choose(ThemeMode mode) async {
    value = mode;
    try {
      await _storage.write(key: _key, value: mode.name);
    } catch (_) {
      // Le thème reste actif pendant cette session si le stockage échoue.
    }
  }
}

class ClinicalThemeScope extends InheritedNotifier<ThemeModeController> {
  const ClinicalThemeScope({
    super.key,
    required ThemeModeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeModeController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ClinicalThemeScope>()?.notifier;
}
