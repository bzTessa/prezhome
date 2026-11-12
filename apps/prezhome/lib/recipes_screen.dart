import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_recipe_chooser.dart';
import 'discover_recipes_screen.dart';
import 'recipe_detail_screen.dart';
import 'models/nutrition_profile.dart';
import 'models/inventory_item.dart';
import 'models/recipe.dart';
import 'utils/pantry_ideas.dart';
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
import 'l10n/l10n.dart';

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

  // Categoría elegida (ver recipeBrowseCategories) y orden de los resultados.
  String? _category;
  RecipeSort _sort = RecipeSort.recent;

  // Despensa del último fetch: las tarjetas dicen si tienes todo.
  List<String> _pantry = const [];

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
    final recipesRes = await supabase
        .from('recipes')
        .select('*, recipe_ingredients(name)')
        .order('created_at', ascending: false);
    final recipes = (recipesRes as List)
        .map((item) => Recipe.fromMap(item))
        .toList();

    // Perfil propio para calcular "raciones que te tocan"
    NutritionProfile? profile;
    final user = supabase.auth.currentUser;
    if (user != null) {
      final p = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (p != null) profile = NutritionProfile.fromMap(p);
    }
    // Despensa del hogar: marca las recetas que se pueden hacer ya.
    var pantry = const <String>[];
    if (recipes.isNotEmpty) {
      try {
        final rows = await supabase
            .from('inventory_items')
            .select()
            .eq('home_id', recipes.first.homeId);
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                recipe.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.ink,
                ),
              ),
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
              foregroundColor: Colors.white,
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

  Widget _card(Recipe recipe, int? perMeal) => _RecipeCard(
    recipe: recipe,
    caloriesPerMeal: perMeal,
    missing: missingAtHome(recipe, _pantry),
    onToggleFavorite: () => _toggleFavorite(recipe),
    onLongPress: () => _openQuickActions(recipe),
    onTap: () async {
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
      );
      if (changed == true) _reload();
    },
  );

  SliverPadding _grid(
    List<Recipe> recipes,
    int? perMeal, {
    double bottom = 0,
  }) => SliverPadding(
    padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
    sliver: SliverGrid.builder(
      gridDelegate: recipeGridDelegate,
      itemCount: recipes.length,
      itemBuilder: (context, index) => _card(recipes[index], perMeal),
    ),
  );

  /// Recetario ordenado por secciones (favoritas, desayunos, comidas...),
  /// cada una con su título y como mucho 4 recetas hasta pulsar "Ver todas".
  List<Widget> _sections(List<Recipe> recipes, int? perMeal) {
    const preview = 4;
    final slivers = <Widget>[];
    final ready = readyToCook(recipes, _pantry);
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
        ..add(_grid(open ? items : items.take(preview).toList(), perMeal));
      if (!open) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextButton(
                // "Ver las N" abre la categoría entera en vez de alargar la
                // página; "Otras" no es categoría y se despliega aquí.
                onPressed: () => setState(
                  () => recipeBrowseCategories.contains(key)
                      ? _category = key
                      : _expanded.add(key),
                ),
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
    return Scaffold(
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-recipes',
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: Text(
          context.l.recNew,
          style: const TextStyle(fontWeight: FontWeight.bold),
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
                  builder: (_) => const DiscoverRecipesScreen(pantryMode: true),
                ),
              ),
            );
          }

          final browsing = _query.trim().isNotEmpty || _category != null;
          final found = browsing
              ? browseRecipes(
                  allRecipes,
                  query: _query,
                  category: _category,
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
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                  child: RecipeCategoryChips(
                    recipes: allRecipes,
                    selected: _category,
                    onSelected: (c) => setState(() => _category = c),
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
                      _category = null;
                    }),
                  ),
                ),
              if (!browsing) ...[
                SliverToBoxAdapter(
                  child: _PantryBanner(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const DiscoverRecipesScreen(pantryMode: true),
                      ),
                    ),
                  ),
                ),
                ..._sections(allRecipes, perMeal),
              ] else if (found.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _NoSearchResults(query: _query.trim()),
                )
              else
                _grid(found, perMeal, bottom: 120),
            ],
          );
        },
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

/// Acceso a "¿Qué cocino con lo que tengo?" sobre la rejilla.
class _PantryBanner extends StatelessWidget {
  const _PantryBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Material(
        color: AppColors.sageBg,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.card,
                  child: Icon(Icons.kitchen_rounded, color: AppColors.sage),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l.recWhatToCook,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        context.l.recPantryIdeas,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.sage),
              ],
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

/// Barra horizontal de chips de filtro sobre la rejilla.
/// Tarjeta de receta para la rejilla: foto arriba, título y chips clave abajo.
class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final int? caloriesPerMeal;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onLongPress;

  /// Ingredientes que faltan en casa (null = no se sabe).
  final int? missing;

  const _RecipeCard({
    required this.recipe,
    this.caloriesPerMeal,
    this.missing,
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

    return Semantics(
      button: true,
      label: recipe.title,
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Foto a sangre: la imagen manda, como en las apps de recetas.
              LayoutBuilder(
                builder: (context, c) =>
                    RecipeImage(recipe: recipe, height: c.maxHeight, radius: 0),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.4, 1],
                  ),
                ),
              ),
              if (missing != null && missing! <= 1)
                Positioned(
                  top: 8,
                  left: 8,
                  child: _HomeStockPill(missing: missing!),
                ),
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: AppColors.card.withValues(alpha: 0.92),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onToggleFavorite,
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: Icon(
                        recipe.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: recipe.isFavorite
                            ? AppColors.favorite
                            : AppColors.ink,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headline.copyWith(
                        fontSize: 17,
                        height: 1.15,
                        color: Colors.white,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        meta,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
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

/// Buscador de recetas: campo de texto cozy con icono de lupa y botón de
/// limpiar. Filtra en cliente por nombre y descripción.
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
            borderSide: BorderSide(color: AppColors.wood, width: 1.4),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.woodDark, width: 1.8),
          ),
        ),
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

/// Pastilla sobre la foto: "Tienes todo" o "Falta 1" según la despensa.
class _HomeStockPill extends StatelessWidget {
  const _HomeStockPill({required this.missing});

  final int missing;

  @override
  Widget build(BuildContext context) {
    final all = missing == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: all ? AppColors.sageBg : AppColors.card,
        borderRadius: AppRadius.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            all ? Icons.check_rounded : Icons.shopping_basket_outlined,
            size: 14,
            color: all ? AppColors.sage : AppColors.terracottaText,
          ),
          const SizedBox(width: 4),
          Text(
            all ? context.l.recHaveAll : context.l.recMissingOne,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: all ? AppColors.sage : AppColors.terracottaText,
            ),
          ),
        ],
      ),
    );
  }
}
