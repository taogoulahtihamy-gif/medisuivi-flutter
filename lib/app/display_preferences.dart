import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Préférences purement visuelles. Aucune donnée patient ni identité ici.
class DisplayPreferences {
  const DisplayPreferences({
    this.reduceMotion = false,
    this.compactLists = true,
  });
  final bool reduceMotion;
  final bool compactLists;

  DisplayPreferences copyWith({bool? reduceMotion, bool? compactLists}) =>
      DisplayPreferences(
        reduceMotion: reduceMotion ?? this.reduceMotion,
        compactLists: compactLists ?? this.compactLists,
      );
}

class DisplayPreferencesController extends ValueNotifier<DisplayPreferences> {
  DisplayPreferencesController({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        super(const DisplayPreferences());

  static const _motionKey = 'medisuivi_ui_reduce_motion_v1';
  static const _listKey = 'medisuivi_ui_compact_lists_v1';
  final FlutterSecureStorage _storage;

  Future<void> load() async {
    try {
      final motion = await _storage.read(key: _motionKey);
      final compact = await _storage.read(key: _listKey);
      value = DisplayPreferences(
        reduceMotion: motion == 'true',
        compactLists: compact != 'false',
      );
    } catch (_) {
      // La perte d'une préférence ne doit pas bloquer MediSuivi.
    }
  }

  Future<void> setReduceMotion(bool enabled) async {
    value = value.copyWith(reduceMotion: enabled);
    try {
      await _storage.write(key: _motionKey, value: enabled.toString());
    } catch (_) {}
  }

  Future<void> setCompactLists(bool enabled) async {
    value = value.copyWith(compactLists: enabled);
    try {
      await _storage.write(key: _listKey, value: enabled.toString());
    } catch (_) {}
  }
}

class DisplayPreferencesScope
    extends InheritedNotifier<DisplayPreferencesController> {
  const DisplayPreferencesScope({
    super.key,
    required DisplayPreferencesController controller,
    required super.child,
  }) : super(notifier: controller);

  static DisplayPreferencesController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DisplayPreferencesScope>()
          ?.notifier;
}
