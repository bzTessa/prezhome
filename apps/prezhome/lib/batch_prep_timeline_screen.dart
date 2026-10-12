import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/recipe.dart';
import 'services/meal_prep_orchestrator.dart';
import 'theme/app_theme.dart';
import 'widgets/animations/celebrate.dart';
import 'widgets/animations/press_scale.dart';
import 'widgets/animations/staggered_entrance.dart';
import 'widgets/miau_character.dart';

/// "Modo cocina": pantalla del orquestador de BATCH COOKING.
///
/// Recibe las recetas que se van a cocinar a la vez, construye con
/// [MealPrepOrchestrator] una [TimelinePlan] unificada (agrupando las cocciones
/// que comparten aparato y marcando las preparaciones que solapan) y la pinta
/// como una línea de tiempo vertical cercana (tarjetas con conector, chip de
/// aparato, qué recetas cubre cada bloque y la duración).
///
/// Además, cada paso con duración trae un TEMPORIZADOR EN VIVO (cuenta atrás
/// mm:ss) con botones grandes de iniciar / pausar / reiniciar, pensados para
/// usarse mientras se cocina. Y cada paso puede marcarse como "Hecho"; cuando
/// todos están completos se dispara una pequeña celebración de Miau.
///
/// NOTA: el progreso de los temporizadores y de los pasos completados NO se
/// persiste (al salir de la pantalla se reinicia). Persistirlo entre sesiones
/// queda como posible mejora futura.
class BatchPrepTimelineScreen extends StatefulWidget {
  final List<Recipe> recipes;

  const BatchPrepTimelineScreen({super.key, required this.recipes});

  @override
  State<BatchPrepTimelineScreen> createState() =>
      _BatchPrepTimelineScreenState();
}

class _BatchPrepTimelineScreenState extends State<BatchPrepTimelineScreen> {
  late final TimelinePlan _plan;

  /// Estado de completado por índice de paso.
  late final List<bool> _done;

  /// Un temporizador por índice de paso (null si el paso aún no se ha iniciado
  /// o está pausado). Se guardan TODOS aquí para poder cancelarlos en dispose.
  late final List<Timer?> _timers;

  /// Segundos restantes de la cuenta atrás por paso.
  late final List<int> _remainingSeconds;

  /// true si la cuenta atrás del paso está corriendo ahora mismo.
  late final List<bool> _running;

  /// true cuando ya hemos celebrado el fin de la sesión (para no repetir).
  bool _celebrated = false;

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

