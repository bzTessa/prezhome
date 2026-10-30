/// País del hogar: decide la moneda y, más adelante, los súper y los precios
/// de referencia. Se guarda en homes.country_code (ISO de 2 letras).
class Country {
  final String code; // 'ES'
  final String name; // nombre en su propio idioma, como en los selectores
  final String currency; // ISO 4217: 'EUR'
  final String off; // país en Open Food Facts: 'spain' (en:spain)
  final String lang; // idioma de los productos en OFF

  const Country(this.code, this.name, this.currency, this.off, this.lang);

  /// Países que la app sabe adaptar, en el orden del selector.
  static const List<Country> all = [
    Country('ES', 'España', 'EUR', 'spain', 'es'),
    Country('DE', 'Deutschland', 'EUR', 'germany', 'de'),
    Country('FR', 'France', 'EUR', 'france', 'fr'),
    Country('IT', 'Italia', 'EUR', 'italy', 'it'),
    Country('PT', 'Portugal', 'EUR', 'portugal', 'pt'),
    Country('AT', 'Österreich', 'EUR', 'austria', 'de'),
    Country('BA', 'Bosna i Hercegovina', 'BAM', 'bosnia-and-herzegovina', 'bs'),
    Country('HR', 'Hrvatska', 'EUR', 'croatia', 'hr'),
    Country('RS', 'Srbija', 'RSD', 'serbia', 'sr'),
    Country('GB', 'United Kingdom', 'GBP', 'united-kingdom', 'en'),
    Country('US', 'United States', 'USD', 'united-states', 'en'),
    Country('MX', 'México', 'MXN', 'mexico', 'es'),
  ];

  /// El país de [code], o España si no está en la lista.
  static Country of(String? code) => all.firstWhere(
    (c) => c.code == code?.toUpperCase(),
    orElse: () => all.first,
  );

  /// Bandera emoji a partir del código (letras indicadoras regionales).
  String get flag =>
      String.fromCharCodes(code.codeUnits.map((c) => c - 0x41 + 0x1F1E6));
}
