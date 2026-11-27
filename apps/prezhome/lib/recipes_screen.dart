import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_recipe_chooser.dart';
import 'discover_recipes_screen.dart';
import 'recipe_detail_screen.dart';
import 'models/nutrition_profile.dart';
import 'models/inventory_item.dart';
import 'models/recipe.dart';
import 'utils/pantry_ideas.dart';
import 'services/offline_provider.dart';
import 'services/rows_cache.dart';
import 'theme/app_theme.dart';
import 'widgets/empty_state.dart';
import 'widgets/miau_character.dart';
import 'utils/recipe_browse.dart';
import 'widgets/recipe_category_chips.dart';
import 'widgets/recipe_chip.dart';
import 'widgets/recipe_image.dart';
import 'widgets/skeleton.dart';
import 'widgets/animations/app_transitions.dart';
import 'utils/friendly_error.dart';
import 'utils/shopping_display.dart';
import 'l10n/l10n.dart';
import 'widgets/hide_fab_on_scroll.dart';

class RecipesScreen extends StatefulWidget {
  /// Cuando va dentro de una pestaña con su propio AppBar, lo ocultamos.
  final bool embedded;
  const RecipesScreen({super.key, this.embedded = false});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

/// Orden de las secciones del recetario. Cada receta sale UNA sola vez: en
/// "favorites" si es favorita y, si no, en el primer tipo de esta lista que
/// tenga (una receta de comida y cena va a "Comida"). Sin tipo -> "other".
const recipeSectionOrder = [
  'favorites',
  'breakfast',
  'lunch',
  'dinner',
  'dessert',
  'snack',
  'drink',
  'other',
];

/// Agrupa las recetas en secciones (ver [recipeSectionOrder]) respetando el
/// orden de entrada dentro de cada una. Solo devuelve secciones con recetas.
List<MapEntry<String, List<Recipe>>> groupRecipesBySection(
  List<Recipe> recipes,
) {
  final groups = {for (final k in recipeSectionOrder) k: <Recipe>[]};
  for (final r in recipes) {
    final key = r.isFavorite
        ? 'favorites'
        : recipeSectionOrder.firstWhere(
            r.mealTypes.contains,
            orElse: () => 'other',
          );
    groups[key]!.add(r);
  }
  return [
    for (final e in groups.entries)
      if (e.value.isNotEmpty) e,
  ];
}

class _RecipesScreenState extends State<RecipesScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  late Future<_RecipesData> _future;

  // Secciones desplegadas con "Ver todas"; el resto enseña solo 4 recetas.
  final Set<String> _expanded = {};

  // Texto del buscador (en cliente, sobre nombre, descripción e ingredientes).
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  // Filtros combinables (ver recipeBrowseCategories), "con lo que tengo" y orden.
  final Set<String> _filters = {};
  bool _onlyReady = false;
  RecipeSort _sort = RecipeSort.recent;

  // Despensa del último fetch: las tarjetas dicen si tienes todo.
  List<String> _pantry = const [];

  void _toggleFilter(String category) {
    setState(() {
      if (!_filters.add(category)) _filters.remove(category);
    });
  }

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<_RecipesData> _fetch() async {
    // Sin conexión, la última copia guardada (la misma que usa el buscador).
    final recipesRes = await RowsCache.fetch(
      'recipes:${OfflineProvider.instance.homeId}',
      () => supabase
          .from('recipes')
          .select('*, recipe_ingredients(name)')
          .order('created_at', ascending: false),
    );
    final recipes = (recipesRes as List)
        .map((item) => Recipe.fromMap(item))
        .toList();

    // Perfil propio para calcular "raciones que te tocan"
    NutritionProfile? profile;
    final user = supabase.auth.currentUser;
    if (user != null) {
      final p = await RowsCache.fetchOne(
        'recipes_profile:${user.id}',
        () =>
            supabase.from('profiles').select().eq('id', user.id).maybeSingle(),
      ).catchError((_) => null);
      if (p != null) profile = NutritionProfile.fromMap(p);
    }
    // Despensa del hogar: marca las recetas que se pueden hacer ya.
    var pantry = const <String>[];
    if (recipes.isNotEmpty) {
      try {
        final rows = await supabase
            .from('inventory_items')
            .select()
            .eq('home_id', recipes.first.homeId)
            .catchError((_) => OfflineProvider.instance.inventory.readCached());
        pantry = pantryNamesForIdeas(
          (rows as List)
              .map((r) => InventoryItem.fromMap(Map<String, dynamic>.from(r)))
              .toList(),
          max: 1000,
        );
      } catch (_) {
        // Sin despensa, el recetario se enseña igual.
      }
    }
    return _RecipesData(recipes: recipes, profile: profile, pantry: pantry);
  }

