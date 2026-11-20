/// Zonas de "Mi cocina" (nevera, congelador, despensa…) y su resumen.
/// Lógica PURA para poder testearla.
library;

import '../models/inventory_item.dart';
import '../services/shelf_life.dart';
import '../utils/practical_quantity.dart';
import '../utils/shopping_display.dart';
import '../widgets/food_category_icon.dart';

enum KitchenZone {
  nevera('Nevera', 'Nevera'),
  congelador('Congelador', 'Congelador'),
  despensa('Despensa', 'Despensa'),
  especias('Especias', 'Condimentos'),
  limpieza('Limpieza', 'Limpieza'),
  hogar('Hogar', 'Varios');

  const KitchenZone(this.filterKey, this.label);

  /// Clave del filtro de la pantalla de inventario.
  final String filterKey;
  final String label;

  /// Ilustración propia de esta zona en `assets/images/zona_*.png`.
  String get assetPath => switch (this) {
    KitchenZone.nevera => 'assets/images/zona_nevera.png',
    KitchenZone.congelador => 'assets/images/zona_congelador.png',
    KitchenZone.despensa => 'assets/images/zona_despensa.png',
    KitchenZone.especias => 'assets/images/zona_condimentos.png',
    KitchenZone.limpieza => 'assets/images/zona_limpieza.png',
    KitchenZone.hogar => 'assets/images/zona_varios.png',
  };

  /// ¿Pertenece [i] a esta zona? (misma regla que el filtro del inventario).
  /// Lo de casa se reparte por su zona guardada ('Hogar' = Varios, el cajón
  /// de sastre); si se guardó en una zona de comida, se deduce por el nombre.
  /// La comida, por su zona.
  bool matches(InventoryItem i) {
    final home = i.itemType != 'comida' || _homeZones.contains(i.category);
    return switch (this) {
      KitchenZone.hogar => home && _homeZone(i) == 'Hogar',
      KitchenZone.limpieza => home && _homeZone(i) == 'Limpieza',
      KitchenZone.nevera => !home && i.category == 'Nevera',
      KitchenZone.congelador => !home && i.category == 'Congelador',
      KitchenZone.especias => !home && i.category == 'Especias',
      KitchenZone.despensa =>
        !home &&
            // Las bebidas ya no son zona aparte: lo guardado como 'Bebidas'
            // sale aquí, en su estante.
            !const {'Nevera', 'Congelador', 'Especias'}.contains(i.category),
    };
  }

  static const _homeZones = {'Limpieza', 'Hogar'};

  static String _homeZone(InventoryItem i) => _homeZones.contains(i.category)
      ? i.category
      : ShelfLife.householdZone(i.name);

  static KitchenZone? byFilterKey(String key) {
    for (final z in KitchenZone.values) {
      if (z.filterKey == key) return z;
    }
    return null;
  }
}

/// Semáforo por nivel (Lleno / A medias / Se acaba) solo para especias,
/// condimentos y productos de limpieza/hogar contados en unidades. Nunca
/// oculta gramos ni volumen en comida o fruta/verdura a peso.
bool isLevelTracked(InventoryItem i) {
  if (i.kind != 'ingredient' || isMeasureUnit(i.unit)) return false;
  return i.itemType == 'hogar' ||
      i.category == 'Especias' ||
      i.category == 'Limpieza' ||
      i.category == 'Hogar' ||
      isCondiment(i.name);
}

/// ¿Está [i] abierto a medias? Cierto si tiene un tamaño de envase conocido en
/// medida y queda menos de un envase entero, o si es un básico por nivel por
/// debajo de 1.
bool isPantryItemOpened(InventoryItem i, double? packSize) {
  if (i.kind != 'ingredient' || i.itemType != 'comida') return false;
  if (packSize != null &&
      packSize > 0 &&
      isMeasureUnit(i.unit) &&
      i.quantity > 0 &&
      i.quantity < packSize - 1e-3) {
    return true;
  }
  if (isLevelTracked(i) && i.quantity > 0 && i.quantity < 1) {
    return true;
  }
  return false;
}

/// Productos de comida que conviene gastar pronto (caducados, caducan en ≤3
/// días, platos listos en la nevera o envases abiertos), ordenados por
/// prioridad.
List<InventoryItem> urgentPantryItems(
  List<InventoryItem> items, {
  double? Function(InventoryItem)? packSizeOf,
}) {
  int? priority(InventoryItem i) {
    if (i.itemType != 'comida' || i.category == 'Especias' || i.quantity <= 0) {
      return null;
    }
    if (i.expiryStatus == ExpiryStatus.caducado) return 0;
    if (i.expiryStatus == ExpiryStatus.pronto) return 1;
    if (i.kind == 'dish' && i.category == 'Nevera') return 2;
    if (isPantryItemOpened(i, packSizeOf?.call(i))) return 3;
    return null;
  }

  final urgent = <({int rank, InventoryItem item})>[
    for (final i in items)
      if (priority(i) case final r?) (rank: r, item: i),
  ];
  urgent.sort((a, b) {
    final byRank = a.rank.compareTo(b.rank);
    if (byRank != 0) return byRank;
    final da = a.item.daysUntilExpiry, db = b.item.daysUntilExpiry;
    if (da != null && db != null && da != db) return da.compareTo(db);
    if (da != null && db == null) return -1;
    if (da == null && db != null) return 1;
    return a.item.name.toLowerCase().compareTo(b.item.name.toLowerCase());
  });
  return [for (final u in urgent) u.item];
}

/// Estante dentro de una zona (nevera, despensa, congelador): agrupa lo que
/// hay por tipo para encontrarlo de un vistazo.
enum PantryShelf {
  preparados,
  verduraFruta,
  carnePescado,
  lacteos,
  bebidas,
  panCereales,
  conservas,
  dulces,
  otros,
}

/// Estante de [i]: los tápers y platos van con los preparados; el resto,
/// por el tipo de alimento. Lo guardado en la antigua zona 'Bebidas', con las
/// bebidas.
PantryShelf shelfOf(InventoryItem i) {
  if (i.kind == 'dish' || i.recipeId != null) return PantryShelf.preparados;
  final cat = CategoryIcons.categoryFor(i.name, itemType: i.itemType);
  return switch (cat) {
    FoodCategory.preparados => PantryShelf.preparados,
    FoodCategory.verdura || FoodCategory.fruta => PantryShelf.verduraFruta,
    FoodCategory.carne || FoodCategory.pescado => PantryShelf.carnePescado,
    FoodCategory.lacteos => PantryShelf.lacteos,
    FoodCategory.bebidas => PantryShelf.bebidas,
    FoodCategory.panaderia || FoodCategory.cereales => PantryShelf.panCereales,
    FoodCategory.conservas => PantryShelf.conservas,
    FoodCategory.dulces => PantryShelf.dulces,
    _ when i.category == 'Bebidas' => PantryShelf.bebidas,
    _ => PantryShelf.otros,
  };
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
            zone != KitchenZone.especias &&
            zone != KitchenZone.limpieza &&
            zone != KitchenZone.hogar;
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
