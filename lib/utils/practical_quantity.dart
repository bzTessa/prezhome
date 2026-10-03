/// Redondeo "de cocina" para que las cantidades de las recetas sean PRÁCTICAS
/// en vez de exactas y raras (p. ej. 1060 g, 53 ml, 5,5 dientes de ajo).
///
/// Es lógica PURA (sin Flutter ni red) para poder testearla con datos fijos.
/// Opcionalmente recibe el FORMATO DE VENTA real de Open Food Facts
/// (packageQuantity, p. ej. 400 g de garbanzos de bote) para redondear al
/// múltiplo de ese formato, de modo que la cantidad cuadre con lo que compras
/// aunque siga expresada en gramos (lo que la usuaria pidió explícitamente:
/// seguir en gramos, pero cantidades normales).
///
/// Filosofía (de Tessa): "mejor que sobre un poco a cantidades imposibles de
/// medir". Siempre redondea a algo que una persona usaría de verdad.
library;

/// Resultado del ajuste práctico de una cantidad.
class PracticalQuantity {
  final double? quantity;
  final String unit;

  const PracticalQuantity(this.quantity, this.unit);
}

/// Unidades de peso/volumen que redondeamos a cifras "de cocina".
const Set<String> _weightUnits = {'g', 'gr', 'gramo', 'gramos'};
const Set<String> _volumeUnits = {'ml', 'mililitro', 'mililitros'};

/// Nombres que, en poca cantidad y en ml, es más natural dar en cucharadas
/// (1 cucharada ≈ 15 ml). Sobre todo el aceite y el vinagre.
bool _isSpoonableLiquid(String name) {
  final n = name.toLowerCase();
  return n.contains('aceite') || n.contains('vinagre');
}

/// Redondea [value] al múltiplo de [step] más cercano (hacia arriba a partir de
/// la mitad), con un mínimo de un paso.
double _roundToStep(double value, double step) {
  if (step <= 0) return value;
  final r = (value / step).round() * step;
  return r < step ? step : r;
}

/// Ajusta una cantidad+unidad a una forma práctica.
///
/// - [name]: nombre del ingrediente (para reglas por tipo).
/// - [quantity], [unit]: cantidad y unidad originales (ya escaladas).
/// - [packageGrams]: formato de venta en g/ml de OFF, si se conoce (p. ej. 400
///   para un bote de garbanzos). Si se da y la unidad es de peso/volumen,
///   redondeamos a múltiplos de ese formato.
PracticalQuantity makePractical(
  String name,
  double? quantity,
  String? unit, {
  double? packageGrams,
}) {
  final u = (unit ?? '').trim();
  final uNorm = u.toLowerCase();

  // Sin cantidad (p. ej. "al gusto"): se deja igual.
  if (quantity == null) return PracticalQuantity(null, u);

  // Dientes de ajo y unidades contables: a entero (nunca "5,5 dientes").
  if (uNorm.contains('diente') ||
      uNorm == 'unidad' ||
      uNorm == 'unidades' ||
      uNorm.contains('loncha') ||
      uNorm.contains('rodaja') ||
      uNorm.contains('lata') ||
      uNorm.contains('bote') ||
      uNorm.contains('huevo')) {
    final rounded = quantity.round();
    return PracticalQuantity((rounded < 1 ? 1 : rounded).toDouble(), u);
  }

  // Líquidos "cucharables" (aceite, vinagre) en poca cantidad: a cucharadas.
  if (_volumeUnits.contains(uNorm) && _isSpoonableLiquid(name)) {
    if (quantity <= 60) {
      final tbsp = (quantity / 15).round();
      final n = tbsp < 1 ? 1 : tbsp;
      return PracticalQuantity(n.toDouble(), 'cucharada');
    }
    // Mucho líquido: redondear a 10 ml.
    return PracticalQuantity(_roundToStep(quantity, 10), u);
  }

  // Peso: si conocemos el formato de venta, redondeamos a múltiplos de él
  // (cuadra con los botes/paquetes). Si no, a cifras redondas por tramos.
  if (_weightUnits.contains(uNorm)) {
    if (packageGrams != null && packageGrams > 0) {
      return PracticalQuantity(_roundToStep(quantity, packageGrams), 'g');
    }
    final step = quantity >= 300
        ? 50.0
        : quantity >= 100
        ? 25.0
        : 10.0;
    return PracticalQuantity(_roundToStep(quantity, step), 'g');
  }

  // Volumen genérico (caldo, leche...): redondear a 10 ml / 50 ml por tramo.
  if (_volumeUnits.contains(uNorm)) {
    final step = quantity >= 300 ? 50.0 : 10.0;
    return PracticalQuantity(_roundToStep(quantity, step), u);
  }

  // Cucharadas/cucharaditas/pizcas: a medio o entero, sin pasarnos de decimales.
  if (uNorm.contains('cucharad') || uNorm.contains('pizca')) {
    final half = (quantity * 2).round() / 2;
    return PracticalQuantity(half < 0.5 ? 0.5 : half, u);
  }

  // Resto: dejamos la cantidad tal cual (ya era razonable).
  return PracticalQuantity(quantity, u);
}
