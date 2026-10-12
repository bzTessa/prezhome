import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_recipe_chooser.dart';
import 'discover_recipes_screen.dart';
import 'recipe_detail_screen.dart';
import 'models/nutrition_profile.dart';
import 'models/recipe.dart';
import 'theme/app_theme.dart';
import 'widgets/miau_character.dart';
import 'widgets/recipe_chip.dart';
import 'widgets/recipe_image.dart';
import 'utils/friendly_error.dart';

class RecipesScreen extends StatefulWidget {
  /// Cuando va dentro de una pestaña con su propio AppBar, lo ocultamos.
  final bool embedded;
  const RecipesScreen({super.key, this.embedded = false});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

/// Filtros disponibles en la barra superior. 'all' muestra todo; los tipos
/// usan las claves de [Recipe.mealTypeLabels]; 'favorites' y 'quick' son
/// filtros transversales en cliente.
enum _RecipeFilter {
  all,
  breakfast,
  lunch,
  dinner,
  snack,
  dessert,
  favorites,
  quick,
}

class _RecipesScreenState extends State<RecipesScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  late Future<_RecipesData> _future;

  _RecipeFilter _filter = _RecipeFilter.all;

  // Texto del buscador (en cliente, sobre nombre e ingredientes).
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

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
        .select()
        .order('is_favorite', ascending: false)
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
    return _RecipesData(recipes: recipes, profile: profile);
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
          content: Text(friendlyError(e, 'No se pudo actualizar')),
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
                style: const TextStyle(
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
                    ? 'Quitar de favoritas'
                    : 'Marcar como favorita',
              ),
              onTap: () => Navigator.of(ctx).pop('favorite'),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.expired,
              ),
              title: const Text('Eliminar receta'),
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
        title: const Text('¿Eliminar receta?'),
        content: Text('Se borrará "${recipe.title}" y sus ingredientes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expired,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"${recipe.title}" eliminada.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, 'No se pudo eliminar')),
          backgroundColor: AppColors.expired,
        ),
      );
    }
  }

  void _setFilter(_RecipeFilter f) {
    setState(() {
      _filter = f;
    });
  }

  /// Aplica el filtro de categoría activo + el texto del buscador, manteniendo
  /// el orden original (favoritas primero, luego recientes).
  List<Recipe> _applyFilter(List<Recipe> recipes) {
    final byCategory = _applyCategoryFilter(recipes);
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return byCategory;
    return byCategory.where((r) {
      final title = r.title.toLowerCase();
      final desc = (r.description ?? '').toLowerCase();
      return title.contains(q) || desc.contains(q);
    }).toList();
  }

  List<Recipe> _applyCategoryFilter(List<Recipe> recipes) {
    switch (_filter) {
      case _RecipeFilter.all:
        return recipes;
      case _RecipeFilter.favorites:
        return recipes.where((r) => r.isFavorite).toList();
      case _RecipeFilter.quick:
        return recipes
            .where((r) => (r.totalTimeMinutes ?? 1 << 30) <= 30)
            .toList();
      case _RecipeFilter.breakfast:
        return recipes.where((r) => r.mealTypes.contains('breakfast')).toList();
      case _RecipeFilter.lunch:
        return recipes.where((r) => r.mealTypes.contains('lunch')).toList();
      case _RecipeFilter.dinner:
        return recipes.where((r) => r.mealTypes.contains('dinner')).toList();
      case _RecipeFilter.snack:
        return recipes.where((r) => r.mealTypes.contains('snack')).toList();
      case _RecipeFilter.dessert:
        return recipes.where((r) => r.mealTypes.contains('dessert')).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text(
                'Recetas',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.cream,
              elevation: 0,
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-recipes',
        onPressed: _openAdd,
        backgroundColor: AppColors.wood,
        foregroundColor: AppColors.ink,
        icon: const Icon(Icons.add),
        label: const Text(
          'Nueva receta',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<_RecipesData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingGrid();
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: friendlyError(
                snapshot.error,
                'No he podido cargar las recetas',
              ),
              onRetry: _reload,
            );
          }
          final data = snapshot.data!;
          final allRecipes = data.recipes;
          final perMeal = data.profile?.caloriesPerMeal;

          if (allRecipes.isEmpty) {
            return const _EmptyState();
          }

          final visible = _applyFilter(allRecipes);
          final searching = _query.trim().isNotEmpty;

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
                child: _FilterBar(
                  active: _filter,
                  onSelected: _setFilter,
                  recipes: allRecipes,
                ),
              ),
              if (!searching && _filter == _RecipeFilter.all)
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    visible.isEmpty
                        ? 'Sin resultados'
                        : '${visible.length} '
                              '${visible.length == 1 ? 'receta' : 'recetas'}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              if (visible.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: searching
                      ? _NoSearchResults(query: _query.trim())
                      : const _NoMatchesState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 240,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.74,
                        ),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final recipe = visible[index];
                      return _RecipeCard(
                        recipe: recipe,
                        caloriesPerMeal: perMeal,
                        onToggleFavorite: () => _toggleFavorite(recipe),
                        onLongPress: () => _openQuickActions(recipe),
                        onTap: () async {
                          final changed = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RecipeDetailScreen(recipe: recipe),
                                ),
                              );
                          if (changed == true) _reload();
                        },
                      );
                    },
                  ),
                ),
            ],
          );
        },
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
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: const Padding(
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
                        '¿Qué cocino con lo que tengo?',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Ideas con lo que hay en tu despensa',
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
  final List<Recipe> recipes;
  final NutritionProfile? profile;
  _RecipesData({required this.recipes, this.profile});
}

