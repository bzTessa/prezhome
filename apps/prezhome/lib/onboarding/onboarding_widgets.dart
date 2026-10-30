import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../widgets/tactile_button.dart';
import '../l10n/l10n.dart';

/// Piezas visuales del cuestionario inicial.

/// Botón del cuestionario: el principal es el [TactileButton] terracota de la
/// app; el secundario, una píldora de papel con trazo carbón a juego.
class OnboardingButton extends StatelessWidget {
  const OnboardingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    if (!outlined) {
      return SizedBox(
        width: double.infinity,
        child: TactileButton(label: label, onPressed: onPressed),
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        side: BorderSide(color: AppColors.stroke, width: 1.5),
        textStyle: AppTextStyles.title,
      ),
      child: Text(label),
    );
  }
}

/// Barra de progreso por pasos (un segmento por pregunta).
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.step, required this.total});

  /// Paso actual, empezando en 1.
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= total; i++) ...[
          if (i > 1) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: AppMotion.base,
              height: 5,
              decoration: BoxDecoration(
                color: i <= step
                    ? AppColors.woodDark
                    : AppColors.wood.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Estructura de cada pregunta: progreso, título, subtítulo, contenido y
/// botón de continuar abajo.
class QuestionScaffold extends StatelessWidget {
  const QuestionScaffold({
    super.key,
    required this.section,
    required this.step,
    required this.total,
    required this.title,
    required this.child,
    required this.onContinue,
    required this.onBack,
    this.subtitle,
    this.continueLabel,
    this.illustration,
  });

  final String section;
  final int step;
  final int total;
  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onContinue;
  final VoidCallback onBack;
  final String? continueLabel;

  /// Dibujo opcional encima de la pregunta (assets/images/onb_*.png).
  final String? illustration;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: context.l.back,
                ),
                Text(
                  section,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StepProgress(step: step, total: total),
            SizedBox(height: illustration == null ? 32 : 12),
            if (illustration != null) ...[
              Image.asset(illustration!, height: 110),
              const SizedBox(height: 12),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                letterSpacing: -0.6,
                fontWeight: FontWeight.w800,
                height: 1.15,
                color: AppColors.ink,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Expanded(child: SingleChildScrollView(child: child)),
            const SizedBox(height: 12),
            OnboardingButton(
              label: continueLabel ?? context.l.continueLabel,
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}

/// Opción grande con icono de color, título, subtítulo y marca de elegida.
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.14)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: selected
                      ? color
                      : AppColors.wood.withValues(alpha: 0.4),
                  width: selected ? 2 : 1,
                ),
                boxShadow: selected ? null : AppElevation.level1,
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: AppMotion.fast,
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: selected ? color : color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      color: selected ? Colors.white : color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  AnimatedOpacity(
                    duration: AppMotion.fast,
                    opacity: selected ? 1 : 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
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

/// Barra de 10 segmentos para la carga mental (resultado del cuestionario).
class LoadMeter extends StatelessWidget {
  const LoadMeter({
    super.key,
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.color,
  });

  final String label;

  /// De 1 a 10.
  final int value;
  final String valueLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.ink,
                ),
              ),
            ),
            Text(
              valueLabel,
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 1; i <= 10; i++) ...[
              if (i > 1) const SizedBox(width: 5),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: i <= value ? 1 : 0),
                  duration: Duration(milliseconds: 250 + i * 60),
                  builder: (context, t, _) => Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        AppColors.wood.withValues(alpha: 0.3),
                        color,
                        t,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
