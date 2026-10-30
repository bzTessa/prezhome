import 'dart:async';

import 'package:flutter/material.dart';

import '../login_screen.dart';
import '../models/onboarding_answers.dart';
import '../models/supermarket.dart';
import '../services/home_country.dart';
import '../services/offline_provider.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../widgets/miau_character.dart';
import 'onboarding_widgets.dart';
import '../l10n/l10n.dart';

/// Primer arranque: bienvenida + cuestionario + perfil de hogar. Las
/// respuestas se guardan en el dispositivo y se aplican cuando el usuario ya
/// tiene hogar (ver `OnboardingApplier`). Sustituye a las diapositivas de
/// bienvenida.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    @visibleForTesting this.initialPage = 0,
    @visibleForTesting this.initialAnswers = const OnboardingAnswers(),
  });

  /// Solo para tests y vistas previas: abrir en un paso concreto.
  final int initialPage;
  final OnboardingAnswers initialAnswers;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  /// 0 = bienvenida; 1..[_questions] = preguntas; [_questions]+1 = resultado.
  late int _page = widget.initialPage;
  late OnboardingAnswers _a = widget.initialAnswers;

  static const int _questions = 4;

  void _next() => setState(() => _page++);
  void _back() => setState(() => _page = (_page - 1).clamp(0, _page));

  Future<void> _finish({required bool signUp}) async {
    if (signUp) {
      try {
        await OfflineProvider.instance.store.write(
          OnboardingAnswers.storageKey,
          _a.encode(),
        );
      } catch (_) {
        // Sin guardado local la app funciona igual, solo sin personalizar.
      }
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginScreen(startInSignUp: signUp)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: AnimatedSwitcher(
        duration: AppMotion.base,
        switchInCurve: Curves.easeOut,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(_page), child: _buildPage()),
      ),
    );
  }

  Widget _buildPage() {
    switch (_page) {
      case 0:
        return _IntroPage(
          onStart: _next,
          onLogin: () => _finish(signUp: false),
        );
      case 1:
        return QuestionScaffold(
          section: context.l.onbSectionHome,
          step: 1,
          total: _questions,
          title: context.l.onbPeopleTitle,
          illustration: 'assets/images/onb_personas.png',
          subtitle: context.l.onbPeopleHint,
          onBack: _back,
          onContinue: _next,
          child: _PeoplePicker(
            value: _a.people,
            onChanged: (v) => setState(() => _a = _a.copyWith(people: v)),
          ),
        );
      case 2:
        return QuestionScaffold(
          section: context.l.onbSectionGoals,
          step: 2,
          total: _questions,
          title: context.l.onbGoalsTitle,
          illustration: 'assets/images/onb_cabeza.png',
          subtitle: context.l.onbGoalsHint,
          onBack: _back,
          onContinue: _a.goals.isEmpty ? null : _next,
          continueLabel: _a.goals.isEmpty
              ? context.l.onbPickOne
              : context.l.onbContinueCount(_a.goals.length),
          child: Column(
            children: [
              for (final g in HomeGoal.values)
                OptionCard(
                  icon: _goalIcon(g),
                  color: _goalColor(g),
                  title: context.l.goalLabel(g.id),
                  subtitle: context.l.goalHint(g.id),
                  selected: _a.goals.contains(g),
                  onTap: () => setState(() {
                    final next = {..._a.goals};
                    if (!next.remove(g)) next.add(g);
                    _a = _a.copyWith(goals: next);
                  }),
                ),
            ],
          ),
        );
      case 3:
        return _single<CookingHabit>(
          section: context.l.onbSectionKitchen,
          title: context.l.onbCookingTitle,
          subtitle: context.l.onbCookingHint,
          values: CookingHabit.values,
          selected: _a.cooking,
          label: (v) => context.l.cookingLabel(v.id),
          sub: (v) => context.l.cookingHint(v.id),
          icon: (v) => switch (v) {
            CookingHabit.diario => Icons.today_rounded,
            CookingHabit.lote => Icons.inventory_2_rounded,
            CookingHabit.mixto => Icons.sync_rounded,
            CookingHabit.poco => Icons.takeout_dining_rounded,
          },
          color: (v) => switch (v) {
            CookingHabit.diario => AppColors.terracotta,
            CookingHabit.lote => AppColors.frost,
            CookingHabit.mixto => AppColors.sage,
            CookingHabit.poco => AppColors.peach,
          },
          onSelect: (v) => _a = _a.copyWith(cooking: v),
        );
      case 4:
        return QuestionScaffold(
          section: context.l.onbSectionShopping,
          step: 4,
          total: _questions,
          title: context.l.onbShopTitle,
          illustration: 'assets/images/onb_compra.png',
          subtitle: context.l.onbShopHint,
          onBack: _back,
          onContinue: _next,
          continueLabel: _a.supermarkets.isEmpty
              ? context.l.onbSkipSeeHome
              : context.l.onbSeeHome,
          child: _SupermarketPicker(
            selected: _a.supermarkets,
            onChanged: (v) => setState(() => _a = _a.copyWith(supermarkets: v)),
          ),
        );
      default:
        return _ResultPage(
          profile: _a.profile,
          onContinue: () => _finish(signUp: true),
        );
    }
  }

  /// Pregunta de una sola respuesta.
  Widget _single<T>({
    required String section,
    required String title,
    String? subtitle,
    required List<T> values,
    required T? selected,
    required String Function(T) label,
    required String Function(T) sub,
    required IconData Function(T) icon,
    required Color Function(T) color,
    required void Function(T) onSelect,
    String? illustration,
  }) {
    return QuestionScaffold(
      illustration: illustration,
      section: section,
      step: _page,
      total: _questions,
      title: title,
      subtitle: subtitle,
      onBack: _back,
      onContinue: selected == null ? null : _next,
      child: Column(
        children: [
          for (final v in values)
            OptionCard(
              icon: icon(v),
              color: color(v),
              title: label(v),
              subtitle: sub(v),
              selected: v == selected,
              onTap: () => setState(() => onSelect(v)),
            ),
        ],
      ),
    );
  }

  static IconData _goalIcon(HomeGoal g) => switch (g) {
    HomeGoal.comidas => Icons.restaurant_menu_rounded,
    HomeGoal.compra => Icons.shopping_cart_rounded,
    HomeGoal.despensa => Icons.kitchen_rounded,
    HomeGoal.tareas => Icons.cleaning_services_rounded,
    HomeGoal.lote => Icons.inventory_2_rounded,
    HomeGoal.gastos => Icons.savings_rounded,
  };

  static Color _goalColor(HomeGoal g) => switch (g) {
    HomeGoal.comidas => AppColors.terracotta,
    HomeGoal.compra => AppColors.sage,
    HomeGoal.despensa => AppColors.peach,
    HomeGoal.tareas => AppColors.frost,
    HomeGoal.lote => const Color(0xFF7A5C9E),
    HomeGoal.gastos => AppColors.woodDark,
  };
}

