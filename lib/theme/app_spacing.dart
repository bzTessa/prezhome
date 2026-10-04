import 'package:flutter/widgets.dart';

/// Escala de espaciados de PrezHome.
///
/// Esta clase es la ÚNICA fuente de verdad para separaciones, paddings y
/// gaps de la app. Sustituye los paddings "a ojo" dispersos (14 / 16 / 18 /
/// 20...) por una escala fija de 4 en 4 que da ritmo visual coherente.
///
/// De aquí en adelante, en lugar de `EdgeInsets.all(16)` usa
/// `EdgeInsets.all(AppSpacing.lg)`; en lugar de `SizedBox(height: 12)` usa
/// `SizedBox(height: AppSpacing.md)`.
class AppSpacing {
  const AppSpacing._();

  /// 4 — micro separación (entre icono y texto muy pegados).
  static const double xs = 4;

  /// 8 — separación pequeña (gaps dentro de un chip o fila compacta).
  static const double sm = 8;

  /// 12 — separación media (entre elementos relacionados).
  static const double md = 12;

  /// 16 — separación estándar (padding de tarjetas, gap entre tarjetas).
  static const double lg = 16;

  /// 20 — separación amplia.
  static const double xl = 20;

  /// 24 — separación grande (márgenes de sección).
  static const double xxl = 24;

  /// 32 — separación extra grande (bloques principales, cabeceras).
  static const double xxxl = 32;

  // --- Helpers de conveniencia ----------------------------------------------
  // Paddings reutilizables para no repetir EdgeInsets por toda la app.

  /// Padding interior estándar de una tarjeta.
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  /// Padding compacto para chips e identificadores pequeños.
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  /// Padding horizontal de pantalla (márgenes laterales del contenido).
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: xl,
  );
}
