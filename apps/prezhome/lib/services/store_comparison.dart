import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/practical_quantity.dart';
import '../utils/shopping_display.dart';
import 'product_search_service.dart';

/// Un producto de la lista que se quiere comparar.
typedef BasketItem = ({String name, double? quantity, String? unit});

/// Criterio para calcular totales y elegir qué súper sale mejor.
enum CompareBasis {
  /// Compara la misma cantidad entre súpers (€/kg, €/L, €/ud).
  sameQuantity,

  /// Suma lo que pagas en caja por los envases enteros que necesitas hoy.
  checkoutTotal,
}

/// Lo que se cogería en un súper para una línea de la lista.
class BasketLine {
  const BasketLine({
    required this.index,
    required this.product,
    required this.packs,
    double? comparableCost,
    this.unitPrice,
    this.unitLabel,
    this.packLabel,
    this.targetLabel,
    this.sizeAdjusted = false,
  }) : _comparableCost = comparableCost;

  /// Posición de la línea en la lista comparada.
  final int index;
  final SupermarketProduct product;

  /// Envases o unidades que hay que comprar para cubrir la cantidad.
  final int packs;

  final double? _comparableCost;

  /// Precio por unidad normalizado (€/kg, €/L o €/ud), si se conoce.
  final double? unitPrice;

  /// Unidad de [unitPrice]: 'kg', 'L' o 'ud'.
  final String? unitLabel;

  /// Formato real del producto en este súper ("1 L", "500 g", "12 ud").
  final String? packLabel;

  /// Cantidad común de referencia sobre la que se comparan los súpers ("1 L").
  final String? targetLabel;

  /// `true` cuando el envase difiere de la cantidad común y [cost] se normalizó.
  final bool sizeAdjusted;

  /// Coste real en caja de los envases enteros.
  double get checkoutCost => (product.price ?? 0) * packs;

  /// Coste comparable a igual cantidad (cae a [checkoutCost] si no hay medida).
  double get cost => _comparableCost ?? checkoutCost;

  double costFor(CompareBasis basis) => switch (basis) {
    CompareBasis.sameQuantity => cost,
    CompareBasis.checkoutTotal => checkoutCost,
  };
}

/// La lista de la compra en un súper: qué se encontró y cuánto cuesta.
class StoreBasket {
  const StoreBasket({required this.store, required this.lines});

  /// Clave del catálogo ("mercadona", "lidl_fr"…).
  final String store;

  /// Por índice de la línea de la lista. Lo que no está, no se encontró.
  final Map<int, BasketLine> lines;

  int get found => lines.length;

  double totalForBasis(CompareBasis basis) =>
      lines.values.fold(0.0, (s, l) => s + l.costFor(basis));

  double get total => totalForBasis(CompareBasis.sameQuantity);

  /// Coste solo de las líneas [indexes] (las que tienen todos los súpers).
  double totalFor(
    Set<int> indexes, {
    CompareBasis basis = CompareBasis.sameQuantity,
  }) => indexes.fold(0.0, (s, i) => s + (lines[i]?.costFor(basis) ?? 0));
}

/// Resultado de comparar la lista entre súpers.
class BasketComparison {
  const BasketComparison({
    required this.ranked,
    required this.partial,
    required this.common,
    required this.itemCount,
  });

  /// Súpers comparables, del más barato al más caro (sobre [common]).
  final List<StoreBasket> ranked;

  /// Súpers donde salen muy pocos productos (p. ej. Lidl, solo ofertas): se
  /// enseñan aparte y no entran en el ranking.
  final List<StoreBasket> partial;

  /// Líneas encontradas en TODOS los súpers de [ranked]: la comparación
  /// justa se hace solo con estas. Vacío si solo hay un súper.
  final Set<int> common;

  final int itemCount;

  bool get isEmpty => ranked.isEmpty;

  /// Coste comparable de [b]: lo común si hay, si no todo lo encontrado.
  double comparableTotal(
    StoreBasket b, {
    CompareBasis basis = CompareBasis.sameQuantity,
  }) => common.isEmpty
      ? b.totalForBasis(basis)
      : b.totalFor(common, basis: basis);

  /// Cuánto más cuesta [b] que el más barato según [basis].
  double extraOver(
    StoreBasket b, {
    CompareBasis basis = CompareBasis.sameQuantity,
  }) {
    final ordered = rankedFor(basis);
    return ordered.isEmpty
        ? 0
        : comparableTotal(b, basis: basis) -
              comparableTotal(ordered.first, basis: basis);
  }

  /// Súpers comparables ordenados del más barato al más caro según [basis].
  List<StoreBasket> rankedFor(CompareBasis basis) {
    final copy = [...ranked];
    copy.sort(
      (a, b) => comparableTotal(
        a,
        basis: basis,
      ).compareTo(comparableTotal(b, basis: basis)),
    );
    return copy;
  }
}

/// Línea asignada a uno de los dos súpers al repartir la compra.
class SplitLine {
  const SplitLine({
    required this.itemIndex,
    required this.chosen,
    this.alternative,
    required this.saved,
  });

  final int itemIndex;
  final BasketLine chosen;
  final BasketLine? alternative;
  final double saved;
}