// ---- Bienvenida ---------------------------------------------------------------

class _IntroPage extends StatefulWidget {
  const _IntroPage({required this.onStart, required this.onLogin});

  final VoidCallback onStart;
  final VoidCallback onLogin;

  @override
  State<_IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<_IntroPage> {
  static final _features = [
    (Icons.shopping_cart_rounded, 'compra', AppColors.sage),
    (Icons.restaurant_menu_rounded, 'comidas', AppColors.terracotta),
    (Icons.kitchen_rounded, 'despensa', AppColors.peach),
    (Icons.cleaning_services_rounded, 'tareas', AppColors.frost),
    (Icons.savings_rounded, 'gastos', AppColors.woodDark),
  ];

  final _controller = PageController(viewportFraction: 0.37, initialPage: 1000);
  Timer? _timer;
  int _current = 1000;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!_controller.hasClients) return;
      _controller.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _features[_current % _features.length];
    return Stack(
      children: [
        // Halo de color que cambia con la función destacada.
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, 0.25),
                radius: 0.9,
                colors: [
                  current.$3.withValues(alpha: 0.22),
                  AppColors.cream.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              children: [
                const Spacer(flex: 3),
                const MiauCharacter(mood: MiauMood.greeting, size: 120),
                Text(
                  'PrezHome',
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l.onbSlogan,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: AppColors.inkMuted),
                ),
                const Spacer(),
                // A todo el ancho y sin recorte: si no, las sombras de las
                // tarjetas quedan cortadas en línea recta.
                SizedBox(
                  height: 190,
                  child: OverflowBox(
                    maxWidth: MediaQuery.sizeOf(context).width,
                    child: PageView.builder(
                      controller: _controller,
                      clipBehavior: Clip.none,
                      onPageChanged: (i) => setState(() => _current = i),
                      itemBuilder: (context, i) {
                        final f = _features[i % _features.length];
                        final active = i == _current;
                        return AnimatedScale(
                          duration: const Duration(milliseconds: 400),
                          scale: active ? 1 : 0.82,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 400),
                            opacity: active ? 1 : 0.45,
                            child: _FeaturePill(
                              icon: f.$1,
                              label: context.l.onbFeature(f.$2),
                              color: f.$3,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                OnboardingButton(
                  label: context.l.onbStart,
                  onPressed: widget.onStart,
                ),
                const SizedBox(height: 12),
                OnboardingButton(
                  label: context.l.onbHaveAccount,
                  outlined: true,
                  onPressed: widget.onLogin,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(80),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Personas ------------------------------------------------------------------

class _PeoplePicker extends StatelessWidget {
  const _PeoplePicker({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget round(IconData icon, VoidCallback? onTap, String tip) => IconButton(
      onPressed: onTap,
      tooltip: tip,
      iconSize: 30,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.card,
        disabledBackgroundColor: AppColors.card.withValues(alpha: 0.5),
        fixedSize: const Size(64, 64),
        side: BorderSide(color: AppColors.wood.withValues(alpha: 0.6)),
      ),
      icon: Icon(icon, color: AppColors.ink),
    );

    return Column(
      children: [
        const SizedBox(height: 24),
        // Se reduce en móviles estrechos en lugar de desbordar.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              round(
                Icons.remove_rounded,
                value > 1 ? () => onChanged(value - 1) : null,
                context.l.onbOneLess,
              ),
              const SizedBox(width: 24),
              AnimatedSwitcher(
                duration: AppMotion.fast,
                transitionBuilder: (c, a) =>
                    ScaleTransition(scale: a, child: c),
                child: Container(
                  key: ValueKey(value),
                  width: 130,
                  height: 130,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.woodDark.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.woodDark, width: 3),
                  ),
                  child: Text(
                    value >= 8 ? '8+' : '$value',
                    style: TextStyle(
                      fontSize: 56,
                      letterSpacing: -0.6,
                      fontWeight: FontWeight.w900,
                      color: AppColors.woodDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              round(
                Icons.add_rounded,
                value < 8 ? () => onChanged(value + 1) : null,
                context.l.onbOneMore,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          children: [
            for (var i = 0; i < value.clamp(1, 8); i++)
              Icon(
                Icons.person_rounded,
                size: 34,
                color: [
                  AppColors.terracotta,
                  AppColors.sage,
                  AppColors.frost,
                  AppColors.peach,
                ][i % 4],
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          context.l.onbPeopleCount(value),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.inkMuted,
          ),
        ),
      ],
    );
  }
}

// ---- Supermercados -----------------------------------------------------------

class _SupermarketPicker extends StatelessWidget {
  const _SupermarketPicker({required this.selected, required this.onChanged});

  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (final s in Supermarket.forCountry(HomeCountry.current.value.code))
          _SuperChip(
            label: s.label,
            order: selected.indexOf(s.key),
            onTap: () {
              final next = [...selected];
              if (!next.remove(s.key)) next.add(s.key);
              onChanged(next);
            },
          ),
      ],
    );
  }
}

class _SuperChip extends StatelessWidget {
  const _SuperChip({
    required this.label,
    required this.order,
    required this.onTap,
  });

  final String label;

  /// Posición en la selección (0 = principal) o -1 si no está elegido.
  final int order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = order >= 0;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.sage : AppColors.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.sage
                  : AppColors.wood.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(
                  order == 0 ? Icons.star_rounded : Icons.check_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Resultado -------------------------------------------------------------------

class _ResultPage extends StatelessWidget {
  const _ResultPage({required this.profile, required this.onContinue});

  final HouseholdProfile profile;
  final VoidCallback onContinue;

  static String _loadLevel(int v) => v >= 7
      ? 'high'
      : v >= 4
      ? 'medium'
      : 'low';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.woodDark.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                context.l.onbProfileBadge,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.woodDark,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              context.l.onbProfileName(profile.kind),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 40,
                letterSpacing: -0.6,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.surfaceDecoration(radius: AppRadius.lg),
              child: Text(
                context.l.onbProfileDescription(profile.kind),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.45,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 28),
            LoadMeter(
              label: context.l.onbLoadToday,
              value: profile.loadToday,
              valueLabel: context.l.onbLoad(_loadLevel(profile.loadToday)),
              color: AppColors.terracotta,
            ),
            const SizedBox(height: 18),
            LoadMeter(
              label: context.l.onbLoadWithApp,
              value: profile.loadWithApp,
              valueLabel: context.l.onbLoad(_loadLevel(profile.loadWithApp)),
              color: AppColors.sage,
            ),
            const Spacer(flex: 2),
            OnboardingButton(
              label: context.l.onbCreateAccount,
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}
