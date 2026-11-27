import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/animations/app_transitions.dart';

import 'app_elevation.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

// Reexportamos los tokens del sistema de diseño para que un único import de
// `app_theme.dart` dé acceso a toda la paleta y escalas (sin dependencias
// circulares: estos ficheros no importan de vuelta a AppTheme).
export 'app_elevation.dart';
export 'app_radius.dart';
export 'app_spacing.dart';
export 'app_text_styles.dart';

/// Paleta y estilo "Cozy" de PrezHome, centralizados.
class AppColors {
  /// Modo oscuro activo. Lo fija la raíz de la app según el brillo del sistema.
  static bool dark = false;

  /// Estilo "Cocina cálida" (ver [AppLook]). Solo cambia la paleta clara y
  /// las letras; el modo oscuro es el mismo en los dos estilos.
  static bool warm = true;
  static bool get _w => warm && !dark;

  static Color get cream => dark
      ? const Color(0xFF181512)
      : _w
      ? const Color(0xFFF4ECDF) // crema tostado
      : const Color(0xFFFAF7F2); // porcelana cálida limpia
  static Color get wood => dark
      ? const Color(0xFF7A6238)
      : const Color(0xFFE2C792); // madera clara (acento)
  static Color get woodDark => dark
      ? const Color(0xFFE2C792)
      : const Color(
          0xFF8C6420,
        ); // acento oscuro para texto/números (≥4,5:1 sobre crema)
  static Color get ink => dark
      ? const Color(0xFFF2EBD9)
      : _w
      ? const Color(0xFF241C15)
      : const Color(0xFF1E1E1E); // gris muy oscuro (texto)
  static Color get card => dark
      ? const Color(0xFF24201C)
      : _w
      ? const Color(0xFFFFFCF6)
      : const Color(0xFFFFFFFF);
  static Color get softShadow =>
      dark ? const Color(0x40000000) : const Color(0x14000000);

  /// Gris de marca para texto secundario / apoyo.
  ///
  /// Reemplaza los `Colors.grey[500/600/700]` sueltos repartidos por la app.
  /// Derivado del tono `ink` pero más claro para dar jerarquía sin perder
  /// la calidez de la paleta.
  static Color get inkMuted => dark
      ? const Color(0xFFA89F8E)
      : _w
      ? const Color(0xFF6B5C4C)
      : const Color(0xFF6E6558);

  /// Línea suave crema para separadores, asas de hojas y bordes discretos.
  static Color get line => dark
      ? const Color(0xFF3A342B)
      : _w
      ? const Color(0xFFE6DACA)
      : const Color(0xFFEFEAE0);

  /// Sombra aún más suave que `softShadow`, para superficies en reposo que
  /// necesitan apenas una pizca de profundidad (nivel 1 de [AppElevation]).
  static Color get faintShadow => dark
      ? const Color(0x26000000)
      : _w
      ? const Color(0x00000000) // tarjetas planas de papel
      : const Color(0x0D000000);

  /// Sombra algo más marcada para elementos elevados / interactivos
  /// (nivel 2 de [AppElevation]).
  static Color get mediumShadow =>
      dark ? const Color(0x59000000) : const Color(0x1F000000);

  // --- Tonos para chips e identificadores con jerarquía visual ---------------
  // Mantienen la calidez de la paleta pero dan contraste suave entre tipos de
  // información (tipo de comida, tiempo, kcal, favorita...). Se usan como pares
  // fondo + texto/icono para chips tipo "pastel".

  /// Verde salvia suave: tiempo de preparación (reloj).
  static Color get sageBg => dark
      ? const Color(0xFF2A3326)
      : _w
      ? const Color(0xFFE3EEDF)
      : const Color(0xFFE8F3E9);
  static Color get sage =>
      dark ? const Color(0xFF7E9C6E) : const Color(0xFF4E7A51);

  /// Terracota suave: calorías / energía (destacado cálido).
  static Color get terracottaBg => dark
      ? const Color(0xFF3A2A22)
      : _w
      ? const Color(0xFFFBE3D6)
      : const Color(0xFFFCECE6);
  static Color get terracotta => dark
      ? const Color(0xFFE56B43)
      : _w
      ? const Color(0xFFB8431F)
      : const Color(0xFFD14E28);

  /// Terracota para texto pequeño: el de marca no llega a 4,5:1 sobre crema.
  static Color get terracottaText => dark
      ? const Color(0xFFE56B43)
      : _w
      ? const Color(0xFFA23C1A)
      : const Color(0xFFB53E1B);

  /// Terracota al pulsar.
  static Color get terracottaPressed => const Color(0xFF9E3B1C);

  /// Melocotón suave: tipo de comida principal.
  static Color get peachBg => dark
      ? const Color(0xFF3A3020)
      : _w
      ? const Color(0xFFF7E3C4)
      : const Color(0xFFF6E6CC);
  static Color get peach =>
      dark ? const Color(0xFFD9AE73) : const Color(0xFF9B6B2E);

