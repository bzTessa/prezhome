/// Motor PREDICTIVO LOCAL del "Asistente Proactivo" (sin IA ni red): a partir
/// de datos ya cargados (espejos reducidos de los modelos) produce sugerencias
/// ACCIONABLES tipadas. Es LÓGICA PURA: no importa Flutter ni Supabase, solo
/// `dart core` y el modelo [ShoppingListItem] (que a su vez solo depende de
/// utils/measure_format.dart, sin Flutter), de modo que todo se puede testear
/// en la Dart VM con días/fechas fijos sin plugins nativos.
///
/// Es COMPLEMENTARIO a smart_reminders.dart, no lo duplica:
///  - smart_reminders.dart = panel INFORMATIVO "Hoy toca" en Inicio.
///  - este servicio = sugerencias ACCIONABLES: (a) tarjeta de caducidad que
///    invita a aprovechar un alimento en el próximo Batch Cooking/Modo cocina
///    (se pintará en main_shell) y (b) reposición automática de básicos
///    agotados hacia la lista de la compra.
///
/// La UI (FEAT-003) consume estas funciones; aquí no hay nada de presentación.
library;

import '../models/shopping_list_item.dart';

/// Espejo reducido de un alimento del inventario para calcular caducidades.
///
/// [daysUntilExpiry] viene YA calculado por quien llama (igual que en
/// [ReminderStockItem] de smart_reminders): es `InventoryItem.daysUntilExpiry`
/// sobre la caducidad efectiva. Negativo = ya caducado, `null` = sin fecha.
/// [isFood] distingue comida de artículos de hogar (solo la comida caduca de
/// forma relevante para cocinar).
class ProactiveStockItem {
  final String name;
  final int? daysUntilExpiry;
  final bool isFood;

  const ProactiveStockItem({
    required this.name,
    this.daysUntilExpiry,
    this.isFood = true,
  });
}

/// Sugerencia de "caduca pronto": invita a aprovechar [name] en el próximo
/// Batch Cooking antes de que caduque. [daysUntilExpiry] es 0 (hoy), 1 (mañana)
/// o 2 (pasado mañana).
class ExpiringSuggestion {
  final String name;
  final int daysUntilExpiry;

  const ExpiringSuggestion({required this.name, required this.daysUntilExpiry});

  /// Texto en español cercano para la tarjeta (sin la palabra "IA"). La UI
  /// puede usarlo tal cual o construir el suyo; aquí es solo texto puro.
  String get message {
    final cuando = switch (daysUntilExpiry) {
      0 => 'caduca hoy',
      1 => 'caduca mañana',
      _ => 'caduca en $daysUntilExpiry días',
    };
    return 'Cocina $name antes de que caduque ($cuando)';
  }
}

/// Construye las sugerencias de "caduca pronto" para el próximo Batch Cooking.
///
/// Incluye SOLO alimentos de comida (`isFood == true`) cuya caducidad efectiva
/// está dentro del umbral: `0 <= daysUntilExpiry <= thresholdDays`. Con el
/// valor por defecto `thresholdDays = 2` eso significa "hoy (0), mañana (1) o
/// pasado mañana (2)".
///
/// EXCLUYE explícitamente:
///  - caducados (`daysUntilExpiry < 0`): ya no sirve proponer cocinarlos,
///  - frescos (`daysUntilExpiry > thresholdDays`): aún no urge,
///  - sin fecha (`daysUntilExpiry == null`),
///  - no-comida (`isFood == false`).
///
/// El resultado se ordena por `daysUntilExpiry` ascendente (lo más urgente
/// primero) de forma estable (el orden de entrada se respeta a igualdad de
/// días).
List<ExpiringSuggestion> buildExpiringSuggestions(
  List<ProactiveStockItem> stock, {
  int thresholdDays = 2,
}) {
  final out = <ExpiringSuggestion>[];
  for (final s in stock) {
    final d = s.daysUntilExpiry;
    if (!s.isFood) continue;
    if (d == null) continue;
    if (d < 0 || d > thresholdDays) continue;
    out.add(ExpiringSuggestion(name: s.name, daysUntilExpiry: d));
  }
  // Orden ascendente estable: List.sort es estable para claves iguales cuando
  // el comparador devuelve 0, así que mantenemos el orden de entrada a empate.
  out.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
  return out;
}

/// Normaliza un nombre para comparar duplicados: minúsculas + sin espacios
/// sobrantes. Se usa una normalización SIMPLE y local a propósito para no
/// acoplar el motor con assets ni con Flutter (en el código original la UI usa
/// un helper de categorías; aquí basta con lowercase+trim para el dedup de la
/// lista de la compra, manteniendo la pureza del servicio).
String normalizeName(String name) => name.trim().toLowerCase();

/// Regla única y testeable de "básico agotado": es un alimento marcado como
/// básico (`isStaple`, "siempre en casa") cuya cantidad ha llegado a cero (o
/// menos). No se añade ninguna columna nueva: "agotado" = `quantity <= 0`.
bool isDepletedStaple(bool isStaple, double quantity) =>
    isStaple && quantity <= 0;

/// Construye el [ShoppingListItem] a insertar en la compra para REPONER un
/// básico agotado, con `source: 'auto'`.
///
/// Deduplica por nombre normalizado contra [existingShoppingNames] (los nombres
/// de los artículos que ya están en la lista de la compra): si el nombre ya
/// está presente devuelve `null` para no crear duplicados; si no, devuelve el
/// item listo para insertar.
///
/// [quantity] por defecto es 1 (reponer una unidad). El resto de campos
/// (unit/category/itemType/imageUrl) se arrastran del item de la despensa.
ShoppingListItem? buildRestockItem({
  required String homeId,
  required String name,
  required String itemType,
  String? category,
  String? unit,
  String? imageUrl,
  double quantity = 1,
  required Iterable<String> existingShoppingNames,
}) {
  final target = normalizeName(name);
  final alreadyThere = existingShoppingNames.any(
    (n) => normalizeName(n) == target,
  );
  if (alreadyThere) return null;
  return ShoppingListItem(
    homeId: homeId,
    name: name,
    quantity: quantity,
    unit: unit,
    source: 'auto',
    itemType: itemType,
    category: category,
    imageUrl: imageUrl,
  );
}