/// Reparto de la lista entre dos supermercados ([storeA] y [storeB]).
class TwoStoreSplit {
  const TwoStoreSplit({
    required this.storeA,
    required this.storeB,
    required this.linesA,
    required this.linesB,
    required this.missingIndices,
    required this.totalA,
    required this.totalB,
    required this.combinedTotal,
    required this.bestSingleStore,
    required this.savings,
    required this.selectableStores,
  });

  final String storeA;
  final String storeB;
  final List<SplitLine> linesA;
  final List<SplitLine> linesB;
  final List<int> missingIndices;
  final double totalA;
  final double totalB;
  final double combinedTotal;

  /// Cuál de los dos súpers habría salido mejor comprando todo lo compartido en
  /// uno solo, y cuánto ahorras repartiéndolo frente a ese único súper.
  final String bestSingleStore;
  final double savings;
  final List<String> selectableStores;
}

/// Una línea que sale por más de esto se descarta: casi siempre es un pack
/// grande o un producto que no es (mismo tope que la estimación de la lista).
const double _maxLineCost = 60;

// Marcas blancas / de súper que impiden encontrar el mismo producto en otra
// cadena cuando la lista trae "Aceite de oliva virgen extra Hacendado".
const Set<String> _storeBrandTokens = {
  'hacendado',
  'bosque',
  'deliplus',
  'mercadona',
  'consum',
  'dia',
  'bonarea',
  'milbona',
  'carrefour',
  'alcampo',
  'auchan',
  'eroski',
  'ahorramas',
  'aldi',
  'bm',
  'hipercor',
  'eliges',
  'gutbio',
  'milsani',
  'alipende',
  'selecta',
  'fuenteliviana',
};

// Prefijos de envase o porción culinaria al inicio ("diente de ajo" -> "ajo").
const Set<String> _leadingPortionTokens = {
  'diente',
  'dientes',
  'cabeza',
  'cabezas',
  'rama',
  'ramas',
  'manojo',
  'manojos',
  'pizca',
  'pizcas',
  'cucharada',
  'cucharadas',
  'cucharadita',
  'cucharaditas',
  'lata',
  'latas',
  'bote',
  'botes',
  'tarro',
  'tarros',
  'paquete',
  'paquetes',
  'bolsa',
  'bolsas',
  'brik',
  'brick',
  'botella',
  'botellas',
  'bandeja',
  'bandejas',
  'tarrina',
  'tarrinas',
  'sobre',
  'sobres',
};

// Modificadores opcionales que se relajan solo si la consulta completa no
// devuelve candidatos en la BD.
const Set<String> _optionalRelaxTokens = {
  'fresco',
  'fresca',
  'frescos',
  'frescas',
  'bote',
  'lata',
  'taquitos',
  'natural',
  'tradicional',
  'casero',
  'casera',
  'suave',
  'intenso',
  'dulce',
};

// Especialidades que no deben ganar a un producto estándar salvo que el usuario
// las haya pedido explícitamente en el nombre.
const Set<String> _specialtyTokens = {
  'lactosa',
  'ecologico',
  'ecologica',
  'ecologicos',
  'ecologicas',
  'eco',
  'bio',
  'calcio',
  'cabra',
  'oveja',
  'proteina',
  'proteinas',
  'zero',
  'avena',
  'soja',
  'almendra',
  'almendras',
  'arroz',
  'desnatada',
  'semidesnatada',
  'light',
  'integral',
  'integrales',
  'descafeinado',
  'descafeinada',
  'sabor',
  'infantil',
};

