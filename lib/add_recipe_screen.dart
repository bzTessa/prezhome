import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/ingredient.dart';
import 'models/recipe.dart';

class AddRecipeScreen extends StatefulWidget {
  /// Si se pasa una receta, la pantalla funciona en modo EDICIÓN.
  final Recipe? recipe;

  /// Si es true, al abrir muestra directamente el diálogo de "Rellenar con IA".
  final bool startWithAI;

  const AddRecipeScreen({super.key, this.recipe, this.startWithAI = false});

  bool get isEditing => recipe != null;

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _client = Supabase.instance.client;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _servingsController = TextEditingController(text: '1');
  final _gramsController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _prepController = TextEditingController();
  final _cookController = TextEditingController();

  String _appliance = 'none';
  final Set<String> _mealTypes = {}; // selección múltiple
  bool _isFavorite = false;
  bool _freezable = false;
  bool _isLoading = false;
  bool _aiLoading = false;
  bool _loadingInitial = false;

  // Imagen de la receta
  final _picker = ImagePicker();
  Uint8List? _newImageBytes; // imagen recién elegida (aún sin subir)
  String? _newImageExt;
  String? _existingImageUrl; // la que ya tenía la receta (en edición)

  final List<_IngredientControllers> _ingredients = [_IngredientControllers()];

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      _prefillFromRecipe(widget.recipe!);
    } else {
      _mealTypes.add('lunch');
      if (widget.startWithAI) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _fillWithAI());
      }
    }
  }

  void _prefillFromRecipe(Recipe r) {
    _titleController.text = r.title;
    _descriptionController.text = r.description ?? '';
    _instructionsController.text = r.instructions ?? '';
    _servingsController.text = r.servings.toString();
    _gramsController.text = r.gramsPerServing == null
        ? ''
        : (r.gramsPerServing! % 1 == 0
              ? r.gramsPerServing!.toStringAsFixed(0)
              : r.gramsPerServing!.toString());
    _caloriesController.text = r.calories?.toString() ?? '';
    _proteinController.text = r.protein?.toStringAsFixed(0) ?? '';
    _carbsController.text = r.carbs?.toStringAsFixed(0) ?? '';
    _fatController.text = r.fat?.toStringAsFixed(0) ?? '';
    _prepController.text = r.prepTimeMinutes?.toString() ?? '';
    _cookController.text = r.cookTimeMinutes?.toString() ?? '';
    _appliance = r.appliance;
    _mealTypes
      ..clear()
      ..addAll(r.mealTypes.isEmpty ? ['lunch'] : r.mealTypes);
    _isFavorite = r.isFavorite;
    _freezable = r.freezable;
    _existingImageUrl = r.imageUrl;
    // Cargar ingredientes existentes de la receta.
    _loadingInitial = true;
    _loadIngredients(r.id);
  }

  Future<void> _loadIngredients(String recipeId) async {
    try {
      final res = await _client
          .from('recipe_ingredients')
          .select()
          .eq('recipe_id', recipeId)
          .order('position');
      final list = (res as List).map((m) => Ingredient.fromMap(m)).toList();
      if (list.isNotEmpty) {
        for (final ing in _ingredients) {
          ing.dispose();
        }
        _ingredients
          ..clear()
          ..addAll(
            list.map((ing) {
              final c = _IngredientControllers();
              c.name.text = ing.name;
              c.quantity.text = ing.quantity == null
                  ? ''
                  : (ing.quantity! % 1 == 0
                        ? ing.quantity!.toStringAsFixed(0)
                        : ing.quantity!.toString());
              c.unit.text = ing.unit ?? '';
              return c;
            }),
          );
      }
    } catch (_) {
      // Si falla, se queda con una fila vacía.
    } finally {
      if (mounted) setState(() => _loadingInitial = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _servingsController.dispose();
    _gramsController.dispose();
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

  Future<void> _fillWithAI() async {
    final query = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFFFDF8E1),
          title: const Text('Rellenar con IA'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 6,
            minLines: 1,
            decoration: InputDecoration(
              hintText: 'Escribe el nombre o pega una receta entera…',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE2C792),
                foregroundColor: const Color(0xFF1E1E1E),
                elevation: 0,
              ),
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Generar'),
            ),
          ],
        );
      },
    );

    if (query == null || query.isEmpty) return;

    setState(() => _aiLoading = true);
    try {
      final res = await _client.functions.invoke(
        'generate-recipe',
        body: {'query': query},
      );

      final data = res.data;
      if (data is Map && data['recipe'] is Map) {
        _applyAIRecipe(Map<String, dynamic>.from(data['recipe'] as Map));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receta rellenada. Revísala antes de guardar.'),
            ),
          );
        }
      } else {
        final msg = (data is Map && data['error'] != null)
            ? data['error'].toString()
            : 'La IA no devolvió una receta válida';
        throw msg;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error con la IA: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  void _applyAIRecipe(Map<String, dynamic> r) {
    String s(dynamic v) => v == null ? '' : v.toString();

    setState(() {
      _titleController.text = s(r['title']);
      _descriptionController.text = s(r['description']);
      if (r['instructions'] != null) {
        _instructionsController.text = s(r['instructions']);
      }
      if (r['servings'] != null) _servingsController.text = s(r['servings']);
      if (r['grams_per_serving'] != null) {
        _gramsController.text = s(r['grams_per_serving']);
      }
      if (r['calories_per_serving'] != null) {
        _caloriesController.text = s(r['calories_per_serving']);
      }
      if (r['protein_grams'] != null) {
        _proteinController.text = s(r['protein_grams']);
      }
      if (r['carbs_grams'] != null) _carbsController.text = s(r['carbs_grams']);
      if (r['fat_grams'] != null) _fatController.text = s(r['fat_grams']);
      if (r['prep_minutes'] != null) _prepController.text = s(r['prep_minutes']);
      if (r['cook_minutes'] != null) _cookController.text = s(r['cook_minutes']);

      final appliance = s(r['appliance']);
      if (Recipe.applianceLabels.containsKey(appliance)) _appliance = appliance;

      // Tipos de comida (array). Fallback al singular por compatibilidad.
      final rawTypes = r['meal_types'];
      final types = <String>{};
      if (rawTypes is List) {
        for (final t in rawTypes) {
          final key = t.toString();
          if (Recipe.mealTypeLabels.containsKey(key)) types.add(key);
        }
      }
      if (types.isEmpty && Recipe.mealTypeLabels.containsKey(s(r['meal_type']))) {
        types.add(s(r['meal_type']));
      }
      if (types.isNotEmpty) {
        _mealTypes
          ..clear()
          ..addAll(types);
      }

      if (r['freezable'] is bool) _freezable = r['freezable'] as bool;

      final ings = r['ingredients'];
      if (ings is List && ings.isNotEmpty) {
        for (final ing in _ingredients) {
          ing.dispose();
        }
        _ingredients
          ..clear()
          ..addAll(
            ings.map((raw) {
              final m = raw is Map ? raw : <String, dynamic>{};
              final c = _IngredientControllers();
              c.name.text = s(m['name']);
              if (m['quantity'] != null) c.quantity.text = s(m['quantity']);
              c.unit.text = s(m['unit']);
              return c;
            }),
          );
        if (_ingredients.isEmpty) _ingredients.add(_IngredientControllers());
      }
    });
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 82,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _newImageBytes = bytes;
      _newImageExt = file.name.contains('.')
          ? file.name.split('.').last.toLowerCase()
          : 'jpg';
    });
  }

  /// Sube la imagen elegida al bucket y devuelve su ruta (o null si no hay).
  Future<String?> _uploadImageIfAny(String homeId) async {
    if (_newImageBytes == null) return null;
    final ext = (_newImageExt == 'png') ? 'png' : 'jpg';
    final path =
        '$homeId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _client.storage.from('recipe-images').uploadBinary(
          path,
          _newImageBytes!,
          fileOptions: FileOptions(
            contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
            upsert: true,
          ),
        );
    return path;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mealTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige al menos un tipo de comida.')),
      );
      return;
    }
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

      // Subir imagen nueva si se eligió. Si falla (p. ej. incidencia de
      // Storage), no bloqueamos: guardamos la receta sin foto y avisamos.
      String? uploadedPath;
      bool imageFailed = false;
      try {
        uploadedPath = await _uploadImageIfAny(homeId);
      } catch (_) {
        imageFailed = true;
      }

      final recipe = Recipe(
        id: widget.recipe?.id ?? '',
        homeId: homeId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        instructions: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
        servings: _parseI(_servingsController) ?? 1,
        gramsPerServing: _parseD(_gramsController),
        prepTimeMinutes: _parseI(_prepController),
        cookTimeMinutes: _parseI(_cookController),
        calories: _parseI(_caloriesController),
        protein: _parseD(_proteinController),
        carbs: _parseD(_carbsController),
        fat: _parseD(_fatController),
        appliance: _appliance,
        mealTypes: _mealTypes.toList(),
        isFavorite: _isFavorite,
        freezable: _freezable,
      );

      final recipeMap = recipe.toMap();
      // Guardar la ruta de la imagen: la nueva si se subió, si no la que había.
      if (uploadedPath != null) {
        recipeMap['image_path'] = uploadedPath;
      }

      String recipeId;
      if (widget.isEditing) {
        // Actualizar receta existente
        recipeId = widget.recipe!.id;
        await _client.from('recipes').update(recipeMap).eq('id', recipeId);
        // Reemplazar ingredientes: borrar los antiguos y volver a insertar.
        await _client
            .from('recipe_ingredients')
            .delete()
            .eq('recipe_id', recipeId);
      } else {
        final inserted = await _client
            .from('recipes')
            .insert(recipeMap)
            .select('id')
            .single();
        recipeId = inserted['id'] as String;
      }

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

      if (mounted) {
        if (imageFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Receta guardada, pero la foto no se pudo subir. '
                'Prueba a editarla más tarde.',
              ),
            ),
          );
        }
        Navigator.of(context).pop(true);
      }
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
        title: Text(
          widget.isEditing ? 'Editar Receta' : 'Nueva Receta',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFDF8E1),
        elevation: 0,
      ),
      body: _loadingInitial
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (!widget.isEditing) ...[
                    OutlinedButton.icon(
                      onPressed: _aiLoading ? null : _fillWithAI,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E1E1E),
                        minimumSize: const Size.fromHeight(48),
                        side: const BorderSide(
                          color: Color(0xFFE2C792),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: _aiLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        _aiLoading ? 'Generando…' : 'Rellenar con IA',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // Selector de imagen de la receta
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                        image: _newImageBytes != null
                            ? DecorationImage(
                                image: MemoryImage(_newImageBytes!),
                                fit: BoxFit.cover,
                              )
                            : (_existingImageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(_existingImageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null),
                      ),
                      child:
                          (_newImageBytes == null && _existingImageUrl == null)
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 36,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Añadir foto (opcional)',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            )
                          : Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  radius: 16,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    onPressed: _pickImage,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: _dec('Título'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Ponle un título'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: _dec('Descripción (opcional)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  // --- Tipos de comida (selección múltiple) ---
                  const _SectionTitle('Tipo de comida (puedes elegir varios)'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: Recipe.mealTypeLabels.entries.map((e) {
                      final selected = _mealTypes.contains(e.key);
                      return FilterChip(
                        label: Text(e.value),
                        selected: selected,
                        selectedColor: const Color(0xFFE2C792),
                        checkmarkColor: const Color(0xFF1E1E1E),
                        backgroundColor: Colors.white,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _mealTypes.add(e.key);
                          } else {
                            _mealTypes.remove(e.key);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _servingsController,
                          keyboardType: TextInputType.number,
                          decoration: _dec('Raciones'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _gramsController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _dec('Gramos / ración'),
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
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
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
                    title: const Text('Marcar como favorita'),
                    value: _isFavorite,
                    activeThumbColor: const Color(0xFFE2C792),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _isFavorite = v),
                  ),
                  const SizedBox(height: 16),

                  // --- Ingredientes ---
                  const _SectionTitle('Ingredientes'),
                  const SizedBox(height: 12),
                  ..._buildIngredientRows(),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(
                        () => _ingredients.add(_IngredientControllers()),
                      ),
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

                  // --- Pasos / instrucciones ---
                  const _SectionTitle('Pasos de preparación'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _instructionsController,
                    decoration: _dec('Escribe los pasos, uno por línea…'),
                    maxLines: 8,
                    minLines: 4,
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
                        : Text(
                            widget.isEditing
                                ? 'Guardar cambios'
                                : 'Guardar Receta',
                            style: const TextStyle(
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