  /// Azul grisáceo suave: congelable / frío.
  static Color get frostBg =>
      dark ? const Color(0xFF22303A) : const Color(0xFFDFE9EF);
  static Color get frost =>
      dark ? const Color(0xFF8DB3C7) : const Color(0xFF4A7489);

  /// Dorado de la corona del logo: favorita y puntos.
  static Color get gold =>
      dark ? const Color(0xFFF2B632) : const Color(0xFFE5A01D);
  static Color get favorite => gold;

  /// Fondo de las insignias de puntos.
  static Color get goldBg =>
      dark ? const Color(0xFF3A3020) : const Color(0xFFFEF5DC);

  // --- Estilo táctil del logo ("Warm Tactile") -------------------------------

  /// Tarjeta táctil: papel cálido con borde de trazo.
  static Color get paper => card;

  /// Hueco crema para iconos dentro de una tarjeta táctil.
  static Color get iconTile => dark
      ? const Color(0xFF302A24)
      : _w
      ? const Color(0xFFF1E7D8)
      : const Color(0xFFF2ECE2);

  /// Borde de tarjeta: línea cálida fina en claro para recortarla sobre el
  /// fondo crema, y línea sutil en oscuro.
  static Color get cardEdge => dark
      ? const Color(0xFF363029)
      : _w
      ? const Color(0xFFEDE3D3)
      : const Color(0xFFEBE4D8);

  /// Sombra cálida y difusa de las tarjetas.
  static Color get cardShadow =>
      dark ? const Color(0x66000000) : const Color(0x1838291E);

  /// Trazo marrón tinta cálido para botones y elementos destacados del estilo
  /// táctil (acorde al trazo de la mascota).
  static Color get stroke =>
      dark ? const Color(0xFF534538) : const Color(0xFF3B2618);

  /// Verde de "hecho": producto en el carro, tarea completada.
  static Color get done =>
      dark ? const Color(0xFF5FAF7E) : const Color(0xFF3B8A5A);

  /// Texto sobre los rellenos de marca claros (dorado, madera, verde):
  /// carbón para mantener contraste en claro y oscuro.
  static const Color onBrand = Color(0xFF1E1E1E);

  /// Texto e iconos sobre botones y franjas en terracota: crema cálido.
  static const Color onTerracotta = Color(0xFFFFFDF7);

  /// Lila suave: zona "Hogar" y objetivo de lotes.
  static Color get lilacBg =>
      dark ? const Color(0xFF2F2938) : const Color(0xFFEDE7F3);
  static Color get lilac =>
      dark ? const Color(0xFFB9A6D6) : const Color(0xFF6E5A8A);

  // --- Estados de caducidad --------------------------------------------------
  // Pares fondo + acento cálidos y suaves (nada de rojos chillones) para que
  // la usuaria entienda de un vistazo si algo está fresco, caduca pronto o ya
  // ha caducado. Consistentes con el resto de la paleta cozy.

  /// Verde suave: alimento fresco, aún queda tiempo.
  static Color get freshBg =>
      dark ? const Color(0xFF233026) : const Color(0xFFE6F4EA);
  static Color get fresh =>
      dark ? const Color(0xFF5FAF7E) : const Color(0xFF3B8A5A);

  /// Ámbar suave: caduca pronto, conviene usarlo ya.
  static Color get soonBg =>
      dark ? const Color(0xFF3A3220) : const Color(0xFFFFF3D6);
  // Texto ámbar más oscuro que el #E89B23 de las insignias para que se lea.
  static Color get soon =>
      dark ? const Color(0xFFE0B46A) : const Color(0xFFB5863C);

  /// Rojo terroso suave: caducado (cálido, no alarmante).
  static Color get expiredBg =>
      dark ? const Color(0xFF3D2420) : const Color(0xFFFDE8E6);
  static Color get expired =>
      dark ? const Color(0xFFE5675A) : const Color(0xFFD93829);
}

