/// Dónde va lo que se apunta rápido desde Hoy.
enum CaptureTarget { shopping, pantry, task }

/// Parte lo escrito en cosas sueltas: "leche, pan y huevos" son tres.
/// Las tareas no se parten: "Llamar al fontanero y al seguro" es una sola.
List<String> splitCapture(String text, CaptureTarget target) {
  final t = text.trim();
  if (t.isEmpty) return const [];
  if (target == CaptureTarget.task) return [t];
  return [
    for (final part in t.split(RegExp(r',|;|\n|\s+y\s+')))
      if (part.trim().isNotEmpty) _capitalize(part.trim()),
  ];
}

String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
