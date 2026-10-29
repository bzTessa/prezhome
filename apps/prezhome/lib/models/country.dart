/// País del hogar: decide la moneda y, más adelante, los súper y los precios
/// de referencia. Se guarda en homes.country_code (ISO de 2 letras).
class Country {
  final String code; // 'ES'
  final String name; // nombre en su propio idioma, como en los selectores
  final String currency; // ISO 4217: 'EUR'

  const Country(this.code, this.name, this.currency);

  /// Países que la app sabe adaptar, en el orden del selector.
  static const List<Country> all = [
    Country('ES', 'España', 'EUR'),
    Country('DE', 'Deutschland', 'EUR'),
    Country('FR', 'France', 'EUR'),
    Country('IT', 'Italia', 'EUR'),
    Country('PT', 'Portugal', 'EUR'),
    Country('AT', 'Österreich', 'EUR'),
    Country('BA', 'Bosna i Hercegovina', 'BAM'),
    Country('HR', 'Hrvatska', 'EUR'),
    Country('RS', 'Srbija', 'RSD'),
    Country('GB', 'United Kingdom', 'GBP'),
    Country('US', 'United States', 'USD'),
    Country('MX', 'México', 'MXN'),
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
