/// Helpers de presentación para la lista de la compra: limpian el nombre del
/// producto (quitan marcas de distribuidor y redundancias de unidad) y dan una
/// etiqueta CORTA de cantidad (p. ej. "300 g", "4 ud", "2 dientes"), para que
/// la fila se vea limpia: nombre a un lado, cantidad en una pastilla al otro.
///
/// Lógica PURA (sin Flutter) para poder testearla.
library;

import '../l10n/l10n.dart';

/// Marcas de distribuidor y palabras de marca que a veces se cuelan en el
/// nombre (de recetas antiguas de IA) y que NO queremos mostrar.
const Set<String> _brandWords = {
  'hacendado',
  'mercadona',
  'carrefour',
  'lidl',
  'dia',
  'alcampo',
  'eroski',
  'aldi',
  'consum',
  'auchan',
  'hipercor',
  'ahorramas',
  'deluxe',
  'eliges',
};

/// Normaliza una unidad (en cualquiera de sus variantes de entrada) a una
/// CLAVE canónica interna. Así la lógica de concordancia singular/plural y de
/// abreviaturas vive en un único sitio y la comparten la etiqueta corta de la
/// compra (`_shortUnit`) y la larga del inventario (`inventoryQtyLabel`).
/// Devuelve null si la unidad no es conocida (p. ej. una medida libre).
String? _unitKey(String unit) {
  switch (unit.trim().toLowerCase()) {
    case 'unidad':
    case 'unidades':
    case 'ud':
      return 'unidad';
    case 'g':
    case 'gr':
    case 'gramo':
    case 'gramos':
      return 'g';
    case 'kg':
      return 'kg';
    case 'ml':
      return 'ml';
    case 'l':
    case 'litro':
    case 'litros':
      return 'l';
    case 'diente':
    case 'dientes':
      return 'diente';
    case 'loncha':
    case 'lonchas':
      return 'loncha';
    case 'lata':
    case 'latas':
      return 'lata';
    case 'bote':
    case 'botes':
      return 'bote';
    case 'bolsa':
    case 'bolsas':
      return 'bolsa';
    case 'comida':
    case 'comidas':
      return 'comida';
    case 'cucharada':
    case 'cucharadas':
      return 'cucharada';
    case 'cucharadita':
    case 'cucharaditas':
      return 'cucharadita';
    case 'al gusto':
    case 'a ojo':
      return '';
    default:
      return null;
  }
}

/// Formas (singular, plural) de cada unidad canónica para la etiqueta LARGA
/// del inventario. Las unidades métricas no varían con el número.
const Map<String, (String, String)> _unitForms = {
  'unidad': ('unidad', 'unidades'),
  'g': ('g', 'g'),
  'kg': ('kg', 'kg'),
  'ml': ('ml', 'ml'),
  'l': ('L', 'L'),
  'diente': ('diente', 'dientes'),
  'loncha': ('loncha', 'lonchas'),
  'lata': ('lata', 'latas'),
  'bote': ('bote', 'botes'),
  'bolsa': ('bolsa', 'bolsas'),
  'comida': ('comida', 'comidas'),
  'cucharada': ('cucharada', 'cucharadas'),
  'cucharadita': ('cucharadita', 'cucharaditas'),
};

/// Palabra de la unidad en el idioma de la app: g, kg, ml y L son iguales en
/// todos; el resto sale de l10n (unitOne/unitMany).
String _unitWord(String key, bool plural) {
  final forms = _unitForms[key]!;
  if (forms.$1 == forms.$2) return forms.$1;
  return plural ? appL10n.unitMany(key) : appL10n.unitOne(key);
}

/// Nombre de una unidad para un selector ("unidades", "botes", "L").
String unitName(String unit) {
  final key = _unitKey(unit);
  if (key == null || key.isEmpty || !_unitForms.containsKey(key)) return unit;
  return _unitWord(key, true);
}

