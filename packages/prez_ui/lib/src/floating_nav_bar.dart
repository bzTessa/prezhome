import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Una pestaña de [FloatingNavBar].
@immutable
class FloatingNavItem {
  const FloatingNavItem({
    required this.icon,
    required this.label,
    this.selectedIcon,
  });

  final IconData icon;

  /// Icono cuando la pestaña está activa (si no se da, se usa [icon]).
  final IconData? selectedIcon;

  final String label;
}

/// Botón circular de acción rápida que acompaña a la barra (p. ej. "+").
@immutable
class FloatingNavAction {
  const FloatingNavAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
}

/// Barra de navegación inferior flotante en forma de píldora.
///
/// - Las pestañas inactivas muestran solo su icono.
/// - La activa se expande (animada) en una cápsula tintada con icono + texto.
/// - [action], si se da, es un botón circular aparte a la derecha.
/// - Deslizar el dedo a lo largo de la barra va cambiando de pestaña.
///
/// Los colores son opcionales: por defecto salen del [ColorScheme] del tema.
/// Pensada para colocarse en `Scaffold.bottomNavigationBar` dentro de un
/// `SafeArea` con margen lateral.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.action,
    this.height = 64,
    this.backgroundColor,
    this.indicatorColor,
    this.selectedColor,
    this.unselectedColor,
    this.actionColor,
    this.actionForegroundColor,
    this.shadow,
    this.border,
    this.duration = const Duration(milliseconds: 260),
    this.curve = Curves.easeOutCubic,
  }) : assert(items.length >= 2),
       assert(selectedIndex >= 0 && selectedIndex < items.length);

  final List<FloatingNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final FloatingNavAction? action;

  /// Alto de la píldora (y diámetro del botón de acción).
  final double height;

  final Color? backgroundColor;
  final Color? indicatorColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? actionColor;
  final Color? actionForegroundColor;

  /// Sombra de la píldora y del botón. Por defecto, una sombra suave.
  final List<BoxShadow>? shadow;

  /// Borde de la píldora y del botón (por defecto, ninguno).
  final BoxBorder? border;

  final Duration duration;
  final Curve curve;

  static const double _padding = 6;

  static const List<BoxShadow> _defaultShadow = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 18, offset: Offset(0, 6)),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shadows = shadow ?? _defaultShadow;
    final radius = BorderRadius.circular(height / 2);
    Widget pill = Container(
      height: height,
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: backgroundColor ?? scheme.surface,
        borderRadius: radius,
        border: border,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Las inactivas tienen un ancho fijo (como mucho 56); la activa se
          // queda con el resto. Animar el ancho da el efecto de "expandirse".
          final n = items.length;
          final inactive = math.min(56.0, constraints.maxWidth / (n + 1.6));
          final active = constraints.maxWidth - inactive * (n - 1);
          // Al deslizar, la barra se reparte en tramos iguales: el tramo bajo
          // el dedo es la pestaña elegida.
          void scrub(double dx) {
            final i = (dx / constraints.maxWidth * n).floor().clamp(0, n - 1);
            if (i == selectedIndex) return;
            HapticFeedback.selectionClick();
            onSelected(i);
          }

          final row = Row(
            children: [
              for (var i = 0; i < n; i++)
                AnimatedContainer(
                  duration: duration,
                  curve: curve,
                  width: i == selectedIndex ? active : inactive,
                  child: _NavItem(
                    item: items[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                    indicatorColor: indicatorColor ?? scheme.secondaryContainer,
                    selectedColor: selectedColor ?? scheme.onSecondaryContainer,
                    unselectedColor: unselectedColor ?? scheme.onSurfaceVariant,
                    duration: duration,
                    curve: curve,
                  ),
                ),
            ],
          );
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (d) => scrub(d.localPosition.dx),
            onHorizontalDragUpdate: (d) => scrub(d.localPosition.dx),
            child: row,
          );
        },
      ),
    );

    pill = DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: shadows),
      child: pill,
    );

    final a = action;
    if (a == null) return pill;
    return Row(
      children: [
        Expanded(child: pill),
        const SizedBox(width: 12),
        _ActionButton(
          action: a,
          size: height,
          color: actionColor ?? scheme.primary,
          foregroundColor: actionForegroundColor ?? scheme.onPrimary,
          shadow: shadows,
          border: border,
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.indicatorColor,
    required this.selectedColor,
    required this.unselectedColor,
    required this.duration,
    required this.curve,
  });

  final FloatingNavItem item;
  final bool selected;
  final VoidCallback onTap;
  final Color indicatorColor;
  final Color selectedColor;
  final Color unselectedColor;
  final Duration duration;
  final Curve curve;

  /// Ancho mínimo para mostrar el texto junto al icono sin desbordar.
  static const double _minWidthForLabel = 76;

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : unselectedColor;
    final icon = Icon(
      selected ? (item.selectedIcon ?? item.icon) : item.icon,
      color: color,
      size: 24,
    );
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final showLabel = selected && constraints.maxWidth >= _minWidthForLabel;
        if (!showLabel) return Center(child: icon);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    final tile = Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: AnimatedContainer(
            duration: duration,
            curve: curve,
            decoration: ShapeDecoration(
              color: selected ? indicatorColor : indicatorColor.withAlpha(0),
              shape: const StadiumBorder(),
            ),
            child: content,
          ),
        ),
      ),
    );
    // La activa ya muestra su texto; las demás lo ofrecen como tooltip.
    return selected ? tile : Tooltip(message: item.label, child: tile);
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.size,
    required this.color,
    required this.foregroundColor,
    required this.shadow,
    this.border,
  });

  final FloatingNavAction action;
  final double size;
  final Color color;
  final Color foregroundColor;
  final List<BoxShadow> shadow;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: action.tooltip,
      child: Semantics(
        button: true,
        label: action.tooltip,
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: shadow,
            border: border,
          ),
          child: Material(
            color: color,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: action.onPressed,
              child: SizedBox.square(
                dimension: size,
                child: Icon(action.icon, color: foregroundColor, size: 28),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
