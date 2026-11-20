import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../login_screen.dart';
import '../models/country.dart';
import '../models/onboarding_answers.dart';
import '../models/supermarket.dart';
import '../services/home_country.dart';
import '../services/offline_provider.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../utils/miau_mood_resolver.dart';
import '../widgets/animations/press_scale.dart';
import '../widgets/miau_character.dart';
import '../widgets/supermarket_badge.dart';
import 'onboarding_widgets.dart';

/// Primer arranque: bienvenida + cuestionario + perfil de hogar. Las
/// respuestas se guardan en el dispositivo y se aplican cuando el usuario ya
/// tiene hogar (ver `OnboardingApplier`).
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
  bool _goingForward = true;

  static const int _questions = 5;

  void _next() => setState(() {
    _goingForward = true;
    _page++;
  });

  void _back() => setState(() {
    _goingForward = false;
    _page = (_page - 1).clamp(0, _page);
  });

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
    final reduced = AppMotion.reduceMotionOf(context);
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: AnimatedSwitcher(
        duration: AppMotion.effectiveDuration(
          AppMotion.base,
          reduceMotion: reduced,
        ),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(
              begin: Offset(_goingForward ? 0.06 : -0.06, 0),
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
          catMood: onboardingCatMood(1),
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
          catMood: onboardingCatMood(2, hasSelection: _a.goals.isNotEmpty),
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
          catMood: onboardingCatMood(3),
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
          section: context.l.onbSectionKitchen,
          step: 4,
          total: _questions,
          title: context.l.onbFoodTitle,
          illustration: 'assets/images/onb_hogar.png',
          catMood: onboardingCatMood(4),
          subtitle: context.l.onbFoodHint,
          onBack: _back,
          onContinue: _next,
          continueLabel: _a.foodLimits.isEmpty
              ? context.l.onbFoodNone
              : context.l.onbContinueCount(_a.foodLimits.length),
          child: _FoodLimitsPicker(
            selected: _a.foodLimits,
            onChanged: (v) => setState(() => _a = _a.copyWith(foodLimits: v)),
          ),
        );
      case 5:
        final countryCode = _a.countryCode ?? HomeCountry.current.value.code;
        return QuestionScaffold(
          section: context.l.onbSectionShopping,
          step: 5,
          total: _questions,
          title: context.l.onbShopTitle,
          illustration: 'assets/images/onb_compra.png',
          catMood: onboardingCatMood(5),
          subtitle: context.l.onbShopHint,
          onBack: _back,
          onContinue: _next,
          continueLabel: _a.supermarkets.isEmpty
              ? context.l.onbSkipSeeHome
              : context.l.onbSeeHome,
          child: _SupermarketPicker(
            countryCode: countryCode,
            selected: _a.supermarkets,
            onCountryChanged: (c) => setState(
              () => _a = _a.copyWith(countryCode: c, supermarkets: const []),
            ),
            onChanged: (v) => setState(() => _a = _a.copyWith(supermarkets: v)),
          ),
        );
      default:
        return _ResultPage(
          answers: _a,
          onBack: _back,
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
    MiauMood? catMood,
  }) {
    return QuestionScaffold(
      illustration: illustration,
      catMood: catMood,
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
    HomeGoal.lote => AppColors.lilac,
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
  int _selected = 3;

  @override
  Widget build(BuildContext context) {
    final features = [
      (
        id: 'comidas',
        image: 'assets/images/onb_hogar.png',
        icon: Icons.restaurant_menu_rounded,
        bg: AppColors.terracottaBg,
        accent: AppColors.terracotta,
        mood: MiauMood.cooking,
      ),
      (
        id: 'compra',
        image: 'assets/images/onb_compra.png',
        icon: Icons.shopping_cart_rounded,
        bg: AppColors.sageBg,
        accent: AppColors.sage,
        mood: MiauMood.shopping,
      ),
      (
        id: 'despensa',
        image: 'assets/images/zona_nevera.png',
        icon: Icons.kitchen_rounded,
        bg: AppColors.peachBg,
        accent: AppColors.peach,
        mood: MiauMood.curious,
      ),
      (
        id: 'tareas',
        image: 'assets/images/onb_cabeza.png',
        icon: Icons.cleaning_services_rounded,
        bg: AppColors.frostBg,
        accent: AppColors.frost,
        mood: MiauMood.greeting,
      ),
    ];
    final current = features[_selected];
    final reduced = AppMotion.reduceMotionOf(context);
    return Stack(
      children: [
        // Halo suave que responde a la zona visual seleccionada.
        Positioned.fill(
          child: AnimatedContainer(
            duration: AppMotion.effectiveDuration(
              const Duration(milliseconds: 450),
              reduceMotion: reduced,
            ),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, 0.15),
                radius: 0.9,
                colors: [
                  current.accent.withValues(alpha: 0.18),
                  AppColors.cream.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Center(
                // En ordenador, columna de ancho de móvil en vez de botones
                // estirados de lado a lado.
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 520,
                    minHeight: (constraints.maxHeight - 32).clamp(0.0, 2000.0),
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const Spacer(),
                        MiauCharacter(
                          mood: current.mood,
                          size: 116,
                          interactive: true,
                        ),
                        Text(
                          'PrezHome',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.l.onbSlogan,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            color: AppColors.inkMuted,
                          ),
                        ),
                        const Spacer(),
                        // Composición fija 2x2 visual con ilustraciones, sin
                        // carruseles horizontales de deslizar.
                        Column(
                          children: [
                            Row(
                              children: [
                                for (var i = 0; i < 2; i++) ...[
                                  if (i > 0) const SizedBox(width: 10),
                                  Expanded(
                                    child: _IntroFeatureTile(
                                      image: features[i].image,
                                      fallbackIcon: features[i].icon,
                                      label: context.l.onbFeature(
                                        features[i].id,
                                      ),
                                      bg: features[i].bg,
                                      accent: features[i].accent,
                                      selected: _selected == i,
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() => _selected = i);
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                for (var i = 2; i < 4; i++) ...[
                                  if (i > 2) const SizedBox(width: 10),
                                  Expanded(
                                    child: _IntroFeatureTile(
                                      image: features[i].image,
                                      fallbackIcon: features[i].icon,
                                      label: context.l.onbFeature(
                                        features[i].id,
                                      ),
                                      bg: features[i].bg,
                                      accent: features[i].accent,
                                      selected: _selected == i,
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() => _selected = i);
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        const Spacer(flex: 2),
                        const SizedBox(height: 16),
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
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IntroFeatureTile extends StatelessWidget {
  const _IntroFeatureTile({
    required this.image,
    required this.fallbackIcon,
    required this.label,
    required this.bg,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String image;
  final IconData fallbackIcon;
  final String label;
  final Color bg;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduceMotionOf(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: PressScale(
        pressedScale: 0.97,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.effectiveDuration(
            AppMotion.fast,
            reduceMotion: reduced,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? bg : AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? accent : AppColors.cardEdge,
              width: selected ? 1.75 : 1,
            ),
            boxShadow: selected ? AppElevation.level1 : AppElevation.level0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                image,
                height: 44,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    Icon(fallbackIcon, size: 32, color: accent),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
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
    final reduced = AppMotion.reduceMotionOf(context);
    Widget round(IconData icon, VoidCallback? onTap, String tip) => IconButton(
      onPressed: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap();
            },
      tooltip: tip,
      iconSize: 30,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.card,
        disabledBackgroundColor: AppColors.card.withValues(alpha: 0.5),
        fixedSize: const Size(64, 64),
        side: BorderSide(color: AppColors.cardEdge),
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
                duration: AppMotion.effectiveDuration(
                  AppMotion.fast,
                  reduceMotion: reduced,
                ),
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
  const _SupermarketPicker({
    required this.countryCode,
    required this.selected,
    required this.onChanged,
    required this.onCountryChanged,
  });

  final String countryCode;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final ValueChanged<String> onCountryChanged;

  Future<void> _pickCountry(BuildContext context, Country active) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cream,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                context.l.onbPickCountry,
                style: AppTextStyles.headline,
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final c in Country.all)
                    ListTile(
                      leading: Text(
                        c.flag,
                        style: const TextStyle(fontSize: 22),
                      ),
                      title: Text(
                        c.name,
                        style: TextStyle(
                          fontWeight: c.code == active.code
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      trailing: c.code == active.code
                          ? Icon(Icons.check_rounded, color: AppColors.sage)
                          : null,
                      onTap: () => Navigator.pop(sheetCtx, c.code),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (chosen != null && chosen != active.code) {
      onCountryChanged(chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final country = Country.of(countryCode);
    final stores = Supermarket.forCountry(country.code);
    return Column(
      children: [
        Center(
          child: Semantics(
            button: true,
            label: '${context.l.onbCountryLabel}: ${country.name}',
            child: PressScale(
              pressedScale: 0.97,
              onTap: () => _pickCountry(context, country),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(color: AppColors.cardEdge),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(country.flag, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      country.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppColors.inkMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (final s in stores)
              _SuperChip(
                supermarket: s,
                order: selected.indexOf(s.key),
                onTap: () {
                  final next = [...selected];
                  if (!next.remove(s.key)) next.add(s.key);
                  onChanged(next);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _SuperChip extends StatelessWidget {
  const _SuperChip({
    required this.supermarket,
    required this.order,
    required this.onTap,
  });

  final Supermarket supermarket;

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
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: AppMotion.effectiveDuration(
            AppMotion.fast,
            reduceMotion: AppMotion.reduceMotionOf(context),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.sage : AppColors.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.sage : AppColors.cardEdge,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SupermarketBadge(supermarket: supermarket, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  supermarket.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.onTerracotta : AppColors.ink,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                Icon(
                  order == 0 ? Icons.star_rounded : Icons.check_rounded,
                  size: 16,
                  color: AppColors.onTerracotta,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Resultado -------------------------------------------------------------------

class _ResultPage extends StatelessWidget {
  const _ResultPage({
    required this.answers,
    required this.onBack,
    required this.onContinue,
  });

  final OnboardingAnswers answers;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  static String _loadLevel(int v) => v >= 7
      ? 'high'
      : v >= 4
      ? 'medium'
      : 'low';

  @override
  Widget build(BuildContext context) {
    final profile = answers.profile;
    final primaryStore = answers.supermarkets.isEmpty
        ? null
        : Supermarket.byKey(answers.supermarkets.first);
    final summaryPills = <String>[
      context.l.onbPeopleCount(answers.people),
      for (final g in answers.goals) context.l.goalLabel(g.id),
      if (answers.cooking != null) context.l.cookingLabel(answers.cooking!.id),
      if (primaryStore != null) primaryStore.label,
      if (answers.supermarkets.length > 1)
        '+${answers.supermarkets.length - 1}',
    ];

    // Con letra grande del sistema no cabe en pantalla: se desplaza en vez de
    // desbordarse, y los Spacer siguen centrando cuando sí cabe.
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 28),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: context.l.back,
                    ),
                  ),
                  const Spacer(),
                  const MiauCharacter(
                    mood: MiauMood.celebrating,
                    size: 108,
                    interactive: true,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
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
                  const SizedBox(height: 12),
                  Text(
                    context.l.onbProfileName(profile.kind),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 38,
                      letterSpacing: -0.6,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: AppTheme.surfaceDecoration(
                      radius: AppRadius.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.l.onbProfileDescription(profile.kind),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15.5,
                            height: 1.45,
                            color: AppColors.ink,
                          ),
                        ),
                        if (summaryPills.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Divider(height: 1, color: AppColors.line),
                          const SizedBox(height: 12),
                          Text(
                            context.l.onbSummaryTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final label in summaryPills)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.iconTile,
                                    borderRadius: AppRadius.pillRadius,
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  LoadMeter(
                    label: context.l.onbLoadToday,
                    value: profile.loadToday,
                    valueLabel: context.l.onbLoad(
                      _loadLevel(profile.loadToday),
                    ),
                    color: AppColors.terracotta,
                  ),
                  const SizedBox(height: 16),
                  LoadMeter(
                    label: context.l.onbLoadWithApp,
                    value: profile.loadWithApp,
                    valueLabel: context.l.onbLoad(
                      _loadLevel(profile.loadWithApp),
                    ),
                    color: AppColors.sage,
                  ),
                  const Spacer(flex: 2),
                  const SizedBox(height: 16),
                  OnboardingButton(
                    label: context.l.onbCreateAccount,
                    onPressed: onContinue,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Alergias de casa y, si acaso, dieta vegetariana o vegana. El plan nunca
/// propondrá lo que choque con esto.
class _FoodLimitsPicker extends StatelessWidget {
  const _FoodLimitsPicker({required this.selected, required this.onChanged});

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void _toggle(String key) {
    HapticFeedback.selectionClick();
    final next = {...selected};
    if (!next.remove(key)) {
      next.add(key);
      // Vegana ya incluye vegetariana: solo una de las dos.
      if (key == 'vegana') next.remove('vegetariana');
      if (key == 'vegetariana') next.remove('vegana');
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    Widget chip(String key, String label) {
      final on = selected.contains(key);
      return Semantics(
        button: true,
        selected: on,
        child: Material(
          color: on ? AppColors.terracotta : AppColors.card,
          shape: StadiumBorder(
            side: BorderSide(
              color: on ? AppColors.terracotta : AppColors.cardEdge,
            ),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => _toggle(key),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (on) ...[
                    Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: AppColors.onTerracotta,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: on ? AppColors.onTerracotta : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l.onbFoodAllergies,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final a in OnboardingAnswers.allergyOptions)
              chip(a, _cap(context.l.pwAllergy(a.replaceAll(' ', '')))),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          context.l.onbFoodDiet,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            chip('vegetariana', context.l.onbFoodVeg),
            chip('vegana', context.l.onbFoodVegan),
          ],
        ),
      ],
    );
  }
}
