import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta y estilo "Cozy" de PrezHome, centralizados.
class AppColors {
  static const cream = Color(0xFFFDF8E1); // fondo amarillo pastel cálido
  static const wood = Color(0xFFE2C792); // madera clara (acento)
  static const woodDark = Color(0xFFB58A3C); // acento oscuro para texto/números
  static const ink = Color(0xFF1E1E1E); // gris muy oscuro (texto)
  static const card = Colors.white;
  static const softShadow = Color(0x14000000);

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
    );
  }

  /// Decoración estándar de tarjeta (para Containers).
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
}
