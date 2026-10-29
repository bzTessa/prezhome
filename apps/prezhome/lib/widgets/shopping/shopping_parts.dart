import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../utils/shopping_display.dart';
import '../animations/animated_counter.dart';
import '../animations/press_scale.dart';
import '../animations/spring_value.dart';
import '../miau_character.dart';
import '../../utils/money.dart';

/// Piezas visuales de la lista de la compra. Sin acceso a datos: reciben lo
/// que pintan y callbacks, para poder probarlas y previsualizarlas aparte.

/// Cabecera táctil: Miau de compras, lista activa (toca para cambiar),
/// progreso del carro con muelle y coste estimado animado.
class ShoppingSummaryHeader extends StatelessWidget {
  const ShoppingSummaryHeader({
    super.key,
    required this.listName,
    required this.pending,
    required this.done,
    required this.onTapList,
    required this.onGenerate,
    required this.onOptions,
    this.generating = false,
    this.estimate,
    this.storeLabel,
    this.onTapStore,
  });

  final String listName;
  final int pending;
  final int done;
  final VoidCallback onTapList;
  final VoidCallback onGenerate;
  final VoidCallback onOptions;
  final bool generating;

  /// Coste estimado de lo pendiente en euros, o null si no se conoce.
  final double? estimate;

  /// Súper principal ("Mercadona") o null si no hay; con [onTapStore] se
  /// muestra un selector debajo del nombre de la lista.
  final String? storeLabel;
  final VoidCallback? onTapStore;

  @override
  Widget build(BuildContext context) {
    final total = pending + done;
    final progress = total == 0 ? 0.0 : done / total;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 14),
      decoration: AppTheme.tactileDecoration(radius: AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MiauCharacter(
                mood: MiauMood.shopping,
                size: 56,
                float: false,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: onTapList,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                listName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 20,
                                  letterSpacing: -0.4,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.expand_more_rounded,
                              color: AppColors.inkMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (onTapStore != null)
                      TextButton.icon(
                        onPressed: onTapStore,
                        icon: const Icon(Icons.storefront_outlined, size: 18),
                        label: Text(storeLabel ?? 'Elegir supermercado'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.woodDark,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Añadir lo del plan de la semana',
                onPressed: generating ? null : onGenerate,
                icon: generating
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.event_note_rounded),
                color: AppColors.woodDark,
              ),
              IconButton(
                tooltip: 'Opciones de la lista',
                onPressed: onOptions,
                icon: const Icon(Icons.tune_rounded),
                color: AppColors.woodDark,
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      pending == 0
                          ? 'Todo en el carro'
                          : '$pending por comprar · $done en el carro',
                      style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
                    ),
                  ),
                  if (estimate != null)
                    AnimatedCounter(
                      value: estimate!,
                      formatter: (v) => '≈ ${money(v)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CartProgressBar(progress: progress),
            ),
          ],
        ],
      ),
    );
  }
}

/// Barra del carro: carril con borde de trazo y relleno verde que avanza
/// con un muelle sin rebote.
class CartProgressBar extends StatelessWidget {
  const CartProgressBar({super.key, required this.progress});

  /// De 0 a 1.
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      value: '${(progress * 100).round()} %',
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: AppColors.iconTile,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.stroke, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: SpringValue(
          value: progress,
          from: 0,
          builder: (context, v, _) => FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: v.clamp(0.0, 1.0),
            child: ColoredBox(color: AppColors.done),
          ),
        ),
      ),
    );
  }
}

/// Campo "Añadir producto" siempre visible. Envía el texto al pulsar Intro o
/// el botón, se vacía y mantiene el foco para seguir añadiendo.
class ShoppingQuickAddBar extends StatefulWidget {
  const ShoppingQuickAddBar({
    super.key,
    required this.onSubmit,
    required this.onMore,
    this.onSearch,
  });

  final ValueChanged<String> onSubmit;

  /// Busca el texto escrito entre los productos del súper (con foto).
  final ValueChanged<String>? onSearch;

  /// Abre el formulario completo (tipo, cantidad, unidad).
  final VoidCallback onMore;

  @override
  State<ShoppingQuickAddBar> createState() => _ShoppingQuickAddBarState();
}

