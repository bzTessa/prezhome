import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/inventory_item.dart';
import 'models/nutrition_profile.dart';
import 'models/recipe.dart';
import 'models/shopping_list_item.dart';
import 'models/supermarket.dart';
import 'services/recipe_photo_service.dart';
import 'services/food_facts_service.dart';
import 'services/price_memory.dart';
import 'services/recipe_refiner.dart';
import 'theme/app_theme.dart';
import 'utils/approx_price.dart';
import 'utils/pantry_ideas.dart';
import 'utils/shopping_categories.dart';
import 'utils/friendly_error.dart';

/// "Ideas personalizadas" (estilo mise): eliges parámetros y la IA propone
/// recetas. Puedes guardar las que te gusten en tus recetas.
///
/// Con [pantryMode] ("¿Qué cocino con esto?") las ideas se construyen sobre lo
/// que ya hay en la despensa, empezando por lo que caduca antes, y cada idea
/// dice qué falta (con un botón para añadirlo a la compra).
class DiscoverRecipesScreen extends StatefulWidget {
  const DiscoverRecipesScreen({super.key, this.pantryMode = false});

  final bool pantryMode;

  /// Regla pura de precedencia de dieta: si el perfil tiene una dieta marcada y
  /// mapeable a etiqueta en español, esa etiqueta manda sobre el dropdown
  /// local; en caso contrario se usa la dieta local. Extraída como estática
  /// pura para poder testearla sin Supabase ni widgets.
  ///
  /// Coherencia con [profileDietOverrides]: 'omnivora' ("De todo") NO es una
  /// restricción real, así que se trata como "sin override" en AMBAS funciones.
  /// En ese caso resolveDiet usa la dieta local del dropdown (que vuelve a ser
  /// editable) para que el control tenga efecto real y no sea un fantasma.
  static String resolveDiet(String? profileDiet, String localDiet) {
    if (!profileDietOverrides(profileDiet)) return localDiet;
    return NutritionProfile.dietLabels[profileDiet] ?? localDiet;
  }

  /// ¿La dieta del perfil tiene prioridad sobre el dropdown local? True cuando
  /// hay una dieta de perfil mapeable y que suponga una restricción real. Se
  /// usa para avisar en la UI de que el dropdown de dieta queda sin efecto en
  /// ese caso. 'omnivora' ("De todo") devuelve false porque no restringe nada:
  /// así el dropdown sigue editable y se oculta el aviso. Debe permanecer
  /// alineada con [resolveDiet] (ver su documentación).
  static bool profileDietOverrides(String? profileDiet) =>
      profileDiet != null &&
      profileDiet != 'omnivora' &&
      NutritionProfile.dietLabels[profileDiet] != null;

  /// Preferencia de tiempo de cocina legible (español) a partir de la clave del
  /// perfil (rapido/normal/elaborado). null si no hay preferencia o no mapea.
  static String? cookTimeLabel(String? profileCookTime) =>
      profileCookTime != null
      ? NutritionProfile.cookTimeLabels[profileCookTime]
      : null;

  @override
  State<DiscoverRecipesScreen> createState() => _DiscoverRecipesScreenState();
}