String _stripAccents(String input) {
  const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const to = 'aaaaaeeeeiiiiooooouuuunc';
  final b = StringBuffer();
  for (final ch in input.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  return b.toString();
}

List<String> _cleanTokens(String input) => _stripAccents(
  input,
).split(RegExp(r'[^a-z0-9]+')).where((t) => t.isNotEmpty).toList();

/// Limpia el nombre de la lista para buscar el MISMO producto entre distintos
/// súpers: quita marcas blancas ("Hacendado", "Consum"…) y envases/porciones
/// iniciales ("diente de ajo" → "ajo"), conservando las palabras de variante.
String comparisonSearchQuery(String name) {
  var tokens = _cleanTokens(name);
  if (tokens.isEmpty) return name.trim();
  while (tokens.length > 1 && _leadingPortionTokens.contains(tokens.first)) {
    tokens = tokens.sublist(1);
    if (tokens.length > 1 && (tokens.first == 'de' || tokens.first == 'del')) {
      tokens = tokens.sublist(1);
    }
  }
  final noBrand = [
    for (final t in tokens)
      if (!_storeBrandTokens.contains(t)) t,
  ];
  final kept = noBrand.isNotEmpty ? noBrand : tokens;
  return kept.join(' ').trim();
}

/// Versión relajada de [cleanQuery] cuando no hubo coincidencias exactas
/// ("espinacas frescas" → "espinacas", "garbanzos cocidos de bote" → "garbanzos cocidos").
/// Devuelve null si no hay nada que relajar.
String? comparisonRelaxedQuery(String cleanQuery) {
  final tokens = _cleanTokens(cleanQuery);
  if (tokens.length < 2) return null;
  final relaxed = [
    for (final t in tokens)
      if (!_optionalRelaxTokens.contains(t) &&
          t != 'de' &&
          t != 'del' &&
          t != 'en')
        t,
  ];
  if (relaxed.isEmpty || relaxed.length == tokens.length) return null;
  return relaxed.join(' ');
}

/// Unidades del producto si el formato las dice ("12 ud", "6 x 33 cl",
/// "6 huevos"). Null si no.
int? _countInSize(String? size) {
  final s = (size ?? '').toLowerCase();
  final m = RegExp(
    r'(\d+)\s*(?:uds?\b|u\b|unidades|unid\b|huevos|piezas|x\b|×)',
  ).firstMatch(s);
  final n = m == null ? null : int.tryParse(m.group(1)!);
  return n != null && n > 0 ? n : null;
}

({double qty, String unit})? _toBaseMeasure(
  ({double quantity, String unit})? parsed,
) {
  if (parsed == null) return null;
  return switch (parsed.unit) {
    'kg' => (qty: parsed.quantity * 1000, unit: 'g'),
    'g' => (qty: parsed.quantity, unit: 'g'),
    'ml' => (qty: parsed.quantity, unit: 'ml'),
    _ => (qty: parsed.quantity * 1000, unit: 'ml'),
  };
}

/// Medida efectiva de [p] en unidad canónica base ('g', 'ml' o 'ud').
/// Lee primero `p.quantity`, luego `p.name`, luego recuentos ("12 ud"), y como
/// último recurso calcula `price / unitPrice` cuando ambos vienen en el catálogo.
({double qty, String unit})? effectiveMeasure(SupermarketProduct p) {
  if (isTicketPrice(p)) return null;
  final fromQty = _toBaseMeasure(parsePackageQuantity(p.quantity));
  if (fromQty != null) return fromQty;
  final fromName = _toBaseMeasure(parsePackageQuantity(p.name));
  if (fromName != null) return fromName;
  final count = _countInSize(p.quantity) ?? _countInSize(p.name);
  if (count != null) return (qty: count.toDouble(), unit: 'ud');

  final price = p.price;
  final unitPrice = p.unitPrice;
  final rawUnit = p.unit?.trim().toLowerCase();
  if (price != null &&
      price > 0 &&
      unitPrice != null &&
      unitPrice > 0 &&
      rawUnit != null) {
    final ratio = price / unitPrice;
    final derived = switch (rawUnit) {
      'kg' || 'kilo' => (qty: ratio * 1000, unit: 'g'),
      'g' || 'gr' => (qty: ratio, unit: 'g'),
      'l' || 'litro' || 'litros' => (qty: ratio * 1000, unit: 'ml'),
      'ml' => (qty: ratio, unit: 'ml'),
      'ud' || 'u' || 'u.' || 'unidad' => (qty: ratio, unit: 'ud'),
      _ => null,
    };
    if (derived != null) {
      final minQ = derived.unit == 'ud' ? 0.9 : 5.0;
      final maxQ = derived.unit == 'ud' ? 500.0 : 50000.0;
      if (derived.qty >= minQ && derived.qty <= maxQ) return derived;
    }
  }
  return null;
}

/// Precio por unidad normalizado (€/kg, €/L o €/ud). Usa `p.unitPrice` si viene
/// del catálogo y, si falta, lo calcula con `p.price` y `effectiveMeasure(p)`.
({double pricePerBase, String displayUnit})? effectiveUnitPrice(
  SupermarketProduct p,
) {
  final up = p.unitPrice;
  final rawUnit = p.unit?.trim().toLowerCase();
  if (up != null && up > 0 && rawUnit != null) {
    final direct = switch (rawUnit) {
      'kg' || 'kilo' => (pricePerBase: up, displayUnit: 'kg'),
      'g' || 'gr' => (pricePerBase: up * 1000, displayUnit: 'kg'),
      'l' || 'litro' || 'litros' => (pricePerBase: up, displayUnit: 'L'),
      'ml' => (pricePerBase: up * 1000, displayUnit: 'L'),
      'ud' || 'u' || 'u.' || 'unidad' => (pricePerBase: up, displayUnit: 'ud'),
      _ => null,
    };
    if (direct != null) return direct;
  }
  final price = p.price;
  if (price == null || price <= 0) return null;
  final m = effectiveMeasure(p);
  if (m == null || m.qty <= 0) return null;
  return switch (m.unit) {
    'g' => (pricePerBase: price / (m.qty / 1000), displayUnit: 'kg'),
    'ml' => (pricePerBase: price / (m.qty / 1000), displayUnit: 'L'),
    'ud' => (pricePerBase: price / m.qty, displayUnit: 'ud'),
    _ => null,
  };
}

/// Etiqueta compacta para una medida base ("1 L", "500 g", "12 ud").
String formatMeasureLabel(double qty, String unit) {
  String fmt(double v) {
    if ((v - v.roundToDouble()).abs() < 0.01) return v.round().toString();
    var s = v.toStringAsFixed(2);
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return s.replaceAll('.', ',');
  }

  if (unit == 'ml' && qty >= 1000) return '${fmt(qty / 1000)} L';
  if (unit == 'ml') return '${fmt(qty)} ml';
  if (unit == 'g' && qty >= 1000) return '${fmt(qty / 1000)} kg';
  if (unit == 'g') return '${fmt(qty)} g';
  return '${fmt(qty)} $unit';
}

({double qty, String unit})? _itemBaseMeasure(BasketItem item) {
  final qty = item.quantity;
  final u = item.unit?.trim().toLowerCase();
  if (qty == null || qty <= 0 || u == null || !isMeasureUnit(u)) return null;
  return switch (u) {
    'kg' => (qty: qty * 1000, unit: 'g'),
    'g' || 'gr' || 'gramo' || 'gramos' => (qty: qty, unit: 'g'),
    'l' || 'litro' || 'litros' => (qty: qty * 1000, unit: 'ml'),
    'ml' || 'mililitro' || 'mililitros' => (qty: qty, unit: 'ml'),
    _ => null,
  };
}

bool _matchesToken(String a, String b) =>
    a == b || '${a}s' == b || '${b}s' == a || '${a}es' == b || '${b}es' == a;

int _specialtyCount(String query, SupermarketProduct product) {
  final qTokens = _cleanTokens(query);
  final brandTokens = _cleanTokens(product.brand ?? '').toSet();
  final pTokens = _cleanTokens(
    product.name,
  ).where((t) => !brandTokens.contains(t));
  var count = 0;
  for (final t in pTokens) {
    if (_specialtyTokens.contains(t) &&
        !qTokens.any((q) => _matchesToken(q, t))) {
      count++;
    }
  }
  return count;
}

/// Envases de [product] que hay que comprar para tener [item]. Función pura.
///   * En g, kg, ml o l: cantidad / tamaño del envase, hacia arriba.
///   * En unidades: si el formato trae varias ("12 huevos"), las que hagan
///     falta; la fruta suelta que se vende a peso se pasa a gramos; si no,
///     una por unidad.
///   * Sin cantidad, o con precio de ticket (sin formato), un envase.
int packsNeeded(BasketItem item, SupermarketProduct product) {
  final qty = item.quantity;
  if (qty == null || qty <= 0) return 1;
  // Del ticket no se sabe el formato: se cuenta lo que se suele comprar.
  if (isTicketPrice(product)) return 1;
  // Algunos catálogos (Consum) no traen formato: va en el nombre
  // ("Leche Entera Brik 1 L", "Pan Molde 820 Gr").
  final pack =
      parsePackageQuantity(product.quantity) ??
      parsePackageQuantity(product.name);
  if (isMeasureUnit(item.unit)) {
    return shoppingPacks(qty, item.unit, packSizeIn(pack, item.unit)) ?? 1;
  }
  final count =
      _countInSize(product.quantity) ??
      (product.quantity == null ? _countInSize(product.name) : null);
  if (count != null) return _ceil(qty / count);
  final pieceGrams = looseProduceGrams(item.name);
  final packGrams = packSizeIn(pack, 'g');
  if (pieceGrams != null && packGrams != null) {
    return _ceil(qty * pieceGrams / packGrams);
  }
  return _ceil(qty);
}

// Tolerancia para no comprar uno de más por decimales (1,0000001).
int _ceil(double v) => (v - 1e-6).ceil().clamp(1, 999);

double _costForTarget(
  SupermarketProduct p,
  ({double qty, String unit})? targetMeasure,
  int packs,
) {
  final checkout = (p.price ?? 0) * packs;
  if (targetMeasure == null || isTicketPrice(p)) return checkout;
  final up = effectiveUnitPrice(p);
  if (up == null) return checkout;
  final compat =
      (targetMeasure.unit == 'g' && up.displayUnit == 'kg') ||
      (targetMeasure.unit == 'ml' && up.displayUnit == 'L') ||
      (targetMeasure.unit == 'ud' && up.displayUnit == 'ud');
  if (!compat) return checkout;
  final targetInUnit = targetMeasure.unit == 'ud'
      ? targetMeasure.qty
      : targetMeasure.qty / 1000;
  return up.pricePerBase * targetInUnit;
}

int _sizeBand(
  ({double qty, String unit})? m,
  ({double qty, String unit})? target,
) {
  if (target == null || m == null || m.unit != target.unit || target.qty <= 0) {
    return 1;
  }
  final ratio = m.qty / target.qty;
  if (ratio >= 0.65 && ratio <= 1.55) return 0;
  if (ratio >= 0.45 && ratio <= 2.2) return 1;
  return 2;
}

({String query, List<SupermarketProduct> valid}) _validCandidates(
  BasketItem item,
  List<SupermarketProduct> candidates, {
  String? dominantUnit,
}) {
  final clean = comparisonSearchQuery(item.name);
  var query = clean.isEmpty ? item.name : clean;
  var ranked = rankProducts(query, candidates);
  if (ranked.isEmpty || !isProductFor(query, ranked.first)) {
    final relaxed = comparisonRelaxedQuery(query);
    if (relaxed != null) {
      final alt = rankProducts(relaxed, candidates);
      if (alt.isNotEmpty && isProductFor(relaxed, alt.first)) {
        query = relaxed;
        ranked = alt;
      }
    }
  }
  if (ranked.isEmpty || !isProductFor(query, ranked.first)) {
    return (query: query, valid: const []);
  }
  final out = <SupermarketProduct>[];
  for (final p in ranked) {
    if (p.price == null || p.price! <= 0) continue;
    if (!isProductFor(query, p)) continue;
    if (dominantUnit != null && !isTicketPrice(p)) {
      final m = effectiveMeasure(p);
      if (m != null && m.unit != dominantUnit) continue;
    }
    out.add(p);
  }
  return (query: query, valid: out);
}

({double qty, String unit})? _resolveTargetMeasure(
  BasketItem item,
  List<SupermarketProduct> allValid,
  String? dominantUnit,
) {
  final explicit = _itemBaseMeasure(item);
  if (explicit != null) return explicit;
  if (dominantUnit == null) return null;

  final measures = <double>[];
  for (final p in allValid) {
    final m = effectiveMeasure(p);
    if (m != null && m.unit == dominantUnit) measures.add(m.qty);
  }
  if (measures.isEmpty) return null;

  final standard = [
    for (final q in measures)
      if ((dominantUnit == 'ml' && q >= 250 && q <= 2000) ||
          (dominantUnit == 'g' && q >= 150 && q <= 1500) ||
          (dominantUnit == 'ud' && q >= 2 && q <= 24))
        q,
  ];
  final pool = standard.isNotEmpty ? standard : measures;

  // Moda redondeada para agrupar equivalentes cercanos (990 g -> 1000 g).
  final buckets = <int, List<double>>{};
  for (final q in pool) {
    final key = dominantUnit == 'ud' ? q.round() : ((q / 50).round() * 50);
    (buckets[key] ??= []).add(q);
  }
  final sortedBuckets = buckets.values.toList()
    ..sort((a, b) {
      final cmp = b.length.compareTo(a.length);
      if (cmp != 0) return cmp;
      return a.first.compareTo(b.first);
    });
  if (sortedBuckets.first.length >= 2 || pool.length == 1) {
    final avg =
        sortedBuckets.first.reduce((a, b) => a + b) /
        sortedBuckets.first.length;
    return (qty: avg, unit: dominantUnit);
  }
  pool.sort();
  return (qty: pool[pool.length ~/ 2], unit: dominantUnit);
}

String? _dominantMeasureUnit(
  BasketItem item,
  List<SupermarketProduct> allValid,
) {
  final explicit = _itemBaseMeasure(item);
  if (explicit != null) return explicit.unit;
  final counts = <String, int>{};
  for (final p in allValid) {
    final m = effectiveMeasure(p);
    if (m != null) counts[m.unit] = (counts[m.unit] ?? 0) + 1;
  }
  if (counts.isEmpty) return null;
  final ordered = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return ordered.first.key;
}

/// Producto que se cogería en un súper para [item] de entre [candidates]:
/// prioriza variantes sin especialidades no pedidas, formatos compatibles con
/// [targetMeasure] (si se indica), menor puntuación de desvío y menor coste
/// comparable a igual cantidad. Null si ninguno encaja.
BasketLine? pickBasketLine(
  int index,
  BasketItem item,
  List<SupermarketProduct> candidates, {
  ({double qty, String unit})? targetMeasure,
  String? dominantUnit,
  Set<String> preferredEans = const {},
}) {
  final filtered = _validCandidates(
    item,
    candidates,
    dominantUnit: dominantUnit,
  );
  if (filtered.valid.isEmpty) return null;

  final query = filtered.query;
  final minMatchScore = filtered.valid
      .map((p) => productMatchScore(query, p) ?? 99)
      .reduce(math.min);
  final minSpecialty = filtered.valid
      .map((p) => _specialtyCount(query, p))
      .reduce(math.min);

  final effectiveTarget = targetMeasure ?? _itemBaseMeasure(item);

  ({
    BasketLine line,
    int specialty,
    int band,
    int matchBucket,
    int eanBonus,
    double compareCost,
  })?
  best;

  for (final p in filtered.valid) {
    final spec = _specialtyCount(query, p);
    // Si hay variantes limpias en este súper, descartamos especialidades.
    if (minSpecialty == 0 && spec > 0) continue;

    final score = productMatchScore(query, p) ?? 99;
    // Toleramos +1 palabra extra ("Brik", "Botella") para no perder formatos
    // estándar de 1 L frente a un mini-envase con nombre más corto.
    if (score > minMatchScore + 1 && score > 1) continue;

    final effMeasure = effectiveMeasure(p);
    int packs;
    if (effectiveTarget != null &&
        _itemBaseMeasure(item) == null &&
        effMeasure != null &&
        effMeasure.unit == effectiveTarget.unit &&
        effMeasure.qty < effectiveTarget.qty * 0.72) {
      packs = _ceil(effectiveTarget.qty / effMeasure.qty);
    } else {
      packs = packsNeeded(item, p);
    }

    final comparable = _costForTarget(p, effectiveTarget, packs);
    final checkout = (p.price ?? 0) * packs;
    if (comparable > _maxLineCost || checkout > _maxLineCost) continue;

    final up = effectiveUnitPrice(p);
    final sizeAdjusted =
        effectiveTarget != null &&
        effMeasure != null &&
        effMeasure.unit == effectiveTarget.unit &&
        (effMeasure.qty - effectiveTarget.qty).abs() / effectiveTarget.qty >
            0.10;

    final line = BasketLine(
      index: index,
      product: p,
      packs: packs,
      comparableCost: comparable,
      unitPrice: up?.pricePerBase,
      unitLabel: up?.displayUnit,
      packLabel: effMeasure == null
          ? null
          : formatMeasureLabel(effMeasure.qty, effMeasure.unit),
      targetLabel: effectiveTarget == null
          ? null
          : formatMeasureLabel(effectiveTarget.qty, effectiveTarget.unit),
      sizeAdjusted: sizeAdjusted,
    );

    final cand = (
      line: line,
      specialty: spec,
      band: _sizeBand(effMeasure, effectiveTarget),
      matchBucket: score <= minMatchScore ? 0 : 1,
      eanBonus: (p.ean != null && preferredEans.contains(p.ean)) ? 0 : 1,
      compareCost: comparable,
    );

    if (best == null || _compareCandidate(cand, best) < 0) {
      best = cand;
    }
  }
  return best?.line;
}

int _compareCandidate(
  ({
    BasketLine line,
    int specialty,
    int band,
    int matchBucket,
    int eanBonus,
    double compareCost,
  })
  a,
  ({
    BasketLine line,
    int specialty,
    int band,
    int matchBucket,
    int eanBonus,
    double compareCost,
  })
  b,
) {
  if (a.specialty != b.specialty) return a.specialty.compareTo(b.specialty);
  if (a.band != b.band) return a.band.compareTo(b.band);
  // Si el coste comparable es prácticamente igual (<= 2%), preferimos mejor
  // coincidencia de texto o EAN compartido antes que ahorro mínimo.
  final diff = (a.compareCost - b.compareCost).abs();
  final base = math.min(a.compareCost, b.compareCost);
  if (base > 0 && diff / base > 0.02) {
    return a.compareCost.compareTo(b.compareCost);
  }
  if (a.matchBucket != b.matchBucket)
    return a.matchBucket.compareTo(b.matchBucket);
  if (a.eanBonus != b.eanBonus) return a.eanBonus.compareTo(b.eanBonus);
  return a.compareCost.compareTo(b.compareCost);
}

/// Compara [items] entre súpers con los candidatos de cada uno
/// (`candidates[store][index]`). Alinea formatos a una cantidad común por
/// producto entre todos los súpers. Los súpers con menos del 60 % de lo que
/// encuentra el mejor van a [BasketComparison.partial]. Función pura.
BasketComparison compareBaskets(
  List<BasketItem> items,
  Map<String, Map<int, List<SupermarketProduct>>> candidates,
) {
  // Paso 1: calcular dimensión dominante, cantidad objetivo y EANs compartidos
  // por producto mirando todos los súpers juntos.
  final targets = <int, ({double qty, String unit})?>{};
  final domUnits = <int, String?>{};
  final sharedEans = <int, Set<String>>{};

  for (var i = 0; i < items.length; i++) {
    final allValid = <SupermarketProduct>[];
    final eanStores = <String, Set<String>>{};
    candidates.forEach((store, byIndex) {
      final cands = byIndex[i] ?? const [];
      final res = _validCandidates(items[i], cands);
      for (final p in res.valid) {
        allValid.add(p);
        if (p.ean != null && p.ean!.isNotEmpty) {
          (eanStores[p.ean!] ??= {}).add(store);
        }
      }
    });
    final dom = _dominantMeasureUnit(items[i], allValid);
    domUnits[i] = dom;
    final domValid = dom == null
        ? allValid
        : [
            for (final p in allValid)
              if (effectiveMeasure(p)?.unit == dom) p,
          ];
    targets[i] = _resolveTargetMeasure(
      items[i],
      domValid.isNotEmpty ? domValid : allValid,
      dom,
    );
    sharedEans[i] = {
      for (final e in eanStores.entries)
        if (e.value.length >= 2) e.key,
    };
  }

  // Paso 2: elegir en cada súper la mejor línea alineada al formato común.
  final baskets = <StoreBasket>[];
  candidates.forEach((store, byIndex) {
    final lines = <int, BasketLine>{};
    for (var i = 0; i < items.length; i++) {
      final line = pickBasketLine(
        i,
        items[i],
        byIndex[i] ?? const [],
        targetMeasure: targets[i],
        dominantUnit: domUnits[i],
        preferredEans: sharedEans[i] ?? const {},
      );
      if (line != null) lines[i] = line;
    }
    if (lines.isNotEmpty) baskets.add(StoreBasket(store: store, lines: lines));
  });

  if (baskets.isEmpty) {
    return BasketComparison(
      ranked: const [],
      partial: const [],
      common: const {},
      itemCount: items.length,
    );
  }
  final maxFound = baskets.map((b) => b.found).reduce(math.max);
  final minFound = (maxFound * 0.6).ceil();
  final ranked = [
    for (final b in baskets)
      if (b.found >= minFound) b,
  ];
  final partial = [
    for (final b in baskets)
      if (b.found < minFound) b,
  ]..sort((a, b) => b.found.compareTo(a.found));
  var common = ranked.first.lines.keys.toSet();
  for (final b in ranked.skip(1)) {
    common = common.intersection(b.lines.keys.toSet());
  }
  final result = BasketComparison(
    ranked: ranked,
    partial: partial,
    common: ranked.length < 2 ? const {} : common,
    itemCount: items.length,
  );
  ranked.sort(
    (a, b) => result.comparableTotal(a).compareTo(result.comparableTotal(b)),
  );
  return result;
}

/// Calcula el mejor reparto posible en 2 supermercados (o el reparto para la
/// pareja elegida [storeA]/[storeB]). El ahorro se calcula exclusivamente sobre
/// los productos presentes en AMBOS súpers para que ningún hueco infle el ahorro.
TwoStoreSplit? computeTwoStoreSplit(
  BasketComparison comparison, {
  CompareBasis basis = CompareBasis.sameQuantity,
  String? storeA,
  String? storeB,
}) {
  final minEligible = comparison.itemCount <= 2 ? 1 : 2;
  final ordered = comparison.rankedFor(basis);
  final allBaskets = [...ordered, ...comparison.partial];
  final selectable = [
    for (final b in allBaskets)
      if (b.found >= minEligible) b.store,
  ];
  if (selectable.length < 2) return null;

  final basketByStore = {for (final b in allBaskets) b.store: b};
  final rankOrder = {
    for (var i = 0; i < ordered.length; i++) ordered[i].store: i,
  };

  TwoStoreSplit buildPair(String a, String b) {
    final ba = basketByStore[a]!;
    final bb = basketByStore[b]!;
    final linesA = <SplitLine>[];
    final linesB = <SplitLine>[];
    final missing = <int>[];
    var totalA = 0.0;
    var totalB = 0.0;
    var overlapA = 0.0;
    var overlapB = 0.0;
    var overlapCombined = 0.0;

    final aBeatsB = (rankOrder[a] ?? 999) <= (rankOrder[b] ?? 999);

    for (var i = 0; i < comparison.itemCount; i++) {
      final la = ba.lines[i];
      final lb = bb.lines[i];
      if (la == null && lb == null) {
        missing.add(i);
        continue;
      }
      if (la != null && lb == null) {
        linesA.add(SplitLine(itemIndex: i, chosen: la, saved: 0));
        totalA += la.costFor(basis);
        continue;
      }
      if (lb != null && la == null) {
        linesB.add(SplitLine(itemIndex: i, chosen: lb, saved: 0));
        totalB += lb.costFor(basis);
        continue;
      }
      final ca = la!.costFor(basis);
      final cb = lb!.costFor(basis);
      overlapA += ca;
      overlapB += cb;
      final chooseA = (ca - cb).abs() < 1e-6 ? aBeatsB : ca < cb;
      if (chooseA) {
        final saved = math.max(0.0, cb - ca);
        linesA.add(
          SplitLine(itemIndex: i, chosen: la, alternative: lb, saved: saved),
        );
        totalA += ca;
        overlapCombined += ca;
      } else {
        final saved = math.max(0.0, ca - cb);
        linesB.add(
          SplitLine(itemIndex: i, chosen: lb, alternative: la, saved: saved),
        );
        totalB += cb;
        overlapCombined += cb;
      }
    }

    final aWinsOverlap = overlapA <= overlapB;
    final bestSingleStore = aWinsOverlap ? a : b;
    final bestSingleOverlap = aWinsOverlap ? overlapA : overlapB;
    final savings = math.max(0.0, bestSingleOverlap - overlapCombined);

    return TwoStoreSplit(
      storeA: a,
      storeB: b,
      linesA: linesA,
      linesB: linesB,
      missingIndices: missing,
      totalA: totalA,
      totalB: totalB,
      combinedTotal: totalA + totalB,
      bestSingleStore: bestSingleStore,
      savings: savings,
      selectableStores: selectable,
    );
  }

  if (storeA != null &&
      storeB != null &&
      storeA != storeB &&
      basketByStore.containsKey(storeA) &&
      basketByStore.containsKey(storeB)) {
    return buildPair(storeA, storeB);
  }

  final pairPool = ordered.length >= 2
      ? [for (final b in ordered) b.store]
      : selectable;
  final candidates = <TwoStoreSplit>[];
  for (var i = 0; i < pairPool.length; i++) {
    for (var j = i + 1; j < pairPool.length; j++) {
      final split = buildPair(pairPool[i], pairPool[j]);
      if (split.linesA.isNotEmpty && split.linesB.isNotEmpty) {
        candidates.add(split);
      }
    }
  }
  if (candidates.isEmpty) {
    return buildPair(selectable[0], selectable[1]);
  }
  final maxCovered = candidates
      .map((s) => s.linesA.length + s.linesB.length)
      .reduce(math.max);
  final viable = candidates
      .where((s) => s.linesA.length + s.linesB.length >= maxCovered - 1)
      .toList();
  viable.sort((a, b) {
    final savCmp = b.savings.compareTo(a.savings);
    if (savCmp.abs() > 0 && (b.savings - a.savings).abs() > 0.01) return savCmp;
    final covA = a.linesA.length + a.linesB.length;
    final covB = b.linesA.length + b.linesB.length;
    if (covA != covB) return covB.compareTo(covA);
    return a.combinedTotal.compareTo(b.combinedTotal);
  });
  return viable.first;
}

/// Catálogo de [store] como clave de súper del hogar ("lidl_fr" → "lidl").
String homeKeyForCatalog(String store) =>
    RegExp(r'^(.+)_[a-z]{2}$').firstMatch(store)?.group(1) ?? store;

/// Precio sacado de los tickets (no del catálogo de la web).
bool isTicketPrice(SupermarketProduct p) => p.code.contains(':ticket:');

/// Pide al servidor los candidatos de los catálogos (`compare_catalog_basket`)
/// y los precios de los tickets (`ticket_store_prices`), haciendo un segundo
/// pase con consultas relajadas si algún ítem no obtuvo candidatos, y
/// completando `unit_price`/`unit`/`ean` si la migración SQL v2 aún no está
/// desplegada.
class StoreComparisonService {
  StoreComparisonService(this._client);
  final SupabaseClient _client;

  static const maxItems = 60;

  Future<BasketComparison> compare(
    List<BasketItem> items,
    List<String> catalogs,
  ) async {
    final list = items.take(maxItems).toList();
    final cleanQueries = [for (final i in list) comparisonSearchQuery(i.name)];
    final queries = [
      for (final q in cleanQueries) catalogSearchWords(q).join(' '),
    ];

    final results = await Future.wait([
      _client.rpc(
        'compare_catalog_basket',
        params: {'p_stores': catalogs, 'p_queries': queries},
      ),
      // Sin tickets se compara igual con los catálogos.
      _client
          .rpc('ticket_store_prices', params: {'p_queries': queries})
          .then<Object?>((v) => v, onError: (_) => const []),
    ]);

    final rawRows = (results[0] as List).cast<Map<String, dynamic>>();
    final missingRelaxed = <(int index, String query)>[];
    final hitIndices = {
      for (final r in rawRows) (r['query_idx'] as num).toInt() - 1,
    };
    for (var i = 0; i < cleanQueries.length; i++) {
      if (!hitIndices.contains(i)) {
        final relaxed = comparisonRelaxedQuery(cleanQueries[i]);
        if (relaxed != null) {
          final words = catalogSearchWords(relaxed).join(' ');
          if (words.isNotEmpty) missingRelaxed.add((i, words));
        }
      }
    }
    if (missingRelaxed.isNotEmpty) {
      try {
        final rescueRows =
            (await _client.rpc(
                      'compare_catalog_basket',
                      params: {
                        'p_stores': catalogs,
                        'p_queries': [for (final e in missingRelaxed) e.$2],
                      },
                    )
                    as List)
                .cast<Map<String, dynamic>>();
        for (final r in rescueRows) {
          final localIdx = (r['query_idx'] as num).toInt() - 1;
          if (localIdx >= 0 && localIdx < missingRelaxed.length) {
            rawRows.add({...r, 'query_idx': missingRelaxed[localIdx].$1 + 1});
          }
        }
      } catch (_) {}
    }

    // Si la migración 0091 aún no está aplicada en el servidor, enriquecemos
    // unit_price/unit/ean/member_price con lecturas puntuales por lotes.
    final needsEnrich =
        rawRows.isNotEmpty && !rawRows.first.containsKey('unit_price');
    final enriched = needsEnrich
        ? await _enrichMeta(rawRows)
        : const <String, Map<String, dynamic>>{};

    final candidates = <String, Map<int, List<SupermarketProduct>>>{};
    void add(String store, int index, SupermarketProduct p) =>
        (candidates[homeKeyForCatalog(store)] ??= {})
            .putIfAbsent(index, () => [])
            .add(p);

    for (final r in rawRows) {
      final store = r['store'] as String;
      final pid = r['product_id'].toString();
      final meta = enriched['$store:$pid'];
      add(
        store,
        (r['query_idx'] as num).toInt() - 1,
        SupermarketProduct(
          code: '$store:$pid',
          name: r['name'] as String,
          brand: r['brand'] as String?,
          quantity: r['size'] as String?,
          imageUrl: r['image_url'] as String?,
          price: (r['price'] as num?)?.toDouble(),
          unitPrice: ((r['unit_price'] ?? meta?['unit_price']) as num?)
              ?.toDouble(),
          unit: (r['unit'] ?? meta?['unit']) as String?,
          ean: (r['ean'] ?? meta?['ean']) as String?,
          memberPrice: ((r['member_price'] ?? meta?['member_price']) as num?)
              ?.toDouble(),
        ),
      );
    }

    for (final r
        in ((results[1] as List?) ?? const []).cast<Map<String, dynamic>>()) {
      final store = r['store'] as String;
      final name = r['name_normalized'] as String;
      add(
        store,
        (r['query_idx'] as num).toInt() - 1,
        SupermarketProduct(
          code: '$store:ticket:$name',
          name: name,
          price: (r['price'] as num?)?.toDouble(),
        ),
      );
    }
    return compareBaskets(list, candidates);
  }

  Future<Map<String, Map<String, dynamic>>> _enrichMeta(
    List<Map<String, dynamic>> rows,
  ) async {
    final idsByStore = <String, Set<String>>{};
    for (final r in rows) {
      final store = r['store'] as String?;
      final pid = r['product_id']?.toString();
      if (store != null && pid != null) {
        (idsByStore[store] ??= {}).add(pid);
      }
    }
    final out = <String, Map<String, dynamic>>{};
    await Future.wait([
      for (final entry in idsByStore.entries)
        _fetchStoreMeta(entry.key, entry.value.take(150).toList(), out),
    ]);
    return out;
  }

  Future<void> _fetchStoreMeta(
    String store,
    List<String> productIds,
    Map<String, Map<String, dynamic>> out,
  ) async {
    if (productIds.isEmpty) return;
    try {
      final metaRows = await _client
          .from('supermarket_products')
          .select('product_id,unit_price,unit,ean,member_price')
          .eq('store', store)
          .inFilter('product_id', productIds);
      for (final m in (metaRows as List).cast<Map<String, dynamic>>()) {
        out['$store:${m['product_id']}'] = m;
      }
    } catch (_) {}
  }
}
