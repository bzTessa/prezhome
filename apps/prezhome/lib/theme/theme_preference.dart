import 'package:flutter/foundation.dart';

import '../services/file_local_store.dart';

/// Apariencia elegida en Ajustes. Por defecto, clara.
enum AppThemeMode {
  claro('Claro'),
  oscuro('Oscuro'),
  sistema('Sistema');

  const AppThemeMode(this.label);
  final String label;
}

/// Estilo visual de la app. "Cocina cálida" (fondo crema tostado, títulos
/// DM Serif y barra oscura) es el nuevo; "Clásico" es el de antes.
enum AppLook { calida, clasica }

/// Guarda la apariencia en el dispositivo y avisa al cambiarla.
class ThemePreference {
  static final mode = ValueNotifier<AppThemeMode>(AppThemeMode.claro);
  static final _store = FileLocalStore(folderName: 'settings');
  static const _key = 'theme_mode';
  static final look = ValueNotifier<AppLook>(AppLook.calida);
  static const _lookKey = 'app_look';

  static Future<void> load() async {
    try {
      final v = await _store.read(_key);
      mode.value = AppThemeMode.values.firstWhere(
        (m) => m.name == v,
        orElse: () => AppThemeMode.claro,
      );
    } catch (_) {}
    try {
      final v = await _store.read(_lookKey);
      look.value = AppLook.values.firstWhere(
        (m) => m.name == v,
        orElse: () => AppLook.calida,
      );
    } catch (_) {}
  }

  static Future<void> setLook(AppLook l) async {
    look.value = l;
    try {
      await _store.write(_lookKey, l.name);
    } catch (_) {}
  }

  static Future<void> set(AppThemeMode m) async {
    mode.value = m;
    try {
      await _store.write(_key, m.name);
    } catch (_) {}
  }

  /// ¿Toca pintar en oscuro? El onboarding ([forceLight]) siempre va en claro.
  static bool isDark({
    required AppThemeMode mode,
    required bool systemDark,
    required bool forceLight,
  }) {
    if (forceLight) return false;
    return switch (mode) {
      AppThemeMode.claro => false,
      AppThemeMode.oscuro => true,
      AppThemeMode.sistema => systemDark,
    };
  }
}
