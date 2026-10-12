import 'package:supabase_flutter/supabase_flutter.dart';

/// Datos reales de un alimento obtenidos de Open Food Facts (vía la edge
/// function food-facts): formato de venta típico y nutrición por 100 g.
/// Sirve para que las recetas tengan cantidades normales (formatos de súper) y
/// una nutrición más fiable (sumando ingredientes) en vez de a ojo.
class FoodFacts {
  final bool found;
  final String? productName;
  final String? brand;

  /// Formato de venta (p. ej. 400 g de garbanzos de bote). Null si OFF no lo da.
  final double? packageQuantity;
  final String? packageUnit; // 'g' | 'ml'

  /// Nutrición por 100 g/ml.
  final double? kcal100;
  final double? protein100;
  final double? carbs100;
  final double? fat100;

  /// Código de barras escaneado (eco de la consulta por barcode). Null cuando
  /// la consulta fue por nombre.
  final String? barcode;

  /// Pista de categoría derivada de OFF (texto libre). Null si OFF no la da.
  final String? categoryHint;

  /// Foto REAL del producto en Open Food Facts (añadida en FEAT-001 a la edge
  /// function food-facts). URL http(s) o null si OFF no la da. La usa la lista
  /// de la compra / inventario para mostrar una foto real del producto.
  final String? imageUrl;

  const FoodFacts({
    required this.found,
    this.productName,
    this.brand,
    this.packageQuantity,
    this.packageUnit,
    this.kcal100,
    this.protein100,
    this.carbs100,
    this.fat100,
    this.barcode,
    this.categoryHint,
    this.imageUrl,
  });

  static const FoodFacts notFound = FoodFacts(found: false);

  factory FoodFacts.fromMap(Map<String, dynamic> m) {
    double? d(dynamic v) => v == null ? null : (v as num).toDouble();
    return FoodFacts(
      found: (m['found'] as bool?) ?? false,
      productName: m['productName'] as String?,
      brand: m['brand'] as String?,
      packageQuantity: d(m['packageQuantity']),
      packageUnit: m['packageUnit'] as String?,
      kcal100: d(m['kcal100']),
      protein100: d(m['protein100']),
      carbs100: d(m['carbs100']),
      fat100: d(m['fat100']),
      barcode: m['barcode'] as String?,
      categoryHint: m['categoryHint'] as String?,
      imageUrl: m['imageUrl'] as String?,
    );
  }
}

/// Resuelve datos de Open Food Facts para un alimento. Cachea en memoria por
/// sesión (clave: nombre normalizado + súper) para no repetir consultas al
/// resolver todos los ingredientes de una receta. Degrada con elegancia: ante
/// cualquier fallo devuelve FoodFacts.notFound (nunca lanza hacia la UI).
class FoodFactsService {
  FoodFactsService(this._client);

  final SupabaseClient _client;
  static const String _function = 'food-facts';

  // Caché en memoria por proceso. La información de OFF es pública y estable,
  // así que basta con no repetirla dentro de la misma sesión.
  static final Map<String, FoodFacts> _cache = {};

  String _key(String name, String supermarket) =>
      '${name.trim().toLowerCase()}|${supermarket.trim().toLowerCase()}';

  /// Devuelve los datos de OFF para [name] (opcionalmente afinando por
  /// [supermarket]). Nunca lanza; si no hay datos devuelve FoodFacts.notFound.
  Future<FoodFacts> lookup(String name, {String supermarket = ''}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return FoodFacts.notFound;
    final key = _key(trimmed, supermarket);
    final cached = _cache[key];
    if (cached != null) return cached;

    try {
      final res = await _client.functions.invoke(
        _function,
        body: {'name': trimmed, 'supermarket': supermarket},
      );
      final data = res.data;
      final facts = data is Map
          ? FoodFacts.fromMap(Map<String, dynamic>.from(data))
          : FoodFacts.notFound;
      _cache[key] = facts;
      return facts;
    } catch (_) {
      return FoodFacts.notFound;
    }
  }

  /// Resuelve los datos de OFF para un CÓDIGO DE BARRAS (EAN/UPC) a través de la
  /// misma edge function food-facts (que acepta `barcode` en el body). Nunca
  /// lanza; ante cualquier fallo o producto no encontrado devuelve
  /// FoodFacts.notFound. Cachea por código para no repetir escaneos.
  Future<FoodFacts> lookupByBarcode(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return FoodFacts.notFound;
    final key = 'barcode|$trimmed';
    final cached = _cache[key];
    if (cached != null) return cached;

    try {
      final res = await _client.functions.invoke(
        _function,
        body: {'barcode': trimmed},
      );
      final data = res.data;
      final facts = data is Map
          ? FoodFacts.fromMap(Map<String, dynamic>.from(data))
          : FoodFacts.notFound;
      _cache[key] = facts;
      return facts;
    } catch (_) {
      return FoodFacts.notFound;
    }
  }
}
