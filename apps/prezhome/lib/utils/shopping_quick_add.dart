/// Lógica PURA del alta rápida de la lista de la compra y de sus preferencias
/// de vista. Sin Flutter, para poder testearla.
library;

import 'dart:convert';

/// Resultado de interpretar lo que la usuaria escribe en "Añadir producto".
class QuickAddEntry {
  const QuickAddEntry({required this.name, this.quantity, this.unit});

  final String name;
  final double? quantity;
  final String? unit;
}

/// Unidades que se reconocen al principio del texto ("2 kg tomates").
/// Clave = como se escribe (minúsculas); valor = como se guarda.
const Map<String, String> _units = {
  'kg': 'kg',
  'kilo': 'kg',
  'kilos': 'kg',
  'g': 'g',
  'gr': 'g',
  'gramos': 'g',
  'l': 'l',
  'litro': 'l',
  'litros': 'l',
  'ml': 'ml',
  'ud': 'ud',
  'uds': 'ud',
  'unidad': 'ud',
  'unidades': 'ud',
  'paquete': 'paquete',
  'paquetes': 'paquete',
  'bote': 'bote',
  'botes': 'bote',
  'lata': 'lata',
  'latas': 'lata',
  'docena': 'docena',
  'docenas': 'docena',
  'bolsa': 'bolsa',
  'bolsas': 'bolsa',
  'botella': 'botella',
  'botellas': 'botella',
};

/// Interpreta textos como:
///   "tomates"            -> tomates
///   "2 kg tomates"       -> tomates, 2, kg
///   "3 yogures"          -> yogures, 3
///   "leche x2"           -> leche, 2
///   "1,5 l de leche"     -> leche, 1.5, l
/// Devuelve null si no queda nombre.
QuickAddEntry? parseQuickAdd(String raw) {
  var text = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (text.isEmpty) return null;

  double? quantity;
  String? unit;

  // Cantidad al final: "leche x2" / "leche x 2".
  final trailing = RegExp(
    r'\s+x\s*(\d+(?:[.,]\d+)?)$',
    caseSensitive: false,
  ).firstMatch(text);
  if (trailing != null) {
    quantity = double.tryParse(trailing.group(1)!.replaceAll(',', '.'));
    text = text.substring(0, trailing.start).trim();
  } else {
    // Cantidad al principio, con unidad opcional pegada o separada:
    // "2 kg tomates", "2kg tomates", "3 yogures".
    final leading = RegExp(
      r'^(\d+(?:[.,]\d+)?)\s*([a-záéíóúñ]+)?\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(text);
    if (leading != null) {
      quantity = double.tryParse(leading.group(1)!.replaceAll(',', '.'));
      final maybeUnit = leading.group(2)?.toLowerCase();
      var rest = leading.group(3)!;
      if (maybeUnit != null && _units.containsKey(maybeUnit)) {
        unit = _units[maybeUnit];
      } else if (maybeUnit != null) {
        // No era una unidad: forma parte del nombre ("3 yogures").
        rest = '${leading.group(2)} $rest';
      }
      text = rest.trim();
    }
  }

  // "de leche" -> "leche" tras una unidad.
  if (unit != null) {
    text = text.replaceFirst(RegExp(r'^de\s+', caseSensitive: false), '');
  }
  if (text.isEmpty) return null;
  return QuickAddEntry(name: text, quantity: quantity, unit: unit);
}

/// Preferencias de vista de la lista de la compra (por dispositivo).
class ShoppingViewPrefs {
  const ShoppingViewPrefs({this.showPhotos = false, this.groupByAisle = true});

  /// Mostrar la foto/ilustración de cada producto. Por defecto no: la lista
  /// se lee más rápido sin imágenes.
  final bool showPhotos;

  /// Agrupar por pasillo (verduras, carne...). Si no, una sola lista en el
  /// orden en que se añadieron.
  final bool groupByAisle;

  /// Clave en el almacenamiento local.
  static const String storageKey = 'shopping_view_prefs';

  ShoppingViewPrefs copyWith({bool? showPhotos, bool? groupByAisle}) =>
      ShoppingViewPrefs(
        showPhotos: showPhotos ?? this.showPhotos,
        groupByAisle: groupByAisle ?? this.groupByAisle,
      );

  String encode() =>
      jsonEncode({'show_photos': showPhotos, 'group_by_aisle': groupByAisle});

  /// Tolerante: cualquier valor ausente o corrupto cae al defecto.
  static ShoppingViewPrefs decode(String? raw) {
    if (raw == null || raw.isEmpty) return const ShoppingViewPrefs();
    try {
      final m = jsonDecode(raw);
      if (m is! Map) return const ShoppingViewPrefs();
      return ShoppingViewPrefs(
        showPhotos: m['show_photos'] == true,
        groupByAisle: m['group_by_aisle'] != false,
      );
    } catch (_) {
      return const ShoppingViewPrefs();
    }
  }
}
