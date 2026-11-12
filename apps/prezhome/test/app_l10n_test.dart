import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/l10n/l10n.dart';
import 'package:prezhome/utils/friendly_error.dart';
import 'package:prezhome/utils/shopping_display.dart';

void main() {
  tearDown(() => appL10n = lookupAppLocalizations(const Locale('es')));

  test('los textos sin pantalla siguen el idioma de la app', () {
    appL10n = lookupAppLocalizations(const Locale('en'));
    expect(shoppingQtyLabel(4, 'unidad'), '4 pc');
    expect(inventoryQtyLabel(2, 'bote'), '2 jars');
    expect(inventoryQtyLabel(300, 'g'), '300 g');
    expect(friendlyError(Exception('boom')), 'Something went wrong. Try again.');
  });
}
