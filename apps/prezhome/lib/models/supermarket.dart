/// Catálogo de supermercados que el hogar puede seleccionar. La selección es
/// OPCIONAL y puede incluir VARIOS (el hogar compra en distintos sitios). Se
/// guarda en homes.supermarkets como una lista de CLAVES canónicas en
/// minúsculas; esta clase mapea cada clave a su etiqueta visible.
class Supermarket {
  final String key; // clave canónica almacenada (p. ej. 'mercadona')
  final String label; // etiqueta visible (p. ej. 'Mercadona')

  const Supermarket(this.key, this.label);

  /// Supermercados españoles más habituales. El orden es el que se muestra en
  /// la lista de selección.
  static const List<Supermarket> all = [
    Supermarket('mercadona', 'Mercadona'),
    Supermarket('lidl', 'Lidl'),
    Supermarket('carrefour', 'Carrefour'),
    Supermarket('dia', 'Dia'),
    Supermarket('alcampo', 'Alcampo'),
    Supermarket('eroski', 'Eroski'),
    Supermarket('aldi', 'Aldi'),
    Supermarket('consum', 'Consum'),
    Supermarket('elcorteingles', 'El Corte Inglés / Hipercor'),
    Supermarket('ahorramas', 'Ahorramás'),
  ];

  /// Devuelve la etiqueta visible de una clave, o la propia clave capitalizada
  /// si no está en el catálogo (tolerante a datos antiguos o manuales).
  static String labelFor(String key) {
    for (final s in all) {
      if (s.key == key) return s.label;
    }
    if (key.isEmpty) return key;
    return key[0].toUpperCase() + key.substring(1);
  }

  /// Convierte una lista de claves guardadas en sus etiquetas visibles,
  /// descartando claves vacías.
  static List<String> labelsFor(List<String> keys) =>
      keys.where((k) => k.trim().isNotEmpty).map(labelFor).toList();
}