class _ShoppingQuickAddBarState extends State<ShoppingQuickAddBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
    _controller.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.tactileDecoration(radius: AppRadius.md, shadow: 2),
      padding: const EdgeInsets.only(left: AppSpacing.md),
      child: Row(
        children: [
          Icon(Icons.add_rounded, color: AppColors.woodDark),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                hintText: 'Añadir producto',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (widget.onSearch != null)
            IconButton(
              tooltip: 'Buscar en el súper',
              onPressed: () {
                final text = _controller.text.trim();
                _controller.clear();
                widget.onSearch!(text);
              },
              icon: const Icon(Icons.storefront_rounded),
              color: AppColors.woodDark,
            ),
          IconButton(
            tooltip: 'Más opciones',
            onPressed: widget.onMore,
            icon: const Icon(Icons.more_horiz_rounded),
            color: AppColors.inkMuted,
          ),
        ],
      ),
    );
  }
}

/// Sección de la lista (un pasillo, "Por comprar" o "En el carrito"):
/// cabecera plegable con icono, nombre y pendientes, y debajo las tarjetas.
/// Cuando ya está todo marcado ([complete]) la cabecera lleva un check verde
/// y se atenúa.
class ShoppingSection extends StatelessWidget {
  const ShoppingSection({
    super.key,
    required this.title,
    required this.count,
    required this.expanded,
    required this.onToggle,
    required this.children,
    this.icon,
    this.iconColor,
    this.iconBackground,
    this.trailing,
    this.complete = false,
  });

  final String title;
  final int count;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackground;
  final bool complete;

