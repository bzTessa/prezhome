import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_country.dart';

/// Producto real de supermercado: del catálogo de la tienda online (con foto
/// oficial y precio) o de Open Food Facts.
class SupermarketProduct {
  const SupermarketProduct({
    required this.code,
    required this.name,
    this.brand,
    this.quantity,
    this.imageUrl,
    this.price,
  });

  final String code;
  final String name;
  final String? brand;

  /// Formato de venta tal cual lo da OFF ("1 l", "500 g"…).
  final String? quantity;
  final String? imageUrl;

  /// Precio orientativo en la tienda online (solo productos de catálogo).
  final double? price;

  /// Nombre con la marca, para la lista ("Leche semidesnatada · Hacendado").
  String get displayName {
    final b = brand;
    if (b == null || name.toLowerCase().contains(b.toLowerCase())) return name;
    return '$name · $b';
  }

  /// Súper del catálogo oficial ("mercadona"…); null si viene de OFF.
  String? get store {
    final i = code.indexOf(':');
    return i > 0 ? code.substring(0, i) : null;
  }
}

/// Resultado de una búsqueda. [throttled] indica que se ha pedido demasiado
/// en poco tiempo y no se ha llamado a OFF. [failed] es que OFF no ha
/// respondido bien y [offline], que ni siquiera se ha podido conectar.
class ProductSearchResult {
  const ProductSearchResult(
    this.products, {
    this.throttled = false,
    this.failed = false,
    this.offline = false,
    this.filteredByStore = false,
  });

