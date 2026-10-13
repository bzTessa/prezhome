import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/theme/theme_preference.dart';

void main() {
  test('claro por defecto y el onboarding siempre en claro', () {
    bool dark(AppThemeMode m, {bool sys = true, bool force = false}) =>
        ThemePreference.isDark(mode: m, systemDark: sys, forceLight: force);
    expect(ThemePreference.mode.value, AppThemeMode.claro);
    expect(dark(AppThemeMode.claro), isFalse);
    expect(dark(AppThemeMode.oscuro, sys: false), isTrue);
    expect(dark(AppThemeMode.sistema), isTrue);
    expect(dark(AppThemeMode.sistema, sys: false), isFalse);
    expect(dark(AppThemeMode.oscuro, force: true), isFalse);
  });
}
