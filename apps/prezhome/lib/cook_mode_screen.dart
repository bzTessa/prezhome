import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/app_theme.dart';
import 'utils/recipe_steps.dart';

/// Modo cocina: un paso por pantalla con letra grande, para seguir la receta
/// con las manos ocupadas. Se pasa de paso deslizando o con los botones
/// grandes de abajo. Si el paso menciona un tiempo, ofrece un temporizador.
class CookModeScreen extends StatefulWidget {
  const CookModeScreen({
    super.key,
    required this.title,
    required this.steps,
    required this.ingredients,
    this.initialStep = 0,
  });

  final String title;
  final List<String> steps;

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

  Timer? _timer;
  int? _timerStep;
  Duration _left = Duration.zero;

  int get _total => widget.steps.length;
  bool get _isLast => _page >= _total - 1;

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  void _go(int page) {
    _pages.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _startTimer(int step, int minutes) {
    _timer?.cancel();
    setState(() {
      _timerStep = step;
      _left = Duration(minutes: minutes);
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      final next = _left - const Duration(seconds: 1);
      if (next <= Duration.zero) {
        t.cancel();
        setState(() {
          _left = Duration.zero;
          _timerStep = null;
        });
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.alert);
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Tiempo'),
            content: Text('Ha terminado el temporizador del paso ${step + 1}.'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Vale'),
              ),
            ],
          ),
        );
      } else {
        setState(() => _left = next);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _timerStep = null);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

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
            TextButton.icon(
              onPressed: _showIngredients,
              icon: const Icon(Icons.format_list_bulleted_rounded),
              label: const Text('Ingredientes'),
              style: TextButton.styleFrom(foregroundColor: AppColors.ink),
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
          if (_timerStep != null) _timerBanner(),
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: _total,
              onPageChanged: (p) => setState(() => _page = p),
              itemBuilder: (_, i) => _stepPage(i),
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _timerBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_rounded, color: AppColors.cream),
          const SizedBox(width: AppSpacing.sm),
          Text(
            _fmt(_left),
            style: TextStyle(
              color: AppColors.cream,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'paso ${_timerStep! + 1}',
            style: TextStyle(color: AppColors.cream.withValues(alpha: 0.7)),
          ),
          const Spacer(),
          TextButton(
            onPressed: _stopTimer,
            style: TextButton.styleFrom(foregroundColor: AppColors.cream),
            child: const Text('Parar'),
          ),
        ],
      ),
    );
  }

  Widget _stepPage(int i) {
    final step = widget.steps[i];
    final minutes = stepTimerMinutes(step);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
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
          const SizedBox(height: AppSpacing.lg),
          Text(
            step,
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
              onPressed: _timerStep == i ? null : () => _startTimer(i, minutes),
              icon: const Icon(Icons.timer_outlined),
              label: Text(
                _timerStep == i
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
