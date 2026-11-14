import '../models/recipe.dart';
import 'shopping_categories.dart' show normalizeCategoryText;

/// Lo que no se puede (alergias, dieta) o no se quiere comer en casa. Lógica
/// PURA: decide qué recetas puede proponer el plan automático.
///
/// - Alergias: de TODAS las personas del hogar, y son una barrera dura.
/// - Dieta (vegetariana, vegana, pescetariana): se aplica la menos estricta
///   de las personas que la han indicado, para no quitarle la carne a toda la
///   casa porque una persona no la come. "Sin gluten" cuenta como alergia.
/// - Lo que no gusta: se evita si quedan bastantes recetas; nunca deja el plan
///   vacío.
class FoodRestrictions {
  const FoodRestrictions({
    this.allergies = const {},
    this.diet,
    this.disliked = const {},
  });

  /// Claves como en el perfil ('gluten', 'lactosa', 'frutos secos'...) o
  /// texto libre ('kiwi'), que se busca tal cual. Sin acentos.
  final Set<String> allergies;

  /// 'vegetariana' | 'vegana' | 'pescetariana' o null (de todo).
  final String? diet;

  /// Ingredientes que alguien prefiere no comer. Sin acentos.
  final Set<String> disliked;

  static const empty = FoodRestrictions();

  bool get isEmpty => allergies.isEmpty && diet == null && disliked.isEmpty;

  static const _dietRank = {'pescetariana': 1, 'vegetariana': 2, 'vegana': 3};

  /// Junta las filas de `home_food_restrictions()` (diet, allergies,
  /// disliked de cada persona del hogar).
  factory FoodRestrictions.fromRows(Iterable<Map<String, dynamic>> rows) {
    final allergies = <String>{};
    final disliked = <String>{};
    int? rank;
    for (final r in rows) {
      for (final a in _strings(r['allergies'])) {
        allergies.add(normalizeCategoryText(a));
      }
      for (final d in _strings(r['disliked'])) {
        disliked.add(normalizeCategoryText(d));
      }
      final diet = (r['diet'] as String?)?.trim();
      if (diet == null || diet.isEmpty) continue; // no lo ha dicho
      if (diet == 'sin_gluten') allergies.add('gluten');
      final mine = _dietRank[diet] ?? 0;
      rank = rank == null || mine < rank ? mine : rank;
    }
    String? diet;
    if (rank != null && rank > 0) {
      diet = _dietRank.entries.firstWhere((e) => e.value == rank).key;
    }
    allergies.removeWhere((a) => a.isEmpty);
    disliked.removeWhere((d) => d.isEmpty);
    return FoodRestrictions(
      allergies: allergies,
      diet: diet,
      disliked: disliked,
    );
  }

  static List<String> _strings(Object? v) => v is List
      ? [for (final x in v) x.toString().trim()]
      : v is String && v.trim().isNotEmpty
      ? v.split(',').map((s) => s.trim()).toList()
      : const [];

  /// Por qué no se puede comer algo con estos nombres (título e
  /// ingredientes): la alergia ('gluten') o la dieta ('vegetariana'), o null
  /// si se puede.
  String? blockerIn(Iterable<String> names) {
    final texts = [for (final n in names) normalizeCategoryText(n)];
    for (final a in allergies) {
      if (_matchesGroup(texts, a)) return a;
    }
    final d = diet;
    if (d != null) {
      final groups = switch (d) {
        'pescetariana' => const ['_carne'],
        'vegetariana' => const ['_carne', 'pescado', 'marisco'],
        _ => const [
          '_carne',
          'pescado',
          'marisco',
          'lactosa',
          'huevo',
          '_miel',
        ],
      };
      for (final g in groups) {
        if (_matchesGroup(texts, g)) return d;
      }
    }
    return null;
  }

  /// True si lleva algo que a alguien no le gusta.
  bool dislikedIn(Iterable<String> names) {
    if (disliked.isEmpty) return false;
    final texts = [for (final n in names) normalizeCategoryText(n)];
    return disliked.any((d) => texts.any((t) => _hasWord(t, d)));
  }

  /// Nombres por los que se mira una receta: título e ingredientes.
  static List<String> namesOf(Recipe r) => [r.title, ...r.ingredientNames];

  /// Recetas que el plan puede usar: nunca las que chocan con una alergia o la
  /// dieta; las que no gustan solo vuelven si sin ellas quedan menos de
  /// [minLiked].
  List<Recipe> safeRecipes(List<Recipe> recipes, {int minLiked = 6}) =>
      pick(recipes, namesOf, minLiked: minLiked);

  /// Igual que [safeRecipes] para cualquier tipo; [names] da los nombres de
  /// cada elemento.
  List<T> pick<T>(
    List<T> items,
    Iterable<String> Function(T) names, {
    int minLiked = 6,
  }) {
    if (isEmpty) return items;
    final safe = [
      for (final i in items)
        if (blockerIn(names(i)) == null) i,
    ];
    final liked = [
      for (final i in safe)
        if (!dislikedIn(names(i))) i,
    ];
    return liked.length >= minLiked || liked.length == safe.length
        ? liked
        : safe;
  }

  // ---- Palabras por grupo ----------------------------------------------------

