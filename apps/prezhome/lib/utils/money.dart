import 'package:intl/intl.dart';

import '../services/home_country.dart';

/// Importe en la moneda del hogar y con el formato del idioma de la app:
/// "1,80 €" en español, "€1.80" en inglés, "1,80 KM" en bosnio.
String money(num value, {int decimals = 2}) => NumberFormat.simpleCurrency(
  locale: Intl.defaultLocale ?? 'es_ES',
  name: HomeCountry.current.value.currency,
  decimalDigits: decimals,
).format(value);

/// Símbolo de la moneda del hogar, para los campos de importe.
String currencySymbol() => NumberFormat.simpleCurrency(
  locale: Intl.defaultLocale ?? 'es_ES',
  name: HomeCountry.current.value.currency,
).currencySymbol;
