import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_recipe_chooser.dart';
import 'recipe_detail_screen.dart';
import 'models/nutrition_profile.dart';
import 'models/recipe.dart';
import 'widgets/recipe_image.dart';

class RecipesScreen extends StatefulWidget {
  /// Cuando va dentro de una pestaña con su propio AppBar, lo ocultamos.
  final bool embedded;
  const RecipesScreen({super.key, this.embedded = false});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  late Future<_RecipesData> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
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

  void _reload() => setState(() => _future = _fetch());

  Future<void> _openAdd() async {
    final added = await AddRecipeChooser.show(context);
    if (added == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8E1),
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text(
                'Recetas & Meal Prep',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color(0xFFFDF8E1),
              elevation: 0,
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: const Color(0xFFE2C792),
        foregroundColor: const Color(0xFF1E1E1E),
        icon: const Icon(Icons.add),
        label: const Text(
          'Nueva receta',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<_RecipesData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar recetas: ${snapshot.error}'),
            );
          }
          final data = snapshot.data!;
          final recipes = data.recipes;
          final perMeal = data.profile?.caloriesPerMeal;

          if (recipes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/presidente_prezhome.jpg',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Presidente Miau supervisa la cocina, pero aún no hay '
                      'recetas registradas.\n¡Pulsa "Nueva receta" para empezar!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return _RecipeCard(
                recipe: recipe,
                caloriesPerMeal: perMeal,
                onTap: () async {
                  final changed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailScreen(recipe: recipe),
                    ),
                  );
                  if (changed == true) _reload();
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _RecipesData {
  final List<Recipe> recipes;
  final NutritionProfile? profile;
  _RecipesData({required this.recipes, this.profile});
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final int? caloriesPerMeal;
  final VoidCallback? onTap;

  const _RecipeCard({required this.recipe, this.caloriesPerMeal, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Raciones que te tocan por comida = kcal por comida / kcal por ración
    String? servingsHint;
    if (caloriesPerMeal != null &&
        recipe.calories != null &&
        recipe.calories! > 0) {
      final n = caloriesPerMeal! / recipe.calories!;
      servingsHint = '≈ ${n.toStringAsFixed(1)} ración(es) por comida';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RecipeImage(recipe: recipe, height: 150, radius: 16),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  recipe.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ),
              if (recipe.isFavorite)
                const Icon(Icons.star, color: Color(0xFFE2C792), size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final label in recipe.mealTypeLabelsList)
                _Chip(text: label),
              if (recipe.appliance != 'none')
                _Chip(text: recipe.applianceLabel),
              if (recipe.totalTimeMinutes != null)
                _Chip(text: '${recipe.totalTimeMinutes} min'),
              if (recipe.freezable) const _Chip(text: 'Congelable'),
            ],
          ),
          if (recipe.description != null) ...[
            const SizedBox(height: 8),
            Text(
              recipe.description!,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (recipe.calories != null)
                Text(
                  '${recipe.calories} kcal',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB58A3C),
                  ),
                ),
              if (recipe.protein != null) ...[
                const SizedBox(width: 12),
                Text(
                  'P: ${recipe.protein!.toStringAsFixed(0)}g',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
              if (recipe.carbs != null) ...[
                const SizedBox(width: 8),
                Text(
                  'C: ${recipe.carbs!.toStringAsFixed(0)}g',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
              if (recipe.fat != null) ...[
                const SizedBox(width: 8),
                Text(
                  'G: ${recipe.fat!.toStringAsFixed(0)}g',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ],
          ),
            if (servingsHint != null) ...[
              const SizedBox(height: 8),
              Text(
                servingsHint,
                style: const TextStyle(
                  color: Color(0xFF1E1E1E),
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF8E1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E1E1E),
        ),
      ),
    );
  }
}