  final List<SupermarketProduct> products;
  final bool throttled;
  final bool failed;
  final bool offline;

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

/// URL de búsqueda de OFF (search-a-licious; la antigua cgi/search.pl ya no
/// responde a apps sin cuenta): productos vendidos en el país del hogar y, si
/// se indica, en la tienda [storeTag].
Uri buildProductSearchUri(String query, {String? storeTag}) {
  final country = HomeCountry.current.value;
  // Fuera la sintaxis de búsqueda (comillas, dos puntos…): solo palabras.
  final words = query.replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ');
  final q = StringBuffer('${words.trim()} countries_tags:"en:${country.off}"');
  if (storeTag != null) q.write(' stores:"$storeTag"');
  return Uri.https('search.openfoodfacts.org', '/search', {
    'q': q.toString(),
    'langs': country.lang,
    'page_size': '24',
    'fields':
        'code,product_name_es,product_name,brands,quantity,'
        'image_front_small_url,image_front_url',
  });
}

/// Convierte la respuesta JSON de OFF (`hits` de la búsqueda o `products`)
/// en productos. Descarta los que no tienen nombre y los repetidos (mismo
/// nombre y marca).
List<SupermarketProduct> parseProductSearch(Map<String, dynamic> json) {
  final raw = json['hits'] ?? json['products'];
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
    // OFF da las marcas en lista o separadas por comas: la primera.
    final brands = p['brands'];
    final brand = clean(
      brands is List
          ? (brands.isEmpty ? null : brands.first)
          : brands?.toString().split(',').first,
    );
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

// Palabras que no dicen qué producto es ("de", "pack"…).
const _filler = {
  'de',
  'del',
  'la',
  'las',
  'el',
  'los',
  'con',
  'y',
  'e',
  'en',
  'al',
  'a',
  'para',
  'sin',
  'bolsa',
  'pack',
  'paquete',
  'malla',
  'botella',
  'brick',
  'lata',
  'bote',
  'tarro',
  'bandeja',
  'granel',
  'unidad',
  'unidades',
  'kg',
  'gr',
  'ml',
  'cl',
};

// Si el producto las lleva y la búsqueda no, es otra cosa: "arroz blanco
// cocido" no es arroz, "vinagre de vino blanco" no es vino.
const _transformed = {
  'cocido',
  'cocida',
  'cocidos',
  'cocidas',
  'preparado',
  'preparada',
  'precocinado',
  'precocinada',
  'tiras',
  'vinagre',
  'chocolate',
  'sabor',
  'tortitas',
  'tortita',
  'galletas',
  'galleta',
  'crackers',
  'snack',
  'chips',
  'empanado',
  'empanada',
  'empanadas',
  'rebozado',
  'rebozada',
  'salsa',
  'crema',
  'sopa',
  'caldo',
  'ensalada',
  'pizza',
  'relleno',
  'rellena',
  'frito',
  'frita',
  'fritos',
  'fritas',
  'asado',
  'asada',
  'ahumado',
  'ahumada',
  'zumo',
  'bebida',
  'yogur',
  'helado',
  'turron',
  'barrita',
  'barritas',
  'cereales',
  'harina',
  'pure',
  'nuggets',
  'hamburguesa',
  'croquetas',
  'lasana',
  'tortilla',
  'bizcocho',
  'mermelada',
  'aroma',
  'condimento',
  'sazonador',
  'concentrado',
  'polvo',
  'deshidratado',
  'liofilizado',
  'congelado',
  'microondas',
  'kebab',
  'burger',
  'mix',
};

List<String> _words(String s) {
  const from = 'áàäâéèëêíìïîóòöôúùüûñç';
  const to = 'aaaaeeeeiiiioooouuuunc';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  return b
      .toString()
      .split(RegExp(r'[^a-z0-9]+'))
      .where(
        (w) =>
            w.length > 1 &&
            !_filler.contains(w) &&
            !RegExp(r'^\d+$').hasMatch(w),
      )
      .toList();
}

// Singular y plural cuentan igual ("patata" = "patatas", "limon" = "limones").
bool _sameWord(String a, String b) =>
    a == b || '${a}s' == b || '${b}s' == a || '${a}es' == b || '${b}es' == a;

/// Cuánto se aleja [product] de lo buscado: 0 es exacto, cada palabra de más
/// suma 1. Null si no es lo buscado: le falta alguna palabra, empieza por
/// otra cosa ("harina de arroz") o está transformado ("arroz cocido").
int? productMatchScore(String query, SupermarketProduct product) {
  final q = _words(query);
  if (q.isEmpty) return null;
  final brand = _words(product.brand ?? '').toSet();
  final name = _words(product.name).where((w) => !brand.contains(w)).toList();
  if (name.isEmpty || !q.any((w) => _sameWord(w, name.first))) return null;
  for (final w in q) {
    if (!name.any((n) => _sameWord(w, n))) return null;
  }
  final extra = name.where((n) => !q.any((w) => _sameWord(w, n))).toList();
  if (extra.any(_transformed.contains)) return null;
  return extra.length;
}

/// Ordena: primero lo que es justo lo buscado, luego lo que al menos lo
/// nombra ("tortilla de patatas" para "patata"). Lo que no tiene nada que ver
/// (crackers, copos de avena…) se quita: OFF devuelve mucho ruido.
List<SupermarketProduct> rankProducts(
  String query,
  List<SupermarketProduct> products,
) {
  final q = _words(query);
  bool mentions(SupermarketProduct p) =>
      _words(p.name).any((n) => q.any((w) => _sameWord(w, n)));
  final scored = [
    for (var i = 0; i < products.length; i++)
      if (mentions(products[i]))
        (p: products[i], s: productMatchScore(query, products[i]), i: i),
  ];
  scored.sort((a, b) {
    final sa = a.s ?? 1 << 20, sb = b.s ?? 1 << 20;
    return sa != sb ? sa.compareTo(sb) : a.i.compareTo(b.i);
  });
  return [for (final e in scored) e.p];
}

/// Si [product] es lo que dice [query] (como mucho 3 palabras de más).
bool isProductFor(String query, SupermarketProduct product) {
  final s = productMatchScore(query, product);
  return s != null && s <= 3;
}

/// Código de barras de una foto de OFF
/// (`.../images/products/843/000/000/1234/front_es.3.200.jpg` → 8430000001234).
String? offBarcodeFromUrl(String url) {
  final m = RegExp(
    r'^https://images\.openfoodfacts\.(?:org|net)/images/products/((?:\d+/)+)',
  ).firstMatch(url);
  if (m == null) return null;
  final code = m.group(1)!.replaceAll('/', '');
  return code.isEmpty ? null : code;
}

/// Foto para [query] solo si hay un producto que es claramente eso (con foto
/// y, como mucho, 3 palabras de más). Mejor sin foto que con una que no es.
String? confidentProductPhoto(String query, List<SupermarketProduct> products) {
  for (final p in rankProducts(query, products)) {
    if (!isProductFor(query, p)) return null;
    if ((p.imageUrl ?? '').isNotEmpty) return p.imageUrl;
  }
  return null;
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

/// Súpers con catálogo propio en supermarket_products (scripts/*_sync.py).
const catalogStores = {'mercadona', 'dia', 'consum', 'bonarea', 'lidl', 'rewe'};

/// Catálogos oficiales de cada país, en el orden en que se buscan.
const catalogStoresByCountry = {
  'ES': ['mercadona', 'dia', 'consum', 'bonarea', 'lidl'],
  'DE': ['rewe'],
};

/// Catálogos donde buscar: primero el del súper del hogar y luego los demás
/// del país.
List<String> catalogSearchOrder(String? supermarketKey) => [
  if (catalogStores.contains(supermarketKey)) supermarketKey!,
  ...?catalogStoresByCountry[HomeCountry.current.value.code]?.where(
    (s) => s != supermarketKey,
  ),
];

/// Catálogo que pone la foto a lo genérico (fruta, verdura…) en cada país.
const catalogForCountry = {'ES': 'mercadona', 'DE': 'rewe'};

/// Secciones de producto fresco y sin envase de marca: su foto sirve para
/// lo genérico ("cebolla", "plátano").
const freshCategories = [
  'Fruta y verdura',
  'Carne',
  'Marisco y pescado',
  'frutas',
  'verduras',
  'carnes',
  'pescados-y-mariscos',
  'Obst & Gemüse',
  'Fleisch, Wurst & Fisch',
];

typedef CatalogSearch =
    Future<List<SupermarketProduct>> Function(
      String query,
      String store, {
      bool freshOnly,
    });

/// Busca [query] en el catálogo de [store]: cada palabra (sin plural) tiene
/// que estar en el nombre. Con [freshOnly], solo en [freshCategories].
Future<List<SupermarketProduct>> searchCatalog(
  String query,
  String store, {
  bool freshOnly = false,
}) async {
  final words = [
    for (final w in _words(query))
      w.length > 4 && w.endsWith('es')
          ? w.substring(0, w.length - 2)
          : w.length > 3 && w.endsWith('s')
          ? w.substring(0, w.length - 1)
          : w,
  ];
  if (words.isEmpty) return const [];
  var q = Supabase.instance.client
      .from('supermarket_products')
      .select('product_id,name,brand,size,price,image_url')
      .eq('store', store);
  if (freshOnly) q = q.inFilter('category', freshCategories);
  for (final w in words) {
    q = q.ilike('name_normalized', '%$w%');
  }
  final rows = await q.limit(40);
  return [
    for (final r in rows)
      SupermarketProduct(
        code: '$store:${r['product_id']}',
        name: r['name'] as String,
        brand: r['brand'] as String?,
        quantity: r['size'] as String?,
        imageUrl: r['image_url'] as String?,
        price: (r['price'] as num?)?.toDouble(),
      ),
  ];
}

/// Busca productos de súper: primero en los catálogos oficiales y luego en
/// Open Food Facts (gratis, sin clave).
///
/// Se llama directamente desde el móvil para que el límite de OFF (10
/// búsquedas/minuto por IP) cuente por persona y no para toda la app. Por eso
/// solo se busca cuando la persona lo pide (no al teclear) y además se frena
/// aquí por si acaso. Nunca lanza.
class ProductSearchService {
  ProductSearchService({
    http.Client? client,
    DateTime Function()? now,
    CatalogSearch? catalog,
  }) : _client = client ?? http.Client(),
       _now = now ?? DateTime.now,
       _catalog = catalog ?? searchCatalog;

  final http.Client _client;
  final CatalogSearch _catalog;
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

  /// Busca [query]: primero en los catálogos oficiales (el de
  /// [supermarketKey] delante) y, si no lo tienen, en Open Food Facts (ese
  /// súper y luego todos los del país), que va siempre detrás. [background] marca las búsquedas
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
    // Primero los catálogos oficiales (foto y precio de la tienda), que
    // salen mucho mejor que OFF: si alguno tiene justo lo buscado, OFF ni se
    // consulta. Van antes los que son eso, cada uno en el orden de súper.
    final stores = catalogSearchOrder(supermarketKey);
    final lists = await Future.wait([
      for (final s in stores) _catalogSafe(q, s),
    ]);
    final all = [for (final l in lists) ...l];
    final official = [
      ...all.where((p) => isProductFor(q, p)),
      ...all.where((p) => !isProductFor(q, p)),
    ];
    if (official.isNotEmpty && isProductFor(q, official.first)) {
      return _cache[key] = ProductSearchResult(
        official,
        filteredByStore: official.any((p) => p.store == supermarketKey),
      );
    }
    try {
      var inStore = <SupermarketProduct>[];
      if (store != null) {
        final r = await _fetch(
          buildProductSearchUri(q, storeTag: store),
          background: background,
        );
        if (r == null) return const ProductSearchResult([], throttled: true);
        inStore = rankProducts(q, r);
        // Solo se queda en el súper si allí está justo lo buscado.
        if (inStore.any((p) => isProductFor(q, p))) {
          return _cache[key] = ProductSearchResult([
            ...official,
            ...inStore,
          ], filteredByStore: true);
        }
      }
      final offAll = await _fetch(
        buildProductSearchUri(q),
        background: background,
      );
      if (offAll == null) {
        // Sin más búsquedas libres: lo que haya del súper.
        return inStore.isEmpty && official.isEmpty
            ? const ProductSearchResult([], throttled: true)
            : ProductSearchResult([
                ...official,
                ...inStore,
              ], filteredByStore: inStore.isNotEmpty);
      }
      final seen = {for (final p in inStore) p.code};
      // Open Food Facts siempre al final, detrás de los catálogos.
      return _cache[key] = ProductSearchResult([
        ...official,
        ...rankProducts(q, [
          ...inStore,
          ...offAll.where((p) => seen.add(p.code)),
        ]),
      ]);
    } on http.ClientException {
      // El móvil no llega a ningún servidor (sin datos, modo avión…).
      return official.isNotEmpty
          ? ProductSearchResult(official)
          : const ProductSearchResult([], failed: true, offline: true);
    } catch (_) {
      return official.isNotEmpty
          ? ProductSearchResult(official)
          : const ProductSearchResult([], failed: true);
    }
  }

  /// El catálogo nunca tumba la búsqueda: si falla, se sigue con OFF.
  Future<List<SupermarketProduct>> _catalogSafe(
    String q,
    String store, {
    bool freshOnly = false,
  }) async {
    try {
      return rankProducts(q, await _catalog(q, store, freshOnly: freshOnly));
    } catch (_) {
      return const [];
    }
  }

  /// Foto oficial del súper para algo genérico ("cebolla"): la de la sección
  /// de frescos del catálogo de [store], si hay una que es claramente eso.
  Future<String?> freshPhoto(String name, String store) async =>
      confidentProductPhoto(
        name,
        await _catalogSafe(name, store, freshOnly: true),
      );

  static final Map<String, SupermarketProduct?> _byCode = {};

  /// Producto de OFF por código de barras (para comprobar fotos guardadas).
  /// Null si no existe o no se pudo leer; no gasta búsquedas.
  Future<SupermarketProduct?> productByCode(String code) async {
    if (_byCode.containsKey(code)) return _byCode[code];
    try {
      final res = await _client
          .get(
            Uri.https('es.openfoodfacts.org', '/api/v2/product/$code.json', {
              'fields': 'code,product_name_es,product_name,brands',
            }),
            headers: const {'User-Agent': _userAgent},
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 404) return _byCode[code] = null;
      if (res.statusCode != 200) return null;
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      final p = body is Map ? body['product'] : null;
      final parsed = p is Map
          ? parseProductSearch({
              'products': [p],
            })
          : const <SupermarketProduct>[];
      return _byCode[code] = parsed.isEmpty ? null : parsed.first;
    } catch (_) {
      return null;
    }
  }

  /// Solo para tests: olvida caché y límite.
  static void resetForTest() {
    _byCode.clear();
    _cache.clear();
    _recent.clear();
  }
}
