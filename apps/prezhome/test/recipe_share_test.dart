import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/recipe_share.dart';

void main() {
  test(
    'la receta compartida se guarda en tu hogar, sin favorita y con foto',
    () {
      final row = sharedRecipeRow({
        'title': 'Lentejas',
        'servings': 2,
        'is_favorite': true,
        'image_path': 'otro/hogar.jpg',
        'meal_types': ['lunch'],
        'ingredients': [
          {'name': 'Lentejas', 'quantity': 160, 'unit': 'g'},
        ],
        'columna_rara': 1,
      }, 'mi-hogar');
      expect(row['home_id'], 'mi-hogar');
      expect(row['title'], 'Lentejas');
      expect(row['is_favorite'], false);
      expect(row['image_url'], endsWith('/recipe-images/otro/hogar.jpg'));
      expect(row.containsKey('ingredients'), isFalse);
      expect(row.containsKey('columna_rara'), isFalse);
      expect(row.containsKey('id'), isFalse);
    },
  );
}
