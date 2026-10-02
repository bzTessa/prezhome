/// Utilidades para mostrar cantidades + unidades de ingredientes y compras
/// con una concordancia de singular/plural correcta en español.
///
/// La IA (y a veces la propia usuaria) escribe la unidad en singular aunque la
/// cantidad sea mayor que 1 (p.ej. "2 unidad Cebolla"). Estas funciones
/// normalizan ese texto para que se lea bien ("2 unidades Cebolla") sin tener
/// que fiarnos de lo que devuelva el modelo.
///
/// Reglas:
///   - Si [quantity] es null se devuelve solo la expresión de la unidad
///     ("al gusto", "a ojo", ...), ya que no hay número que mostrar.
///   - La cantidad se formatea sin decimales cuando es entera
///     (`toStringAsFixed(0)`), igual que hacían los getters `display`.
///   - La unidad solo se pluraliza cuando `quantity != 1` y es una unidad
///     contable conocida. Las unidades de peso/volumen ('g', 'kg', 'ml', 'l',
///     'litros') y las expresiones sueltas ('al gusto', 'a ojo') NUNCA se
///     pluralizan.
///   - Si la unidad no se reconoce (o ya viene en plural), se deja tal cual:
///     nunca inventamos un plural.
library;

/// Mapa de unidades contables conocidas (clave normalizada -> plural).
const Map<String, String> _pluralByUnit = {
  'unidad': 'unidades',
  'cucharada': 'cucharadas',
  'cucharadita': 'cucharaditas',
  'pizca': 'pizcas',
  'diente': 'dientes',
  'loncha': 'lonchas',
  'rodaja': 'rodajas',
  'rebanada': 'rebanadas',
  'vaso': 'vasos',
  'taza': 'tazas',
  'lata': 'latas',
  'bote': 'botes',
  'bolsa': 'bolsas',
  'punado': 'puñados',
  'chorro': 'chorros',
};

/// Unidades invariables: nunca se pluralizan (ya son abreviaturas de
/// peso/volumen o expresiones que no admiten número plural).
const Set<String> _invariableUnits = {
  'g',
  'kg',
  'ml',
  'l',
  'litros',
  'al gusto',
  'a ojo',
};

/// Normaliza una unidad para compararla: minúsculas, sin espacios sobrantes y
/// sin acentos (para que 'puñado' y 'punado' sean equivalentes).
String _normalizeUnit(String unit) {
  final lower = unit.trim().toLowerCase();
  const withAccents = 'áéíóúüñ';
  const withoutAccents = 'aeiouun';
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    final idx = withAccents.indexOf(char);
    buffer.write(idx >= 0 ? withoutAccents[idx] : char);
  }
  return buffer.toString();
}

/// Devuelve la unidad concordada con [quantity].
///
/// Pluraliza solo las unidades contables conocidas cuando `quantity != 1`.
/// Deja intactas las unidades invariables ('g', 'ml', ...) y cualquier unidad
/// desconocida o ya en plural.
String pluralizeUnit(String unit, num quantity) {
  final trimmed = unit.trim();
  if (trimmed.isEmpty) return trimmed;
  final normalized = _normalizeUnit(trimmed);
  if (_invariableUnits.contains(normalized)) return trimmed;
  if (quantity == 1) return trimmed;
  final plural = _pluralByUnit[normalized];
  if (plural == null) return trimmed; // desconocida o ya en plural: no tocar
  return plural;
}

/// Formatea una cantidad + unidad para mostrarla al usuario.
///
/// Ejemplos:
///   - `formatQuantityUnit(2, 'unidad')`  -> "2 unidades"
///   - `formatQuantityUnit(1, 'unidad')`  -> "1 unidad"
///   - `formatQuantityUnit(200, 'g')`     -> "200 g"
///   - `formatQuantityUnit(null, 'al gusto')` -> "al gusto"
///   - `formatQuantityUnit(3, 'cucharadita')` -> "3 cucharaditas"
///
/// Devuelve una cadena vacía si no hay ni cantidad ni unidad que mostrar.
String formatQuantityUnit(num? quantity, String? unit) {
  final cleanUnit = unit?.trim() ?? '';

  // Sin cantidad: solo la expresión de la unidad ("al gusto", ...).
  if (quantity == null) return cleanUnit;

  final qty = quantity % 1 == 0
      ? quantity.toStringAsFixed(0)
      : quantity.toString();

  if (cleanUnit.isEmpty) return qty;
  return '$qty ${pluralizeUnit(cleanUnit, quantity)}';
}
