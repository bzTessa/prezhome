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

/// Abreviatura corta de una unidad para la pastilla de cantidad.
String _shortUnit(String unit, num quantity) {
  final u = unit.trim().toLowerCase();
  final plural = quantity != 1;
  switch (u) {
    case 'unidad':
    case 'unidades':
    case 'ud':
      return 'ud';
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
      return 'L';
    case 'diente':
    case 'dientes':
      return plural ? 'dientes' : 'diente';
    case 'loncha':
    case 'lonchas':
      return plural ? 'lonchas' : 'loncha';
    case 'lata':
    case 'latas':
      return plural ? 'latas' : 'lata';
    case 'bote':
    case 'botes':
      return plural ? 'botes' : 'bote';
    case 'bolsa':
    case 'bolsas':
      return plural ? 'bolsas' : 'bolsa';
    case 'cucharada':
    case 'cucharadas':
      return 'cda';
    case 'cucharadita':
    case 'cucharaditas':
      return 'cdta';
    case 'al gusto':
    case 'a ojo':
      return '';
    default:
      return unit.trim();
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
