import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/widgets/dish_illustration.dart';

void main() {
  test('elige el dibujo por el título', () {
    expect(dishKindFor('Crema de calabaza'), DishKind.soup);
    expect(dishKindFor('Espaguetis a la boloñesa'), DishKind.pasta);
    expect(dishKindFor('Bowl de pollo con arroz'), DishKind.rice);
    expect(dishKindFor('Ensalada César'), DishKind.salad);
    expect(dishKindFor('Tarta de queso'), DishKind.dessert);
    expect(dishKindFor('Pollo al limón'), DishKind.plate);
    expect(dishKindFor('Algo raro', ['dessert']), DishKind.dessert);
  });

  testWidgets('se pinta sin errores', (tester) async {
    for (final title in [
      'Sopa',
      'Pasta',
      'Arroz',
      'Ensalada',
      'Tarta',
      'Batido',
      'Tostada',
      'Pollo',
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 200,
            height: 160,
            child: DishIllustration(title: title),
          ),
        ),
      );
    }
    expect(find.byType(DishIllustration), findsOneWidget);
  });
}