  /// Palabras (sin acentos) de cada alergia o grupo de la dieta. Se aceptan
  /// plurales en -s y -es.
  static const Map<String, List<String>> _words = {
    'gluten': [
      'trigo',
      'harina',
      'pan',
      'pasta',
      'espagueti',
      'spaghetti',
      'macarron',
      'fideo',
      'tallarin',
      'lasana',
      'canelon',
      'cuscus',
      'couscous',
      'cebada',
      'centeno',
      'espelta',
      'cerveza',
      'galleta',
      'bizcocho',
      'hojaldre',
      'masa',
      'empanada',
      'empanadilla',
      'rebozado',
      'rebozada',
      'picatoste',
      'seitan',
      'wrap',
      'pizza',
      'croissant',
      'magdalena',
      'bechamel',
      'noqui',
      'gnocchi',
      'bulgur',
      'salsa de soja',
      'tortita',
      'crepe',
      'brioche',
      'baguette',
      'tostada',
      'biscote',
      'semola',
    ],
    'lactosa': [
      'leche',
      'queso',
      'nata',
      'mantequilla',
      'yogur',
      'yogurt',
      'requeson',
      'mozzarella',
      'parmesano',
      'mascarpone',
      'bechamel',
      'kefir',
      'cuajada',
      'helado',
      'burrata',
      'ricotta',
      'emmental',
      'gouda',
      'cheddar',
      'manchego',
      'feta',
      'brie',
    ],
    'huevo': [
      'huevo',
      'clara',
      'yema',
      'mayonesa',
      'alioli',
      'merengue',
      'tortilla de patata',
      'tortilla francesa',
    ],
    'frutos secos': [
      'frutos secos',
      'almendra',
      'nuez',
      'nueces',
      'avellana',
      'anacardo',
      'pistacho',
      'pinon',
      'cacahuete',
      'macadamia',
      'pecana',
      'praline',
      'turron',
      'mazapan',
    ],
    'marisco': [
      'marisco',
      'gamba',
      'langostino',
      'mejillon',
      'almeja',
      'calamar',
      'sepia',
      'pulpo',
      'chipiron',
      'berberecho',
      'cigala',
      'cangrejo',
      'bogavante',
      'langosta',
      'navaja',
      'vieira',
      'surimi',
      'carabinero',
      'necora',
      'chirla',
      'centollo',
      'percebe',
      'ostra',
    ],
    'soja': ['soja', 'tofu', 'edamame', 'tempeh', 'miso'],
    'pescado': [
      'pescado',
      'merluza',
      'salmon',
      'atun',
      'bacalao',
      'sardina',
      'boqueron',
      'dorada',
      'lubina',
      'rape',
      'anchoa',
      'caballa',
      'bonito',
      'trucha',
      'lenguado',
      'emperador',
      'pez espada',
      'surimi',
      'panga',
      'palometa',
      'rodaballo',
      'abadejo',
      'pescadilla',
      'jurel',
      'besugo',
      'mero',
      'corvina',
      'arenque',
    ],
    '_carne': [
      'carne',
      'pollo',
      'ternera',
      'cerdo',
      'jamon',
      'chorizo',
      'bacon',
      'beicon',
      'panceta',
      'salchicha',
      'pavo',
      'cordero',
      'conejo',
      'lomo',
      'morcilla',
      'solomillo',
      'costilla',
      'hamburguesa',
      'albondiga',
      'pechuga',
      'muslo',
      'contramuslo',
      'fuet',
      'salchichon',
      'longaniza',
      'sobrasada',
      'pato',
      'cecina',
      'butifarra',
      'carrillada',
      'magro',
      'chistorra',
      'mortadela',
      'salami',
      'pepperoni',
      'entrecot',
      'chuleta',
      'cochinillo',
      'codorniz',
      'higado',
      'callos',
      'lacon',
    ],
    '_miel': ['miel'],
  };

  /// Lo que NO cuenta aunque contenga una palabra del grupo.
  static const Map<String, List<String>> _except = {
    'gluten': [
      'harina de arroz',
      'harina de maiz',
      'harina de garbanzo',
      'pan de maiz',
      'pasta de arroz',
      'pasta de dientes',
      'pasta de tomate',
      'pasta de curry',
      'pasta de miso',
      'tortitas de arroz',
      'tortita de arroz',
      'tortitas de maiz',
      'tortita de maiz',
      'fideos de arroz',
    ],
    'lactosa': [
      'leche de coco',
      'leche de avena',
      'leche de soja',
      'leche de almendras',
      'leche de almendra',
      'leche de arroz',
      'leche vegetal',
      'nata vegetal',
      'yogur de soja',
      'yogur vegetal',
      'queso vegano',
      'mantequilla de cacahuete',
    ],
    'huevo': ['mayonesa vegana', 'mayonesa sin huevo'],
    'frutos secos': ['nuez moscada'],
    '_carne': [
      'lomo de ',
      'lomos de ',
      'carne vegetal',
      'carne de soja',
      'hamburguesa vegetal',
      'hamburguesa vegana',
      'salchicha vegetal',
      'salchicha vegana',
    ],
  };

  /// "Pasta sin gluten", "leche sin lactosa": el producto entero está libre.
  static const Map<String, String> _freeOf = {
    'gluten': 'sin gluten',
    'lactosa': 'sin lactosa',
    'huevo': 'sin huevo',
    'soja': 'sin soja',
    'frutos secos': 'sin frutos secos',
  };

  static bool _matchesGroup(List<String> texts, String group) {
    final words = _words[group] ?? [group];
    final except = _except[group] ?? const <String>[];
    final free = _freeOf[group];
    for (var t in texts) {
      if (free != null && t.contains(free)) continue;
      for (final e in except) {
        t = t.replaceAll(e, ' ');
      }
      if (words.any((w) => _hasWord(t, w))) return true;
    }
    return false;
  }

  static final Map<String, RegExp> _re = {};

  static bool _hasWord(String text, String word) {
    final re = _re.putIfAbsent(
      word,
      () => RegExp('(^|[^a-z0-9])${RegExp.escape(word)}(s|es)?(?![a-z0-9])'),
    );
    return re.hasMatch(text);
  }
}
