import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/dashboard_prefs.dart';
import 'models/food_log_entry.dart';
import 'models/nutrition_profile.dart';
import 'models/recipe.dart';
import 'nutrition_profile_screen.dart';
import 'photo_meal_screen.dart';
import 'services/plan_diary.dart';
import 'theme/app_theme.dart';
import 'widgets/miau_character.dart';
import 'utils/friendly_error.dart';
import 'widgets/skeleton.dart';
import 'l10n/l10n.dart';

/// Diario de consumo personal del día: muestra lo que la persona ha comido
/// un día concreto, el total de kcal frente a su objetivo del perfil, y
/// permite añadir comidas a mano o desde una receta propia y navegar entre
/// días. Es PERSONAL (va por user_id), no por hogar.
class FoodDiaryScreen extends StatefulWidget {
  /// Día que se muestra al abrir la pantalla (por defecto, hoy).
  final DateTime? initialDate;

  /// Cuando va dentro de una pestaña con su propio AppBar, lo ocultamos.
  final bool embedded;
  const FoodDiaryScreen({super.key, this.initialDate, this.embedded = false});

  @override
  State<FoodDiaryScreen> createState() => _FoodDiaryScreenState();
}

class _FoodDiaryScreenState extends State<FoodDiaryScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  late Future<_DiaryData> _future;

  // Día que se está viendo (a medianoche).
  late DateTime _viewDay;

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
    await PlanDiary.sync(_client);

    // Perfil propio para leer el objetivo diario (puede ser null si está
    // incompleto). El perfil es por usuario: id = auth user id.
    int? targetCalories;
    var prefs = DashboardPrefs.defaults();
    final profileRow = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (profileRow != null) {
      targetCalories = NutritionProfile.fromMap(profileRow).targetCalories;
      final raw = profileRow['dashboard_prefs'];
      if (raw is Map) {
        prefs = DashboardPrefs.fromJson(Map<String, dynamic>.from(raw));
      }
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

    // Macros del día visible (para el gráfico de reparto).
    final dayProtein = entries.fold<double>(0, (a, e) => a + (e.protein ?? 0));
    final dayCarbs = entries.fold<double>(0, (a, e) => a + (e.carbs ?? 0));
    final dayFat = entries.fold<double>(0, (a, e) => a + (e.fat ?? 0));

    // Evolución de kcal de los últimos 7 días (incluyendo el día visible como
    // último punto). Una sola consulta por rango y agregación por día en Dart.
    final startDay = DateTime(_viewDay.year, _viewDay.month, _viewDay.day - 6);
    final startKey = startDay.toIso8601String().split('T').first;
    final rangeRes = await _client
        .from('food_log_entries')
        .select('log_date, calories')
        .eq('user_id', user.id)
        .gte('log_date', startKey)
        .lte('log_date', _dayKey);
    final rangeRows = (rangeRes as List)
        .map((m) => FoodLogEntry.fromMap(Map<String, dynamic>.from(m)))
        .toList();

    // Agregamos las kcal por clave de fecha (yyyy-MM-dd).
    final kcalByDay = <String, double>{};
    for (final e in rangeRows) {
      final key = e.logDate.toIso8601String().split('T').first;
      kcalByDay[key] = (kcalByDay[key] ?? 0) + (e.calories ?? 0);
    }

    // Rellenamos siempre 7 puntos (días sin datos a 0.0).
    final last7Days = <_DayCalories>[];
    for (int i = 0; i < 7; i++) {
      final day = DateTime(startDay.year, startDay.month, startDay.day + i);
      final key = day.toIso8601String().split('T').first;
      last7Days.add(_DayCalories(day: day, calories: kcalByDay[key] ?? 0.0));
    }

    return _DiaryData(
      prefs: prefs,
      entries: entries,
      totalCalories: total,
      targetCalories: targetCalories,
      last7Days: last7Days,
      dayProtein: dayProtein,
      dayCarbs: dayCarbs,
      dayFat: dayFat,
    );
  }

  /// Etiqueta legible del día: 'Hoy', 'Ayer' o 'd de MES'.
  String _dayLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = _viewDay.difference(today).inDays;
    if (diff == 0) return context.l.today;
    if (diff == -1) return context.l.yesterday;
    return DateFormat.MMMMd(
      Localizations.localeOf(context).toString(),
    ).format(_viewDay);
  }

  Future<void> _deleteEntry(String id) async {
    try {
      await _client.from('food_log_entries').delete().eq('id', id);
    } catch (e) {
      debugPrint('FoodDiary._deleteEntry error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l.diaDeleteError)));
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
                leading: Icon(Icons.edit_outlined, color: AppColors.ink),
                title: Text(context.l.diaManual),
                subtitle: Text(context.l.diaManualHint),
                onTap: () => Navigator.of(context).pop('manual'),
              ),
              ListTile(
                leading: Icon(Icons.menu_book_outlined, color: AppColors.ink),
                title: Text(context.l.diaFromRecipe),
                subtitle: Text(context.l.diaFromRecipeHint),
                onTap: () => Navigator.of(context).pop('receta'),
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.ink,
                ),
                title: Text(context.l.diaWithPhoto),
                subtitle: Text(context.l.diaWithPhotoHint),
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
              title: Text(context.l.diaAddManual),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dialogField(nameController, context.l.name),
                    const SizedBox(height: 12),
                    _dialogField(
                      kcalController,
                      context.l.diaKcalField,
                      number: true,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: mealType,
                      isExpanded: true,
                      decoration: _dialogDecoration(
                        context.l.diaMealTypeOptional,
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(context.l.diaNoType),
                        ),
                        ...FoodLogEntry.mealTypeLabels.keys.map(
                          (k) => DropdownMenuItem<String>(
                            value: k,
                            child: Text(context.l.mealType(k)),
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
                            context.l.diaProteinG,
                            number: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _dialogField(
                            carbsController,
                            context.l.diaCarbsG,
                            number: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _dialogField(
                            fatController,
                            context.l.diaFatG,
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
                  child: Text(context.l.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final kcal = double.tryParse(
                      kcalController.text.trim().replaceAll(',', '.'),
                    );
                    if (name.isEmpty || kcal == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.l.diaNeedNameKcal)),
                      );
                      return;
                    }
                    Navigator.of(context).pop(true);
                  },
                  child: Text(context.l.save),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l.diaSaveError)));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l.diaRecipesLoadError)));
      }
      return;
    }

    if (!mounted) return;
    if (recipes.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l.diaNoRecipes)));
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
              Text(
                context.l.planPickRecipe,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
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
                            ? context.l.diaKcalPerServing(r.calories!)
                            : context.l.diaNoKcal,
                        style: TextStyle(
                          color: hasKcal
                              ? AppColors.inkMuted
                              : AppColors.expired,
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
                context.l.diaKcalPerServing(recipe.calories!),
                style: TextStyle(color: AppColors.inkMuted),
              ),
              const SizedBox(height: 12),
              _dialogField(
                servingsController,
                context.l.diaServings,
                number: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final servings = double.tryParse(
                  servingsController.text.trim().replaceAll(',', '.'),
                );
                if (servings == null || servings <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l.diaServingsError)),
                  );
                  return;
                }
                Navigator.of(context).pop(true);
              },
              child: Text(context.l.diaLog),
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
      // El diario no tiene 'drink' como comida: las bebidas van sin grupo.
      mealType: recipe.mealTypes
          .where(FoodLogEntry.mealTypeLabels.containsKey)
          .firstOrNull,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l.diaRecipeLogError)));
      return;
    }
    if (!mounted) return;
    _reload();
  }

  InputDecoration _dialogDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppColors.card,
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
      appBar: widget.embedded ? null : AppBar(title: Text(context.l.diaTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-food-diary',
        onPressed: _openAddChooser,
        backgroundColor: AppColors.wood,
        foregroundColor: AppColors.ink,
        icon: const Icon(Icons.add),
        label: Text(
          context.l.diaAddMeal,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<_DiaryData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const DiarySkeleton();
          }
          if (snapshot.hasError) {
            return Center(child: Text(friendlyError(snapshot.error)));
          }
          final data = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _dayNavigator(),
              const SizedBox(height: 12),
              _summaryCard(data),
              _askedCard(),
              if (data.last7Days.any((d) => d.calories > 0)) ...[
                const SizedBox(height: 16),
                _caloriesChartCard(data),
              ],
              if (data.entries.isNotEmpty) ...[
                const SizedBox(height: 16),
                _macrosCard(data),
              ],
              const SizedBox(height: 16),
              if (data.entries.isEmpty)
                _empty()
              else
                ..._buildGroups(data.entries),
              if (data.prefs.trackCalories) _askSwitch(data.prefs),
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
            tooltip: context.l.previous,
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeDay(-1),
          ),
          Text(
            _dayLabel(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            tooltip: context.l.next,
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
          Text(
            context.l.diaDayCalories,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${total.round()} kcal',
            style: TextStyle(
              fontSize: 32,
              letterSpacing: -0.6,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          if (hasTarget) ...[
            Text(
              context.l.diaOfTarget(target),
              style: TextStyle(color: AppColors.inkMuted, fontSize: 15),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
                backgroundColor: AppColors.line,
                color: over ? AppColors.expired : AppColors.wood,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              over
                  ? context.l.homeKcalOver((total - target).round())
                  : context.l.homeKcalLeft((target - total).round()),
              style: TextStyle(
                color: over ? AppColors.expired : AppColors.inkMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              context.l.diaNoTarget,
              style: TextStyle(color: AppColors.inkMuted),
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
                  side: BorderSide(color: AppColors.wood, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.person_outline),
                label: Text(context.l.diaCompleteProfile),
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
      widgets.add(_groupHeader(context.l.mealType(type)));
      widgets.addAll(group.map(_entryCard));
      widgets.add(const SizedBox(height: 8));
    }

    final others = entries.where((e) => e.mealType == null).toList();
    if (others.isNotEmpty) {
      widgets.add(_groupHeader(context.l.diaOthers));
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
          color: AppColors.inkMuted,
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
              borderRadius: BorderRadius.circular(16),
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
                  e.name.isNotEmpty ? e.name : context.l.diaMeal,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${(e.calories ?? 0).round()} kcal',
                  style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
                ),
                if (macros.isNotEmpty)
                  Text(
                    macros.join('  ·  '),
                    style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.l.delete,
            icon: Icon(Icons.delete_outline, color: AppColors.expired),
            onPressed: e.id != null ? () => _deleteEntry(e.id!) : null,
          ),
        ],
      ),
    );
  }

  // --- Gráficas ------------------------------------------------------------

  // Iniciales del día de la semana (1=Lun..7=Dom), para el eje X.
  static const _weekdayInitials = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  /// Tarjeta con la evolución de kcal de los últimos 7 días en barras, con una
  /// marca horizontal del objetivo diario cuando existe.
  Widget _caloriesChartCard(_DiaryData data) {
    final days = data.last7Days;
    final target = data.targetCalories;
    final hasTarget = target != null && target > 0;

    final maxDay = days.fold<double>(
      0,
      (a, d) => d.calories > a ? d.calories : a,
    );
    final targetValue = hasTarget ? target.toDouble() : 0.0;
    final maxValue = (maxDay > targetValue ? maxDay : targetValue);
    // Dejamos un poco de aire por encima para que la barra o la línea no toque
    // el borde superior; mínimo razonable para evitar un eje a 0.
    final maxY = maxValue <= 0 ? 100.0 : maxValue * 1.2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l.diaLast7,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (hasTarget) ...[
            const SizedBox(height: 4),
            Text(
              context.l.diaTargetPerDay(target),
              style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.round()} kcal',
                        TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= days.length) {
                          return const SizedBox.shrink();
                        }
                        final d = days[i].day;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _weekdayInitials[d.weekday - 1],
                            style: TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                extraLinesData: hasTarget
                    ? ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: targetValue,
                            color: AppColors.woodDark,
                            strokeWidth: 2,
                            dashArray: [6, 4],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              style: TextStyle(
                                color: AppColors.woodDark,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              labelResolver: (_) => context.l.diaTarget,
                            ),
                          ),
                        ],
                      )
                    : const ExtraLinesData(),
                barGroups: [
                  for (int i = 0; i < days.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: days[i].calories,
                          color: AppColors.wood,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta con el reparto de macros (proteína/carbos/grasa) del día visible.
  /// Si no hay macros registrados, muestra un mensaje amable en vez de una
  /// tarta vacía.
  Widget _macrosCard(_DiaryData data) {
    final protein = data.dayProtein;
    final carbs = data.dayCarbs;
    final fat = data.dayFat;
    final total = protein + carbs + fat;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l.diaTodaySplit,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (total <= 0)
            Text(
              context.l.diaNoMacros,
              style: TextStyle(color: AppColors.inkMuted),
            )
          else
            Row(
              children: [
                SizedBox(
                  height: 120,
                  width: 120,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 28,
                      sections: [
                        PieChartSectionData(
                          value: protein,
                          color: AppColors.woodDark,
                          radius: 26,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: carbs,
                          color: AppColors.wood,
                          radius: 26,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: fat,
                          color: AppColors.line,
                          radius: 26,
                          showTitle: false,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _macroLegend(
                        AppColors.woodDark,
                        context.l.diaProtein,
                        protein,
                      ),
                      const SizedBox(height: 8),
                      _macroLegend(AppColors.wood, context.l.diaCarbs, carbs),
                      const SizedBox(height: 8),
                      _macroLegend(AppColors.line, context.l.diaFat, fat),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _macroLegend(Color color, String label, double grams) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(
          '${grams.round()} g',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  /// "¿Has comido X?" por cada comida del plan pendiente de respuesta.
  Widget _askedCard() {
    return ValueListenableBuilder<List<FoodLogEntry>>(
      valueListenable: PlanDiary.asked,
      builder: (context, asked, _) {
        if (asked.isEmpty) return const SizedBox.shrink();
        final today = DateTime.now();
        return Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          decoration: AppTheme.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l.diaAteThePlan,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              for (final e in asked)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l.diaAskLine(
                          e.logDate.day == today.day
                              ? context.l.today
                              : context.l.yesterday,
                          context.l.mealType(e.mealType ?? ''),
                          e.name,
                          e.calories?.round() ?? 0,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _answer(e, ate: false),
                      child: Text(context.l.no),
                    ),
                    TextButton(
                      onPressed: () => _answer(e, ate: true),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.terracotta,
                      ),
                      child: Text(
                        context.l.yes,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _answer(FoodLogEntry e, {required bool ate}) async {
    try {
      await PlanDiary.answer(_client, e, ate: ate);
    } catch (err) {
      debugPrint('FoodDiary._answer error: $err');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l.diaAnswerError)));
      return;
    }
    if (ate && mounted) _reload();
  }

  Widget _askSwitch(DashboardPrefs prefs) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(context.l.diaAskFirst),
      subtitle: Text(prefs.askMeals ? context.l.diaAskOn : context.l.diaAskOff),
      value: prefs.askMeals,
      onChanged: (v) async {
        try {
          await _client
              .from('profiles')
              .update({'dashboard_prefs': prefs.copyWith(askMeals: v).toJson()})
              .eq('id', _client.auth.currentUser!.id);
        } catch (e) {
          debugPrint('FoodDiary._askSwitch error: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.l.diaSettingError)));
          return;
        }
        if (mounted) _reload();
      },
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
            context.l.diaEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _DiaryData {
  final DashboardPrefs prefs;
  final List<FoodLogEntry> entries;
  final double totalCalories;
  final int? targetCalories;

  /// Evolución de kcal de los últimos 7 días (siempre 7 puntos, con 0.0 en los
  /// días sin datos). El último punto es el día visible.
  final List<_DayCalories> last7Days;

  /// Suma de macros del día visible (en gramos), para el gráfico de reparto.
  final double dayProtein;
  final double dayCarbs;
  final double dayFat;

  _DiaryData({
    required this.prefs,
    required this.entries,
    required this.totalCalories,
    required this.targetCalories,
    required this.last7Days,
    required this.dayProtein,
    required this.dayCarbs,
    required this.dayFat,
  });
}

/// Kcal totales de un día concreto, para la gráfica de evolución.
class _DayCalories {
  final DateTime day;
  final double calories;
  _DayCalories({required this.day, required this.calories});
}
