/// Helpers de presentación para la lista de la compra: limpian el nombre del
/// producto (quitan marcas de distribuidor y redundancias de unidad) y dan una
/// etiqueta CORTA de cantidad (p. ej. "300 g", "4 ud", "2 dientes"), para que
/// la fila se vea limpia: nombre a un lado, cantidad en una pastilla al otro.
///
/// Lógica PURA (sin Flutter) para poder testearla.
library;

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
  'cucharada': ('cucharada', 'cucharadas'),
  'cucharadita': ('cucharadita', 'cucharaditas'),
};

/// Abreviatura CORTA de una unidad para la pastilla de cantidad de la compra.
/// Deriva de la clave canónica (`_unitKey`) para no duplicar el mapeo de
/// variantes; solo cambia la forma mostrada (p. ej. 'unidad' -> 'ud').
String _shortUnit(String unit, num quantity) {
  final key = _unitKey(unit);
  if (key == null) return unit.trim();
  final plural = quantity != 1;
  switch (key) {
    case 'unidad':
      return 'ud';
    case 'cucharada':
      return 'cda';
    case 'cucharadita':
      return 'cdta';
    case '':
      return '';
    default:
      final forms = _unitForms[key];
      if (forms == null) return key;
      return plural ? forms.$2 : forms.$1;
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
String shoppingQtyLabel(double? quantity, String? unit) {
  final u = (unit ?? '').trim();
  if (quantity == null) {
    // Solo expresión suelta (al gusto / a ojo).
    final lu = u.toLowerCase();
    if (lu == 'al gusto' || lu == 'a ojo') return u;
    return '';
  }
  final short = _shortUnit(u, quantity);
  final num q = quantity;
  if (short.isEmpty) return _fmtNum(q);
  return '${_fmtNum(q)} $short';
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
    if (lu == 'al gusto' || lu == 'a ojo') return u;
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
  final forms = _unitForms[key];
  if (forms == null) return _fmtNum(q);
  final plural = q != 1;
  final label = plural ? forms.$2 : forms.$1;
  return '${_fmtNum(q)} $label';
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
