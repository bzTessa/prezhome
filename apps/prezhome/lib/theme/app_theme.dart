import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_elevation.dart';
import 'app_radius.dart';

// Reexportamos los tokens del sistema de diseño para que un único import de
// `app_theme.dart` dé acceso a toda la paleta y escalas (sin dependencias
// circulares: estos ficheros no importan de vuelta a AppTheme).
export 'app_elevation.dart';
export 'app_radius.dart';
export 'app_spacing.dart';
export 'app_text_styles.dart';

/// Paleta y estilo "Cozy" de PrezHome, centralizados.
class AppColors {
  static const cream = Color(0xFFFDF8E1); // fondo amarillo pastel cálido
  static const wood = Color(0xFFE2C792); // madera clara (acento)
  static const woodDark = Color(0xFFB58A3C); // acento oscuro para texto/números
  static const ink = Color(0xFF1E1E1E); // gris muy oscuro (texto)
  static const card = Colors.white;
  static const softShadow = Color(0x14000000);

  /// Gris de marca para texto secundario / apoyo.
  ///
  /// Reemplaza los `Colors.grey[500/600/700]` sueltos repartidos por la app.
  /// Derivado del tono `ink` pero más claro para dar jerarquía sin perder
  /// la calidez de la paleta.
  static const inkMuted = Color(0xFF6B6B6B);

  /// Sombra aún más suave que `softShadow`, para superficies en reposo que
  /// necesitan apenas una pizca de profundidad (nivel 1 de [AppElevation]).
  static const faintShadow = Color(0x0D000000);

  /// Sombra algo más marcada para elementos elevados / interactivos
  /// (nivel 2 de [AppElevation]).
  static const mediumShadow = Color(0x1F000000);

  // --- Tonos para chips e identificadores con jerarquía visual ---------------
  // Mantienen la calidez de la paleta pero dan contraste suave entre tipos de
  // información (tipo de comida, tiempo, kcal, favorita...). Se usan como pares
  // fondo + texto/icono para chips tipo "pastel".

  /// Verde salvia suave: tiempo de preparación (reloj).
  static const sageBg = Color(0xFFE6EFE0);
  static const sage = Color(0xFF5C7A4F);

  /// Terracota suave: calorías / energía (destacado cálido).
  static const terracottaBg = Color(0xFFF6E0D4);
  static const terracotta = Color(0xFFB5663C);

  /// Melocotón suave: tipo de comida principal.
  static const peachBg = Color(0xFFF6E6CC);
  static const peach = Color(0xFF9B6B2E);

  /// Azul grisáceo suave: congelable / frío.
  static const frostBg = Color(0xFFDFE9EF);
  static const frost = Color(0xFF4A7489);

  /// Dorado/estrella: favorita.
  static const favorite = Color(0xFFE0A52E);

  // --- Estados de caducidad --------------------------------------------------
  // Pares fondo + acento cálidos y suaves (nada de rojos chillones) para que
  // la usuaria entienda de un vistazo si algo está fresco, caduca pronto o ya
  // ha caducado. Consistentes con el resto de la paleta cozy.

  /// Verde suave: alimento fresco, aún queda tiempo.
  static const freshBg = Color(0xFFE6EFE0);
  static const fresh = Color(0xFF5C7A4F);

  /// Ámbar suave: caduca pronto, conviene usarlo ya.
  static const soonBg = Color(0xFFF8ECCF);
  static const soon = Color(0xFFB5863C);

  /// Rojo terroso suave: caducado (cálido, no alarmante).
  static const expiredBg = Color(0xFFF4DAD4);
  static const expired = Color(0xFFB24A3C);
}

class AppTheme {
  static ThemeData build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.wood,
        primary: AppColors.wood,
        surface: AppColors.card,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(
        base.textTheme,
      ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.wood,
          foregroundColor: AppColors.ink,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: AppColors.wood,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: selected ? 24 : 22,
            color: selected ? AppColors.ink : AppColors.inkMuted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.ink : AppColors.inkMuted,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          );
        }),
      ),
    );
  }

  /// Decoración estándar de tarjeta (para Containers).
  ///
  /// Se conserva por compatibilidad con el código existente. Para nuevas
  /// pantallas prefiere [surfaceDecoration], que usa la escala [AppRadius] y
  /// los niveles [AppElevation].
  static BoxDecoration cardDecoration({double radius = 24}) => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: const [
      BoxShadow(
        color: AppColors.softShadow,
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  );

  /// Decoración de superficie recomendada de aquí en adelante.
  ///
  /// Combina la escala de radios [AppRadius] con los niveles de sombra
  /// intencionados de [AppElevation]:
  /// - `elevation: 0` → plano (sin sombra).
  /// - `elevation: 1` → tarjeta en reposo (por defecto).
  /// - `elevation: 2` → elemento elevado / interactivo.
  ///
  /// Ejemplo: `AppTheme.surfaceDecoration(elevation: 2)`.
  static BoxDecoration surfaceDecoration({
    double radius = AppRadius.lg,
    int elevation = 1,
    Color color = AppColors.card,
  }) {
    final List<BoxShadow> shadow = switch (elevation) {
      0 => AppElevation.level0,
      1 => AppElevation.level1,
      _ => AppElevation.level2,
    };
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadow,
    );
  }
}