/// Abreviatura CORTA de una unidad para la pastilla de cantidad de la compra.
/// Deriva de la clave canónica (`_unitKey`) para no duplicar el mapeo de
/// variantes; solo cambia la forma mostrada (p. ej. 'unidad' -> 'ud').
String _shortUnit(String unit, num quantity) {
  final key = _unitKey(unit);
  if (key == null) return unit.trim();
  final plural = quantity != 1;
  switch (key) {
    case 'unidad' || 'cucharada' || 'cucharadita':
      return appL10n.unitShort(key);
    case '':
      return '';
    default:
      if (!_unitForms.containsKey(key)) return key;
      return _unitWord(key, plural);
  }
}

/// Formatea un número sin decimales si es entero (3.0 -> "3", 1.5 -> "1,5").
String _fmtNum(num n) {
  if (n % 1 == 0) return n.toInt().toString();
  return n.toStringAsFixed(1).replaceAll('.', ',');
}

/// Etiqueta CORTA de cantidad para la pastilla, o cadena vacía si no procede.
/// Ej: (300,'g') -> "300 g"; (4,'unidad') -> "4 ud"; (2,'diente') -> "2 dientes";
/// (null,'al gusto') -> "al gusto".
String shoppingQtyLabel(double? quantity, String? unit, {double? packSize}) {
  final u = (unit ?? '').trim();
  if (quantity == null) {
    // Solo expresión suelta (al gusto / a ojo).
    final lu = u.toLowerCase();
    if (lu == 'al gusto' || lu == 'a ojo') {
      return appL10n.unitToTaste(lu == 'a ojo' ? 'a_ojo' : 'al_gusto');
    }
    return '';
  }
  final packs = shoppingPacks(quantity, unit, packSize);
  if (isMeasureUnit(u)) {
    final key = _unitKey(u)!;
    if (packs != null) return '$packs × ${_measure(packSize!, key)}';
    return _measure(quantity, key);
  }
  final short = _shortUnit(u, quantity);
  final num q = quantity;
  if (short.isEmpty) return _fmtNum(q);
  return '${_fmtNum(q)} $short';
}

/// Peso o volumen legible: 200 ml, 2,7 kg, 1,5 L (a partir de 1000 g/ml se
/// pasa a kg/L).
String _measure(double q, String key) {
  String n(double v) {
    final s = (v * 100).round() / 100;
    return s % 1 == 0
        ? s.toInt().toString()
        : s.toString().replaceAll('.', ',');
  }

  return switch (key) {
    'g' when q >= 1000 => '${n(q / 1000)} kg',
    'ml' when q >= 1000 => '${n(q / 1000)} L',
    'l' => '${n(q)} L',
    _ => '${n(q)} $key',
  };
}

/// ¿Va [unit] a peso o volumen (g, kg, ml, L)?
bool isMeasureUnit(String? unit) =>
    const {'g', 'kg', 'ml', 'l'}.contains(_unitKey(unit ?? ''));

/// Envases que hay que comprar (redondeando hacia arriba) si se conoce el
/// tamaño del envase y la cantidad va a peso o volumen; si no, null.
int? shoppingPacks(double? quantity, String? unit, double? packSize) {
  if (quantity == null || packSize == null || packSize <= 0) return null;
  if (!isMeasureUnit(unit)) return null;
  // Tolerancia para no comprar un envase de más por decimales (399,999 ml).
  final packs = (quantity / packSize - 1e-6).ceil();
  return packs < 1 ? 1 : packs;
}

/// Tamaño del envase [raw] del catálogo ("0.2 l", "500 g") expresado en
/// [unit], la unidad de la línea de la compra. Null si no se entiende o no
/// es la misma magnitud (un envase en litros para algo que va en gramos).
double? packSizeIn(({double quantity, String unit})? pack, String? unit) {
  if (pack == null) return null;
  final key = _unitKey(unit ?? '');
  final inBase = switch (pack.unit) {
    'kg' => (pack.quantity * 1000, 'g'),
    'g' => (pack.quantity, 'g'),
    'ml' => (pack.quantity, 'ml'),
    _ => (pack.quantity * 1000, 'ml'),
  };
  final size = switch (key) {
    'g' when inBase.$2 == 'g' => inBase.$1,
    'kg' when inBase.$2 == 'g' => inBase.$1 / 1000,
    'ml' when inBase.$2 == 'ml' => inBase.$1,
    'l' when inBase.$2 == 'ml' => inBase.$1 / 1000,
    _ => null,
  };
  return size == null || size <= 0 ? null : size;
}

