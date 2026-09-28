import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/ingredient.dart';
import 'models/recipe.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _client = Supabase.instance.client;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _servingsController = TextEditingController(text: '1');
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _prepController = TextEditingController();
  final _cookController = TextEditingController();

  String _appliance = 'none';
  String _mealType = 'lunch';
  bool _isFavorite = false;
  bool _freezable = false;
  bool _isLoading = false;

  // Ingredientes dinámicos
  final List<_IngredientControllers> _ingredients = [_IngredientControllers()];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _servingsController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _prepController.dispose();
    _cookController.dispose();
    for (final ing in _ingredients) {
      ing.dispose();
    }
    super.dispose();
  }

  double? _parseD(TextEditingController c) {
    final t = c.text.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  int? _parseI(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw 'No hay usuario autenticado';

      final profile = await _client
          .from('profiles')
          .select('home_id')
          .eq('id', user.id)
          .single();
      final homeId = profile['home_id'];
      if (homeId == null) throw 'El usuario no está asignado a ningún hogar.';

      final recipe = Recipe(
        id: '',
        homeId: homeId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        servings: _parseI(_servingsController) ?? 1,
        prepTimeMinutes: _parseI(_prepController),
        cookTimeMinutes: _parseI(_cookController),
        calories: _parseI(_caloriesController),
        protein: _parseD(_proteinController),
        carbs: _parseD(_carbsController),
        fat: _parseD(_fatController),
        appliance: _appliance,
        mealType: _mealType,
        isFavorite: _isFavorite,
        freezable: _freezable,
      );

      // Insertar receta y recuperar su id
      final inserted = await _client
          .from('recipes')
          .insert(recipe.toMap())
          .select('id')
          .single();
      final recipeId = inserted['id'] as String;

      // Insertar ingredientes (los que tengan nombre)
      final ingredientRows = <Map<String, dynamic>>[];
      var pos = 0;
      for (final ing in _ingredients) {
        final name = ing.name.text.trim();
        if (name.isEmpty) continue;
        ingredientRows.add(
          Ingredient(
            name: name,
            quantity: _parseD(ing.quantity),
            unit: ing.unit.text.trim().isEmpty ? null : ing.unit.text.trim(),
            position: pos++,
          ).toInsertMap(recipeId: recipeId, homeId: homeId),
        );
      }
      if (ingredientRows.isNotEmpty) {
        await _client.from('recipe_ingredients').insert(ingredientRows);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8E1),
      appBar: AppBar(
        title: const Text(
          'Nueva Receta',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFDF8E1),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: _dec('Título (ej. Pesto Chicken Sub)'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ponle un título' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: _dec('Descripción (opcional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _mealType,
                    decoration: _dec('Tipo de comida'),
                    items: Recipe.mealTypeLabels.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _mealType = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _servingsController,
                    keyboardType: TextInputType.number,
                    decoration: _dec('Raciones'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Macros ---
            const _SectionTitle('Valores nutricionales (por ración)'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _caloriesController,
              keyboardType: TextInputType.number,
              decoration: _dec('Calorías (kcal)'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _proteinController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _dec('Proteína (g)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _carbsController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _dec('Carbos (g)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _fatController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _dec('Grasa (g)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Tiempos y aparato ---
            const _SectionTitle('Cocina'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prepController,
                    keyboardType: TextInputType.number,
                    decoration: _dec('Prep (min)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cookController,
                    keyboardType: TextInputType.number,
                    decoration: _dec('Cocción (min)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _appliance,
              decoration: _dec('Aparato principal'),
              items: Recipe.applianceLabels.entries
                  .map(
                    (e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _appliance = v!),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Es congelable'),
              value: _freezable,
              activeThumbColor: const Color(0xFFE2C792),
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _freezable = v),
            ),
            SwitchListTile(
              title: const Text('Marcar como favorita ⭐'),
              value: _isFavorite,
              activeThumbColor: const Color(0xFFE2C792),
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _isFavorite = v),
            ),
            const SizedBox(height: 16),

            // --- Ingredientes dinámicos ---
            const _SectionTitle('Ingredientes'),
            const SizedBox(height: 12),
            ..._buildIngredientRows(),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _ingredients.add(_IngredientControllers())),
                icon: const Icon(Icons.add, color: Color(0xFF1E1E1E)),
                label: const Text(
                  'Añadir ingrediente',
                  style: TextStyle(
                    color: Color(0xFF1E1E1E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE2C792),
                foregroundColor: const Color(0xFF1E1E1E),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text(
                      'Guardar Receta',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildIngredientRows() {
    final rows = <Widget>[];
    for (var i = 0; i < _ingredients.length; i++) {
      final ing = _ingredients[i];
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: ing.quantity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _dec('Cant.'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: ing.unit,
                  decoration: _dec('Unidad'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: TextField(
                  controller: ing.name,
                  decoration: _dec('Ingrediente'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.redAccent),
                onPressed: _ingredients.length == 1
                    ? null
                    : () => setState(() {
                        _ingredients.removeAt(i);
                        ing.dispose();
                      }),
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }
}

class _IngredientControllers {
  final quantity = TextEditingController();
  final unit = TextEditingController();
  final name = TextEditingController();

  void dispose() {
    quantity.dispose();
    unit.dispose();
    name.dispose();
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E1E1E),
      ),
    );
  }
}
