import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'services/hands_free.dart';
import 'theme/app_motion.dart';
import 'theme/app_theme.dart';
import 'utils/cook_voice.dart';
import 'utils/recipe_steps.dart';
import 'l10n/l10n.dart';

/// Un paso del modo cocina. [note] dice para qué receta es o si va mientras
/// otra cosa se hace (en tandas); [minutes] ofrece un temporizador.
class CookStep {
  const CookStep(this.text, {this.note, this.minutes});

  /// Paso de una receta suelta: el temporizador sale del propio texto.
  CookStep.fromText(String text) : this(text, minutes: stepTimerMinutes(text));

  final String text;
  final String? note;
  final int? minutes;
}

/// Modo cocina: un paso por pantalla con letra grande, para seguir la receta
/// (o una tanda de varias) con las manos ocupadas. Se pasa de paso deslizando,
/// con los botones grandes o, en manos libres, con la voz. Puede haber varios
/// temporizadores a la vez (el horno y la olla), siempre visibles arriba.
class CookModeScreen extends StatefulWidget {
  const CookModeScreen({
    super.key,
    required this.title,
    required this.steps,
    required this.ingredients,
    this.initialStep = 0,
  });

  final String title;
  final List<CookStep> steps;

  /// Ingredientes ya formateados ("200 g arroz").
  final List<String> ingredients;
  final int initialStep;

  @override
  State<CookModeScreen> createState() => _CookModeScreenState();
}

class _CookModeScreenState extends State<CookModeScreen> {
  late final PageController _pages = PageController(
    initialPage: widget.initialStep,
  );
  late int _page = widget.initialStep;
  final Set<int> _checkedIngredients = {};

  /// Fin de cada temporizador en marcha, por paso. Con la hora de fin (y no
  /// restando segundos) no se desfasa aunque la app pase a segundo plano.
  final Map<int, DateTime> _timerEnds = {};
  Timer? _ticker;

  late final HandsFree _voice = HandsFree(onCommand: _onVoice);
  bool _voiceOn = false;

  int get _total => widget.steps.length;
  bool get _isLast => _page >= _total - 1;

  @override
  void initState() {
    super.initState();
    // Que la pantalla no se apague mientras se cocina.
    WakelockPlus.enable().catchError((_) {});
  }

  @override
  void dispose() {
    _ticker?.cancel();
    if (_voiceOn) _voice.stop();
    WakelockPlus.disable().catchError((_) {});
    _pages.dispose();
    super.dispose();
  }

  void _go(int page) {
    if (page < 0 || page >= _total) return;
    _pages.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int p) {
    setState(() => _page = p);
    HapticFeedback.selectionClick();
    if (_voiceOn) _voice.say(_spoken(p));
  }

  String _spoken(int i) {
    final s = widget.steps[i];
    return [
      context.l.voiceStep(i + 1),
      if (s.note != null) '${s.note}.',
      s.text,
    ].join(' ');
  }

  // --- Temporizadores ---------------------------------------------------------

