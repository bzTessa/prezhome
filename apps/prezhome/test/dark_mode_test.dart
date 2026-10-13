import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/theme/app_theme.dart';

void main() {
  tearDown(() => AppColors.dark = false);

  testWidgets('el tema sigue al modo oscuro de la paleta', (tester) async {
    late ThemeData light, dark;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          AppColors.dark = false;
          light = AppTheme.build(context);
          AppColors.dark = true;
          dark = AppTheme.build(context);
          return const SizedBox();
        },
      ),
    );

    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(dark.colorScheme.brightness, Brightness.dark);
    // Fondo oscuro y texto claro: se invierte la jerarquía de luminancia.
    expect(dark.scaffoldBackgroundColor.computeLuminance(), lessThan(0.05));
    expect(AppColors.ink.computeLuminance(), greaterThan(0.7));
    expect(light.scaffoldBackgroundColor, isNot(dark.scaffoldBackgroundColor));
  });
}
