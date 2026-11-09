import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cook_mode_screen.dart';
import 'models/recipe.dart';
import 'services/meal_prep_orchestrator.dart';
import 'services/meal_prep_planner.dart';
import 'services/plan_shopping.dart';
import 'theme/app_theme.dart';
import 'utils/recipe_steps.dart';
import 'widgets/animations/staggered_entrance.dart';
import 'widgets/miau_character.dart';
import 'l10n/l10n.dart';

/// Cocina en lote: la vista previa tranquila de una tanda antes de cocinar.
///
/// Recibe las recetas que se van a cocinar a la vez y construye con
/// [MealPrepOrchestrator] una [TimelinePlan] unificada. Aquí solo se lee:
/// qué se cocina (y a qué táper va), lo que hay que sacar y el orden de los
/// pasos. Cocinar, con los temporizadores, se hace en [CookModeScreen], un
/// paso por pantalla.
class BatchPrepTimelineScreen extends StatefulWidget {
  final List<Recipe> recipes;

  /// Qué va a la nevera y qué al congelador de cada receta (del plan de
  /// cocción). Si viene, se añade el reparto en tápers al final.
  final List<PrepBatch> batches;

  /// Día de la tanda: dice qué se come recién hecho y qué va en táper.
  final DateTime? cookDay;

  const BatchPrepTimelineScreen({
    super.key,
    required this.recipes,
    this.batches = const [],
    this.cookDay,
  });

  @override
  State<BatchPrepTimelineScreen> createState() =>
      _BatchPrepTimelineScreenState();
}

class _BatchPrepTimelineScreenState extends State<BatchPrepTimelineScreen> {
  late final TimelinePlan _plan;

  @override
  void initState() {
    super.initState();

    // Convertimos cada Recipe de la app a su espejo reducido OrchestratorRecipe
    // (igual que meal_plan_screen construye PrepRecipe) y pedimos la timeline.
    final orchestratorRecipes = widget.recipes
        .map(
          (r) => OrchestratorRecipe(
            id: r.id,
            title: r.title,
            appliance: r.appliance,
            prepTimeMinutes: r.prepTimeMinutes,
            cookTimeMinutes: r.cookTimeMinutes,
            instructions: r.instructions,
          ),
        )
        .toList();

    _plan = const MealPrepOrchestrator().buildTimeline(
      recipes: orchestratorRecipes,
    );
    _loadIngredients();
  }

  /// Ingredientes de toda la tanda, ya multiplicados por las raciones.
  List<String> _ingredients = const [];

  Future<void> _loadIngredients() async {
    if (widget.batches.isEmpty) return;
    try {
      final res = await Supabase.instance.client
          .from('recipe_ingredients')
          .select()
          .inFilter('recipe_id', [for (final b in widget.batches) b.recipeId]);
      final lines = batchIngredientLines(
        [for (final m in res as List) Map<String, dynamic>.from(m as Map)],
        widget.batches,
        {for (final r in widget.recipes) r.id: r.servings},
      );
      if (mounted) setState(() => _ingredients = lines);
    } catch (_) {
      // Sin red se cocina igual con los pasos.
    }
  }

  /// Icono según el aparato del paso.
  IconData _applianceIcon(String appliance) {
    switch (appliance) {
      case 'oven':
        return Icons.local_fire_department_rounded;
      case 'stovetop':
        return Icons.outdoor_grill_rounded;
      case 'pot':
        return Icons.soup_kitchen_rounded;
      case 'airfryer':
        return Icons.air_rounded;
      case 'microwave':
        return Icons.microwave_rounded;
      case 'blender':
        return Icons.blender_rounded;
      default:
        return Icons.back_hand_outlined;
    }
  }

