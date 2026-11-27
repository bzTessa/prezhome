import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'animations/press_scale.dart';

/// Botón principal del estilo táctil del logo: relleno de marca (terracota por
/// defecto), borde carbón de 2 px y sombra dura. Encoge al tocar.
class TactileButton extends StatelessWidget {
  const TactileButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fill = color ?? AppColors.terracotta;
    final fg = color == null
        ? AppColors.onTerracotta
        : (fill.computeLuminance() < 0.4
              ? AppColors.onTerracotta
              : AppColors.onBrand);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: PressScale(
        onTap: onPressed,
        pressedScale: 0.97,
        child: Opacity(
          opacity: onPressed == null ? 0.5 : 1,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: fill.withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: fg),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    // GoogleFonts para que cargue el peso 800 de verdad.
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: fg,
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
}
