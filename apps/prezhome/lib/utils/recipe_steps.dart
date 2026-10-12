/// Lógica PURA de los pasos de una receta (para la vista y el modo cocina).
library;

/// Separa el texto de instrucciones en pasos. Prueba por líneas, luego por
/// numeración "1. 2. 3." y, como último recurso, por frases. Quita el número
/// inicial de cada paso (la UI pone el suyo).
List<String> splitRecipeSteps(String instructions) {
  List<String> clean(Iterable<String> parts) =>
      parts.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  var parts = clean(instructions.split(RegExp(r'\n+')));
  if (parts.length <= 1) {
    parts = clean(instructions.split(RegExp(r'(?=\d+[\.\)]\s)')));
  }
  if (parts.length <= 1) {
    parts = clean(instructions.split(RegExp(r'(?<=[\.\!])\s+(?=[A-ZÁÉÍÓÚÑ])')));
  }
  return clean(parts.map((s) => s.replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '')));
}

/// Minutos de espera que menciona un paso ("hornea 25 minutos", "de 10 a 12
/// min", "1 hora"), para ofrecer un temporizador. Con un rango se toma el
/// mayor. Null si no menciona tiempo.
int? stepTimerMinutes(String step) {
  final s = step.toLowerCase();
  final hours = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:h\b|horas?)').firstMatch(s);
  final mins = RegExp(
    r'(?:(\d+)\s*(?:-|a|o)\s*)?(\d+)\s*(?:min\b|minutos?|mins\b)',
  ).firstMatch(s);
  var total = 0;
  if (hours != null) {
    final h = double.tryParse(hours.group(1)!.replaceAll(',', '.')) ?? 0;
    total += (h * 60).round();
  }
  if (mins != null) total += int.parse(mins.group(2)!);
  return total > 0 ? total : null;
}