  /// "1 h 55 min" o "40 min".
  String _duration(int minutes) => minutes < 60
      ? context.l.minutesShort(minutes)
      : '${minutes ~/ 60} h${minutes % 60 == 0 ? '' : ' ${minutes % 60} min'}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(context.l.bpBatchCook)),
      body: SafeArea(
        child: _plan.isEmpty ? _buildEmptyState() : _buildOverview(),
      ),
      bottomNavigationBar: _plan.isEmpty ? null : _buildStartBar(),
    );
  }

  // --- Paso a paso ------------------------------------------------------------

  /// Los pasos de la tanda para el modo cocina paso a paso: cada uno dice para
  /// qué receta es y si se hace mientras otra cosa está al fuego.
  List<CookStep> _cookSteps() => [
    for (final step in _plan.steps)
      CookStep(
        step.title,
        note: [
          if (!step.isPrep) context.l.appliance(step.appliance),
          step.recipeTitles.join(', '),
          if (step.canRunInParallel) context.l.bpMeanwhile,
        ].join(' · '),
        // La cocción dura lo que dice la receta; en la preparación solo hay
        // temporizador si el propio paso menciona un tiempo.
        minutes: step.isPrep
            ? stepTimerMinutes(step.title)
            : (step.durationMinutes > 0 ? step.durationMinutes : null),
      ),
    for (final b in widget.batches)
      if (_taperText(b) != null)
        CookStep(_taperText(b)!, note: context.l.bpTapers(b.title)),
  ];

  /// "Nevera para el mié y vie · congelador para el sáb", o null si no hay
  /// nada.
  String? _taperText(PrepBatch b) {
    final day = widget.cookDay;
    if (day == null) return null;
    final text = taperPlan(b, day);
    if (text.isEmpty) return null;
    return '${text[0].toUpperCase()}${text.substring(1)}.';
  }

  Widget _buildStartBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        child: SizedBox(
          height: 60,
          child: FilledButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CookModeScreen(
                    title: context.l.bpBatchCook,
                    steps: _cookSteps(),
                    ingredients: _ingredients,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 26),
            label: Text(context.l.bpStart),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.terracotta,
              foregroundColor: AppColors.onBrand,
              shape: const StadiumBorder(),
              textStyle: AppTextStyles.title.copyWith(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }

  // --- Estado vacío -----------------------------------------------------------

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiauCharacter(mood: MiauMood.sleeping, size: 140),
            const SizedBox(height: AppSpacing.xl),
            Text(
              context.l.bpEmpty,
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l.bpEmptySub,
              style: AppTextStyles.bodyMuted,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- Vista previa -----------------------------------------------------------

  Widget _buildOverview() {
    final sections = [
      _buildHeader(),
      _buildRecipes(),
      if (_ingredients.isNotEmpty) _buildIngredients(),
      _buildSteps(),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xxxl,
      ),
      children: [
        for (var i = 0; i < sections.length; i++)
          StaggeredEntrance(index: i, child: sections[i]),
      ],
    );
  }

  /// Ilustración, cuántas recetas y tres datos: tiempo, pasos y raciones.
  Widget _buildHeader() {
    final servings = widget.batches.fold(0, (s, b) => s + b.totalServings);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l.bpHeroTitle(widget.recipes.length),
                  style: AppTextStyles.display.copyWith(fontSize: 28),
                ),
              ),
              const MiauCharacter(mood: MiauMood.cooking, size: 84),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _stat(
                Icons.schedule_rounded,
                _duration(_plan.totalEstimatedMinutes),
                AppColors.sageBg,
                AppColors.sage,
              ),
              _stat(
                Icons.format_list_numbered_rounded,
                context.l.bpSteps(_plan.steps.length),
                AppColors.peachBg,
                AppColors.peach,
              ),
              if (servings > 0)
                _stat(
                  Icons.restaurant_rounded,
                  context.l.planServings(servings),
                  AppColors.frostBg,
                  AppColors.frost,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pillRadius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.bodyStrong.copyWith(color: fg, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headline.copyWith(fontSize: 19)),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            decoration: AppTheme.surfaceDecoration(radius: AppRadius.lg),
            child: child,
          ),
        ],
      ),
    );
  }

  /// Filas separadas por una línea fina.
  Widget _rows(List<Widget> rows) => Column(
    children: [
      for (var i = 0; i < rows.length; i++) ...[
        if (i > 0) Divider(height: 1, color: AppColors.line),
        rows[i],
      ],
    ],
  );

  /// Qué se cocina, cuántas raciones y a qué táper va cada receta.
  Widget _buildRecipes() {
    final batchById = {for (final b in widget.batches) b.recipeId: b};
    return _section(
      context.l.bpCooking,
      _rows([
        for (final r in widget.recipes)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.terracottaBg,
                    borderRadius: AppRadius.mdRadius,
                  ),
                  child: Icon(
                    _applianceIcon(r.appliance),
                    size: 20,
                    color: AppColors.terracottaText,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.title, style: AppTextStyles.bodyStrong),
                      const SizedBox(height: 2),
                      Text(
                        [
                          context.l.planServings(
                            batchById[r.id]?.totalServings ?? r.servings,
                          ),
                          if (batchById[r.id] case final b?) ?_taperText(b),
                        ].join(' · '),
                        style: AppTextStyles.bodyMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ]),
    );
  }

  /// Todo lo que hace falta para la tanda, sumado entre recetas.
  Widget _buildIngredients() {
    return _section(
      context.l.bpNeed,
      Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: [
            for (final line in _ingredients)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.wood,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Text(line, style: AppTextStyles.body)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// El orden de la tanda, solo para leer: número, paso y un dato discreto.
  Widget _buildSteps() {
    final steps = _plan.steps;
    return _section(
      context.l.bpStepsTitle,
      _rows([
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.iconTile,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(steps[i].title, style: AppTextStyles.body),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (!steps[i].isPrep)
                            context.l.appliance(steps[i].appliance),
                          if (steps[i].durationMinutes > 0)
                            context.l.minutesShort(steps[i].durationMinutes),
                          if (steps[i].canRunInParallel) context.l.bpMeanwhile,
                          steps[i].recipeTitles.join(', '),
                        ].join(' · '),
                        style: AppTextStyles.labelMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ]),
    );
  }
}
