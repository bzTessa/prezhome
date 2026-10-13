import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';

/// Piezas visuales de la lista de la compra. Sin acceso a datos: reciben lo
/// que pintan y callbacks, para poder probarlas y previsualizarlas aparte.

/// Cabecera: lista activa (toca para cambiar), progreso y coste estimado.
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

  /// Coste estimado ya formateado ("≈ 34,20 €"), o null si no se conoce.
  final String? estimate;

  /// Súper principal ("Mercadona") o null si no hay; con [onTapStore] se
  /// muestra un selector debajo del nombre de la lista.
  final String? storeLabel;
  final VoidCallback? onTapStore;

  @override
  Widget build(BuildContext context) {
    final total = pending + done;
    final progress = total == 0 ? 0.0 : done / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
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
                              fontSize: 22,
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
        if (onTapStore != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onTapStore,
              icon: const Icon(Icons.storefront_outlined, size: 18),
              label: Text(storeLabel ?? 'Elegir supermercado'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.woodDark,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        if (total > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  pending == 0
                      ? 'Todo en el carro'
                      : '$pending por comprar · $done en el carro',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
              if (estimate != null)
                Text(
                  estimate!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.wood.withValues(alpha: 0.35),
              valueColor: AlwaysStoppedAnimation(AppColors.sage),
            ),
          ),
        ],
      ],
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
      decoration: AppTheme.surfaceDecoration(radius: AppRadius.md),
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

/// Sección de la lista (un pasillo, "Por comprar" o "En el carro"): cabecera
/// ligera plegable y, debajo, una única tarjeta con las filas.
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
  });

  final String title;
  final int count;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackground;

  /// Acción opcional en la cabecera (p. ej. "Quitar comprados").
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: iconBackground ?? AppColors.peachBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 15,
                        color: iconColor ?? AppColors.peach,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            title.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: AppColors.inkMuted,
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
          AnimatedSize(
            duration: AppMotion.fast,
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Container(
                    decoration: AppTheme.surfaceDecoration(
                      radius: AppRadius.md,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0; i < children.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              thickness: 1,
                              indent: 52,
                              color: AppColors.cream,
                            ),
                          children[i],
                        ],
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Fila de un producto: círculo para marcar, (foto opcional), nombre y
/// cantidad. Tocar marca/desmarca; mantener pulsado abre las acciones.
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
  });

  final String name;
  final bool checked;
  final VoidCallback onToggle;
  final VoidCallback? onLongPress;
  final String? quantityLabel;
  final String? subtitle;

  /// Foto o ilustración del producto (solo si la vista lo pide).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final qty = quantityLabel?.trim() ?? '';
    return Semantics(
      checked: checked,
      label: name,
      child: InkWell(
        onTap: onToggle,
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                _CheckCircle(checked: checked),
                const SizedBox(width: AppSpacing.md),
                if (leading != null) ...[
                  Opacity(opacity: checked ? 0.5 : 1, child: leading),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
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
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          color: checked ? AppColors.inkMuted : AppColors.ink,
                          decoration: checked
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: AppColors.inkMuted,
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
                if (qty.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    qty,
                    style: TextStyle(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: checked ? AppColors.inkMuted : AppColors.woodDark,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.fast,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? AppColors.sage : Colors.transparent,
        border: Border.all(
          color: checked ? AppColors.sage : AppColors.wood,
          width: 2,
        ),
      ),
      child: checked
          ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
          : null,
    );
  }
}
