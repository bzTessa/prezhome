/// Lógica PURA de la BARRA DE CADUCIDAD que usa el grid de la despensa.
///
/// A partir del estado de caducidad de un [InventoryItem] calcula una FRACCIÓN
/// 0..1 (cuánta barra pintar) y la CLAVE DE ESTADO/color. Es presentación pura,
/// así que depende SOLO de `models/inventory_item.dart` para el enum
/// [ExpiryStatus] y para `daysUntilExpiry`. NO importa `material.dart`: los
/// colores concretos (AppColors) se eligen en el widget a partir del estado,
/// para no acoplar esta utilidad al tema (ver FEAT-003).
///
/// Semántica de la fracción (la barra representa "vida útil restante"):
/// - [ExpiryStatus.sinFecha]  -> 0.0  (el widget pintará una barra neutra o
///   ninguna; no hay información de vida útil).
/// - [ExpiryStatus.caducado]  -> 1.0  (barra LLENA en color de alarma; no es
///   proporción de vida restante sino señal de "agotado/caducado").
/// - [ExpiryStatus.pronto]    -> fracción PEQUEÑA que CRECE con los días
///   (0..3 días), con un mínimo visible [kProntoMinFraction] para que "caduca
///   hoy" (0 días) se vea casi vacía pero NO invisible.
/// - [ExpiryStatus.fresco]    -> `min(días / freshWindowDays, 1.0)`, es decir
///   cuanto más lejos la caducidad, más llena, con tope en 1.0.
///
/// La función es DETERMINISTA, MONÓTONA NO DECRECIENTE respecto a los días
/// dentro de pronto/fresco y SIEMPRE devuelve un valor dentro de [0, 1].
library;

import '../models/inventory_item.dart';

/// Ventana de "frescura" por defecto, en días. Es el horizonte con el que se
/// normaliza la vida útil restante: a partir de [freshWindowDays] días o más la
/// barra está llena (1.0). Dos semanas es un valor genérico y cómodo para que
/// la usuaria vea de un vistazo lo que aguanta sin tener que ajustarlo.
const int kFreshWindowDays = 14;

/// Mínimo visible para el estado "pronto". Garantiza que "caduca hoy" (0 días)
/// no quede como una barra invisible: se verá casi vacía pero perceptible.
const double kProntoMinFraction = 0.08;

/// Devuelve la fracción 0..1 de barra a pintar para un estado de caducidad.
///
/// - [status]: estado de caducidad (ver [ExpiryStatus]).
/// - [daysUntilExpiry]: días que quedan hasta la caducidad efectiva; puede ser
///   null (sin fecha) o negativo (ya caducado). Solo se usa en pronto/fresco.
/// - [freshWindowDays]: horizonte de normalización para el estado fresco (y la
///   escala base de "pronto"); por defecto [kFreshWindowDays].
///
/// El resultado está SIEMPRE acotado a [0, 1].
double expiryBarFraction(
  ExpiryStatus status,
  int? daysUntilExpiry, {
  int freshWindowDays = kFreshWindowDays,
}) {
  switch (status) {
    case ExpiryStatus.sinFecha:
      // No hay información de vida útil: barra vacía/neutra.
      return 0.0;
    case ExpiryStatus.caducado:
      // Barra llena como señal de alarma (no es proporción).
      return 1.0;
    case ExpiryStatus.pronto:
      // 0..3 días: fracción pequeña que crece con los días. Partimos de la
      // misma escala del estado fresco (días / freshWindowDays) pero elevada a
      // un mínimo visible para que "caduca hoy" no sea invisible.
      final days = (daysUntilExpiry ?? 0).clamp(0, freshWindowDays);
      final raw = days / freshWindowDays;
      final value = raw < kProntoMinFraction ? kProntoMinFraction : raw;
      return value.clamp(0.0, 1.0);
    case ExpiryStatus.fresco:
      // Proporción de vida útil restante respecto a la ventana de frescura,
      // con tope en 1.0 para caducidades muy lejanas.
      final days = (daysUntilExpiry ?? 0).clamp(0, freshWindowDays);
      final value = days / freshWindowDays;
      return value.clamp(0.0, 1.0);
  }
}

/// Estado de caducidad del [item], usado como CLAVE para elegir el color de la
/// barra en el widget (fresco/pronto/caducado/sinFecha -> AppColors en FEAT-003).
/// Es un simple reenvío a [InventoryItem.expiryStatus] para que el widget y los
/// tests tengan un único punto de entrada en esta utilidad.
ExpiryStatus expiryBarStatusFor(InventoryItem item) => item.expiryStatus;

/// Fracción de barra directamente a partir de un [item], combinando su estado y
/// sus días restantes. Atajo cómodo para el widget del grid.
double expiryBarFractionFor(
  InventoryItem item, {
  int freshWindowDays = kFreshWindowDays,
}) {
  return expiryBarFraction(
    item.expiryStatus,
    item.daysUntilExpiry,
    freshWindowDays: freshWindowDays,
  );
}
