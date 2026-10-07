import '../utils/measure_format.dart';

class ShoppingListItem {
  final String? id;
  final String homeId;
  final String name;
  final double? quantity;
  final String? unit;
  final bool checked;
  final String source; // 'manual' o 'auto'
  final DateTime? createdAt;

  /// Tipo: 'comida' (por defecto) | 'hogar'. Define a qué parte del inventario
  /// va al comprarlo.
  final String itemType;

  /// Ubicación/categoría elegida (Nevera/Congelador/Despensa/Especias/
  /// Limpieza/Hogar) o null para que el sistema la deduzca.
  final String? category;

  /// URL http(s) COMPLETA de la foto real del artículo (banco de imágenes vía
  /// la edge function recipe-photo). NULL = sin foto; la UI muestra la
  /// ilustración cozy de la categoría en su lugar.
  final String? imageUrl;

  /// Lista de la compra a la que pertenece (tabla shopping_lists, migración
  /// 0045). NULL = "Lista principal". Nullable por compatibilidad con las
  /// filas antiguas.
  final String? listId;

  /// Categoría/sección a la que pertenece (tabla shopping_categories, migración
  /// 0045). NULL = "Sin categorizar". Se mantiene además la columna de texto
  /// libre [category] para compatibilidad con items antiguos.
  final String? categoryId;

  ShoppingListItem({
    this.id,
    required this.homeId,
    required this.name,
    this.quantity,
    this.unit,
    this.checked = false,
    this.source = 'manual',
    this.createdAt,
    this.itemType = 'comida',
    this.category,
    this.imageUrl,
    this.listId,
    this.categoryId,
  });

  // Devuelve el valor como String si no es null ni vacío; si no, null. Trata
  // la cadena vacía como ausencia de foto (igual que Recipe._nonEmptyString).
  static String? _nonEmptyString(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    return s.isEmpty ? null : s;
  }

  factory ShoppingListItem.fromMap(Map<String, dynamic> map) {
    // Parseo tolerante: algunas consultas pueden no traer todas las columnas.
    // Nunca debe petar aunque falte un campo o venga nulo.
    return ShoppingListItem(
      id: map['id'] as String?,
      homeId: (map['home_id'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      quantity: (map['quantity'] as num?)?.toDouble(),
      unit: map['unit'] as String?,
      checked: (map['checked'] as bool?) ?? false,
      source: (map['source'] ?? 'manual') as String,
      createdAt: _parseDate(map['created_at']),
      itemType: (map['item_type'] ?? 'comida') as String,
      category: map['category'] as String?,
      imageUrl: _nonEmptyString(map['image_url']),
      listId: map['list_id'] as String?,
      categoryId: map['category_id'] as String?,
    );
  }

  // Parsea la fecha de forma segura. Si viene nula o con un formato invalido
  // devolvemos null para no romper la carga de la lista.
  static DateTime? _parseDate(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }

  // No incluimos id ni created_at: los pone la base de datos.
  Map<String, dynamic> toInsertMap() {
    return {
      'home_id': homeId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'checked': checked,
      'source': source,
      'item_type': itemType,
      'category': category,
      'image_url': imageUrl,
      'list_id': listId,
      'category_id': categoryId,
    };
  }

  /// Serialización COMPLETA (incluye id y created_at) para CACHEAR la fila
  /// entera en disco y poder releerla con [ShoppingListItem.fromMap] al abrir
  /// la app sin conexión. A diferencia de [toInsertMap] (que omite id y
  /// created_at porque los pone la base de datos), aquí conservamos TODO el
  /// estado para reconstruir la fila tal cual. Útil también para el merge
  /// caché<->remoto. Usa las mismas claves snake_case que Supabase.
  Map<String, dynamic> toCacheMap() {
    return {
      'id': id,
      'home_id': homeId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'checked': checked,
      'source': source,
      'created_at': createdAt?.toIso8601String(),
      'item_type': itemType,
      'category': category,
      'image_url': imageUrl,
      'list_id': listId,
      'category_id': categoryId,
    };
  }

  /// Alias de [toCacheMap] para serializar a JSON (misma forma completa).
  Map<String, dynamic> toJson() => toCacheMap();

  /// Texto legible: "2 unidades Cebolla" o "Sal".
  ///
  /// Usa [formatQuantityUnit] (el mismo helper que [Ingredient.display]) para
  /// que el plural de la unidad concuerde con la cantidad.
  String get display {
    final measure = formatQuantityUnit(quantity, unit);
    if (measure.isEmpty) return name;
    return '$measure $name';
  }
}
