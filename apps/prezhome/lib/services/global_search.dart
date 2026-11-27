import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/recipe.dart';
import '../utils/recipe_browse.dart' show recipeMatchesQuery;
import '../utils/shopping_categories.dart' show normalizeCategoryText;
import 'offline_provider.dart';
import 'rows_cache.dart';

enum SearchKind { shopping, pantry, recipe, task }

class SearchHit {
  const SearchHit({
    required this.kind,
    required this.title,
    this.detail,
    this.recipe,
    this.done = false,
  });

  final SearchKind kind;
  final String title;

  /// Dato corto de apoyo: cantidad, zona de En casa, minutos…
  final String? detail;
  final Recipe? recipe;

  /// Producto ya tachado en la lista.
  final bool done;
}

/// Todo lo que el buscador mira, ya cargado.
class SearchData {
  const SearchData({
    this.shopping = const [],
    this.pantry = const [],
    this.recipes = const [],
    this.tasks = const [],
  });

  final List<Map<String, dynamic>> shopping;
  final List<Map<String, dynamic>> pantry;
  final List<Recipe> recipes;
  final List<Map<String, dynamic>> tasks;
}

/// Cada palabra tiene que salir en el texto, sin acentos ni mayúsculas.
bool _matches(String text, List<String> words) {
  final t = normalizeCategoryText(text);
  return words.every(t.contains);
}

List<String> searchWords(String query) => normalizeCategoryText(
  query,
).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

String? _qty(Map<String, dynamic> r) {
  final q = (r['quantity'] as num?)?.toDouble();
  if (q == null || q <= 0) return null;
  final n = q == q.roundToDouble() ? q.toInt().toString() : '$q';
  final unit = (r['unit'] as String?)?.trim();
  return unit == null || unit.isEmpty || unit == 'unidades' ? n : '$n $unit';
}

/// Busca en la lista, En casa, recetas y tareas. Lo que empieza por lo
/// buscado va antes; como mucho [limit] por sección.
Map<SearchKind, List<SearchHit>> searchEverything(
  SearchData data,
  String query, {
  int limit = 6,
}) {
  final words = searchWords(query);
  if (words.isEmpty) return const {};
  int rank(String title) =>
      normalizeCategoryText(title).startsWith(words.first) ? 0 : 1;
  List<SearchHit> sorted(Iterable<SearchHit> hits) {
    final list = hits.toList()
      ..sort((a, b) {
        final r = rank(a.title).compareTo(rank(b.title));
        if (r != 0) return r;
        if (a.done != b.done) return a.done ? 1 : -1;
        return a.title.length.compareTo(b.title.length);
      });
    return list.take(limit).toList();
  }

  final out = <SearchKind, List<SearchHit>>{
    SearchKind.shopping: sorted([
      for (final r in data.shopping)
        if (_matches('${r['name'] ?? ''}', words))
          SearchHit(
            kind: SearchKind.shopping,
            title: '${r['name']}',
            detail: _qty(r),
            done: r['checked'] == true,
          ),
    ]),
    SearchKind.pantry: sorted([
      for (final r in data.pantry)
        if (_matches('${r['name'] ?? ''}', words))
          SearchHit(
            kind: SearchKind.pantry,
            title: '${r['name']}',
            detail: [
              ?_qty(r),
              if ('${r['category'] ?? ''}'.isNotEmpty) '${r['category']}',
            ].join(' · '),
          ),
    ]),
    SearchKind.recipe: sorted([
      for (final r in data.recipes)
        if (recipeMatchesQuery(r, query))
          SearchHit(
            kind: SearchKind.recipe,
            title: r.title,
            recipe: r,
            detail: switch ((r.prepTimeMinutes ?? 0) +
                (r.cookTimeMinutes ?? 0)) {
              0 => null,
              final m => '$m min',
            },
          ),
    ]),
    SearchKind.task: sorted([
      for (final r in data.tasks)
        if (r['is_done'] != true && _matches('${r['title'] ?? ''}', words))
          SearchHit(kind: SearchKind.task, title: '${r['title']}'),
    ]),
  };
  out.removeWhere((_, v) => v.isEmpty);
  return out;
}

/// Carga lo que el buscador necesita. Lo de la compra y En casa sale de la
/// copia del móvil; recetas y tareas del servidor, o de su copia sin red.
Future<SearchData> loadSearchData(SupabaseClient client) async {
  Future<List<Map<String, dynamic>>> safe(
    Future<List<Map<String, dynamic>>> Function() f,
  ) async {
    try {
      return await f();
    } catch (_) {
      return const [];
    }
  }

  final home = OfflineProvider.instance.homeId;
  final results = await Future.wait([
    safe(() => OfflineProvider.instance.shopping.readCached()),
    safe(() => OfflineProvider.instance.inventory.readCached()),
    safe(
      () => RowsCache.fetch(
        'recipes:$home',
        () => client
            .from('recipes')
            .select('*, recipe_ingredients(name)')
            .order('created_at', ascending: false),
      ),
    ),
    safe(
      () => RowsCache.fetch(
        'tasks:$home',
        () => client.from('tasks').select().eq('is_done', false),
      ),
    ),
  ]);
  return SearchData(
    shopping: results[0],
    pantry: results[1],
    recipes: [for (final r in results[2]) Recipe.fromMap(r)],
    tasks: results[3],
  );
}
