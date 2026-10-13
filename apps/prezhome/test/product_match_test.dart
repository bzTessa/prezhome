import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/product_search_service.dart';

SupermarketProduct _p(String name, {String? brand, String? img = 'x.jpg'}) =>
    SupermarketProduct(code: name, name: name, brand: brand, imageUrl: img);

void main() {
  test('no acepta productos que son otra cosa', () {
    expect(
      productMatchScore('Vino blanco', _p('Vinagre de vino blanco')),
      isNull,
    );
    expect(
      productMatchScore(
        'arroz blanco',
        _p('Sabroz arroz blanco cocido', brand: 'Sabroz'),
      ),
      isNull,
    );
    expect(productMatchScore('patata', _p('Espelta crackers')), isNull);
    expect(
      productMatchScore('pechuga de pollo', _p('Tiras pollo frango')),
      isNull,
    );
    expect(productMatchScore('arroz', _p('Harina de arroz')), isNull);
    expect(productMatchScore('patata', _p('Patatas fritas onduladas')), isNull);
  });

  test('acepta el producto normal, en singular o plural', () {
    expect(productMatchScore('patata', _p('Patatas')), 0);
    expect(
      productMatchScore(
        'Pechuga de pollo 500 g',
        _p('Pechuga de pollo fileteada'),
      ),
      1,
    );
    expect(
      productMatchScore(
        'leche',
        _p('Leche semidesnatada Hacendado', brand: 'Hacendado'),
      ),
      1,
    );
    expect(productMatchScore('tomate frito', _p('Tomate frito')), 0);
  });

  test('ordena lo exacto primero y solo da foto si está claro', () {
    final products = [
      _p('Sabroz arroz blanco cocido', brand: 'Sabroz'),
      _p('Turrón de chocolate blanco crujiente'),
      _p('Arroz blanco largo', img: 'bueno.jpg'),
    ];
    expect(
      rankProducts('arroz blanco', products).first.name,
      'Arroz blanco largo',
    );
    expect(confidentProductPhoto('arroz blanco', products), 'bueno.jpg');
    expect(
      confidentProductPhoto('vino blanco', [_p('Vinagre de vino blanco')]),
      isNull,
    );
  });

  test('quita el ruido de OFF y no da foto a cebolla con una tortilla', () {
    final patata = [
      _p('Trigo Espelta Crackers'),
      _p('Corn flakes 0% azúcares añadidos'),
      _p('Tortilla De Patatas Con Cebolla'),
      _p('Copos de avena sin gluten'),
    ];
    expect(rankProducts('Patata', patata).map((p) => p.name), [
      'Tortilla De Patatas Con Cebolla',
    ]);
    expect(confidentProductPhoto('Patata', patata), isNull);
    expect(
      confidentProductPhoto('Cebolla', [_p('Tortilla De Patatas Con Cebolla')]),
      isNull,
    );
    expect(isProductFor('Cebolla', _p('Cebolla dulce malla')), isTrue);
  });
}
