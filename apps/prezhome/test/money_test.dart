import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:prezhome/models/country.dart';
import 'package:prezhome/models/supermarket.dart';
import 'package:prezhome/services/home_country.dart';
import 'package:prezhome/utils/approx_price.dart';
import 'package:prezhome/utils/money.dart';

void main() {
  tearDown(() {
    HomeCountry.current.value = Country.of('ES');
    Intl.defaultLocale = null;
  });

  test('moneda del país y formato del idioma', () {
    expect(money(1.8), '1,80 €');
    expect(money(12, decimals: 0), '12 €');

    HomeCountry.current.value = Country.of('US');
    Intl.defaultLocale = 'en_US';
    expect(money(1.8), '\$1.80');

    HomeCountry.current.value = Country.of('BA');
    Intl.defaultLocale = 'bs';
    expect(money(1.8), '1,80 KM');
    expect(currencySymbol(), 'KM');
  });

  test('país desconocido cae en España; bandera', () {
    expect(Country.of('CL').code, 'ES');
    expect(Country.of('de').flag, '🇩🇪');
  });

  test('precios fijos de España solo con euros', () {
    expect(ApproxPrice.estimate('pollo', 1, 'kg'), isNotNull);
    HomeCountry.current.value = Country.of('US');
    expect(ApproxPrice.estimate('pollo', 1, 'kg'), isNull);
  });

  test('súper del país; las etiquetas se encuentran en cualquier país', () {
    final de = Supermarket.forCountry('DE').map((s) => s.key);
    expect(de, containsAll(['rewe', 'lidl']));
    expect(de, isNot(contains('mercadona')));
    expect(Supermarket.forCountry('ES'), Supermarket.all);
    expect(Supermarket.labelFor('bingo'), 'Bingo');
  });
}
