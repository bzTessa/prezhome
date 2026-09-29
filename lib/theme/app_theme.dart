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
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
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
