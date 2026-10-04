import 'package:flutter/widgets.dart';

/// Escala de radios de borde de PrezHome.
///
/// Única fuente de verdad para los `borderRadius`. Mantiene coherencia con los
/// radios reales ya usados en la app (12 / 16 / 24) y añade un valor "pill"
/// para chips totalmente redondeados.
///
/// Usa `BorderRadius.circular(AppRadius.lg)` o directamente los helpers
/// `AppRadius.lgRadius`.
class AppRadius {
  const AppRadius._();

  /// 12 — radio pequeño (chips, inputs, elementos compactos).
  static const double sm = 12;

  /// 16 — radio medio (botones, tarjetas internas).
  static const double md = 16;

  /// 24 — radio grande (tarjetas principales, superficies destacadas).
  static const double lg = 24;

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
