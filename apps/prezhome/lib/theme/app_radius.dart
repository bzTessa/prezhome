import 'package:flutter/widgets.dart';

/// Escala de radios de borde de PrezHome.
///
/// Única fuente de verdad para los `borderRadius`: 10 botones y chips, 14
/// celdas (despensa, tareas, compra) y 20 tarjetas grandes y hojas, más un
/// valor "pill" para chips totalmente redondeados.
///
/// Usa `BorderRadius.circular(AppRadius.lg)` o directamente los helpers
/// `AppRadius.lgRadius`.
class AppRadius {
  const AppRadius._();

  /// 10 — botones, chips y elementos compactos.
  static const double sm = 10;

  /// 14 — celdas de despensa, tareas y compra; campos de texto.
  static const double md = 14;

  /// 20 — tarjetas grandes, hojas y superficies destacadas.
  static const double lg = 20;

  /// 999 — pastilla totalmente redondeada (chips tipo "pill", avatares).
  static const double pill = 999;

  // --- Helpers de conveniencia ----------------------------------------------

  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius pillRadius = BorderRadius.all(
    Radius.circular(pill),
  );
}
