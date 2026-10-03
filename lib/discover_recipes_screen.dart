import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/recipe.dart';
import 'models/supermarket.dart';
import 'services/food_facts_service.dart';
import 'services/recipe_refiner.dart';
import 'theme/app_theme.dart';

/// "Ideas personalizadas" (estilo mise): eliges parámetros y la IA propone
/// recetas. Puedes guardar las que te gusten en tus recetas.
class DiscoverRecipesScreen extends StatefulWidget {
  const DiscoverRecipesScreen({super.key});

  @override
  State<DiscoverRecipesScreen> createState() => _DiscoverRecipesScreenState();
}

class _DiscoverRecipesScreenState extends State<DiscoverRecipesScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  final _budgetController = TextEditingController();
  String _goal = 'mantener';
  String _diet = 'sin restricción';
  final Set<String> _appliances = {};

  // Supermercados elegidos para esta generación. Se precargan con los del
  // hogar (homes.supermarkets) pero se pueden ajustar aquí sin cambiar los del
  // hogar. Opcional: si está vacío, la IA no se ciñe a ningún súper.
  final Set<String> _supermarkets = {};

  bool _loading = false;
  bool _savedAny = false;
  List<Map<String, dynamic>> _ideas = [];
  final Set<int> _saving = {};
  final Set<int> _savedIdx = {};

  static const _goals = [
    'mantener',
    'perder grasa',
    'ganar músculo',
    'alta proteína',
  ];
  static const _diets = [
    'sin restricción',
    'vegetariana',
    'vegana',
    'rápida',
    'baja en carbohidratos',
  ];
  static const Map<String, String> _applianceOptions = {
    'oven': 'Horno',
    'stovetop': 'Sartén',
    'pot': 'Olla',
    'airfryer': 'Airfryer',
    'microwave': 'Microondas',
  };

  @override
  void initState() {
    super.initState();
    _loadHomeSupermarkets();
  }

  /// Precarga los supermercados del hogar como selección inicial (sin bloquear
  /// la UI; si falla, simplemente arranca vacío).
  Future<void> _loadHomeSupermarkets() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;
      final profile = await _client
          .from('profiles')
          .select('home_id')
          .eq('id', user.id)
          .maybeSingle();
      final homeId = profile?['home_id'] as String?;
      if (homeId == null) return;
      final home = await _client
          .from('homes')
          .select('supermarkets')
          .eq('id', homeId)
          .maybeSingle();
      final raw = home?['supermarkets'];
      if (raw is List && mounted) {
        setState(() {
          _supermarkets
            ..clear()
            ..addAll(raw.map((e) => e.toString()));
        });
      }
    } catch (_) {
      // Sin preselección si falla; no es crítico.
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _savedIdx.clear();
    });
    try {
      final res = await _client.functions.invoke(
        'discover-recipes',
        body: {
          // Enviamos los supermercados elegidos como etiquetas legibles
          // (p. ej. "Mercadona, Lidl"); vacío si no se eligió ninguno.
          'supermarket': Supermarket.labelsFor(
            _supermarkets.toList(),
          ).join(', '),
          'goal': _goal,
          'diet': _diet,
          'appliances': _appliances.toList(),
          'weekly_budget': _budgetController.text.trim(),
          'count': 5,
        },
      );
      final data = res.data;
      if (data is Map && data['recipes'] is List) {
        setState(() {
          _ideas = (data['recipes'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
      } else {
        final msg = (data is Map && data['error'] != null)
            ? data['error'].toString()
            : 'No se recibieron ideas';
        throw msg;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveIdea(int index) async {
    setState(() => _saving.add(index));
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw 'No autenticado';
      final profile = await _client
          .from('profiles')
          .select('home_id')
          .eq('id', user.id)
          .single();
      final homeId = profile['home_id'];
      if (homeId == null) throw 'No perteneces a ningún hogar.';

      final r = _ideas[index];
      double? d(dynamic v) =>
          v == null ? null : double.tryParse(v.toString().replaceAll(',', '.'));
      int? i(dynamic v) => v == null ? null : int.tryParse(v.toString());

      final types = (r['meal_types'] is List)
          ? (r['meal_types'] as List).map((e) => e.toString()).toList()
          : <String>['lunch'];

      // Foto automática (Pexels) para la idea guardada. Las ideas no traen foto
      // manual, así que siempre lo intentamos. Degrada con elegancia: si falla o
      // viene null, se guarda sin foto (se verá el placeholder cozy).
      final title = (r['title'] ?? 'Receta').toString();
      String? autoImageUrl;
      if (title.trim().isNotEmpty) {
        try {
          final photoRes = await _client.functions.invoke(
            'recipe-photo',
            body: {'query': title},
          );
          final photoData = photoRes.data;
          if (photoData is Map) {
            final url = photoData['url']?.toString();
            if (url != null && url.isNotEmpty) autoImageUrl = url;
          }
        } catch (e) {
          debugPrint('DiscoverRecipesScreen recipe-photo error: $e');
        }
      }

      final servings = i(r['servings']) ?? 1;

      // Refinar la receta con Open Food Facts: cantidades prácticas (formatos
      // de súper reales) y nutrición recalculada sumando ingredientes. Afina
      // por el primer súper elegido. Best-effort: si OFF no sabe, las
      // cantidades igualmente salen más limpias y la nutrición queda la de IA.
      final rawIngredients = (r['ingredients'] is List)
          ? (r['ingredients'] as List)
                .whereType<Map>()
                .map((m) => Map<String, dynamic>.from(m))
                .toList()
          : <Map<String, dynamic>>[];
      final supermarket = _supermarkets.isNotEmpty ? _supermarkets.first : '';
      final refined = await RecipeRefiner(FoodFactsService(_client)).refine(
        raw: rawIngredients,
        servings: servings,
        supermarket: supermarket,
      );
      final nut = refined.nutrition;

      final recipe = Recipe(
        id: '',
        homeId: homeId,
        title: title,
        description: r['description']?.toString(),
        instructions: r['instructions']?.toString(),
        servings: servings,
        prepTimeMinutes: i(r['prep_minutes']),
        cookTimeMinutes: i(r['cook_minutes']),
        // Si OFF dio una nutrición fiable, la usamos; si no, la de la IA.
        calories: nut?.kcal ?? i(r['calories_per_serving']),
        protein: nut?.protein.toDouble() ?? d(r['protein_grams']),
        carbs: nut?.carbs.toDouble() ?? d(r['carbs_grams']),
        fat: nut?.fat.toDouble() ?? d(r['fat_grams']),
        appliance: (r['appliance'] ?? 'none').toString(),
        mealTypes: types.isEmpty ? ['lunch'] : types,
        gramsPerServing: d(r['grams_per_serving']),
        externalImageUrl: autoImageUrl,
        components: (r['components'] is List)
            ? (r['components'] as List)
                  .whereType<Map>()
                  .map(
                    (m) =>
                        RecipeComponent.fromMap(Map<String, dynamic>.from(m)),
                  )
                  .where((c) => c.name.isNotEmpty)
                  .toList()
            : const [],
      );

      final inserted = await _client
          .from('recipes')
          .insert(recipe.toMap())
          .select('id')
          .single();
      final recipeId = inserted['id'] as String;

      if (refined.ingredients.isNotEmpty) {
        var pos = 0;
        final rows = refined.ingredients
            .map(
              (ing) => {
                'recipe_id': recipeId,
                'home_id': homeId,
                'name': ing.name,
                'quantity': ing.quantity,
                'unit': ing.unit,
                'position': pos++,
              },
            )
            .toList();
        await _client.from('recipe_ingredients').insert(rows);
      }

      setState(() {
        _savedIdx.add(index);
        _savedAny = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardada en tus recetas')),
        );
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
      if (mounted) setState(() => _saving.remove(index));
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
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {},
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          title: const Text('Ideas personalizadas'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_savedAny),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: AppTheme.cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dinos qué buscas',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  const Text('Supermercados (opcional):'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: Supermarket.all.map((s) {
                      final sel = _supermarkets.contains(s.key);
                      return FilterChip(
                        label: Text(s.label),
                        selected: sel,
                        selectedColor: AppColors.wood,
                        backgroundColor: Colors.white,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _supermarkets.add(s.key);
                          } else {
                            _supermarkets.remove(s.key);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _goal,
                    decoration: _dec('Objetivo'),
                    items: _goals
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => _goal = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _diet,
                    decoration: _dec('Dieta'),
                    items: _diets
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => _diet = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    decoration: _dec('Presupuesto semanal € (opcional)'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Electrodomésticos:'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: _applianceOptions.entries.map((e) {
                      final sel = _appliances.contains(e.key);
                      return FilterChip(
                        label: Text(e.value),
                        selected: sel,
                        selectedColor: AppColors.wood,
                        backgroundColor: Colors.white,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _appliances.add(e.key);
                          } else {
                            _appliances.remove(e.key);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _generate,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      _loading ? 'Generando ideas…' : 'Generar ideas',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ..._ideas.asMap().entries.map((e) => _ideaCard(e.key, e.value)),
          ],
        ),
      ),
    );
  }

  Widget _ideaCard(int index, Map<String, dynamic> r) {
    final saved = _savedIdx.contains(index);
    final saving = _saving.contains(index);
    final kcal = r['calories_per_serving'];
    final protein = r['protein_grams'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (r['title'] ?? 'Receta').toString(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          if (r['description'] != null) ...[
            const SizedBox(height: 4),
            Text(
              r['description'].toString(),
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (kcal != null)
                Text(
                  '$kcal kcal',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.woodDark,
                  ),
                ),
              if (protein != null) ...[
                const SizedBox(width: 12),
                Text(
                  'P: ${protein}g',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: saved
                ? OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check),
                    label: const Text('Guardada'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: saving ? null : () => _saveIdea(index),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar en mis recetas'),
                  ),
          ),
        ],
      ),
    );
  }
}