  void _reload() {
    final future = _fetch();
    setState(() {
      _future = future;
    });
  }

  Future<void> _openAdd() async {
    final added = await AddRecipeChooser.show(context);
    if (added == true) _reload();
  }

  /// Alterna favorita de una receta directamente desde la rejilla, con un solo
  /// toque en la estrella. Actualiza is_favorite y recarga la lista.
  Future<void> _toggleFavorite(Recipe recipe) async {
    final newValue = !recipe.isFavorite;
    try {
      await supabase
          .from('recipes')
          .update({'is_favorite': newValue})
          .eq('id', recipe.id);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, context.l.couldNotUpdate)),
          backgroundColor: AppColors.expired,
        ),
      );
    }
  }

  /// Menú rápido (pulsación larga) sobre una tarjeta: favorita o eliminar.
  Future<void> _openQuickActions(Recipe recipe) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(recipe.title, style: AppTextStyles.sheetTitle),
            ),
            ListTile(
              leading: Icon(
                recipe.isFavorite
                    ? Icons.star_border_rounded
                    : Icons.star_rounded,
                color: AppColors.favorite,
              ),
              title: Text(
                recipe.isFavorite
                    ? context.l.recUnfavorite
                    : context.l.recFavorite,
              ),
              onTap: () => Navigator.of(ctx).pop('favorite'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.expired),
              title: Text(context.l.recDelete),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == 'favorite') {
      await _toggleFavorite(recipe);
    } else if (action == 'delete') {
      await _confirmDelete(recipe);
    }
  }

  /// Confirma y borra una receta desde la rejilla. Limpia también sus comidas
  /// del plan (la FK es SET NULL y quedarían como "Receta" fantasma).
  Future<void> _confirmDelete(Recipe recipe) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: Text(context.l.recDeleteAsk),
        content: Text(context.l.recRemoveAsk(recipe.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expired,
              foregroundColor: AppColors.onTerracotta,
              elevation: 0,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.l.delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await supabase
          .from('meal_plan_entries')
          .delete()
          .eq('recipe_id', recipe.id);
      await supabase.from('recipes').delete().eq('id', recipe.id);
      _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l.recDeleted(recipe.title))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, context.l.couldNotDelete)),
          backgroundColor: AppColors.expired,
        ),
      );
    }
  }

  Widget _card(Recipe recipe, int? perMeal, {required String heroTag}) =>
      _RecipeCard(
        recipe: recipe,
        caloriesPerMeal: perMeal,
        missing: missingAtHome(recipe, _pantry),
        heroTag: heroTag,
        onToggleFavorite: () => _toggleFavorite(recipe),
        onLongPress: () => _openQuickActions(recipe),
        onTap: () async {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) =>
                  RecipeDetailScreen(recipe: recipe, heroTag: heroTag),
            ),
          );
          if (changed == true) _reload();
        },
      );

  /// Recetas en cuadrícula visual de 2 columnas con foto protagonista.
  SliverPadding _grid(
    List<Recipe> recipes,
    int? perMeal, {
    required String scopeKey,
    double bottom = 0,
  }) => SliverPadding(
    padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
    sliver: SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.74,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, i) => _card(
          recipes[i],
          perMeal,
          heroTag: 'recipe-photo-$scopeKey-${recipes[i].id}',
        ),
        childCount: recipes.length,
      ),
    ),
  );

  /// Recetario ordenado por secciones (listas, favoritas, desayunos, comidas...),
  /// cada una con su título y como mucho 4 recetas hasta pulsar "Ver todas".
  List<Widget> _sections(
    List<Recipe> recipes,
    List<Recipe> ready,
    int? perMeal,
  ) {
    const preview = 4;
    final slivers = <Widget>[];
    final sections = [
      if (ready.isNotEmpty) MapEntry('ready', ready),
      ...groupRecipesBySection(recipes),
    ];
    for (final section in sections) {
      final key = section.key;
      final items = section.value;
      final open = _expanded.contains(key) || items.length <= preview;
      slivers
        ..add(
          SliverToBoxAdapter(
            child: _SectionHeader(
              icon: _sectionIcon(key),
              title: _sectionTitle(context, key),
              count: items.length,
            ),
          ),
        )
        ..add(
          _grid(
            open ? items : items.take(preview).toList(),
            perMeal,
            scopeKey: key,
          ),
        );
      if (!open) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextButton(
                // "Ver las N" abre el filtro de la categoría entera en vez de
                // alargar la página; "Otras" no es categoría y se despliega aquí.
                onPressed: () => setState(() {
                  if (key == 'ready') {
                    _onlyReady = true;
                  } else if (recipeBrowseCategories.contains(key)) {
                    _filters.add(key);
                  } else {
                    _expanded.add(key);
                  }
                }),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.woodDark,
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
                child: Text(context.l.recSeeAll(items.length)),
              ),
            ),
          ),
        );
      }
    }
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 120)));
    return slivers;
  }

  static String _sectionTitle(BuildContext context, String key) =>
      switch (key) {
        'favorites' => context.l.recFavorites,
        'ready' => context.l.recReadyNow,
        'other' => context.l.recOther,
        _ => context.l.mealType(key),
      };

  static IconData _sectionIcon(String key) => switch (key) {
    'favorites' => Icons.favorite_rounded,
    'ready' => Icons.kitchen_rounded,
    'other' => Icons.restaurant_rounded,
    _ => mealTypeIcon(key),
  };

  @override
  Widget build(BuildContext context) {
    return HideFabOnScroll(
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: widget.embedded
            ? null
            : AppBar(
                title: Text(
                  context.l.recTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: AppColors.cream,
                elevation: 0,
              ),
        floatingActionButton: widget.embedded
            ? null
            : HideFabOnScroll.fab(
                FloatingActionButton.extended(
                  heroTag: 'fab-recipes',
                  onPressed: _openAdd,
                  icon: const Icon(Icons.add),
                  label: Text(
                    context.l.recNew,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
        body: FadeFutureBuilder<_RecipesData>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData &&
                snapshot.connectionState == ConnectionState.waiting) {
              return const RecipesSkeleton();
            }
            if (snapshot.hasError) {
              return _ErrorState(
                message: friendlyError(snapshot.error, context.l.recLoadError),
                onRetry: _reload,
              );
            }
            final data = snapshot.data!;
            _pantry = data.pantry;
            final allRecipes = data.recipes;
            final perMeal = data.profile?.caloriesPerMeal;

            if (allRecipes.isEmpty) {
              return EmptyState(
                image: 'assets/images/vacio_recetas.png',
                title: context.l.recEmptyTitle,
                message: context.l.recEmptyHint,
                actionLabel: context.l.recNew,
                onAction: _openAdd,
                secondaryLabel: context.l.recIdeas,
                onSecondary: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const DiscoverRecipesScreen(pantryMode: true),
                  ),
                ),
              );
            }

            final ready = readyToCook(allRecipes, _pantry);
            final browsing =
                _query.trim().isNotEmpty || _filters.isNotEmpty || _onlyReady;
            final found = browsing
                ? browseRecipes(
                    allRecipes,
                    query: _query,
                    categories: _filters,
                    onlyReady: _onlyReady,
                    pantry: _pantry,
                    sort: _sort,
                  )
                : const <Recipe>[];

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _SearchBar(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    onClear: () => setState(() {
                      _searchCtrl.clear();
                      _query = '';
                    }),
                    onAdd: widget.embedded ? _openAdd : null,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                    child: RecipeCategoryChips(
                      recipes: allRecipes,
                      selectedSet: _filters,
                      onToggle: _toggleFilter,
                    ),
                  ),
                ),
                if (ready.isNotEmpty || _onlyReady)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ReadyFilterPill(
                            count: ready.length,
                            selected: _onlyReady,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _onlyReady = !_onlyReady);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                if (browsing)
                  SliverToBoxAdapter(
                    child: _ResultsBar(
                      count: found.length,
                      sort: _sort,
                      onSort: (s) => setState(() => _sort = s),
                      onClear: () => setState(() {
                        _searchCtrl.clear();
                        _query = '';
                        _filters.clear();
                        _onlyReady = false;
                      }),
                    ),
                  ),
                if (!browsing) ...[
                  SliverToBoxAdapter(
                    child: _PantryBanner(
                      readyCount: ready.length,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const DiscoverRecipesScreen(pantryMode: true),
                        ),
                      ),
                    ),
                  ),
                  ..._sections(allRecipes, ready, perMeal),
                ] else if (found.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _NoSearchResults(query: _query.trim()),
                  )
                else
                  _grid(found, perMeal, scopeKey: 'search', bottom: 120),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Encima de los resultados: cuántas recetas hay, cómo ordenarlas y un botón