/// Etiqueta LARGA de cantidad para la fila del inventario de la despensa.
/// A diferencia de `shoppingQtyLabel` (pastilla compacta de la compra: '4 ud'),
/// aquí mostramos la unidad completa con concordancia singular/plural para que
/// la fila se lea natural: '1 unidad', '2 unidades', '300 g', '1,5 kg',
/// '1 bote', '2 botes'. Nunca devuelve '1.0' ni '1 unidades'.
/// Ej: (1,'unidad') -> "1 unidad"; (2,'ud') -> "2 unidades"; (null,'al gusto')
/// -> "al gusto"; (null,'g') -> "".
String inventoryQtyLabel(double? quantity, String? unit) {
  final u = (unit ?? '').trim();
  if (quantity == null) {
    // Sin cantidad solo tiene sentido una expresión suelta (al gusto / a ojo).
    final lu = u.toLowerCase();
    if (lu == 'al gusto' || lu == 'a ojo') {
      return appL10n.unitToTaste(lu == 'a ojo' ? 'a_ojo' : 'al_gusto');
    }
    return '';
  }
  final num q = quantity;
  final key = _unitKey(u);
  // Unidad desconocida: mostramos el texto tal cual (p. ej. una medida libre).
  if (key == null) {
    final raw = u;
    if (raw.isEmpty) return _fmtNum(q);
    return '${_fmtNum(q)} $raw';
  }
  // Expresión suelta sin unidad real (al gusto / a ojo): solo el número.
  if (key.isEmpty) return _fmtNum(q);
  if (isMeasureUnit(u)) return _measure(quantity, key);
  final forms = _unitForms[key];
  if (forms == null) return _fmtNum(q);
  return '${_fmtNum(q)} ${_unitWord(key, q != 1)}';
}

/// Limpia el NOMBRE del producto para mostrarlo: quita palabras de marca
/// (Hacendado...) y recorta espacios. No toca el dato guardado, solo la
/// presentación. Si tras limpiar queda vacío, devuelve el original.
String shoppingCleanName(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  final kept = words.where((w) {
    final normalized = w.toLowerCase().replaceAll(RegExp(r'[^a-záéíóúñ]'), '');
    return !_brandWords.contains(normalized);
  }).toList();
  final cleaned = kept.join(' ').trim();
  if (cleaned.isEmpty) return name.trim();
  // Primera letra en mayúscula para que quede cuidado.
  return cleaned[0].toUpperCase() + cleaned.substring(1);
}

/// Cantidad siguiente al pulsar + ([up]) o − en la pastilla de la compra: de
/// envase en envase si se conoce [packSize]; si no, de 100 en 100 en g y ml, de medio en medio en kg y L, y de uno en uno en lo
/// demás. Devuelve null si bajaría de un paso (quitar es otra acción).
double? shoppingQtyNext(
  double? quantity,
  String? unit, {
  required bool up,
  double? packSize,
}) {
  // Con envase conocido, el paso es un envase entero.
  final packs = shoppingPacks(quantity, unit, packSize);
  if (packs != null) {
    final next = packs + (up ? 1 : -1);
    if (next < 1) return null;
    return (next * packSize! * 1000).round() / 1000;
  }
  final step = switch (_unitKey(unit ?? '')) {
    'g' || 'ml' => 100.0,
    'kg' || 'l' => 0.5,
    _ => 1.0,
  };
  final next = (quantity ?? (up ? 0 : step)) + (up ? step : -step);
  if (next < step) return null;
  return (next * 100).round() / 100;
}
