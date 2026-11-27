import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/recipe.dart';
import 'package:prezhome/services/global_search.dart';

void main() {
  final data = SearchData(
    shopping: [
      {'name': 'Leche semidesnatada', 'quantity': 6, 'unit': 'L'},
      {'name': 'Pan', 'checked': true},
    ],
    pantry: [
      {
        'name': 'Leche de avena',
        'quantity': 1,
        'unit': 'unidades',
        'category': 'Nevera',
      },
    ],
    recipes: [
      Recipe.fromMap({
        'id': 'r1',
        'home_id': 'h',
        'title': 'Arroz con leche',
        'servings': 4,
        'prep_minutes': 10,
        'cook_minutes': 40,
      }),
      Recipe.fromMap({
        'id': 'r2',
        'home_id': 'h',
        'title': 'Lentejas',
        'servings': 2,
      }),
    ],
    tasks: [
      {'title': 'Limpiar la nevera', 'is_done': false},
      {'title': 'Comprar leche', 'is_done': true},
    ],
  );

  test('busca en todas las secciones sin acentos ni mayúsculas', () {
    final r = searchEverything(data, 'LECHE');
    expect(r[SearchKind.shopping]!.single.title, 'Leche semidesnatada');
    expect(r[SearchKind.shopping]!.single.detail, '6 L');
    expect(r[SearchKind.pantry]!.single.detail, '1 · Nevera');
    expect(r[SearchKind.recipe]!.single.detail, '50 min');
    // Las tareas hechas no salen.
    expect(r.containsKey(SearchKind.task), isFalse);
  });

  test('todas las palabras tienen que estar', () {
    expect(searchEverything(data, 'leche avena').keys, [SearchKind.pantry]);
    expect(searchEverything(data, 'nevera')[SearchKind.task], hasLength(1));
  });

  test('lo comprado se marca y sin texto no hay resultados', () {
    expect(
      searchEverything(data, 'pan')[SearchKind.shopping]!.single.done,
      isTrue,
    );
    expect(searchEverything(data, '   '), isEmpty);
  });
}
