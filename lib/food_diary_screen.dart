import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/food_log_entry.dart';
import 'models/nutrition_profile.dart';
import 'models/recipe.dart';
import 'nutrition_profile_screen.dart';
import 'photo_meal_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/miau_character.dart';

/// Diario de consumo personal del día: muestra lo que la persona ha comido
/// un día concreto, el total de kcal frente a su objetivo del perfil, y
/// permite añadir comidas a mano o desde una receta propia y navegar entre
/// días. Es PERSONAL (va por user_id), no por hogar.
class FoodDiaryScreen extends StatefulWidget {
  /// Día que se muestra al abrir la pantalla (por defecto, hoy).
  final DateTime? initialDate;
  const FoodDiaryScreen({super.key, this.initialDate});

  @override
  State<FoodDiaryScreen> createState() => _FoodDiaryScreenState();
}

class _FoodDiaryScreenState extends State<FoodDiaryScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  late Future<_DiaryData> _future;

  // Día que se está viendo (a medianoche).
  late DateTime _viewDay;

  static const _monthNames = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  // Orden de los grupos por tipo de comida; null va al final en 'Otras'.
  static const _mealOrder = [
    'breakfast',
    'lunch',
    'dinner',
    'snack',
    'dessert',
  ];

  @override
  void initState() {
    super.initState();
    final base = widget.initialDate ?? DateTime.now();
    _viewDay = DateTime(base.year, base.month, base.day);
    _future = _load();
  }

  void _reload() {
    final future = _load();
    setState(() {
      _future = future;
    });
  }

  void _changeDay(int delta) {
    _viewDay = DateTime(_viewDay.year, _viewDay.month, _viewDay.day + delta);
    final future = _load();
    setState(() {
      _future = future;
    });
  }

  bool get _isToday {
    final now = DateTime.now();
    return _viewDay.year == now.year &&
        _viewDay.month == now.month &&
        _viewDay.day == now.day;
  }

  String get _dayKey => _viewDay.toIso8601String().split('T').first;

  Future<_DiaryData> _load() async {
    final user = _client.auth.currentUser;
    if (user == null) throw 'No autenticado';

    // Perfil propio para leer el objetivo diario (puede ser null si está
    // incompleto). El perfil es por usuario: id = auth user id.
    int? targetCalories;
    final profileRow = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (profileRow != null) {
      targetCalories = NutritionProfile.fromMap(profileRow).targetCalories;
    }

    // Entradas del día.
    final res = await _client
        .from('food_log_entries')
        .select()
        .eq('user_id', user.id)
        .eq('log_date', _dayKey)
        .order('created_at');
    final entries = (res as List)
        .map((m) => FoodLogEntry.fromMap(Map<String, dynamic>.from(m)))
        .toList();

    final total = entries.fold<double>(0, (a, e) => a + (e.calories ?? 0));

    return _DiaryData(
      entries: entries,
      totalCalories: total,
      targetCalories: targetCalories,
    );
  }

  /// Etiqueta legible del día: 'Hoy', 'Ayer' o 'd de MES'.
  String _dayLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = _viewDay.difference(today).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == -1) return 'Ayer';
    return '${_viewDay.day} de ${_monthNames[_viewDay.month - 1]}';
  }

  Future<void> _deleteEntry(String id) async {
    try {
      await _client.from('food_log_entries').delete().eq('id', id);
    } catch (e) {
      debugPrint('FoodDiary._deleteEntry error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo borrar la comida.')),
      );
      return;
    }
    if (!mounted) return;
    _reload();
  }

  // --- Añadir comida -------------------------------------------------------

  Future<void> _openAddChooser() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.wood,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.ink),
                title: const Text('A mano'),
                subtitle: const Text('Escribe el nombre y las calorías'),
                onTap: () => Navigator.of(context).pop('manual'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.menu_book_outlined,
                  color: AppColors.ink,
                ),
                title: const Text('Desde una receta'),
                subtitle: const Text('Registra una receta tuya como comida'),
                onTap: () => Navigator.of(context).pop('receta'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.ink,
                ),
                title: const Text('Con una foto'),
                subtitle: const Text(
                  'Haz una foto al plato y la IA estima las calorías',
                ),
                onTap: () => Navigator.of(context).pop('foto'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (choice == 'manual') {
      await _addManual();
    } else if (choice == 'receta') {
      await _addFromRecipe();
    } else if (choice == 'foto') {
      await _addFromPhoto();
    }
  }

  Future<void> _addFromPhoto() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PhotoMealScreen(logDate: _viewDay)),
    );
    if (!mounted) return;
    if (changed == true) _reload();
  }

  Future<void> _addManual() async {
    final nameController = TextEditingController();
    final kcalController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();
    String? mealType;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cream,
              title: const Text('Añadir a mano'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dialogField(nameController, 'Nombre'),
                    const SizedBox(height: 12),
                    _dialogField(
                      kcalController,
                      'Calorías (kcal)',
                      number: true,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: mealType,
                      isExpanded: true,
                      decoration: _dialogDecoration(
                        'Tipo de comida (opcional)',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Sin tipo'),
                        ),
                        ...FoodLogEntry.mealTypeLabels.entries.map(
                          (e) => DropdownMenuItem<String>(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        ),
                      ],
                      onChanged: (v) => setDialogState(() => mealType = v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _dialogField(
                            proteinController,
                            'Proteína (g)',
                            number: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _dialogField(
                            carbsController,
                            'Carbos (g)',
                            number: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _dialogField(
                            fatController,
                            'Grasa (g)',
                            number: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final kcal = double.tryParse(
                      kcalController.text.trim().replaceAll(',', '.'),
                    );
                    if (name.isEmpty || kcal == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Pon al menos un nombre y las calorías.',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;
    final user = _client.auth.currentUser;
    if (user == null) return;

    final entry = FoodLogEntry(
      userId: user.id,
      logDate: _viewDay,
      mealType: mealType,
      name: nameController.text.trim(),
      calories: double.tryParse(
        kcalController.text.trim().replaceAll(',', '.'),
      ),
      protein: double.tryParse(
        proteinController.text.trim().replaceAll(',', '.'),
      ),
      carbs: double.tryParse(carbsController.text.trim().replaceAll(',', '.')),
      fat: double.tryParse(fatController.text.trim().replaceAll(',', '.')),
      source: 'manual',
    );
    try {
      await _client.from('food_log_entries').insert(entry.toInsertMap());
    } catch (e) {
      debugPrint('FoodDiary._addManual insert error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la comida.')),
      );
      return;
    }
    if (!mounted) return;
    _reload();
  }

  Future<void> _addFromRecipe() async {
    // Cargar las recetas del hogar (mismo patrón de consulta que recipes).
    List<Recipe> recipes;
    try {
      final res = await _client
          .from('recipes')
          .select()
          .order('title', ascending: true);
      recipes = (res as List).map((m) => Recipe.fromMap(m)).toList();
    } catch (e) {
      debugPrint('FoodDiary._addFromRecipe load error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudieron cargar las recetas.')),
        );
      }
      return;
    }

    if (!mounted) return;
    if (recipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aún no tienes recetas que registrar.')),
      );
      return;
    }

    final recipe = await showModalBottomSheet<Recipe>(
      context: context,
      backgroundColor: AppColors.cream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Elige una receta',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: recipes.length,
                  itemBuilder: (context, i) {
                    final r = recipes[i];
                    final hasKcal = r.calories != null;
                    return ListTile(
                      title: Text(r.title),
                      subtitle: Text(
                        hasKcal
                            ? '${r.calories} kcal por ración'
                            : 'Sin calorías registradas',
                        style: TextStyle(
                          color: hasKcal ? Colors.grey[700] : Colors.redAccent,
                        ),
                      ),
                      enabled: hasKcal,
                      onTap: hasKcal
                          ? () => Navigator.of(context).pop(r)
                          : null,
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (recipe == null) return;
    if (!mounted) return;

    // Pedir el número de raciones (por defecto 1). Se valida que sea un
    // número mayor que 0 para no registrar en silencio con un factor erróneo.
    final servingsController = TextEditingController(text: '1');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cream,
          title: Text(recipe.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${recipe.calories} kcal por ración',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              _dialogField(servingsController, 'Raciones', number: true),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final servings = double.tryParse(
                  servingsController.text.trim().replaceAll(',', '.'),
                );
                if (servings == null || servings <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pon un número de raciones mayor que 0.'),
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop(true);
              },
              child: const Text('Registrar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    final user = _client.auth.currentUser;
    if (user == null) return;

    // La validación del diálogo garantiza un número > 0 aquí.
    final factor =
        double.tryParse(servingsController.text.trim().replaceAll(',', '.')) ??
        1.0;
    final baseKcal = (recipe.calories ?? 0).toDouble();

    final entry = FoodLogEntry(
      userId: user.id,
      logDate: _viewDay,
      mealType: recipe.mealTypes.isNotEmpty ? recipe.mealTypes.first : null,
      name: recipe.title,
      calories: baseKcal * factor,
      protein: recipe.protein != null ? recipe.protein! * factor : null,
      carbs: recipe.carbs != null ? recipe.carbs! * factor : null,
      fat: recipe.fat != null ? recipe.fat! * factor : null,
      source: 'receta',
      recipeId: recipe.id,
    );
    try {
      await _client.from('food_log_entries').insert(entry.toInsertMap());
    } catch (e) {
      debugPrint('FoodDiary._addFromRecipe insert error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo registrar la receta.')),
      );
      return;
    }
    if (!mounted) return;
    _reload();
  }

  InputDecoration _dialogDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );

  Widget _dialogField(
    TextEditingController controller,
    String label, {
    bool number = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: _dialogDecoration(label),
    );
  }

  // --- UI ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Mi diario')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-food-diary',
        onPressed: _openAddChooser,
        backgroundColor: AppColors.wood,
        foregroundColor: AppColors.ink,
        icon: const Icon(Icons.add),
        label: const Text(
          'Añadir comida',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<_DiaryData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _dayNavigator(),
              const SizedBox(height: 12),
              _summaryCard(data),
              const SizedBox(height: 16),
              if (data.entries.isEmpty)
                _empty()
              else
                ..._buildGroups(data.entries),
            ],
          );
        },
      ),
    );
  }

  Widget _dayNavigator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: AppTheme.cardDecoration(radius: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeDay(-1),
          ),
          Text(
            _dayLabel(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            // No dejar avanzar más allá del día de hoy.
            onPressed: _isToday ? null : () => _changeDay(1),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(_DiaryData data) {
    final total = data.totalCalories;
    final target = data.targetCalories;
    final hasTarget = target != null && target > 0;
    final ratio = hasTarget ? (total / target).clamp(0.0, 1.0) : 0.0;
    final over = hasTarget && total > target;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calorías del día',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${total.round()} kcal',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          if (hasTarget) ...[
            Text(
              'de $target kcal',
              style: TextStyle(color: Colors.grey[700], fontSize: 15),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
                backgroundColor: const Color(0xFFEFE7CC),
                color: over ? Colors.redAccent : AppColors.wood,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              over
                  ? 'Te has pasado ${(total - target).round()} kcal'
                  : 'Te quedan ${(target - total).round()} kcal',
              style: TextStyle(
                color: over ? Colors.redAccent : Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Completa tu perfil para fijar un objetivo diario de calorías '
              'y ver cuánto te queda cada día.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NutritionProfileScreen(),
                    ),
                  );
                  _reload();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.wood, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.person_outline),
                label: const Text('Completar mi perfil'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Construye los grupos de entradas por tipo de comida, en el orden
  /// breakfast, lunch, dinner, snack, dessert y un grupo final 'Otras' para
  /// las entradas sin tipo.
  List<Widget> _buildGroups(List<FoodLogEntry> entries) {
    final widgets = <Widget>[];

    for (final type in _mealOrder) {
      final group = entries.where((e) => e.mealType == type).toList();
      if (group.isEmpty) continue;
      widgets.add(_groupHeader(FoodLogEntry.mealTypeLabels[type] ?? type));
      widgets.addAll(group.map(_entryCard));
      widgets.add(const SizedBox(height: 8));
    }

    final others = entries.where((e) => e.mealType == null).toList();
    if (others.isNotEmpty) {
      widgets.add(_groupHeader('Otras'));
      widgets.addAll(others.map(_entryCard));
      widgets.add(const SizedBox(height: 8));
    }

    return widgets;
  }

  Widget _groupHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  Widget _entryCard(FoodLogEntry e) {
    final macros = <String>[];
    if (e.protein != null) macros.add('P ${e.protein!.round()} g');
    if (e.carbs != null) macros.add('C ${e.carbs!.round()} g');
    if (e.fat != null) macros.add('G ${e.fat!.round()} g');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(radius: 18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              e.source == 'receta'
                  ? Icons.menu_book_outlined
                  : Icons.restaurant_outlined,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.name.isNotEmpty ? e.name : 'Comida',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${(e.calories ?? 0).round()} kcal',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                if (macros.isNotEmpty)
                  Text(
                    macros.join('  ·  '),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: e.id != null ? () => _deleteEntry(e.id!) : null,
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          const MiauCharacter(mood: MiauMood.curious, size: 110),
          const SizedBox(height: 12),
          Text(
            'Aún no has apuntado nada este día.\nAñade tu primera comida.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

class _DiaryData {
  final List<FoodLogEntry> entries;
  final double totalCalories;
  final int? targetCalories;
  _DiaryData({
    required this.entries,
    required this.totalCalories,
    required this.targetCalories,
  });
}
