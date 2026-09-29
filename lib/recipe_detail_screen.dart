import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_recipe_screen.dart';
import 'models/ingredient.dart';
import 'models/nutrition_profile.dart';
import 'models/recipe.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  late Recipe _recipe;
  late Future<List<Ingredient>> _ingredientsFuture;
  NutritionProfile? _profile;

  // Multiplicador para escalar cantidades sin tocar la receta base.
  double _multiplier = 1;
  bool _changed = false; // para avisar a la lista si hubo cambios al volver

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
    _ingredientsFuture = _fetchIngredients();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    final p = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (p != null && mounted) {
      setState(() => _profile = NutritionProfile.fromMap(p));
    }
  }

  Future<List<Ingredient>> _fetchIngredients() async {
    final res = await _client
        .from('recipe_ingredients')
        .select()
        .eq('recipe_id', _recipe.id)
        .order('position');
    return (res as List).map((m) => Ingredient.fromMap(m)).toList();
  }

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddRecipeScreen(recipe: _recipe)),
    );
    if (updated == true) {
      _changed = true;
      // Recargar la receta y sus ingredientes tras editar.
      final r = await _client
          .from('recipes')
          .select()
          .eq('id', _recipe.id)
          .maybeSingle();
      if (r != null && mounted) {
        setState(() {
          _recipe = Recipe.fromMap(r);
          _ingredientsFuture = _fetchIngredients();
        });
      }
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDF8E1),
        title: const Text('¿Eliminar receta?'),
        content: Text('Se borrará "${_recipe.title}" y sus ingredientes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _client.from('recipes').delete().eq('id', _recipe.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _fmtQty(double? q) {
    if (q == null) return '';
    final scaled = q * _multiplier;
    return scaled % 1 == 0
        ? scaled.toStringAsFixed(0)
        : scaled.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final r = _recipe;
    final scaledServings = (r.servings * _multiplier);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF8E1),
        appBar: AppBar(
          title: Text(
            r.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFFDF8E1),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_changed),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: _edit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Eliminar',
              onPressed: _delete,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Chips de tipo/aparato/tiempo/congelable
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final label in r.mealTypeLabelsList) _chip(label),
                if (r.appliance != 'none') _chip(r.applianceLabel),
                if (r.totalTimeMinutes != null)
                  _chip('${r.totalTimeMinutes} min'),
                if (r.freezable) _chip('Congelable'),
                if (r.isFavorite) _chip('Favorita'),
              ],
            ),
            if (r.description != null && r.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                r.description!,
                style: TextStyle(color: Colors.grey[700], fontSize: 15),
              ),
            ],
            const SizedBox(height: 20),

            // --- Multiplicador de cantidades ---
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cantidad a preparar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Escala la receta para congelar o para más gente. '
                    'No cambia la receta guardada.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _multBtn('×1', 1),
                      _multBtn('×2', 2),
                      _multBtn('×3', 3),
                      _multBtn('×4', 4),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Multiplicador personalizado:'),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _multiplier > 1
                            ? () => setState(
                                () => _multiplier =
                                    (_multiplier - 1).clamp(1, 50).toDouble(),
                              )
                            : null,
                      ),
                      Text(
                        '×${_multiplier % 1 == 0 ? _multiplier.toStringAsFixed(0) : _multiplier}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(
                          () => _multiplier =
                              (_multiplier + 1).clamp(1, 50).toDouble(),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Text(
                    'Rinde: ${scaledServings % 1 == 0 ? scaledServings.toStringAsFixed(0) : scaledServings.toStringAsFixed(1)} raciones',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (r.gramsPerServing != null)
                    Text(
                      '1 ración ≈ ${r.gramsPerServing!.toStringAsFixed(0)} g'
                      '${_multiplier != 1 ? '  ·  total ${(r.gramsPerServing! * scaledServings).toStringAsFixed(0)} g' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  if (r.kcalPer100g != null)
                    Text(
                      'Densidad: ${r.kcalPer100g!.toStringAsFixed(0)} kcal / 100 g',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Cuánto poner en tu taper (automático según tu perfil) ---
            if (r.kcalPer100g != null) ...[
              _autoTaperCard(r),
              const SizedBox(height: 16),
            ],

            // --- Macros (por ración, no se escalan) ---
            if (r.calories != null || r.protein != null)
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Por ración',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (r.calories != null)
                          _macro('${r.calories}', 'kcal'),
                        if (r.protein != null)
                          _macro('${r.protein!.toStringAsFixed(0)}g', 'Proteína'),
                        if (r.carbs != null)
                          _macro('${r.carbs!.toStringAsFixed(0)}g', 'Carbos'),
                        if (r.fat != null)
                          _macro('${r.fat!.toStringAsFixed(0)}g', 'Grasa'),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // --- Ingredientes (escalados por el multiplicador) ---
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Ingredientes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (_multiplier != 1) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(×${_multiplier % 1 == 0 ? _multiplier.toStringAsFixed(0) : _multiplier})',
                          style: const TextStyle(color: Color(0xFFB58A3C)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Ingredient>>(
                    future: _ingredientsFuture,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(8),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final ings = snap.data ?? [];
                      if (ings.isEmpty) {
                        return Text(
                          'Sin ingredientes registrados.',
                          style: TextStyle(color: Colors.grey[600]),
                        );
                      }
                      return Column(
                        children: ings.map((ing) {
                          final qty = _fmtQty(ing.quantity);
                          final parts = <String>[];
                          if (qty.isNotEmpty) parts.add(qty);
                          if (ing.unit != null && ing.unit!.isNotEmpty) {
                            parts.add(ing.unit!);
                          }
                          final prefix = parts.join(' ');
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('•  '),
                                if (prefix.isNotEmpty)
                                  Text(
                                    '$prefix ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                Expanded(child: Text(ing.name)),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Pasos ---
            if (r.instructions != null && r.instructions!.trim().isNotEmpty)
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pasos de preparación',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      r.instructions!,
                      style: const TextStyle(height: 1.5, fontSize: 15),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Calcula automáticamente, según el perfil y el tipo de la receta, cuántas
  /// kcal te tocan y cuántos gramos poner en el taper. Sin preguntar nada.
  Widget _autoTaperCard(Recipe r) {
    final profile = _profile;
    if (profile == null) {
      return _card(
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!profile.isComplete) {
      return _card(
        child: Text(
          'Completa tu Perfil Nutricional para ver cuántos gramos poner en tu taper.',
          style: TextStyle(color: Colors.grey[700]),
        ),
      );
    }

    final kcalForMeal = profile.caloriesForMealTypes(r.mealTypes);
    if (kcalForMeal == null) {
      return _card(
        child: Text(
          'Ajusta el reparto de calorías por comida en tu perfil para este tipo de receta.',
          style: TextStyle(color: Colors.grey[700]),
        ),
      );
    }

    final grams = r.gramsForCalories(kcalForMeal);
    // Etiqueta del tipo con mayor % para explicar de dónde sale.
    String mealLabel = r.mealTypeLabelsList.isNotEmpty
        ? r.mealTypeLabelsList.first
        : 'comida';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu ración',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Calculado con tu perfil: para tu $mealLabel te tocan '
            '≈ $kcalForMeal kcal.',
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text(
            grams == null
                ? '—'
                : 'Pon ≈ ${grams.toStringAsFixed(0)} g en la báscula',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFB58A3C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _multBtn(String label, double value) {
    final selected = _multiplier == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: const Color(0xFFE2C792),
        backgroundColor: const Color(0xFFFDF8E1),
        onSelected: (_) => setState(() => _multiplier = value),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
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

  Widget _macro(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1E1E1E),
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: child,
    );
  }
}


