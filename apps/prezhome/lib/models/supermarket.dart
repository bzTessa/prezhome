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
    _carrefour,
    _lidl,
    Supermarket('dia', 'Dia', 0xFFE30613, '${_logos}dia.png'),
    Supermarket('eroski', 'Eroski', 0xFFD5001C, '${_logos}eroski.png'),
    Supermarket('consum', 'Consum', 0xFFF39200, '${_logos}consum.png'),
    Supermarket('alcampo', 'Alcampo', 0xFFE2001A, '${_logos}alcampo.png'),
    _aldi,
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

  static const _carrefour = Supermarket(
    'carrefour',
    'Carrefour',
    0xFF1E5BC6,
    '${_logos}carrefour.png',
  );
  static const _lidl = Supermarket(
    'lidl',
    'Lidl',
    0xFF0050AA,
    '${_logos}lidl.png',
  );
  static const _aldi = Supermarket(
    'aldi',
    'Aldi',
    0xFF00205B,
    '${_logos}aldi.png',
  );

  // Súper de otros países, de más a menos usados. Sin logo: iniciales.
  static const Map<String, List<Supermarket>> _abroad = {
    'DE': [
      Supermarket('edeka', 'Edeka', 0xFFFFD400),
      Supermarket('rewe', 'REWE', 0xFFCC071E),
      _lidl,
      _aldi,
      Supermarket('kaufland', 'Kaufland', 0xFFE10915),
      Supermarket('netto', 'Netto', 0xFFFFD500),
      Supermarket('penny', 'Penny', 0xFFCD1414),
      Supermarket('globus', 'Globus', 0xFF00653A),
    ],
    'FR': [
      Supermarket('leclerc', 'E.Leclerc', 0xFF0066B3),
      _carrefour,
      Supermarket('intermarche', 'Intermarché', 0xFFE2001A),
      Supermarket('superu', 'Super U', 0xFFE3001B),
      Supermarket('auchan', 'Auchan', 0xFFE2001A),
      _lidl,
      Supermarket('casino', 'Casino', 0xFF00A650),
      _aldi,
      Supermarket('monoprix', 'Monoprix', 0xFFE2001A),
      Supermarket('franprix', 'Franprix', 0xFFE5007D),
    ],
    'IT': [
      Supermarket('conad', 'Conad', 0xFFE30613),
      Supermarket('coop', 'Coop', 0xFFE30613),
      Supermarket('esselunga', 'Esselunga', 0xFF00539F),
      _lidl,
      Supermarket('eurospin', 'Eurospin', 0xFF00539F),
      _carrefour,
      Supermarket('despar', 'Despar', 0xFF00843D),
      Supermarket('pam', 'Pam', 0xFFE30613),
      Supermarket('md', 'MD', 0xFFFFD500),
      _aldi,
    ],
    'PT': [
      Supermarket('continente', 'Continente', 0xFFE30613),
      Supermarket('pingodoce', 'Pingo Doce', 0xFF00843D),
      _lidl,
      Supermarket('intermarche', 'Intermarché', 0xFFE2001A),
      Supermarket('auchan', 'Auchan', 0xFFE2001A),
      Supermarket('minipreco', 'Minipreço', 0xFFE30613),
      _aldi,
      Supermarket(
        'mercadona',
        'Mercadona',
        0xFF00843D,
        '${_logos}mercadona.png',
      ),
    ],
    'AT': [
      Supermarket('billa', 'Billa', 0xFFFFE500),
      Supermarket('spar', 'Spar', 0xFF00843D),
      Supermarket('hofer', 'Hofer', 0xFF00205B),
      _lidl,
      Supermarket('penny', 'Penny', 0xFFCD1414),
      Supermarket('mpreis', 'MPreis', 0xFFE30613),
    ],
    'BA': [
      Supermarket('bingo', 'Bingo', 0xFFE30613),
      Supermarket('konzum', 'Konzum', 0xFFE30613),
      Supermarket('amko', 'Amko', 0xFF00539F),
      Supermarket('robot', 'Robot', 0xFFE30613),
      Supermarket('mercator', 'Mercator', 0xFFE30613),
      Supermarket('hose', 'Hoše', 0xFF00843D),
    ],
    'HR': [
      Supermarket('konzum', 'Konzum', 0xFFE30613),
      _lidl,
      Supermarket('kaufland', 'Kaufland', 0xFFE10915),
      Supermarket('spar', 'Spar', 0xFF00843D),
      Supermarket('plodine', 'Plodine', 0xFF00843D),
      Supermarket('tommy', 'Tommy', 0xFFE30613),
      Supermarket('studenac', 'Studenac', 0xFF00539F),
    ],
    'RS': [
      Supermarket('maxi', 'Maxi', 0xFFE30613),
      Supermarket('idea', 'Idea', 0xFFE30613),
      _lidl,
      Supermarket('univerexport', 'Univerexport', 0xFF00539F),
      Supermarket('aman', 'Aman', 0xFF00843D),
      Supermarket('roda', 'Roda', 0xFFE30613),
    ],
    'GB': [
      Supermarket('tesco', 'Tesco', 0xFF00539F),
      Supermarket('sainsburys', "Sainsbury's", 0xFFF06C00),
      Supermarket('asda', 'Asda', 0xFF78BE20),
      _aldi,
      Supermarket('morrisons', 'Morrisons', 0xFF00563F),
      _lidl,
      Supermarket('coop', 'Co-op', 0xFF00B1E7),
      Supermarket('waitrose', 'Waitrose', 0xFF5C8727),
      Supermarket('iceland', 'Iceland', 0xFFD2232A),
      Supermarket('mands', 'M&S', 0xFF1E1E1E),
    ],
    'US': [
      Supermarket('walmart', 'Walmart', 0xFF0071CE),
      Supermarket('kroger', 'Kroger', 0xFF134B97),
      Supermarket('costco', 'Costco', 0xFFE31837),
      Supermarket('target', 'Target', 0xFFCC0000),
      Supermarket('publix', 'Publix', 0xFF3F8F29),
      Supermarket('safeway', 'Safeway', 0xFFE31837),
      _aldi,
      Supermarket('wholefoods', 'Whole Foods', 0xFF00674B),
      Supermarket('traderjoes', "Trader Joe's", 0xFFD21F26),
      Supermarket('heb', 'H-E-B', 0xFFE31837),
    ],
    'MX': [
      Supermarket('walmart', 'Walmart', 0xFF0071CE),
      Supermarket('bodegaaurrera', 'Bodega Aurrera', 0xFF00843D),
      Supermarket('soriana', 'Soriana', 0xFFE30613),
      Supermarket('chedraui', 'Chedraui', 0xFFFF6600),
      Supermarket('lacomer', 'La Comer', 0xFFE30613),
      Supermarket('heb', 'HEB', 0xFFE31837),
      Supermarket('costco', 'Costco', 0xFFE31837),
      Supermarket('oxxo', 'OXXO', 0xFFE30613),
    ],
  };

  /// Súper del país del hogar (España si no hay lista para ese país).
  static List<Supermarket> forCountry(String code) => _abroad[code] ?? all;

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
    for (final s in [...all, ..._abroad.values.expand((l) => l)]) {
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
