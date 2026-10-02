import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'add_recipe_screen.dart';
import 'models/ingredient.dart';
import 'models/inventory_item.dart';
import 'models/nutrition_profile.dart';
import 'models/recipe.dart';
import 'theme/app_theme.dart';
import 'widgets/recipe_image.dart';

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
  List<NutritionProfile> _profiles =
      []; // miembros del hogar con perfil visible
  NutritionProfile? _myProfile; // perfil del usuario logueado (para el modo)

  bool get _isMealPrep => _myProfile?.isMealPrep ?? false;

  // Multiplicador: nº de "comidas de hogar" a preparar (1 = para hoy todos).
  double _multiplier = 1;
  bool _changed = false; // para avisar a la lista si hubo cambios al volver

  /// Cuántas raciones-base de la receta equivale el total a preparar.
  /// Base = gramos de una comida de hogar / gramos por ración. Si no hay datos
  /// de perfil o peso, cae a "multiplicador = raciones" (comportamiento simple).
  double get _servingsFactor {
    final mealGrams = _householdMealGrams(_recipe);
    final perServing = _recipe.gramsPerServing;
    if (mealGrams != null && perServing != null && perServing > 0) {
      return (mealGrams / perServing) * _multiplier;
    }
    return _multiplier; // fallback: 1 = 1 ración
  }

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
    // Perfiles del hogar visibles: el propio siempre, y los de los miembros
    // que tengan el perfil compartido (RLS ya filtra: solo devuelve visibles).
    final rows = await _client
        .from('profiles')
        .select()
        .eq('home_id', _recipe.homeId);
    if (mounted) {
      setState(() {
        final all = (rows as List)
            .map((p) => NutritionProfile.fromMap(p))
            .toList();
        _profiles = all.where((p) => p.isComplete).toList();
        // Mi perfil (para saber el modo de cocina). Puede estar incompleto.
        for (final p in all) {
          if (p.id == user.id) _myProfile = p;
        }
      });
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

  /// Gramos de UNA comida para todo el hogar: suma de los gramos que come cada
  /// miembro (con perfil, que come en casa hoy) según su objetivo para esta
  /// comida. Es la base de "×1 = comida para todos".
  double? _householdMealGrams(Recipe r) {
    final today = DateTime.now().weekday;
    double total = 0;
    var counted = 0;
    for (final p in _profiles) {
      final eatsHome = r.mealTypes.any((t) => p.eatsAtHome(t, today));
      if (!eatsHome) continue;
      final kcal = p.caloriesForMealTypes(r.mealTypes);
      if (kcal == null) continue;
      final g = r.gramsForCalories(kcal);
      if (g == null) continue;
      total += g;
      counted++;
    }
    return counted > 0 ? total : null;
  }

  /// Registra la receta como cocinada: guarda en el congelador las raciones
  /// preparadas como "plato listo" (para meal prep). El nº de raciones = nº de
  /// comidas de hogar (el multiplicador) × personas que comen en casa.
  Future<void> _markCooked() async {
    try {
      final r = _recipe;
      // Nº de raciones individuales preparadas.
      double servings;
      final mealGrams = _householdMealGrams(r);
      if (mealGrams != null &&
          r.gramsPerServing != null &&
          r.gramsPerServing! > 0) {
        servings = (mealGrams / r.gramsPerServing!) * _multiplier;
      } else {
        servings = r.servings * _multiplier;
      }

      final now = DateTime.now();
      // Consumo preferente: hoy + días recomendados por la IA (o 90 por defecto).
      final days = r.freezerDays ?? 90;
      final bestBefore = days > 0
          ? DateTime(now.year, now.month, now.day + days)
          : null;

      final item = InventoryItem(
        id: '',
        homeId: r.homeId,
        name: r.title,
        category: 'Congelador',
        quantity: _multiplier, // nº de tandas/comidas de hogar
        unit: 'comidas',
        kind: 'dish',
        recipeId: r.id,
        servings: double.parse(servings.toStringAsFixed(1)),
        frozenOn: now,
        bestBefore: bestBefore,
      );
      await _client.from('inventory_items').insert(item.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guardado en el congelador como plato listo.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Abre el enlace de video de la receta en una app/pestaña externa.
  Future<void> _openVideo() async {
    final url = _recipe.videoUrl?.trim();
    if (url == null || url.isEmpty) return;
    try {
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el enlace del video'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el enlace del video'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _fmtQty(double? q) {
    if (q == null) return '';
    // Los ingredientes se escalan respecto a la "comida de hogar": cuántas
    // raciones-base equivale esa comida × el multiplicador.
    final scaled = q * _servingsFactor;
    // Redondeo natural: cantidades grandes a enteros; pequeñas con 1 decimal.
    if (scaled >= 10) return scaled.round().toString();
    if (scaled >= 1) {
      final r1 = (scaled * 2).round() / 2; // medios (1, 1.5, 2...)
      return r1 % 1 == 0 ? r1.toStringAsFixed(0) : r1.toStringAsFixed(1);
    }
    return scaled.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final r = _recipe;

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
            RecipeImage(recipe: r, height: 200, radius: 24),
            const SizedBox(height: 16),
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
            // Enlace de video de la receta, solo si existe.
            if (r.videoUrl != null && r.videoUrl!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openVideo,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.wood, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Ver video'),
                ),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isMealPrep
                        ? '×1 = una comida para todo el hogar. Sube el número '
                              'para cocinar de más y congelar.'
                        : 'Cantidad para una comida de todo el hogar.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  // Controles de lote solo en modo Meal prep.
                  if (_isMealPrep) ...[
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
                                  () => _multiplier = (_multiplier - 1)
                                      .clamp(1, 50)
                                      .toDouble(),
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
                            () => _multiplier = (_multiplier + 1)
                                .clamp(1, 50)
                                .toDouble(),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(),
                  Builder(
                    builder: (_) {
                      final mealGrams = _householdMealGrams(r);
                      if (mealGrams != null) {
                        final totalGrams = mealGrams * _multiplier;
                        final label = _multiplier == 1
                            ? 'una comida para el hogar'
                            : '${_multiplier.toStringAsFixed(0)} comidas para el hogar';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'A preparar: $label',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Total ≈ ${totalGrams.toStringAsFixed(0)} g',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB58A3C),
                              ),
                            ),
                          ],
                        );
                      }
                      // Fallback sin perfiles: mostrar raciones como antes.
                      final servings = r.servings * _multiplier;
                      return Text(
                        'Rinde: ${servings.toStringAsFixed(0)} raciones'
                        '${r.gramsPerServing != null ? '  ·  total ${(r.gramsPerServing! * servings).toStringAsFixed(0)} g' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                  if (r.kcalPer100g != null)
                    Text(
                      'Densidad: ${r.kcalPer100g!.toStringAsFixed(0)} kcal / 100 g',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  if (_isMealPrep) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _markCooked,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: const BorderSide(
                            color: AppColors.wood,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.ac_unit),
                        label: const Text('Ya cocinado → al congelador'),
                      ),
                    ),
                  ],
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
                        if (r.calories != null) _macro('${r.calories}', 'kcal'),
                        if (r.protein != null)
                          _macro(
                            '${r.protein!.toStringAsFixed(0)}g',
                            'Proteína',
                          ),
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
                    ..._buildSteps(r.instructions!),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Convierte el texto de instrucciones en una lista bonita, cada paso con su
  /// número en un círculo. Detecta líneas o el patrón "1. 2. 3.".
  List<Widget> _buildSteps(String instructions) {
    // 1) Separar por saltos de línea.
    var parts = instructions
        .split(RegExp(r'\n+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // 2) Si vino todo junto, separar por los números "1. 2. 3.".
    if (parts.length <= 1) {
      parts = instructions
          .split(RegExp(r'(?=\d+[\.\)]\s)'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // 3) Último recurso: si sigue siendo un solo bloque, separar por frases
    //    (un punto seguido de espacio y mayúscula = nueva instrucción).
    if (parts.length <= 1) {
      parts = instructions
          .split(RegExp(r'(?<=[\.\!])\s+(?=[A-ZÁÉÍÓÚÑ])'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // Quitar el número inicial de cada paso (lo ponemos nosotros en el círculo)
    final steps = parts
        .map((s) => s.replaceFirst(RegExp(r'^\d+[\.\)]\s*'), ''))
        .toList();

    final widgets = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: AppColors.wood,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    steps[i],
                    style: const TextStyle(height: 1.4, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  /// Muestra, para cada miembro del hogar (con perfil), cuántos gramos y kcal
  /// le corresponden de este plato según su perfil. Si el plato tiene
  /// componentes (pollo + arroz...), desglosa los gramos por componente.
  Widget _autoTaperCard(Recipe r) {
    if (_profiles.isEmpty) {
      return _card(
        child: Text(
          'Completa un Perfil Nutricional para ver cuántos gramos y calorías '
          'corresponden a cada persona.',
          style: TextStyle(color: Colors.grey[700]),
        ),
      );
    }

    final today = DateTime.now().weekday; // 1=Lun..7=Dom
    final rows = <Widget>[];
    for (final p in _profiles) {
      // Si ese miembro come FUERA hoy en todos los tipos de esta receta, se salta.
      final eatsHome = r.mealTypes.any((t) => p.eatsAtHome(t, today));
      if (!eatsHome) continue;

      final kcal = p.caloriesForMealTypes(r.mealTypes);
      if (kcal == null) continue;
      final grams = r.gramsForCalories(kcal);
      if (grams == null) continue;
      final name = (p.fullName?.trim().isNotEmpty == true)
          ? p.fullName!.trim()
          : 'Miembro';

      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '${grams.toStringAsFixed(0)} g · $kcal kcal',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB58A3C),
                    ),
                  ),
                ],
              ),
              // Desglose por componentes del plato (pollo + arroz...)
              if (r.hasComponents) ...[
                const SizedBox(height: 4),
                ...r.components.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(left: 4, top: 2),
                    child: Text(
                      '· ${c.name}: ${c.gramsFromTotal(grams).toStringAsFixed(0)} g',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (rows.isEmpty) {
      return _card(
        child: Text(
          'Ajusta el reparto de calorías por comida en el perfil para este tipo '
          'de receta.',
          style: TextStyle(color: Colors.grey[700]),
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Según el perfil de cada uno',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Cantidad y calorías por persona para esta comida.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const Divider(height: 20),
          ...rows,
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
