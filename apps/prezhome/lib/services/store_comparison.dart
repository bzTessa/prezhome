import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/practical_quantity.dart';
import '../utils/shopping_display.dart';
import 'product_search_service.dart';

/// Un producto de la lista que se quiere comparar.
typedef BasketItem = ({String name, double? quantity, String? unit});

/// Lo que se cogería en un súper para una línea de la lista.
class BasketLine {
  const BasketLine({
    required this.index,
    required this.product,
    required this.packs,
  });

  /// Posición de la línea en la lista comparada.
  final int index;
  final SupermarketProduct product;

  /// Envases o unidades que hay que comprar para cubrir la cantidad.
  final int packs;

  double get cost => product.price! * packs;
}

/// La lista de la compra en un súper: qué se encontró y cuánto cuesta.
class StoreBasket {
  const StoreBasket({required this.store, required this.lines});

  /// Clave del catálogo ("mercadona", "lidl_fr"…).
  final String store;

  /// Por índice de la línea de la lista. Lo que no está, no se encontró.
  final Map<int, BasketLine> lines;

  int get found => lines.length;

  double get total => lines.values.fold(0.0, (s, l) => s + l.cost);

  /// Coste solo de las líneas [indexes] (las que tienen todos los súpers).
  double totalFor(Set<int> indexes) =>
      indexes.fold(0.0, (s, i) => s + (lines[i]?.cost ?? 0));
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
  double comparableTotal(StoreBasket b) =>
      common.isEmpty ? b.total : b.totalFor(common);

  /// Cuánto más cuesta [b] que el más barato (0 para el más barato).
  double extraOver(StoreBasket b) =>
      ranked.isEmpty ? 0 : comparableTotal(b) - comparableTotal(ranked.first);
}

/// Una línea que sale por más de esto se descarta: casi siempre es un pack
/// grande o un producto que no es (mismo tope que la estimación de la lista).
const double _maxLineCost = 60;

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

/// Producto que se cogería en un súper para [item] de entre [candidates]:
/// de los que son claramente eso (mismo criterio que la foto y el buscador),
/// el que menos cuesta para la cantidad pedida. Null si ninguno encaja.
BasketLine? pickBasketLine(
  int index,
  BasketItem item,
  List<SupermarketProduct> candidates,
) {
  final ranked = rankProducts(item.name, candidates);
  if (ranked.isEmpty || !isProductFor(item.name, ranked.first)) return null;
  final top = productMatchScore(item.name, ranked.first);
  BasketLine? best;
  for (final p in ranked) {
    if (p.price == null || p.price! <= 0) continue;
    if (productMatchScore(item.name, p) != top) continue;
    final line = BasketLine(
      index: index,
      product: p,
      packs: packsNeeded(item, p),
    );
    if (line.cost > _maxLineCost) continue;
    if (best == null || line.cost < best.cost) best = line;
  }
  return best;
}

/// Compara [items] entre súpers con los candidatos de cada uno
/// (`candidates[store][index]`). Los súpers con menos del 60 % de lo que
/// encuentra el mejor van a [BasketComparison.partial]. Función pura.
BasketComparison compareBaskets(
  List<BasketItem> items,
  Map<String, Map<int, List<SupermarketProduct>>> candidates,
) {
  final baskets = <StoreBasket>[];
  candidates.forEach((store, byIndex) {
    final lines = <int, BasketLine>{};
    for (var i = 0; i < items.length; i++) {
      final line = pickBasketLine(i, items[i], byIndex[i] ?? const []);
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
  final maxFound = baskets.map((b) => b.found).reduce((a, b) => a > b ? a : b);
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

/// Catálogo de [store] como clave de súper del hogar ("lidl_fr" → "lidl").
String homeKeyForCatalog(String store) =>
    RegExp(r'^(.+)_[a-z]{2}$').firstMatch(store)?.group(1) ?? store;

/// Precio sacado de los tickets (no del catálogo de la web).
bool isTicketPrice(SupermarketProduct p) => p.code.contains(':ticket:');

/// Pide al servidor, en dos llamadas en paralelo, los candidatos de los
/// catálogos (`compare_catalog_basket`) y los precios de los tickets
/// (`ticket_store_prices`), y compara. Los catálogos de una cadena en otro
/// país ("lidl_fr") se juntan con sus tickets ("lidl"). Como mucho 60
/// productos.
class StoreComparisonService {
  StoreComparisonService(this._client);
  final SupabaseClient _client;

  static const maxItems = 60;

  Future<BasketComparison> compare(
    List<BasketItem> items,
    List<String> catalogs,
  ) async {
    final list = items.take(maxItems).toList();
    final queries = [
      for (final i in list) catalogSearchWords(i.name).join(' '),
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
    final candidates = <String, Map<int, List<SupermarketProduct>>>{};
    void add(String store, int index, SupermarketProduct p) =>
        (candidates[homeKeyForCatalog(store)] ??= {})
            .putIfAbsent(index, () => [])
            .add(p);
    // query_idx viene de "with ordinality": empieza en 1.
    for (final r in (results[0] as List).cast<Map<String, dynamic>>()) {
      final store = r['store'] as String;
      add(
        store,
        (r['query_idx'] as num).toInt() - 1,
        SupermarketProduct(
          code: '$store:${r['product_id']}',
          name: r['name'] as String,
          brand: r['brand'] as String?,
          quantity: r['size'] as String?,
          imageUrl: r['image_url'] as String?,
          price: (r['price'] as num?)?.toDouble(),
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
}