  /// Acción opcional en la cabecera (p. ej. "Quitar comprados").
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedOpacity(
            opacity: complete ? 0.55 : 1,
            duration: AppMotion.normal,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    if (complete || icon != null) ...[
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: complete
                              ? AppColors.done
                              : iconBackground ?? AppColors.peachBg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.stroke,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          complete ? Icons.check_rounded : icon,
                          size: 15,
                          color: complete
                              ? AppColors.onBrand
                              : iconColor ?? AppColors.peach,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: complete
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.woodDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ?trailing,
                    AnimatedRotation(
                      turns: expanded ? 0 : -0.25,
                      duration: AppMotion.fast,
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 22,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: AppMotion.effectiveDuration(
              AppMotion.slow,
              reduceMotion: AppMotion.reduceMotionOf(context),
            ),
            curve: AppMotion.springCurve(AppMotion.fluidDefault),
            alignment: Alignment.topCenter,
            child: expanded
                ? Column(
                    children: [
                      for (var i = 0; i < children.length; i++)
                        Padding(
                          padding: EdgeInsets.only(top: i == 0 ? 2 : 8),
                          child: children[i],
                        ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Fila de un producto como tarjeta táctil: se marca tocando cualquier parte
/// (responde nada más poner el dedo), lleva el icono del producto en un hueco
/// crema y, si se puede, una pastilla para cambiar la cantidad. Mantener
/// pulsado abre las acciones.
class ShoppingItemTile extends StatelessWidget {
  const ShoppingItemTile({
    super.key,
    required this.name,
    required this.checked,
    required this.onToggle,
    this.onLongPress,
    this.quantityLabel,
    this.subtitle,
    this.leading,
    this.quantity,
    this.unit,
    this.onQuantityChanged,
  });

  final String name;
  final bool checked;
  final VoidCallback onToggle;
  final VoidCallback? onLongPress;
  final String? quantityLabel;
  final String? subtitle;

  /// Foto o icono del producto (va en el hueco de 42 × 42).
  final Widget? leading;

  /// Con [onQuantityChanged], la cantidad se cambia con − y + sin salir de
  /// la lista.
  final double? quantity;
  final String? unit;
  final ValueChanged<double>? onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final qty = quantityLabel?.trim() ?? '';
    return Semantics(
      checked: checked,
      label: name,
      child: PressScale(
        onTap: onToggle,
        onLongPress: onLongPress,
        pressedScale: 0.98,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          decoration: AppTheme.tactileDecoration(shadow: 2),
          child: SpringValue(
            value: checked ? 1 : 0,
            spring: AppMotion.fluidBouncy,
            builder: (context, t, _) {
              final f = t.clamp(0.0, 1.0);
              return Row(
                children: [
                  _CheckCircle(t: t),
                  const SizedBox(width: AppSpacing.md),
                  if (leading != null) ...[
                    Opacity(
                      opacity: 1 - 0.45 * f,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.iconTile,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.center,
                        child: leading,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: Opacity(
                      opacity: 1 - 0.45 * f,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              color: AppColors.ink,
                              // El tachado aparece con el muelle.
                              decoration: TextDecoration.lineThrough,
                              decorationThickness: 2,
                              decorationColor: AppColors.ink.withValues(
                                alpha: f,
                              ),
                            ),
                          ),
                          if (subtitle != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                subtitle!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (onQuantityChanged != null && !checked) ...[
                    const SizedBox(width: AppSpacing.sm),
                    QuantityStepper(
                      label: qty.isEmpty ? '1' : qty,
                      onMinus:
                          shoppingQtyNext(quantity, unit, up: false) == null
                          ? null
                          : () => onQuantityChanged!(
                              shoppingQtyNext(quantity, unit, up: false)!,
                            ),
                      onPlus: () => onQuantityChanged!(
                        shoppingQtyNext(quantity, unit, up: true)!,
                      ),
                    ),
                  ] else if (qty.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        qty,
                        style: TextStyle(
                          fontFeatures: const [FontFeature.tabularFigures()],
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: checked
                              ? AppColors.inkMuted
                              : AppColors.woodDark,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Círculo de 26 px que se rellena de verde con un rebote elástico. [t] va
/// de 0 (sin marcar) a 1 (marcado) y puede pasarse de 1 con el muelle.
class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final f = t.clamp(0.0, 1.0);
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.lerp(Colors.transparent, AppColors.done, f),
        border: Border.all(
          color: Color.lerp(AppColors.stroke, AppColors.done, f)!,
          width: 2,
        ),
      ),
      child: f == 0
          ? null
          : Transform.scale(
              scale: popScale(f, rest: 0.4, peak: 1.25),
              child: const Icon(
                Icons.check_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
    );
  }
}

/// Pastilla − cantidad + con borde de trazo. El número rueda en vertical:
/// entra por abajo al subir y por arriba al bajar.
class QuantityStepper extends StatefulWidget {
  const QuantityStepper({
    super.key,
    required this.label,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;

  /// null = no se puede bajar más.
  final VoidCallback? onMinus;
  final VoidCallback onPlus;

  @override
  State<QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper> {
  bool _up = true;

  Widget _button(IconData icon, String tooltip, VoidCallback? onTap, bool up) {
    return Semantics(
      button: true,
      label: tooltip,
      enabled: onTap != null,
      child: InkResponse(
        onTap: onTap == null
            ? null
            : () {
                setState(() => _up = up);
                onTap();
              },
        radius: 20,
        child: SizedBox(
          width: 34,
          height: 40,
          child: Icon(
            icon,
            size: 18,
            color: onTap == null ? AppColors.line : AppColors.ink,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduceMotionOf(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.stroke, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _button(Icons.remove_rounded, 'Menos', widget.onMinus, false),
          ClipRect(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 26),
              child: AnimatedSwitcher(
                duration: AppMotion.effectiveDuration(
                  AppMotion.normal,
                  reduceMotion: reduce,
                ),
                transitionBuilder: (child, anim) {
                  // Al subir, el nuevo entra por abajo y el viejo sale por
                  // arriba; al bajar, al revés.
                  final incoming = child.key == ValueKey(widget.label);
                  final dy = _up == incoming ? 0.8 : -0.8;
                  return SlideTransition(
                    position: Tween(
                      begin: Offset(0, dy),
                      end: Offset.zero,
                    ).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  );
                },
                child: Text(
                  widget.label,
                  key: ValueKey(widget.label),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
          _button(Icons.add_rounded, 'Más', widget.onPlus, true),
        ],
      ),
    );
  }
}

/// Chip de añadido rápido: al tocarlo hace un "pop" elástico y enseña un
/// check mientras [added] siga a true, para añadir varios seguidos.
class QuickAddChip extends StatelessWidget {
  const QuickAddChip({
    super.key,
    required this.label,
    required this.added,
    required this.onAdd,
  });

  final String label;
  final bool added;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: added ? '$label, añadido' : 'Añadir $label',
      excludeSemantics: true,
      child: PressScale(
        onTap: onAdd,
        child: SpringValue(
          value: added ? 1 : 0,
          spring: AppMotion.fluidBouncy,
          builder: (context, t, child) => Transform.scale(
            scale: added ? popScale(t.clamp(0.0, 1.0), peak: 1.15) : 1,
            child: child,
          ),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
            decoration: BoxDecoration(
              color: added ? AppColors.sageBg : AppColors.paper,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.stroke, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  added ? Icons.check_rounded : Icons.add_rounded,
                  size: 18,
                  color: added ? AppColors.done : AppColors.ink,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
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
