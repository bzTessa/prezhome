/// Texto de la lista de la compra para mandarla por WhatsApp o donde sea:
/// título, y lo que falta por pasillos (en el orden del súper) con cantidad.
/// Lógica PURA.
String shoppingShareText({
  required String title,
  required List<(String, List<(String name, String qty)>)> groups,
  required String footer,
}) {
  final b = StringBuffer('*$title*');
  final named = groups.length > 1;
  for (final (section, items) in groups) {
    if (items.isEmpty) continue;
    b.write('\n\n');
    if (named && section.trim().isNotEmpty) b.writeln('_${section.trim()}_');
    b.write([
      for (final (name, qty) in items)
        qty.trim().isEmpty ? '- $name' : '- $name · ${qty.trim()}',
    ].join('\n'));
  }
  if (footer.isNotEmpty) b.write('\n\n$footer');
  return b.toString();
}
