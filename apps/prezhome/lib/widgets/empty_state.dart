import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_motion.dart';
import 'miau_character.dart';
import 'tactile_button.dart';

/// Pantalla vacía común: Miau, un título corto, una línea de apoyo y, si
/// procede, la acción que saca de ese vacío. Igual en toda la app.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.mood = MiauMood.curious,
    this.image,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String? message;
  final MiauMood mood;

  /// Ilustración propia de esta pantalla vacía (assets/images/vacio_*.png);
  /// si no hay, sale Miau con [mood].
  final String? image;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxxl,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (image != null)
              _Floating(child: Image.asset(image!, width: 160, height: 160))
            else
              MiauCharacter(mood: mood, size: 112, interactive: true),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.headline.copyWith(fontSize: 20),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMuted,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              TactileButton(
                label: actionLabel!,
                icon: actionIcon ?? Icons.add_rounded,
                onPressed: onAction,
              ),
            ],
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Flotación suave y continua (sube y baja unos píxeles). Quieta con
/// "reducir movimiento".
class _Floating extends StatefulWidget {
  const _Floating({required this.child});

  final Widget child;

  @override
  State<_Floating> createState() => _FloatingState();
}

class _FloatingState extends State<_Floating>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotionOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -6 * Curves.easeInOut.transform(_c.value)),
        child: child,
      ),
    );
  }
}