class AppTheme {
  static ThemeData build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: AppColors.dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.terracotta,
        primary: AppColors.terracotta,
        onPrimary: AppColors.onTerracotta,
        secondary: AppColors.gold,
        onSecondary: AppColors.onBrand,
        surface: AppColors.card,
        onSurface: AppColors.ink,
        surfaceContainerHighest: AppColors.iconTile,
        outline: AppColors.stroke,
        brightness: AppColors.dark ? Brightness.dark : Brightness.light,
      ),
    );

    return base.copyWith(
      textTheme: _withSerifHeadings(
        AppColors.warm
            ? GoogleFonts.dmSansTextTheme(base.textTheme)
            : GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
      ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppFonts.serif(
          color: AppColors.ink,
          fontSize: 22,
          letterSpacing: -0.3,
        ),
      ),
      // Pulsación cálida y con esquinas, no el gris cuadrado de Material.
      splashColor: AppColors.wood.withValues(alpha: 0.22),
      highlightColor: AppColors.wood.withValues(alpha: 0.14),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundBuilder: pressFeedbackBuilder,
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.cream,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: AppFonts.sans(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      // Campos de texto: rellenos en blanco, sin borde y con foco en madera.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        labelStyle: TextStyle(color: AppColors.inkMuted),
        floatingLabelStyle: TextStyle(
          color: AppColors.woodDark,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(color: AppColors.inkMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.woodDark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.expired, width: 1.5),
        ),
      ),
      // Chips de elección: píldora de tarjeta; la elegida, en madera. El texto
      // va siempre en tinta, que contrasta con ambos fondos en claro y oscuro.
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.card,
        selectedColor: AppColors.wood,
        checkmarkColor: AppColors.ink,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      // Botón principal: píldora en tinta. Secundario: contorno suave.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundBuilder: pressFeedbackBuilder,
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.cream,
          minimumSize: const Size(64, 52),
          shape: const StadiumBorder(),
          textStyle: AppFonts.sans(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundBuilder: pressFeedbackBuilder,
          foregroundColor: AppColors.ink,
          minimumSize: const Size(64, 48),
          side: BorderSide(color: AppColors.wood, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: AppFonts.sans(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundBuilder: pressFeedbackBuilder,
          foregroundColor: AppColors.woodDark,
          textStyle: AppFonts.sans(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(foregroundBuilder: pressFeedbackBuilder),
      ),
      // Transiciones entre pantallas: fundido + leve subida (iOS conserva
      // la suya para poder deslizar hacia atrás).
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: AppPageTransitionsBuilder(),
          TargetPlatform.windows: AppPageTransitionsBuilder(),
          TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
        },
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.terracotta,
        foregroundColor: AppColors.onTerracotta,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const StadiumBorder(),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.card
              : AppColors.inkMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.sage
              : AppColors.line,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.sage : null,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dividerTheme: DividerThemeData(color: AppColors.line, thickness: 1),
      // Avisos flotantes y redondeados, en el tono de la app (los de error
      // pasan su propio color terracota).
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: AppFonts.sans(
          color: AppColors.cream,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: AppColors.wood,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
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

  /// Títulos grandes en Fraunces (serifa cálida); el resto, Plus Jakarta.
  static TextTheme _withSerifHeadings(TextTheme t) {
    TextStyle? serif(TextStyle? s) =>
        s == null ? null : AppFonts.serif(textStyle: s);
    return t.copyWith(
      displayLarge: serif(t.displayLarge),
      displayMedium: serif(t.displayMedium),
      displaySmall: serif(t.displaySmall),
      headlineLarge: serif(t.headlineLarge),
      headlineMedium: serif(t.headlineMedium),
      headlineSmall: serif(t.headlineSmall),
      titleLarge: serif(t.titleLarge),
    );
  }

  /// Decoración estándar de tarjeta (para Containers).
  ///
  /// Se conserva por compatibilidad con el código existente. Para nuevas
  /// pantallas prefiere [surfaceDecoration], que usa la escala [AppRadius] y
  /// los niveles [AppElevation].
  static BoxDecoration cardDecoration({double radius = AppRadius.lg}) =>
      surfaceDecoration(radius: radius);

  /// Tarjeta de la app: papel cálido, sin borde negro y con sombra suave.
  /// [shadow] 0 = plana; 6 o más = elevada. [borderWidth] se ignora (se
  /// conserva para no romper llamadas antiguas).
  static BoxDecoration tactileDecoration({
    double radius = 14,
    Color? color,
    double borderWidth = 1.5,
    double shadow = 3,
  }) => BoxDecoration(
    color: color ?? AppColors.paper,
    borderRadius: BorderRadius.circular(radius),
    border: AppElevation.border,
    boxShadow: shadow <= 0
        ? AppElevation.level0
        : shadow >= 6
        ? AppElevation.level2
        : AppElevation.level1,
  );

  /// Superficie táctil destacada (botones clave, barra inferior, tarjetas hero):
  /// borde marrón tinta y sombra dura corta.
  static BoxDecoration heroTactileDecoration({
    double radius = AppRadius.lg,
    Color? color,
    bool pressed = false,
  }) => BoxDecoration(
    color: color ?? AppColors.paper,
    borderRadius: BorderRadius.circular(radius),
    border: AppElevation.tactileBorder,
    boxShadow: pressed ? AppElevation.pressed : AppElevation.tactileShadow,
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
    Color? color,
  }) {
    final List<BoxShadow> shadow = switch (elevation) {
      0 => AppElevation.level0,
      1 => AppElevation.level1,
      _ => AppElevation.level2,
    };
    return BoxDecoration(
      color: color ?? AppColors.card,
      borderRadius: BorderRadius.circular(radius),
      border: elevation == 0 ? null : AppElevation.border,
      boxShadow: shadow,
    );
  }
}
