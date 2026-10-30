/// Catálogo de supermercados que el hogar puede seleccionar. La selección es
/// OPCIONAL y puede incluir VARIOS (el hogar compra en distintos sitios). Se
/// guarda en homes.supermarkets como una lista de CLAVES canónicas en
/// minúsculas; esta clase mapea cada clave a su etiqueta visible.
class Supermarket {
  final String key; // clave canónica almacenada (p. ej. 'mercadona')
  final String label; // etiqueta visible (p. ej. 'Mercadona')
  final int brandColor; // color de marca (ARGB) para su insignia
  // Logo en assets/supermarkets/ (icono de su app). Sin logo se pintan las
  // iniciales sobre [brandColor].
  final String? logo;

  const Supermarket(
    this.key,
    this.label, [
    this.brandColor = 0xFF8D6E63,
    this.logo,
  ]);

  static const _logos = 'assets/supermarkets/';

  /// Supermercados españoles, de más a menos usados (cuota de mercado). Es el
  /// orden en que se muestran.
  static const List<Supermarket> all = [
    Supermarket('mercadona', 'Mercadona', 0xFF00843D, '${_logos}mercadona.png'),
    Supermarket('carrefour', 'Carrefour', 0xFF1E5BC6, '${_logos}carrefour.png'),
    Supermarket('lidl', 'Lidl', 0xFF0050AA, '${_logos}lidl.png'),
    Supermarket('dia', 'Dia', 0xFFE30613, '${_logos}dia.png'),
    Supermarket('eroski', 'Eroski', 0xFFD5001C, '${_logos}eroski.png'),
    Supermarket('consum', 'Consum', 0xFFF39200, '${_logos}consum.png'),
    Supermarket('alcampo', 'Alcampo', 0xFFE2001A, '${_logos}alcampo.png'),
    Supermarket('aldi', 'Aldi', 0xFF00205B, '${_logos}aldi.png'),
    Supermarket('ahorramas', 'Ahorramás', 0xFF00A04A, '${_logos}ahorramas.png'),
    Supermarket('bonarea', 'bonÀrea', 0xFF1E1E1E, '${_logos}bonarea.png'),
    Supermarket(
      'elcorteingles',
      'El Corte Inglés / Hipercor',
      0xFF00843D,
      '${_logos}elcorteingles.png',
    ),
    Supermarket('gadis', 'Gadis', 0xFFFFD100, '${_logos}gadis.png'),
    Supermarket('bm', 'BM', 0xFFFFE000, '${_logos}bm.png'),
    Supermarket('condis', 'Condis', 0xFF1D5C7A, '${_logos}condis.png'),
    Supermarket('caprabo', 'Caprabo', 0xFF29ABE2, '${_logos}caprabo.png'),
    Supermarket('hiperdino', 'HiperDino', 0xFF009640, '${_logos}hiperdino.png'),
  ];

  /// ¿Encaja con lo escrito en el buscador? Compara con la etiqueta y con la
  /// clave (sin tildes ni espacios: "bonarea", "corte ingles").
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    return label.toLowerCase().contains(q) ||
        key.contains(q.replaceAll(' ', ''));
  }

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
