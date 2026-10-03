import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/food_category_icon.dart';

/// Precio conocido de un producto (aprendido de los tickets del hogar).
class ProductPrice {
  final String nameNormalized;
  final String? displayName;
  final double? lastUnitPrice;
  final double? avgUnitPrice;
  final int samples;

  const ProductPrice({
    required this.nameNormalized,
    this.displayName,
    this.lastUnitPrice,
    this.avgUnitPrice,
    this.samples = 0,
  });

  /// Mejor estimación de precio por unidad: la media si hay varias muestras,
  /// si no el último visto.
  double? get bestPrice =>
      (samples >= 2 ? avgUnitPrice : lastUnitPrice) ??
      lastUnitPrice ??
      avgUnitPrice;

  factory ProductPrice.fromMap(Map<String, dynamic> m) {
    double? d(dynamic v) => (v as num?)?.toDouble();
    return ProductPrice(
      nameNormalized: (m['name_normalized'] ?? '').toString(),
      displayName: m['display_name'] as String?,
      lastUnitPrice: d(m['last_unit_price']),
      avgUnitPrice: d(m['avg_unit_price']),
      samples: (m['samples'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Estimación del coste de una lista (p. ej. la lista de la compra o los
/// ingredientes de una comida).
class CostEstimate {
  /// Coste total estimado (solo de los productos con precio conocido).
  final double total;

  /// Nº de líneas con precio conocido / total de líneas.
  final int priced;
  final int totalItems;

  const CostEstimate({
    required this.total,
    required this.priced,
    required this.totalItems,
  });

  /// true si tenemos precio de una mayoría razonable (para fiarnos del total).
  bool get isReliable => totalItems > 0 && priced >= (totalItems * 0.5);
}

/// Aprende y consulta los precios de los productos del hogar a partir de los
/// tickets. Nunca lanza hacia la UI (best-effort).
class PriceMemory {
  PriceMemory(this._client);
  final SupabaseClient _client;
  static const String _table = 'product_prices';

  static String keyFor(String name) => CategoryIcons.normalize(name);

  /// Actualiza la memoria de precios con las líneas de un ticket. Cada línea:
  /// {name, quantity, totalPrice}. Calcula el precio UNITARIO (total/cantidad)
  /// y actualiza last/avg/samples por producto. Best-effort.
  Future<void> learnFromTicket(
    String homeId,
    List<({String name, double quantity, double totalPrice})> lines,
  ) async {
    if (homeId.isEmpty) return;
    try {
      // Precio unitario por producto normalizado (una muestra por producto y
      // ticket; si se repite en el mismo ticket, sumamos cantidades y precio).
      final byKey = <String, ({String name, double qty, double total})>{};
      for (final l in lines) {
        if (l.totalPrice <= 0) continue;
        final key = keyFor(l.name);
        if (key.isEmpty) continue;
        final double qty = l.quantity > 0 ? l.quantity : 1.0;
        final prev = byKey[key];
        if (prev == null) {
          byKey[key] = (name: l.name, qty: qty, total: l.totalPrice);
        } else {
          byKey[key] = (
            name: prev.name,
            qty: prev.qty + qty,
            total: prev.total + l.totalPrice,
          );
        }
      }
      if (byKey.isEmpty) return;

      // Precios actuales de esos productos (para actualizar media y samples).
      final keys = byKey.keys.toList();
      final existing = await _client
          .from(_table)
          .select('name_normalized, avg_unit_price, samples')
          .eq('home_id', homeId)
          .inFilter('name_normalized', keys);
      final prevByKey = <String, ({double? avg, int samples})>{};
      for (final row in (existing as List)) {
        final m = row as Map<String, dynamic>;
        prevByKey[(m['name_normalized'] ?? '').toString()] = (
          avg: (m['avg_unit_price'] as num?)?.toDouble(),
          samples: (m['samples'] as num?)?.toInt() ?? 0,
        );
      }

      final now = DateTime.now().toUtc().toIso8601String();
      final rows = <Map<String, dynamic>>[];
      byKey.forEach((key, v) {
        final unit = v.total / v.qty;
        final prev = prevByKey[key];
        final prevSamples = prev?.samples ?? 0;
        final prevAvg = prev?.avg;
        final newSamples = prevSamples + 1;
        // Media incremental.
        final newAvg = prevAvg == null
            ? unit
            : (prevAvg * prevSamples + unit) / newSamples;
        rows.add({
          'home_id': homeId,
          'name_normalized': key,
          'display_name': v.name,
          'last_unit_price': unit,
          'avg_unit_price': newAvg,
          'samples': newSamples,
          'last_seen': now,
        });
      });

      await _client
          .from(_table)
          .upsert(rows, onConflict: 'home_id,name_normalized');
    } catch (_) {
      // best-effort: si falla el aprendizaje de precios, no rompe el ticket.
    }
  }

  /// Carga todos los precios conocidos del hogar, indexados por clave.
  Future<Map<String, ProductPrice>> loadAll(String homeId) async {
    final out = <String, ProductPrice>{};
    if (homeId.isEmpty) return out;
    try {
      final res = await _client.from(_table).select().eq('home_id', homeId);
      for (final row in (res as List)) {
        final p = ProductPrice.fromMap(row as Map<String, dynamic>);
        out[p.nameNormalized] = p;
      }
    } catch (_) {}
    return out;
  }

  /// Estima el coste de una lista de productos {name, quantity} usando los
  /// precios conocidos ([prices], de [loadAll]). Multiplica por la cantidad
  /// cuando la hay; si no, cuenta 1 unidad.
  static CostEstimate estimateCost(
    List<({String name, double? quantity})> items,
    Map<String, ProductPrice> prices,
  ) {
    double total = 0;
    var priced = 0;
    for (final it in items) {
      final p = prices[keyFor(it.name)];
      final unit = p?.bestPrice;
      if (unit == null) continue;
      total += unit * (it.quantity ?? 1);
      priced++;
    }
    return CostEstimate(total: total, priced: priced, totalItems: items.length);
  }
}

/// Coste estimado de una receta por ración.
class RecipeCost {
  /// Coste total de la receta (todas las raciones).
  final double total;

  /// Coste por ración.
  final double perServing;

  /// true si ALGÚN ingrediente usó precio aproximado (no de ticket real).
  final bool approx;

  const RecipeCost({
    required this.total,
    required this.perServing,
    required this.approx,
  });
}

/// Un ingrediente para calcular el coste de la receta.
typedef CostIngredient = ({String name, double? quantity, String? unit});

/// Calcula el coste de una receta sumando sus ingredientes. Para cada uno:
///   1. si hay PRECIO REAL del ticket (prices) -> precio por unidad × cantidad;
///   2. si no, PRECIO APROXIMADO por tipo de alimento ([ApproxPrice]).
/// Devuelve el total y por ración, y marca approx=true si se usó alguna
/// estimación. Lógica PURA (recibe la función de aproximado inyectada para no
/// acoplar con utils en el test).
RecipeCost computeRecipeCost({
  required List<CostIngredient> ingredients,
  required Map<String, ProductPrice> prices,
  required int servings,
  required double? Function(String name, double? quantity, String? unit)
  approxOf,
}) {
  double total = 0;
  var usedApprox = false;
  for (final ing in ingredients) {
    final p = prices[PriceMemory.keyFor(ing.name)];
    final real = p?.bestPrice;
    if (real != null) {
      // Precio real por unidad del ticket × cantidad (o 1 si no hay cantidad).
      total += real * (ing.quantity ?? 1);
    } else {
      final approx = approxOf(ing.name, ing.quantity, ing.unit);
      if (approx != null) {
        total += approx;
        usedApprox = true;
      }
    }
  }
  final s = servings < 1 ? 1 : servings;
  return RecipeCost(total: total, perServing: total / s, approx: usedApprox);
}
