/// Zonas de "Mi cocina" (nevera, congelador, despensa…) y su resumen.
/// Lógica PURA para poder testearla.
library;

import '../models/inventory_item.dart';

enum KitchenZone {
  nevera('Nevera', 'Nevera'),
  congelador('Congelador', 'Congelador'),
  despensa('Despensa', 'Despensa'),
  bebidas('Bebidas', 'Bebidas'),
  especias('Especias', 'Condimentos'),
  hogar('Hogar', 'Limpieza');

  const KitchenZone(this.filterKey, this.label);

  /// Clave del filtro de la pantalla de inventario.
  final String filterKey;
  final String label;

  /// ¿Pertenece [i] a esta zona? (misma regla que el filtro del inventario).
  bool matches(InventoryItem i) {
    final food = i.itemType == 'comida';
    return switch (this) {
      KitchenZone.hogar => !food,
      KitchenZone.nevera => food && i.category == 'Nevera',
      KitchenZone.congelador => food && i.category == 'Congelador',
      KitchenZone.especias => food && i.category == 'Especias',
      KitchenZone.bebidas => food && i.category == 'Bebidas',
      KitchenZone.despensa =>
        food &&
            !const {
              'Nevera',
              'Congelador',
              'Especias',
              'Bebidas',
            }.contains(i.category),
    };
  }

  static KitchenZone? byFilterKey(String key) {
    for (final z in KitchenZone.values) {
      if (z.filterKey == key) return z;
    }
    return null;
  }
}

class ZoneSummary {
  const ZoneSummary({
    required this.zone,
    required this.count,
    required this.soon,
    required this.expired,
  });

  final KitchenZone zone;
  final int count;

  /// Caducan pronto (sin contar los ya caducados).
  final int soon;
  final int expired;
}

/// Resumen por zona, en el orden de [KitchenZone]. Las especias y lo de hogar
/// no cuentan caducidades (no se les muestra semáforo).
List<ZoneSummary> summarizeZones(List<InventoryItem> items) {
  return [
    for (final zone in KitchenZone.values)
      () {
        var count = 0, soon = 0, expired = 0;
        final tracksExpiry =
            zone != KitchenZone.especias && zone != KitchenZone.hogar;
        for (final i in items) {
          if (!zone.matches(i)) continue;
          count++;
          if (!tracksExpiry) continue;
          switch (i.expiryStatus) {
            case ExpiryStatus.pronto:
              soon++;
            case ExpiryStatus.caducado:
              expired++;
            case ExpiryStatus.fresco:
            case ExpiryStatus.sinFecha:
              break;
          }
        }
        return ZoneSummary(
          zone: zone,
          count: count,
          soon: soon,
          expired: expired,
        );
      }(),
  ];
}
