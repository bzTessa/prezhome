/// Zonas de "Mi cocina" (nevera, congelador, despensa…) y su resumen.
/// Lógica PURA para poder testearla.
library;

import '../models/inventory_item.dart';
import '../widgets/food_category_icon.dart';

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

/// Productos repetidos que se unen en uno: [keep] se queda con la suma de
/// cantidades y la caducidad más próxima; [removeIds] sobran.
class PantryMerge {
  const PantryMerge({
    required this.keep,
    required this.quantity,
    required this.expirationDate,
    required this.removeIds,
  });

  final InventoryItem keep;
  final double quantity;
  final DateTime? expirationDate;
  final List<String> removeIds;
}

/// Agrupa los productos iguales (mismo nombre, zona, unidad y tipo). Los platos
/// y preparados (con receta) no se unen: cada táper es distinto.
List<PantryMerge> findPantryDuplicates(List<InventoryItem> items) {
  final groups = <String, List<InventoryItem>>{};
  for (final i in items) {
    if (i.recipeId != null || i.kind != 'ingredient') continue;
    final key = [
      i.itemType,
      i.category,
      i.unit.trim().toLowerCase(),
      CategoryIcons.normalize(i.name),
    ].join('|');
    groups.putIfAbsent(key, () => []).add(i);
  }
  return [
    for (final g in groups.values)
      if (g.length > 1)
        PantryMerge(
          keep: g.first,
          quantity: g.fold(0, (s, i) => s + i.quantity),
          expirationDate: g
              .map((i) => i.expirationDate)
              .whereType<DateTime>()
              .fold<DateTime?>(
                null,
                (a, d) => a == null || d.isBefore(a) ? d : a,
              ),
          removeIds: [for (final i in g.skip(1)) i.id],
        ),
  ];
}
