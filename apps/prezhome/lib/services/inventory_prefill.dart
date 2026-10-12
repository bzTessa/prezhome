import 'food_facts_service.dart';
import 'shelf_life.dart';

/// Valores precargables para la pantalla de alta de inventario. Es una bolsa
/// INMUTABLE con solo los campos que el formulario necesita para rellenarse al
/// escanear un código de barras: nombre, cantidad/unidad del formato de venta,
/// categoría/ubicación sugerida. Mantenerlo como objeto único (en vez de varios
/// parámetros sueltos) hace la precarga trivialmente testeable y deja el
/// constructor de la pantalla con un solo parámetro opcional.
class InventoryPrefill {
  /// Nombre del producto (null si OFF no da uno utilizable).
  final String? name;

  /// Cantidad del formato de venta (product_quantity de OFF), si la hay.
  final double? quantity;

  /// Unidad normalizada a la lista del formulario ('g' | 'ml' | 'unidades').
  final String? unit;

  /// Ubicación/categoría sugerida (una de las categorías del formulario).
  final String category;

  /// Ubicación lógica sugerida a partir del nombre (null si no hay nombre).
  final String? location;

  const InventoryPrefill({
    this.name,
    this.quantity,
    this.unit,
    required this.category,
    this.location,
  });
}

/// Mapea una respuesta de Open Food Facts ([FoodFacts]) a los valores que la
/// pantalla de alta puede precargar. Función PURA (sin Flutter, sin
/// BuildContext, sin DateTime.now) para poder testearla en la VM de Dart:
///   - Devuelve null cuando OFF no encontró el producto (found == false), de
///     modo que la UI abra el formulario vacío.
///   - name: productName recortado (null/vacío -> null).
///   - quantity: packageQuantity tal cual (puede ser null).
///   - unit: packageUnit normalizado a la lista del formulario ('g'/'ml'; el
///     resto cae a 'unidades').
///   - location: ShelfLife.suggestLocation(name) cuando hay nombre (si no null).
///   - category: igual que location cuando existe; si no, 'Despensa' (el
///     valor por defecto del formulario).
InventoryPrefill? inventoryPrefillFromFoodFacts(FoodFacts facts) {
  if (!facts.found) return null;

  final rawName = facts.productName?.trim();
  final name = (rawName == null || rawName.isEmpty) ? null : rawName;

  final location = name != null ? ShelfLife.suggestLocation(name) : null;
  final category = location ?? 'Despensa';

  return InventoryPrefill(
    name: name,
    quantity: facts.packageQuantity,
    unit: _normalizeUnit(facts.packageUnit),
    category: category,
    location: location,
  );
}

/// Normaliza la unidad de OFF a la lista de unidades del formulario de alta.
/// Solo 'g' y 'ml' tienen equivalente directo; cualquier otra cosa (o null) cae
/// a 'unidades'.
String _normalizeUnit(String? unit) {
  switch (unit?.trim().toLowerCase()) {
    case 'g':
      return 'g';
    case 'ml':
      return 'ml';
    default:
      return 'unidades';
  }
}