/// Barra horizontal de chips de filtro sobre la rejilla.
class _FilterBar extends StatelessWidget {
  final _RecipeFilter active;
  final ValueChanged<_RecipeFilter> onSelected;
  final List<Recipe> recipes;

  const _FilterBar({
    required this.active,
    required this.onSelected,
    required this.recipes,
  });

  @override
  Widget build(BuildContext context) {
    final hasFavorites = recipes.any((r) => r.isFavorite);
    final hasQuick = recipes.any((r) => (r.totalTimeMinutes ?? 1 << 30) <= 30);

    // Solo mostramos chips de tipo que existan en la colección, para no dejar
    // filtros que nunca devuelven resultados.
    final presentTypes = <String>{for (final r in recipes) ...r.mealTypes};

    final chips = <Widget>[
      _FilterChip(
        label: 'Todas',
        icon: Icons.grid_view_rounded,
        selected: active == _RecipeFilter.all,
        onTap: () => onSelected(_RecipeFilter.all),
      ),
      if (hasFavorites)
        _FilterChip(
          label: 'Favoritas',
          icon: Icons.star_rounded,
          selected: active == _RecipeFilter.favorites,
          onTap: () => onSelected(_RecipeFilter.favorites),
        ),
      for (final entry in _typeOrder)
        if (presentTypes.contains(entry.key))
          _FilterChip(
            label: Recipe.mealTypeLabels[entry.key] ?? entry.key,
            icon: entry.value,
            selected: active == _filterForType(entry.key),
            onTap: () => onSelected(_filterForType(entry.key)),
          ),
      if (hasQuick)
        _FilterChip(
          label: '< 30 min',
          icon: Icons.bolt_rounded,
          selected: active == _RecipeFilter.quick,
          onTap: () => onSelected(_RecipeFilter.quick),
        ),
    ];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: chips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }

  static const List<MapEntry<String, IconData>> _typeOrder = [
    MapEntry('breakfast', Icons.free_breakfast),
    MapEntry('lunch', Icons.lunch_dining),
    MapEntry('dinner', Icons.dinner_dining),
    MapEntry('snack', Icons.fastfood),
    MapEntry('dessert', Icons.cake),
  ];

  static _RecipeFilter _filterForType(String type) {
    switch (type) {
      case 'breakfast':
        return _RecipeFilter.breakfast;
      case 'lunch':
        return _RecipeFilter.lunch;
      case 'dinner':
        return _RecipeFilter.dinner;
      case 'snack':
        return _RecipeFilter.snack;
      case 'dessert':
        return _RecipeFilter.dessert;
      default:
        return _RecipeFilter.all;
    }
  }
}

/// Chip de filtro seleccionable: resaltado con madera cuando está activo.
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.ink : AppColors.card,
              width: 1.4,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: AppColors.softShadow,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? AppColors.cream : AppColors.woodDark,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de receta para la rejilla: foto arriba, título y chips clave abajo.
class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final int? caloriesPerMeal;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onLongPress;

  const _RecipeCard({
    required this.recipe,
    this.caloriesPerMeal,
    this.onTap,
    this.onToggleFavorite,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final primaryType = recipe.mealTypes.isNotEmpty
        ? recipe.mealTypes.first
        : null;
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
              if (primaryType != null)
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          mealTypeIcon(primaryType),
                          size: 13,
                          color: AppColors.woodDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          Recipe.mealTypeLabels[primaryType] ?? primaryType,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.92),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
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

/// Estado vacío: Miau anima a crear la primera receta.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MiauCharacter(mood: MiauMood.cooking, size: 120),
            const SizedBox(height: 20),
            const Text(
              'Presidente Miau supervisa la cocina',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aún no hay recetas registradas.\n'
              '¡Pulsa "Nueva receta" para empezar!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.3,
                color: AppColors.ink.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado cuando el filtro activo no devuelve resultados.
class _NoMatchesState extends StatelessWidget {
  const _NoMatchesState();

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
              'No hay recetas con este filtro.\nPrueba con otra categoría.',
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
            const Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: AppColors.woodDark,
            ),
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
              label: const Text('Reintentar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.woodDark,
                side: const BorderSide(color: AppColors.wood, width: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Esqueleto de carga: una rejilla de tarjetas atenuadas para que la espera se
/// sienta cuidada y coherente con el resultado final.
class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AppTheme.cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 120, color: AppColors.cream),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(width: double.infinity),
                const SizedBox(height: 8),
                _bar(width: 80),
                const SizedBox(height: 14),
                _bar(width: 60, height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar({required double width, double height = 12}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(6),
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
        style: const TextStyle(color: AppColors.ink, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Buscar receta...',
          hintStyle: TextStyle(color: AppColors.ink.withValues(alpha: 0.45)),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.woodDark,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.woodDark,
                  ),
                  onPressed: onClear,
                  tooltip: 'Limpiar',
                ),
          filled: true,
          fillColor: AppColors.card,
          contentPadding: const EdgeInsets.symmetric(vertical: 2),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.wood, width: 1.4),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.woodDark, width: 1.8),
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
              'No hay recetas que coincidan con\n"$query".',
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
