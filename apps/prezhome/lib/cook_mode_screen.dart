import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'services/hands_free.dart';
import 'theme/app_theme.dart';
import 'utils/cook_voice.dart';
import 'utils/recipe_steps.dart';

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
      'Paso ${i + 1}.',
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
    final what = widget.steps[step].note ?? 'Paso ${step + 1}';
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
    if (_voiceOn) _voice.say('Tiempo. $what.');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tiempo'),
        content: Text(what),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _go(step);
            },
            child: const Text('Ver paso'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Vale'),
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
        const SnackBar(
          content: Text('Para usar la voz, permite el micrófono en Ajustes.'),
          persist: false,
        ),
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
        _isLast ? _voice.say('Es el último paso.') : _go(_page + 1);
      case CookCommand.previous:
        _page == 0 ? _voice.say(_spoken(0)) : _go(_page - 1);
      case CookCommand.repeat:
        _voice.say(_spoken(_page));
      case CookCommand.startTimer:
        final minutes = widget.steps[_page].minutes;
        if (minutes == null) {
          _voice.say('Este paso no tiene tiempo.');
        } else {
          _startTimer(_page);
          _voice.say('Temporizador de $minutes minutos.');
        }
      case CookCommand.stopTimer:
        final step = _timerEnds.containsKey(_page)
            ? _page
            : (_timerEnds.isEmpty ? null : _timerEnds.keys.first);
        if (step != null) _stopTimer(step);
        _voice.say(step == null ? 'No hay temporizadores.' : 'Parado.');
      case CookCommand.ingredients:
        _voice.say(
          widget.ingredients.isEmpty
              ? 'No hay lista de ingredientes.'
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
                Text(
                  'Ingredientes',
                  style: TextStyle(
                    fontSize: 22,
                    letterSpacing: -0.4,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
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
          tooltip: 'Salir del modo cocina',
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
            IconButton(
              onPressed: _showIngredients,
              icon: const Icon(Icons.format_list_bulleted_rounded),
              tooltip: 'Ingredientes',
              color: AppColors.ink,
            ),
          IconButton(
            onPressed: _toggleVoice,
            tooltip: _voiceOn ? 'Quitar manos libres' : 'Manos libres',
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
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                for (var i = 0; i < _total; i++)
                  Expanded(
                    child: Container(
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i <= _page
                            ? AppColors.woodDark
                            : AppColors.wood.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_voiceOn)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                0,
              ),
              child: Text(
                'Di «siguiente», «anterior», «repite» o «temporizador»',
                style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
              ),
            ),
          if (_timerEnds.isNotEmpty) _timers(),
          Expanded(
            child: PageView.builder(
              controller: _pages,
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

  /// Todos los temporizadores en marcha (el que acaba antes, arriba); tocar
  /// uno lleva a su paso.
  Widget _timers() {
    final steps = _timerEnds.keys.toList()
      ..sort((a, b) => _timerEnds[a]!.compareTo(_timerEnds[b]!));
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
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => _go(s),
                  child: Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.lg),
                    child: Row(
                      children: [
                        Icon(Icons.timer_rounded, color: AppColors.cream),
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
                            widget.steps[s].note ?? 'Paso ${s + 1}',
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
                          child: const Text('Parar'),
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
    final minutes = step.minutes;
    final running = _timerEnds.containsKey(i);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PASO ${i + 1} DE $_total',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: AppColors.woodDark,
            ),
          ),
          if (step.note != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              step.note!,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.inkMuted,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(
            step.text,
            style: TextStyle(
              fontSize: 26,
              letterSpacing: -0.4,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          if (minutes != null) ...[
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: running ? null : () => _startTimer(i),
              icon: const Icon(Icons.timer_outlined),
              label: Text(
                running
                    ? 'Temporizador en marcha'
                    : 'Temporizador $minutes min',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: BorderSide(color: AppColors.ink, width: 1.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          if (i < _total - 1) ...[
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Luego',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.steps[i + 1].text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, color: AppColors.inkMuted),
            ),
          ],
        ],
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
                    shape: const CircleBorder(),
                    side: BorderSide(color: AppColors.ink, width: 1.5),
                  ),
                  child: const Icon(Icons.arrow_back_rounded),
                ),
              ),
            if (_page > 0) const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SizedBox(
                height: 60,
                child: FilledButton(
                  onPressed: _isLast
                      ? () => Navigator.of(context).pop(true)
                      : () => _go(_page + 1),
                  style: FilledButton.styleFrom(
                    backgroundColor: _isLast ? AppColors.sage : AppColors.ink,
                    foregroundColor: _isLast ? Colors.white : AppColors.cream,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: Text(_isLast ? 'Listo' : 'Siguiente paso'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