class _DiscoverRecipesScreenState extends State<DiscoverRecipesScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  // Coste máximo orientativo por ración (EUR). Opcional.
  final _maxCostController = TextEditingController();

  // Modo "con lo que tengo" y los alimentos de la despensa que se usan.
  late bool _pantryMode = widget.pantryMode;
  List<String> _pantry = [];
  bool _pantryLoaded = false;

  // Hogar y precios aprendidos de los tickets (para el coste por ración).
  String? _homeId;
  Map<String, ProductPrice> _prices = {};
  final Set<int> _addingMissing = {};
  final Set<int> _addedMissing = {};
  String _goal = 'mantener';
  String _diet = 'sin restricción';
  final Set<String> _appliances = {};

  // Supermercados elegidos para esta generación. Se precargan con los del
  // hogar (homes.supermarkets) pero se pueden ajustar aquí sin cambiar los del
  // hogar. Opcional: si está vacío, la IA no se ciñe a ningún súper.
  final Set<String> _supermarkets = {};

  // Preferencias de comida del perfil del usuario (FEAT-001/002). Se usan para
  // personalizar la generación: la dieta se envía como etiqueta legible y las
  // alergias/ingredientes no deseados se mandan a la IA para que los evite.
  String? _profileDiet;
  List<String> _profileAllergies = [];
  List<String> _profileDisliked = [];
  String? _profileCookTime;

  bool _loading = false;
  bool _savedAny = false;
  List<Map<String, dynamic>> _ideas = [];
  final Set<int> _saving = {};
  final Set<int> _savedIdx = {};

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

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
          .select('home_id, diet, allergies, disliked, cook_time_pref')
          .eq('id', user.id)
          .maybeSingle();
      // Guardamos las preferencias del perfil para personalizar la generación.
      // Parseo directo tolerante a null (no usamos NutritionProfile.fromMap
      // porque la consulta no trae el 'id' que ese factory exige).
      if (profile != null && mounted) {
        List<String> asStrings(dynamic raw) =>
            (raw is List) ? raw.map((e) => e.toString()).toList() : <String>[];
        setState(() {
          _profileDiet = profile['diet'] as String?;
          _profileAllergies = asStrings(profile['allergies']);
          _profileDisliked = asStrings(profile['disliked']);
          _profileCookTime = profile['cook_time_pref'] as String?;
        });
      }
      final homeId = profile?['home_id'] as String?;
      if (homeId == null) return;
      _homeId = homeId;
      _loadPantryAndPrices(homeId);
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

  /// Despensa (para el modo "con lo que tengo") y precios (para el coste).
  /// Best-effort: si falla, sin despensa ni precios reales.
  Future<void> _loadPantryAndPrices(String homeId) async {
    try {
      final rows = await _client
          .from('inventory_items')
          .select()
          .eq('home_id', homeId);
      final items = (rows as List)
          .map((r) => InventoryItem.fromMap(Map<String, dynamic>.from(r)))
          .toList();
      if (mounted) setState(() => _pantry = pantryNamesForIdeas(items));
    } catch (_) {
      // Sin despensa: el modo "con lo que tengo" avisará.
    } finally {
      if (mounted) setState(() => _pantryLoaded = true);
    }
    try {
      final prices = await PriceMemory(_client).loadAll(homeId);
      if (mounted) setState(() => _prices = prices);
    } catch (_) {
      // Sin precios reales: se usan los orientativos.
    }
  }

  @override
  void dispose() {
    _maxCostController.dispose();
    super.dispose();
  }

  /// Títulos a evitar al generar: los de las recetas que el hogar ya tiene +
  /// las ideas ya mostradas en esta pantalla (para que "Generar" otra vez no
  /// repita). Best-effort: si falla la consulta, devuelve solo las de pantalla.
  Future<List<String>> _existingTitles() async {
    final titles = <String>{};
    for (final idea in _ideas) {
      final t = (idea['title'] ?? '').toString().trim();
      if (t.isNotEmpty) titles.add(t);
    }
    try {
      final res = await _client.from('recipes').select('title');
      for (final row in (res as List)) {
        final t = (row['title'] ?? '').toString().trim();
        if (t.isNotEmpty) titles.add(t);
      }
    } catch (_) {
      // Sin títulos de la BD si falla; usamos los de pantalla.
    }
    return titles.toList();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _savedIdx.clear();
      _addedMissing.clear();
    });
    try {
      // Títulos de recetas que ya tiene el hogar, para pedir a la IA que NO
      // los repita (variedad). Best-effort: si falla, se genera igual.
      final avoid = await _existingTitles();

      // Dieta: si el perfil tiene una dieta marcada, enviamos su etiqueta
      // legible en español (NutritionProfile.dietLabels). Si no hay perfil o
      // la clave no está mapeada, usamos el dropdown local como hasta ahora.
      final diet = DiscoverRecipesScreen.resolveDiet(_profileDiet, _diet);

      // Tiempo de cocina del perfil (rapido/normal/elaborado) como etiqueta
      // legible; null si no hay preferencia. Si es null no se envía al body
      // (compatibilidad hacia atrás: comportamiento idéntico al anterior).
      final cookTime = DiscoverRecipesScreen.cookTimeLabel(_profileCookTime);

      final body = <String, dynamic>{
        // Enviamos los supermercados elegidos como etiquetas legibles
        // (p. ej. "Mercadona, Lidl"); vacío si no se eligió ninguno.
        'supermarket': Supermarket.labelsFor(_supermarkets.toList()).join(', '),
        'goal': _goal,
        'diet': diet,
        'appliances': _appliances.toList(),
        'count': 5,
        // Títulos existentes (para no repetir); el prompt los trata como
        // "no repetir", distinto de alergias/disliked.
        'avoid': avoid,
        // Alergias (restricción dura) e ingredientes no deseados (blanda).
        'allergies': _profileAllergies,
        'disliked': _profileDisliked,
      };
      // Tiempo de cocina del perfil (si lo hay): así ajustamos las recetas al
      // ritmo que la usuaria eligió en su cuestionario. Si es null, la clave no
      // se incluye (compatibilidad hacia atrás: comportamiento idéntico).
      if (cookTime != null) {
        body['cook_time'] = cookTime;
      }
      final maxCost = double.tryParse(
        _maxCostController.text.trim().replaceAll(',', '.'),
      );
      if (maxCost != null && maxCost > 0) {
        body['max_cost_per_serving'] = maxCost;
      }
      if (_pantryMode && _pantry.isNotEmpty) {
        body['pantry'] = _pantry;
      }

      final res = await _client.functions.invoke(
        'discover-recipes',
        body: body,
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
          SnackBar(
            content: Text(friendlyError(e)),
            backgroundColor: AppColors.expired,
          ),
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
      final autoImageUrl = await RecipePhotoService(
        _client,
      ).find(title: title, titleEn: r['photo_query_en']?.toString());

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
            content: Text(friendlyError(e, 'Error al guardar')),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving.remove(index));
    }
  }

  InputDecoration _dec(String label) => InputDecoration(labelText: label);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {},
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          title: Text(
            _pantryMode ? '¿Qué cocino con esto?' : 'Ideas personalizadas',
          ),
          leading: IconButton(
            tooltip: 'Volver',
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
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('Ideas nuevas'),
                        icon: Icon(Icons.lightbulb_outline_rounded),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('Con lo que tengo'),
                        icon: Icon(Icons.kitchen_outlined),
                      ),
                    ],
                    selected: {_pantryMode},
                    showSelectedIcon: false,
                    onSelectionChanged: (v) =>
                        setState(() => _pantryMode = v.first),
                  ),
                  if (_pantryMode) ...[
                    const SizedBox(height: 10),
                    Text(
                      !_pantryLoaded
                          ? 'Mirando tu despensa…'
                          : _pantry.isEmpty
                          ? 'Tu despensa está vacía: añade lo que tienes en '
                                'casa para recibir ideas con ello.'
                          : 'Usaremos ${_pantry.length} alimentos de tu '
                                'despensa, empezando por lo que caduca antes.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
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
                        backgroundColor: AppColors.card,
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
                        .map(
                          (g) =>
                              DropdownMenuItem(value: g, child: Text(_cap(g))),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _goal = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _diet,
                    decoration: _dec('Dieta'),
                    items: _diets
                        .map(
                          (g) =>
                              DropdownMenuItem(value: g, child: Text(_cap(g))),
                        )
                        .toList(),
                    onChanged:
                        DiscoverRecipesScreen.profileDietOverrides(_profileDiet)
                        ? null
                        : (v) => setState(() => _diet = v!),
                  ),
                  if (DiscoverRecipesScreen.profileDietOverrides(
                    _profileDiet,
                  )) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 16,
                          color: AppColors.woodDark,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Usamos la dieta de tu perfil: '
                            '${NutritionProfile.dietLabels[_profileDiet]}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _maxCostController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _dec('Coste máximo por ración € (opcional)'),
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
                        backgroundColor: AppColors.card,
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
                        : const Icon(Icons.search_rounded),
                    label: Text(_loading ? 'Buscando ideas…' : 'Ver ideas'),
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

  /// Ingredientes de una idea tal como los devuelve la IA.
  List<CostIngredient> _ideaIngredients(Map<String, dynamic> r) {
    final raw = r['ingredients'];
    if (raw is! List) return const [];
    return [
      for (final m in raw.whereType<Map>())
        if ((m['name'] ?? '').toString().trim().isNotEmpty)
          (
            name: m['name'].toString().trim(),
            quantity: double.tryParse(
              (m['quantity'] ?? '').toString().replaceAll(',', '.'),
            ),
            unit: m['unit']?.toString(),
          ),
    ];
  }

  /// Coste por ración con precios de tus tickets o, si no, orientativos.
  double? _ideaCostPerServing(Map<String, dynamic> r) {
    final ings = _ideaIngredients(r);
    if (ings.isEmpty) return null;
    final servings = int.tryParse((r['servings'] ?? '').toString()) ?? 1;
    final cost = computeRecipeCost(
      ingredients: ings,
      prices: _prices,
      servings: servings,
      approxOf: ApproxPrice.estimate,
    );
    return cost.total > 0 ? cost.perServing : null;
  }

  /// Añade a la lista de la compra (lista principal) lo que falta.
  Future<void> _addMissingToShopping(int index, List<String> missing) async {
    final homeId = _homeId;
    if (homeId == null || missing.isEmpty) return;
    setState(() => _addingMissing.add(index));
    try {
      await _client.from('shopping_list_items').insert([
        for (final name in missing)
          ShoppingListItem(
            homeId: homeId,
            name: name,
            category: defaultCategoryFor(name),
          ).toInsertMap(),
      ]);
      if (!mounted) return;
      setState(() => _addedMissing.add(index));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            missing.length == 1
                ? 'Añadido a la lista de la compra'
                : 'Añadidos ${missing.length} productos a la compra',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo añadir a la compra. Revisa la conexión e '
            'inténtalo de nuevo.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _addingMissing.remove(index));
    }
  }

  Widget _infoLine(IconData icon, String label, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label ',
                    style: TextStyle(fontWeight: FontWeight.w700, color: color),
                  ),
                  TextSpan(text: text),
                ],
              ),
              style: TextStyle(fontSize: 13, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ideaCard(int index, Map<String, dynamic> r) {
    final saved = _savedIdx.contains(index);
    final saving = _saving.contains(index);
    final kcal = r['calories_per_serving'];
    final protein = r['protein_grams'];
    final costPerServing = _ideaCostPerServing(r);
    final split = _pantryMode && _pantry.isNotEmpty
        ? splitByPantry([for (final i in _ideaIngredients(r)) i.name], _pantry)
        : null;
    final adding = _addingMissing.contains(index);
    final added = _addedMissing.contains(index);

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
              style: TextStyle(color: AppColors.inkMuted, fontSize: 14),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (kcal != null)
                Text(
                  '$kcal kcal',
                  style: TextStyle(
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
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
              const Spacer(),
              if (costPerServing != null)
                Tooltip(
                  message:
                      'Orientativo: precios de tus tickets o, si no, '
                      'precios medios de supermercado.',
                  child: Text(
                    '≈ ${formatEuros(costPerServing)}/ración',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.sage,
                    ),
                  ),
                ),
            ],
          ),
          if (split != null) ...[
            if (split.have.isNotEmpty)
              _infoLine(
                Icons.check_circle_outline,
                'Tienes:',
                split.have.join(', '),
                AppColors.sage,
              ),
            if (split.missing.isNotEmpty)
              _infoLine(
                Icons.shopping_basket_outlined,
                'Te falta:',
                split.missing.join(', '),
                AppColors.terracotta,
              ),
            if (split.missing.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: adding || added
                      ? null
                      : () => _addMissingToShopping(index, split.missing),
                  icon: Icon(
                    added ? Icons.check : Icons.add_shopping_cart,
                    size: 18,
                  ),
                  label: Text(
                    added ? 'Añadido a la compra' : 'Añadir lo que falta',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.woodDark,
                  ),
                ),
              ),
          ],
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
                        borderRadius: BorderRadius.circular(16),
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