  Duration _left(int step) {
    final left = _timerEnds[step]!.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  void _startTimer(int step) {
    final minutes = widget.steps[step].minutes;
    if (minutes == null) return;
    HapticFeedback.mediumImpact();
    setState(
      () => _timerEnds[step] = DateTime.now().add(Duration(minutes: minutes)),
    );
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _stopTimer(int step) {
    setState(() => _timerEnds.remove(step));
    if (_timerEnds.isEmpty) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _tick() {
    if (!mounted) return;
    final done = [
      for (final s in _timerEnds.keys)
        if (_left(s) == Duration.zero) s,
    ];
    setState(() {});
    for (final s in done) {
      _stopTimer(s);
      _timerDone(s);
    }
  }

  void _timerDone(int step) {
    final what = widget.steps[step].note ?? context.l.cmStep(step + 1);
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
    if (_voiceOn) _voice.say(context.l.voiceTime(what));
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l.cmTime),
        content: Text(what),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _go(step);
            },
            child: Text(context.l.cmSeeStep),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l.ok),
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    // Redondeo hacia arriba: al empezar se ve 30:00, no 29:59.
    final secs = (d.inMilliseconds / 1000).ceil();
    final m = (secs ~/ 60 % 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return secs >= 3600 ? '${secs ~/ 3600}:$m:$s' : '$m:$s';
  }

  // --- Manos libres -----------------------------------------------------------

  Future<void> _toggleVoice() async {
    HapticFeedback.lightImpact();
    if (_voiceOn) {
      await _voice.stop();
      setState(() => _voiceOn = false);
      return;
    }
    final ok = await _voice.start();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l.cmMicPermission), persist: false),
      );
      return;
    }
    setState(() => _voiceOn = true);
    _voice.say(_spoken(_page));
  }

  void _onVoice(CookCommand command) {
    if (!mounted) return;
    switch (command) {
      case CookCommand.next:
        _isLast ? _voice.say(context.l.voiceLastStep) : _go(_page + 1);
      case CookCommand.previous:
        _page == 0 ? _voice.say(_spoken(0)) : _go(_page - 1);
      case CookCommand.repeat:
        _voice.say(_spoken(_page));
      case CookCommand.startTimer:
        final minutes = widget.steps[_page].minutes;
        if (minutes == null) {
          _voice.say(context.l.voiceNoTime);
        } else {
          _startTimer(_page);
          _voice.say(context.l.voiceTimer(minutes));
        }
      case CookCommand.stopTimer:
        final step = _timerEnds.containsKey(_page)
            ? _page
            : (_timerEnds.isEmpty ? null : _timerEnds.keys.first);
        if (step != null) _stopTimer(step);
        _voice.say(
          step == null ? context.l.voiceNoTimers : context.l.voiceStopped,
        );
      case CookCommand.ingredients:
        _voice.say(
          widget.ingredients.isEmpty
              ? context.l.voiceNoIngredients
              : widget.ingredients.join('. '),
        );
    }
  }

  // --- Interfaz ---------------------------------------------------------------

  Future<void> _showIngredients() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.7,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l.ingredients,
                        style: AppTextStyles.headline,
                      ),
                    ),
                    Text(
                      context.l.cmIngredientsReady(
                        _checkedIngredients.length,
                        widget.ingredients.length,
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.sage,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                for (var i = 0; i < widget.ingredients.length; i++)
                  CheckboxListTile(
                    value: _checkedIngredients.contains(i),
                    onChanged: (v) {
                      setSheet(() {});
                      setState(() {
                        v == true
                            ? _checkedIngredients.add(i)
                            : _checkedIngredients.remove(i);
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.sage,
                    title: Text(
                      widget.ingredients[i],
                      style: TextStyle(
                        fontSize: 18,
                        decoration: _checkedIngredients.contains(i)
                            ? TextDecoration.lineThrough
                            : null,
                        color: _checkedIngredients.contains(i)
                            ? AppColors.inkMuted
                            : AppColors.ink,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: context.l.cmExit,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        actions: [
          if (widget.ingredients.isNotEmpty)
            TextButton.icon(
              onPressed: _showIngredients,
              icon: const Icon(Icons.checklist_rounded, size: 20),
              label: Text(context.l.ingredients),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.ink,
                backgroundColor: AppColors.card,
                shape: StadiumBorder(side: BorderSide(color: AppColors.line)),
              ),
            ),
          IconButton(
            onPressed: _toggleVoice,
            tooltip: _voiceOn
                ? context.l.cmHandsFreeOff
                : context.l.cmHandsFree,
            icon: Icon(_voiceOn ? Icons.mic_rounded : Icons.mic_none_rounded),
            style: IconButton.styleFrom(
              backgroundColor: _voiceOn ? AppColors.ink : null,
              foregroundColor: _voiceOn ? AppColors.cream : AppColors.ink,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _progress(),
          if (_voiceOn)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                0,
              ),
              child: Text(
                context.l.cmVoiceHint,
                style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
              ),
            ),
          _timers(),
          Expanded(
            child: PageView.builder(
              controller: _pages,
              physics: const CookStepPhysics(),
              itemCount: _total,
              onPageChanged: _onPageChanged,
              itemBuilder: (_, i) => _stepPage(i),
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  /// "PASO 3 DE 6" y una barra que se llena con suavidad.
  Widget _progress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xs,
        AppSpacing.xl,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l.cmStepOf(_page + 1, _total),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: AppColors.woodDark,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.pillRadius,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: (_page + 1) / _total),
              duration: AppMotion.reduceMotionOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                color: AppColors.terracotta,
                backgroundColor: AppColors.line,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Los temporizadores en marcha de OTROS pasos (el del paso que se ve ya
  /// está en grande en la página), el que acaba antes arriba; tocar uno
  /// lleva a su paso.
  Widget _timers() {
    final steps = _timerEnds.keys.where((s) => s != _page).toList()
      ..sort((a, b) => _timerEnds[a]!.compareTo(_timerEnds[b]!));
    if (steps.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        0,
      ),
      child: Column(
        children: [
          for (final s in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Material(
                color: AppColors.ink,
                borderRadius: AppRadius.pillRadius,
                child: InkWell(
                  borderRadius: AppRadius.pillRadius,
                  onTap: () => _go(s),
                  child: Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.lg),
                    child: Row(
                      children: [
                        Icon(Icons.timer_rounded, color: AppColors.gold),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _fmt(_left(s)),
                          style: TextStyle(
                            color: AppColors.cream,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            widget.steps[s].note ?? context.l.cmStep(s + 1),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.cream.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _stopTimer(s),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.cream,
                          ),
                          child: Text(context.l.cmStop),
                        ),
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

  Widget _stepPage(int i) {
    final step = widget.steps[i];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (step.note != null)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final tag in step.note!.split(' · '))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.iconTile,
                      borderRadius: AppRadius.pillRadius,
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            step.text,
            style: TextStyle(
              fontSize: 30,
              letterSpacing: -0.5,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          if (step.minutes != null) ...[
            const SizedBox(height: AppSpacing.xxl),
            _timerCard(i, step.minutes!),
          ],
          if (i < _total - 1) ...[
            const SizedBox(height: AppSpacing.xxxl),
            _nextPreview(i + 1),
          ],
        ],
      ),
    );
  }

  /// Temporizador del paso en grande: los minutos, o la cuenta atrás con un
  /// anillo que se vacía, y un solo botón para iniciar o parar.
  Widget _timerCard(int i, int minutes) {
    final running = _timerEnds.containsKey(i);
    final left = running ? _left(i) : Duration(minutes: minutes);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppTheme.surfaceDecoration(
        radius: AppRadius.lg,
        color: running ? AppColors.goldBg : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: left.inSeconds / (minutes * 60),
                  strokeWidth: 4,
                  color: AppColors.terracotta,
                  backgroundColor: AppColors.line,
                ),
                Icon(Icons.timer_outlined, color: AppColors.ink),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  running ? context.l.cmTimerRunning : context.l.cmTimer,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkMuted,
                  ),
                ),
                Text(
                  running ? _fmt(left) : context.l.minutesShort(minutes),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: running
                ? OutlinedButton(
                    onPressed: () => _stopTimer(i),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.ink, width: 1.5),
                    ),
                    child: Text(context.l.cmStop),
                  )
                : FilledButton.icon(
                    onPressed: () => _startTimer(i),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(context.l.start),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.terracotta,
                      foregroundColor: AppColors.onBrand,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Lo que viene después, en suave; tocarlo avanza.
  Widget _nextPreview(int next) {
    return Material(
      color: AppColors.iconTile.withValues(alpha: 0.6),
      borderRadius: AppRadius.lgRadius,
      child: InkWell(
        borderRadius: AppRadius.lgRadius,
        onTap: () => _go(next),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l.cmThen,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.steps[next].text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        child: Row(
          children: [
            if (_page > 0)
              SizedBox(
                height: 60,
                width: 60,
                child: OutlinedButton(
                  onPressed: () => _go(_page - 1),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: AppColors.ink,
                    backgroundColor: AppColors.card,
                    shape: const CircleBorder(),
                    side: BorderSide(color: AppColors.line, width: 1.5),
                  ),
                  child: const Icon(Icons.arrow_back_rounded),
                ),
              ),
            if (_page > 0) const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SizedBox(
                height: 60,
                child: FilledButton.icon(
                  onPressed: _isLast
                      ? () => Navigator.of(context).pop(true)
                      : () => _go(_page + 1),
                  iconAlignment: IconAlignment.end,
                  icon: Icon(
                    _isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  ),
                  label: Text(_isLast ? context.l.ready : context.l.cmNextStep),
                  style: FilledButton.styleFrom(
                    backgroundColor: _isLast ? AppColors.done : AppColors.ink,
                    foregroundColor: _isLast ? Colors.white : AppColors.cream,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paso a paso con gestos de iOS: el destino se decide proyectando el
/// impulso del dedo ([AppMotion.projectMomentum]), como mucho un paso por
/// gesto, y los extremos estiran con rubber-banding.
class CookStepPhysics extends PageScrollPhysics {
  const CookStepPhysics({ScrollPhysics? parent})
    : super(parent: parent ?? const BouncingScrollPhysics());

  @override
  CookStepPhysics applyTo(ScrollPhysics? ancestor) =>
      CookStepPhysics(parent: buildParent(ancestor));

  /// Página de destino desde [pixels] lanzado a [velocity], en páginas de
  /// [width]: la vecina hacia donde apunta la proyección.
  static double targetPage(double pixels, double velocity, double width) {
    final from = pixels / width;
    final projected = (pixels + AppMotion.projectMomentum(velocity)) / width;
    return projected.roundToDouble().clamp(
      from.floorToDouble(),
      from.ceilToDouble(),
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (position.outOfRange || position.viewportDimension == 0) {
      return super.createBallisticSimulation(position, velocity);
    }
    final w = position.viewportDimension;
    final target = (targetPage(position.pixels, velocity, w) * w).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((target - position.pixels).abs() < toleranceFor(position).distance) {
      return null;
    }
    return ScrollSpringSimulation(
      AppMotion.fluidDefault,
      position.pixels,
      target,
      velocity,
      tolerance: toleranceFor(position),
    );
  }
}
