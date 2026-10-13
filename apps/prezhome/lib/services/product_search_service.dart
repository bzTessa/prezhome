import 'dart:convert';

import 'package:http/http.dart' as http;

/// Producto real de supermercado encontrado en Open Food Facts.
class SupermarketProduct {
  const SupermarketProduct({
    required this.code,
    required this.name,
    this.brand,
    this.quantity,
    this.imageUrl,
  });

  final String code;
  final String name;
  final String? brand;

  /// Formato de venta tal cual lo da OFF ("1 l", "500 g"…).
  final String? quantity;
  final String? imageUrl;

  /// Nombre con la marca, para la lista ("Leche semidesnatada · Hacendado").
  String get displayName {
    final b = brand;
    if (b == null || name.toLowerCase().contains(b.toLowerCase())) return name;
    return '$name · $b';
  }
}

/// Resultado de una búsqueda. [throttled] indica que se ha pedido demasiado
/// en poco tiempo y no se ha llamado a OFF.
class ProductSearchResult {
  const ProductSearchResult(
    this.products, {
    this.throttled = false,
    this.failed = false,
    this.filteredByStore = false,
  });

  final List<SupermarketProduct> products;
  final bool throttled;
  final bool failed;

  /// Los resultados son solo del súper pedido (si no había, se repite sin él).
  final bool filteredByStore;
}

/// Etiqueta de tienda en Open Food Facts para cada clave de súper del hogar.
String? offStoreTag(String? supermarketKey) => switch (supermarketKey) {
  'mercadona' => 'mercadona',
  'lidl' => 'lidl',
  'carrefour' => 'carrefour',
  'dia' => 'dia',
  'alcampo' => 'alcampo',
  'eroski' => 'eroski',
  'aldi' => 'aldi',
  'consum' => 'consum',
  'elcorteingles' => 'el-corte-ingles',
  'ahorramas' => 'ahorramas',
  _ => null,
};

/// URL de búsqueda de OFF: productos vendidos en España y, si se indica, en
/// la tienda [storeTag].
Uri buildProductSearchUri(String query, {String? storeTag}) {
  final params = <String, String>{
    'search_terms': query.trim(),
    'search_simple': '1',
    'action': 'process',
    'json': '1',
    'page_size': '24',
    'lc': 'es',
    'fields':
        'code,product_name_es,product_name,brands,quantity,'
        'image_front_small_url,image_front_url',
    'tagtype_0': 'countries',
    'tag_contains_0': 'contains',
    'tag_0': 'spain',
  };
  if (storeTag != null) {
    params['tagtype_1'] = 'stores';
    params['tag_contains_1'] = 'contains';
    params['tag_1'] = storeTag;
  }
  return Uri.https('es.openfoodfacts.org', '/cgi/search.pl', params);
}