/// para volver al recetario completo.
class _ResultsBar extends StatelessWidget {
  const _ResultsBar({
    required this.count,
    required this.sort,
    required this.onSort,
    required this.onClear,
  });

  final int count;
  final RecipeSort sort;
  final ValueChanged<RecipeSort> onSort;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    String label(RecipeSort s) => switch (s) {
      RecipeSort.recent => context.l.recSortRecent,
      RecipeSort.az => context.l.recSortAz,
      RecipeSort.fastest => context.l.recSortFastest,
      RecipeSort.lightest => context.l.recSortLightest,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l.recCount(count),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          PopupMenuButton<RecipeSort>(
            tooltip: context.l.recSort,
            initialValue: sort,
            onSelected: onSort,
            color: AppColors.cream,
            itemBuilder: (_) => [
              for (final s in RecipeSort.values)
                PopupMenuItem(value: s, child: Text(label(s))),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_vert_rounded, color: AppColors.woodDark),
                  const SizedBox(width: 4),
                  Text(
                    label(sort),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.woodDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onClear,
            tooltip: context.l.recClearFilters,
            icon: Icon(Icons.close_rounded, color: AppColors.woodDark),
          ),
        ],
      ),
    );
  }
}

/// Título de una sección del recetario: icono, nombre y cuántas recetas hay.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  final IconData icon;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.woodDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.headline.copyWith(fontSize: 20),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastilla rápida combinable para filtrar por recetas listas con lo de casa.
class _ReadyFilterPill extends StatelessWidget {
  const _ReadyFilterPill({
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = '${context.l.recFilterReady} ($count)';
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? AppColors.sage : AppColors.sageBg,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected
                ? AppColors.sage
                : AppColors.sage.withValues(alpha: 0.3),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? Icons.check_rounded : Icons.kitchen_rounded,
                  size: 16,
                  color: selected ? AppColors.onTerracotta : AppColors.sage,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: selected ? AppColors.onTerracotta : AppColors.sage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Acceso a "¿Qué cocino con lo que tengo?" sobre la rejilla.
class _PantryBanner extends StatelessWidget {
  const _PantryBanner({required this.onTap, this.readyCount = 0});

  final VoidCallback onTap;
  final int readyCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.sageBg, AppColors.card],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.sage.withValues(alpha: 0.25)),
          boxShadow: AppElevation.level1,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.sage,
                    child: Icon(
                      Icons.kitchen_rounded,
                      color: AppColors.onTerracotta,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l.recWhatToCook,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          readyCount > 0
                              ? context.l.recPantryReadySubtitle(readyCount)
                              : context.l.recPantryIdeas,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.sageBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.sage,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecipesData {
  final List<String> pantry;
  final List<Recipe> recipes;
  final NutritionProfile? profile;
  _RecipesData({required this.recipes, this.profile, this.pantry = const []});
}

/// Tarjeta editorial de receta en cuadrícula de 2 columnas: foto protagonista
/// arriba con insignia de despensa y botón flotante de favorita, y título +
/// metadatos limpios debajo.
class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final int? caloriesPerMeal;
  final String? heroTag;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onLongPress;

  /// Ingredientes que faltan en casa (null = no se sabe).
  final int? missing;

  const _RecipeCard({
    required this.recipe,
    this.caloriesPerMeal,
    this.missing,
    this.heroTag,
    this.onTap,
    this.onToggleFavorite,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (recipe.totalTimeMinutes != null) '${recipe.totalTimeMinutes} min',
      if (recipe.calories != null) '${recipe.calories} kcal',
    ].join(' · ');

    final photo = RecipeImage(
      recipe: recipe,
      height: double.infinity,
      radius: 0,
      cacheWidth: RecipeImage.gridCacheWidth,
    );

    return Semantics(
      button: true,
      label: recipe.title,
      child: Container(
        decoration: AppTheme.surfaceDecoration(radius: AppRadius.lg),
        child: Material(
          color: AppColors.card,
          borderRadius: AppRadius.lgRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (heroTag != null)
                        Hero(
                          tag: heroTag!,
                          flightShuttleBuilder: recipeHeroFlightShuttle(
                            recipe,
                            startRadius: AppRadius.lg,
                            endRadius: 0,
                            cacheWidth: RecipeImage.gridCacheWidth,
                          ),
                          child: photo,
                        )
                      else
                        photo,
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 54,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.22),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if ((missing != null && missing! <= 1) ||
                          recipe.freezesWell)
                        Positioned(
                          top: 8,
                          left: 8,
                          right: 48,
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              if (missing != null && missing! <= 1)
                                _HomeStockPill(missing: missing!),
                              if (recipe.freezesWell)
                                Tooltip(
                                  message: context.l.rdFreezable,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppColors.card.withValues(
                                        alpha: 0.92,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.ac_unit_rounded,
                                      size: 13,
                                      color: AppColors.frost,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Tooltip(
                          message: recipe.isFavorite
                              ? context.l.recUnfavorite
                              : context.l.recFavorite,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: AppElevation.level1,
                            ),
                            child: Material(
                              color: AppColors.card.withValues(alpha: 0.92),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: onToggleFavorite,
                                child: SizedBox(
                                  width: 34,
                                  height: 34,
                                  child: Icon(
                                    recipe.isFavorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: recipe.isFavorite
                                        ? AppColors.terracotta
                                        : AppColors.ink,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // Sin marcas en el título (Hacendado…).
                        shoppingCleanName(recipe.title),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontSize: 14.5,
                          height: 1.2,
                        ),
                      ),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: AppColors.inkMuted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                meta,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.numeric(
                                  AppTextStyles.labelMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Estado de error con botón de reintento, en la paleta cozy.
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MiauCharacter(mood: MiauMood.worried, size: 110),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.ink.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l.retry),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.woodDark,
                side: BorderSide(color: AppColors.wood, width: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Buscador de recetas: campo de texto cozy con icono de lupa, botón de
/// limpiar y acceso compacto a nueva receta cuando la vista va embebida.
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback? onAdd;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final field = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppElevation.level1,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(color: AppColors.ink, fontSize: 15),
        decoration: InputDecoration(
          hintText: context.l.recSearchHint,
          hintStyle: TextStyle(color: AppColors.ink.withValues(alpha: 0.45)),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.woodDark),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close_rounded, color: AppColors.woodDark),
                  onPressed: onClear,
                  tooltip: context.l.clear,
                ),
          filled: true,
          fillColor: AppColors.card,
          contentPadding: const EdgeInsets.symmetric(vertical: 2),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.cardEdge, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.terracotta, width: 1.6),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(child: field),
          if (onAdd != null) ...[
            const SizedBox(width: 10),
            Tooltip(
              message: context.l.recNew,
              child: Material(
                color: AppColors.terracottaBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AppColors.terracotta.withValues(alpha: 0.22),
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onAdd!();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.add_rounded,
                      color: AppColors.terracottaText,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Estado cuando el buscador no encuentra ninguna receta con ese texto.
class _NoSearchResults extends StatelessWidget {
  final String query;
  const _NoSearchResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MiauCharacter(mood: MiauMood.curious, size: 96),
            const SizedBox(height: 16),
            Text(
              query.isEmpty
                  ? context.l.recNoFilter
                  : context.l.recNoMatch(query),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.ink.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pastilla "Tienes todo" o "Falta 1" según la despensa.
class _HomeStockPill extends StatelessWidget {
  const _HomeStockPill({required this.missing});

  final int missing;

  @override
  Widget build(BuildContext context) {
    final all = missing == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: all ? AppColors.sage : AppColors.card.withValues(alpha: 0.92),
        borderRadius: AppRadius.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            all ? Icons.check_rounded : Icons.shopping_basket_outlined,
            size: 12,
            color: all ? AppColors.onTerracotta : AppColors.terracottaText,
          ),
          const SizedBox(width: 4),
          Text(
            all ? context.l.recHaveAll : context.l.recMissingOne,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: all ? AppColors.onTerracotta : AppColors.terracottaText,
            ),
          ),
        ],
      ),
    );
  }
}