    final count = _plan.steps.length;
    _done = List<bool>.filled(count, false);
    _timers = List<Timer?>.filled(count, null);
    _running = List<bool>.filled(count, false);
    _remainingSeconds = _plan.steps.map((s) => s.durationMinutes * 60).toList();
  }

  @override
  void dispose() {
    // Cancelamos TODOS los temporizadores antes de super.dispose() para no
    // dejar callbacks vivos que intenten tocar un State ya desmontado.
    for (final timer in _timers) {
      timer?.cancel();
    }
    super.dispose();
  }

  // --- Lógica del temporizador ------------------------------------------------

  void _startTimer(int index) {
    if (_remainingSeconds[index] <= 0) return;
    _timers[index]?.cancel();
    setState(() {
      _running[index] = true;
    });
    _timers[index] = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds[index] <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds[index] = 0;
          _running[index] = false;
          _timers[index] = null;
        });
        _onTimerFinished();
        return;
      }
      setState(() {
        _remainingSeconds[index] = _remainingSeconds[index] - 1;
      });
    });
  }

  void _pauseTimer(int index) {
    _timers[index]?.cancel();
    if (!mounted) return;
    setState(() {
      _timers[index] = null;
      _running[index] = false;
    });
  }

  void _resetTimer(int index) {
    _timers[index]?.cancel();
    if (!mounted) return;
    setState(() {
      _timers[index] = null;
      _running[index] = false;
      _remainingSeconds[index] = _plan.steps[index].durationMinutes * 60;
    });
  }

  /// Aviso táctil suave cuando una cuenta atrás llega a 0. No bloquea nada si
  /// el dispositivo no soporta vibración.
  void _onTimerFinished() {
    HapticFeedback.lightImpact();
  }

  void _toggleDone(int index) {
    setState(() {
      _done[index] = !_done[index];
      if (_done[index]) {
        // Al dar por hecho un paso, detenemos su temporizador si seguía vivo.
        _timers[index]?.cancel();
        _timers[index] = null;
        _running[index] = false;
      }
    });
    _maybeCelebrate();
  }

  /// Dispara la micro-celebración cuando TODOS los pasos están completados.
  void _maybeCelebrate() {
    if (_celebrated) return;
    if (_plan.steps.isEmpty) return;
    if (_done.every((d) => d)) {
      _celebrated = true;
      Celebrate.show(context);
    }
  }

  /// Formatea segundos a mm:ss.
  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  /// Icono VÁLIDO de Material según el aparato del paso.
  IconData _applianceIcon(String appliance) {
    switch (appliance) {
      case 'oven':
        return Icons.local_fire_department;
      case 'stovetop':
        return Icons.outdoor_grill;
      case 'pot':
        return Icons.soup_kitchen;
      case 'airfryer':
        return Icons.air;
      case 'microwave':
        return Icons.microwave;
      default:
        return Icons.restaurant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Modo cocina')),
      body: SafeArea(
        child: _plan.isEmpty ? _buildEmptyState() : _buildTimeline(),
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
              'No hay nada que cocinar ahora mismo',
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Cuando tengas recetas planificadas, aquí te prepararé un plan '
              'de cocina para hacerlo todo de una vez.',
              style: AppTextStyles.bodyMuted,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- Cabecera + línea de tiempo ---------------------------------------------

  Widget _buildTimeline() {
    final steps = _plan.steps;
    return ListView.builder(
      padding: AppSpacing.screenPadding,
      // +1 por la cabecera (índice 0).
      itemCount: steps.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) return _buildHeader();
        final index = i - 1;
        return StaggeredEntrance(
          index: index,
          child: _buildStepCard(index, steps[index]),
        );
      },
    );
  }

  Widget _buildHeader() {
    final total = _plan.totalEstimatedMinutes;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: AppTheme.surfaceDecoration(radius: AppRadius.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MiauCharacter(mood: MiauMood.cooking, size: 72),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tu plan de cocina', style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.xs),
                  Text(resumenTimeline(_plan), style: AppTextStyles.bodyMuted),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 18,
                        color: AppColors.sage,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Unos $total ${total == 1 ? 'minuto' : 'minutos'} en total',
                        style: AppTextStyles.bodyStrong,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(int index, TimelineStep step) {
    final done = _done[index];
    final isLast = index == _plan.steps.length - 1;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Conector vertical cozy: punto del paso + línea hacia el siguiente.
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.only(top: AppSpacing.md),
                decoration: BoxDecoration(
                  color: done ? AppColors.sage : AppColors.wood,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    color: AppColors.wood,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Opacity(
                opacity: done ? 0.6 : 1,
                child: Container(
                  padding: AppSpacing.cardPadding,
                  decoration: AppTheme.surfaceDecoration(radius: AppRadius.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChips(step),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        step.title,
                        style: AppTextStyles.title.copyWith(
                          decoration: done
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: done ? AppColors.inkMuted : AppColors.ink,
                        ),
                      ),
                      if (step.recipeTitles.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _recipesLabel(step),
                          style: AppTextStyles.labelMuted,
                        ),
                      ],
                      if (step.durationMinutes > 0 && !done) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _buildStepTimer(index),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      _buildDoneButton(index, done),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChips(TimelineStep step) {
    final chips = <Widget>[];

    // Chip de aparato (con icono válido y etiqueta en español).
    if (step.appliance != kApplianceNone && step.appliance.isNotEmpty) {
      final label = Recipe.applianceLabels[step.appliance] ?? step.appliance;
      chips.add(
        _chip(
          icon: _applianceIcon(step.appliance),
          label: label,
          bg: AppColors.peachBg,
          fg: AppColors.peach,
        ),
      );
    }

    // Chip de duración.
    if (step.durationMinutes > 0) {
      chips.add(
        _chip(
          icon: Icons.schedule,
          label: '${step.durationMinutes} min',
          bg: AppColors.sageBg,
          fg: AppColors.sage,
        ),
      );
    }

    // Chip "en paralelo" para los pasos que solapan.
    if (step.canRunInParallel) {
      chips.add(
        _chip(
          icon: Icons.sync,
          label: 'en paralelo',
          bg: AppColors.frostBg,
          fg: AppColors.frost,
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: chips,
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: AppSpacing.chipPadding,
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pillRadius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: AppTextStyles.label.copyWith(color: fg)),
        ],
      ),
    );
  }

  String _recipesLabel(TimelineStep step) {
    if (step.recipeTitles.length == 1) {
      return 'Para ${step.recipeTitles.first}';
    }
    return 'Para ${step.recipeTitles.join(', ')}';
  }

  // --- Temporizador por paso --------------------------------------------------

  Widget _buildStepTimer(int index) {
    final remaining = _remainingSeconds[index];
    final running = _running[index];
    final finished = remaining == 0;

    final Color timeColor = finished ? AppColors.sage : AppColors.ink;

    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: finished ? AppColors.sageBg : AppColors.cream,
        borderRadius: AppRadius.mdRadius,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (finished) ...[
                const Icon(Icons.check_circle, color: AppColors.sage, size: 28),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                finished ? '¡Listo!' : _formatTime(remaining),
                style: AppTextStyles.display.copyWith(
                  fontSize: 44,
                  color: timeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!finished)
                _timerButton(
                  icon: running ? Icons.pause : Icons.play_arrow,
                  label: running ? 'Pausar' : 'Iniciar',
                  bg: AppColors.wood,
                  fg: AppColors.ink,
                  onTap: () =>
                      running ? _pauseTimer(index) : _startTimer(index),
                ),
              if (!finished) const SizedBox(width: AppSpacing.md),
              _timerButton(
                icon: Icons.replay,
                label: 'Reiniciar',
                bg: AppColors.frostBg,
                fg: AppColors.frost,
                onTap: () => _resetTimer(index),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timerButton({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(color: bg, borderRadius: AppRadius.mdRadius),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: fg),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: AppTextStyles.bodyStrong.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }

  Widget _buildDoneButton(int index, bool done) {
    return PressScale(
      onTap: () => _toggleDone(index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: done ? AppColors.sageBg : AppColors.wood,
          borderRadius: AppRadius.mdRadius,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              done ? Icons.check_circle : Icons.check_circle_outline,
              size: 22,
              color: done ? AppColors.sage : AppColors.ink,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              done ? 'Hecho' : 'Marcar como hecho',
              style: AppTextStyles.bodyStrong.copyWith(
                color: done ? AppColors.sage : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