/// Convierte la respuesta JSON de OFF en productos. Descarta los que no
/// tienen nombre y los repetidos (mismo nombre y marca).
List<SupermarketProduct> parseProductSearch(Map<String, dynamic> json) {
  final raw = json['products'];
  if (raw is! List) return const [];
  String? clean(Object? v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  final seen = <String>{};
  final out = <SupermarketProduct>[];
  for (final p in raw) {
    if (p is! Map) continue;
    final name = clean(p['product_name_es']) ?? clean(p['product_name']);
    if (name == null) continue;
    // OFF da las marcas separadas por comas: nos quedamos con la primera.
    final brand = clean(p['brands']?.toString().split(',').first);
    final key = '${name.toLowerCase()}|${brand?.toLowerCase()}';
    if (!seen.add(key)) continue;
    out.add(
      SupermarketProduct(
        code: clean(p['code']) ?? key,
        name: name,
        brand: brand,
        quantity: clean(p['quantity']),
        imageUrl:
            clean(p['image_front_small_url']) ?? clean(p['image_front_url']),
      ),
    );
  }
  return out;
}

/// Formato de venta normalizado a cantidad + unidad del inventario
/// ('g', 'kg', 'ml', 'litros'). Null si no se entiende ("pack de 6").
({double quantity, String unit})? parsePackageQuantity(String? raw) {
  if (raw == null) return null;
  // Packs ("6 x 125 g"): el formato unitario no es lo que hay en casa.
  if (RegExp(r'\d\s*[x×]\s*\d').hasMatch(raw.toLowerCase())) return null;
  final m = RegExp(
    r'(\d+(?:[.,]\d+)?)\s*(kg|g|gr|ml|cl|l|L|litros?)\b',
  ).firstMatch(raw.toLowerCase());
  if (m == null) return null;
  final n = double.tryParse(m.group(1)!.replaceAll(',', '.'));
  if (n == null || n <= 0) return null;
  return switch (m.group(2)!) {
    'kg' => (quantity: n, unit: 'kg'),
    'g' || 'gr' => (quantity: n, unit: 'g'),
    'ml' => (quantity: n, unit: 'ml'),
    'cl' => (quantity: n * 10, unit: 'ml'),
    _ => (quantity: n, unit: 'litros'),
  };
}

/// Busca productos de súper en Open Food Facts (gratis, sin clave).
///
/// Se llama directamente desde el móvil para que el límite de OFF (10
/// búsquedas/minuto por IP) cuente por persona y no para toda la app. Por eso
/// solo se busca cuando la persona lo pide (no al teclear) y además se frena
/// aquí por si acaso. Nunca lanza.
class ProductSearchService {
  ProductSearchService({http.Client? client, DateTime Function()? now})
    : _client = client ?? http.Client(),
      _now = now ?? DateTime.now;

  final http.Client _client;
  final DateTime Function() _now;

  static const _userAgent = 'PrezHome/1.0 (app de hogar; openfoodfacts)';
  static const _maxPerMinute = 8;

  /// Las fotos que se buscan solas en segundo plano solo pueden gastar esta
  /// parte del límite: el resto queda libre para lo que busca la persona.
  static const _maxBackgroundPerMinute = 4;

  static final Map<String, ProductSearchResult> _cache = {};
  static final List<DateTime> _recent = [];

  bool _allowRequest({required bool background}) {
    final now = _now();
    _recent.removeWhere((t) => now.difference(t).inSeconds >= 60);
    final limit = background ? _maxBackgroundPerMinute : _maxPerMinute;
    if (_recent.length >= limit) return false;
    _recent.add(now);
    return true;
  }

  Future<List<SupermarketProduct>?> _fetch(
    Uri uri, {
    required bool background,
  }) async {
    if (!_allowRequest(background: background)) return null;
    final res = await _client
        .get(uri, headers: const {'User-Agent': _userAgent})
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) throw Exception('OFF ${res.statusCode}');
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body is Map<String, dynamic> ? parseProductSearch(body) : const [];
  }

  /// Busca [query]. Con [supermarketKey] prueba primero solo ese súper y, si
  /// no hay nada, en todos los de España. [background] marca las búsquedas
  /// que nadie ha pedido (fotos de la lista), que no pueden agotar el límite.
  Future<ProductSearchResult> search(
    String query, {
    String? supermarketKey,
    bool background = false,
  }) async {
    final q = query.trim();
    if (q.length < 2) return const ProductSearchResult([]);
    final store = offStoreTag(supermarketKey);
    final key = '${q.toLowerCase()}|$store';
    final cached = _cache[key];
    if (cached != null) return cached;
    try {
      if (store != null) {
        final inStore = await _fetch(
          buildProductSearchUri(q, storeTag: store),
          background: background,
        );
        if (inStore == null) {
          return const ProductSearchResult([], throttled: true);
        }
        if (inStore.isNotEmpty) {
          return _cache[key] = ProductSearchResult(
            inStore,
            filteredByStore: true,
          );
        }
      }
      final all = await _fetch(
        buildProductSearchUri(q),
        background: background,
      );
      if (all == null) return const ProductSearchResult([], throttled: true);
      return _cache[key] = ProductSearchResult(all);
    } catch (_) {
      return const ProductSearchResult([], failed: true);
    }
  }

  /// Solo para tests: olvida caché y límite.
  static void resetForTest() {
    _cache.clear();
    _recent.clear();
  }
}
