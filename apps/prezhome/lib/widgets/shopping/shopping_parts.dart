import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../utils/shopping_display.dart';
import '../animations/animated_counter.dart';
import '../animations/spring_value.dart';
import '../../utils/money.dart';
import '../../l10n/l10n.dart';

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
    this.unpriced = 0,
    this.storeLabel,
    this.onTapStore,
    this.inStore = false,
    this.onToggleStore,
    this.onShare,
    this.onCompare,
  });

  /// Mandar lo que falta por WhatsApp u otra app (null = nada que mandar).
  final VoidCallback? onShare;

  final String listName;
  final int pending;
  final int done;
  final VoidCallback onTapList;
  final VoidCallback onGenerate;
  final VoidCallback onOptions;
  final bool generating;

  /// Coste estimado de lo pendiente en euros, o null si no se conoce.
  final double? estimate;

  /// Productos pendientes que no suman al [estimate] por no tener precio.
  final int unpriced;

  /// Súper principal ("Mercadona") o null si no hay; con [onTapStore] se
  /// muestra un selector debajo del nombre de la lista.
  final String? storeLabel;
  final VoidCallback? onTapStore;

  /// Modo tienda: lista a pantalla, sin añadir ni sugerencias, y la
  /// pantalla no se apaga mientras compras.
  final bool inStore;
  final VoidCallback? onToggleStore;

  /// Abre "¿Dónde sale más barata?" (comparar la lista entre súpers).
  final VoidCallback? onCompare;

  @override
  Widget build(BuildContext context) {
    final total = pending + done;
    final progress = total == 0 ? 0.0 : done / total;
    if (inStore) return _storeHeader(context, total, progress);
    final iconStyle = IconButton.styleFrom(
      foregroundColor: AppColors.inkMuted,
      backgroundColor: AppColors.card,
      side: BorderSide(color: AppColors.cardEdge),
      visualDensity: VisualDensity.compact,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (onTapStore != null)
              InkWell(
                onTap: onTapStore,
                borderRadius: AppRadius.pillRadius,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.terracottaBg,
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.storefront_rounded,
                        size: 14,
                        color: AppColors.terracottaText,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        (storeLabel ?? context.l.shopPickStore),
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.terracottaText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.expand_more_rounded,
                        size: 16,
                        color: AppColors.terracottaText,
                      ),
                    ],
                  ),
                ),
              ),
            const Spacer(),
            if (onToggleStore != null && total > 0)
              FilledButton.icon(
                onPressed: onToggleStore,
                icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                label: Text(context.l.shopStoreModeOn),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.terracotta,
                  foregroundColor: AppColors.onTerracotta,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 34),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: InkWell(
                onTap: onTapList,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          listName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.display,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.expand_more_rounded,
                        color: AppColors.inkMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (total > 0) ...[
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$done/$total',
                    style: AppTextStyles.numeric(AppTextStyles.headline),
                  ),
                  if (estimate != null)
                    AnimatedCounter(
                      value: estimate!,
                      formatter: (v) =>
                          '≈ ${money(v)}'
                          '${unpriced > 0 ? context.l.shopUnpriced(unpriced) : ''}',
                      style: AppTextStyles.bodyMuted.copyWith(
                        fontSize: 12,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
        if (total > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          CartProgressBar(progress: progress),
        ],
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _HeaderActionChip(
              icon: Icons.event_note_rounded,
              label: context.l.shopFromPlanAction,
              loading: generating,
              onTap: generating ? null : onGenerate,
            ),
            if (onCompare != null && pending > 0) ...[
              const SizedBox(width: AppSpacing.sm),
              _HeaderActionChip(
                icon: Icons.compare_arrows_rounded,
                label: context.l.shopCompare,
                onTap: onCompare,
              ),
            ],
            const Spacer(),
            if (onShare != null) ...[
              IconButton(
                tooltip: context.l.shopShareList,
                onPressed: onShare,
                style: iconStyle,
                icon: const Icon(Icons.ios_share_rounded, size: 18),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            IconButton(
              tooltip: context.l.shopListOptions,
              onPressed: onOptions,
              style: iconStyle,
              icon: const Icon(Icons.tune_rounded, size: 18),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderActionChip extends StatelessWidget {
  const _HeaderActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: StadiumBorder(side: BorderSide(color: AppColors.cardEdge)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox.square(
                  dimension: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(icon, size: 16, color: AppColors.terracottaText),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on ShoppingSummaryHeader {
  /// Cabecera del modo tienda: dónde estás, cuánto llevas en el carro y un
  /// botón grande para terminar.
  Widget _storeHeader(BuildContext context, int total, double progress) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.place_outlined, size: 16, color: AppColors.woodDark),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  (storeLabel == null
                          ? context.l.shopInStore
                          : context.l.shopInStoreAt(storeLabel!))
                      .toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.terracottaText,
                  ),
                ),
              ),
              // Salir sin terminar la compra; terminarla va en la barra de
              // abajo ("Terminar compra (N)").
              IconButton(
                onPressed: onToggleStore,
                tooltip: context.l.shopLeaveStore,
                icon: const Icon(Icons.close_rounded),
                color: AppColors.ink,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  listName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.display,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$done / $total',
                    style: AppTextStyles.numeric(AppTextStyles.headline),
                  ),
                  if (estimate != null)
                    Text(
                      '≈ ${money(estimate!)}',
                      style: AppTextStyles.bodyMuted,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          CartProgressBar(progress: progress),
        ],
      ),
    );
  }
}

/// Barra del carro: pista crema y relleno verde con extremos redondeados que
/// avanza con un muelle sin rebote. Con poco progreso el relleno mantiene un
/// mínimo para leerse como barra y no como un punto.
class CartProgressBar extends StatelessWidget {
  const CartProgressBar({super.key, required this.progress});

  /// De 0 a 1.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    return Semantics(
      value: '${(progress * 100).round()} %',
      child: Container(
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.iconTile,
          borderRadius: radius,
        ),
        child: SpringValue(
          value: progress,
          from: 0,
          builder: (context, v, _) => LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth * v.clamp(0.0, 1.0);
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: w <= 0 ? 0 : w.clamp(24.0, c.maxWidth),
                  decoration: BoxDecoration(
                    color: AppColors.done,
                    borderRadius: radius,
                  ),
                ),
              );
            },
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

  /// Añade con detalles: abre el formulario completo (tipo, cantidad, unidad).
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

  /// Fila de una acción del menú: icono + texto que puede encoger sin
  /// desbordar en pantallas estrechas.
  Widget _menuRow(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.terracottaText),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  /// Busca en el súper el texto escrito (o abre el buscador vacío).
  void _search() {
    if (widget.onSearch == null) return;
    final text = _controller.text.trim();
    _controller.clear();
    widget.onSearch!(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.tactileDecoration(radius: AppRadius.md, shadow: 2),
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Row(
        children: [
          // El "+" AÑADE de verdad lo escrito (igual que pulsar Intro). Vacío
          // es un no-op seguro.
          IconButton(
            tooltip: context.l.shopAddProduct,
            onPressed: _submit,
            icon: const Icon(Icons.add_rounded),
            color: AppColors.terracottaText,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: context.l.shopAddProduct,
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
              tooltip: context.l.shopSearchStore,
              onPressed: _search,
              icon: const Icon(Icons.storefront_rounded),
              color: AppColors.terracottaText,
            ),
          // Menú de acciones CLARAS con nombre (ya no un formulario sin
          // contexto): buscar en el súper y añadir con detalles.
          PopupMenuButton<String>(
            tooltip: context.l.moreOptions,
            icon: Icon(Icons.more_horiz_rounded, color: AppColors.inkMuted),
            color: AppColors.cream,
            onSelected: (value) {
              switch (value) {
                case 'search':
                  _search();
                case 'details':
                  widget.onMore();
              }
            },
            itemBuilder: (context) => [
              if (widget.onSearch != null)
                PopupMenuItem(
                  value: 'search',
                  child: _menuRow(
                    Icons.storefront_rounded,
                    context.l.shopSearchStore,
                  ),
                ),
              PopupMenuItem(
                value: 'details',
                child: _menuRow(Icons.tune_rounded, context.l.shopAddDetailed),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Cabecera plegable de un pasillo (reutilizable en SliverList virtualizado y
/// en [ShoppingSection]).
class ShoppingAisleHeader extends StatelessWidget {
  const ShoppingAisleHeader({
    super.key,
    required this.title,
    required this.count,
    required this.expanded,
    required this.onToggle,
    this.icon,
    this.iconColor,
    this.iconBackground,
    this.complete = false,
    this.trailing,
  });

  final String title;
  final int count;
  final bool expanded;
  final VoidCallback onToggle;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackground;
  final bool complete;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: complete ? 0.55 : 1,
      duration: AppMotion.fast,
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
                    border: complete
                        ? null
                        : Border.all(
                            color: (iconColor ?? AppColors.peach).withValues(
                              alpha: 0.25,
                            ),
                            width: 1,
                          ),
                  ),
                  child: Icon(
                    complete ? Icons.check_rounded : icon,
                    size: 15,
                    color: complete
                        ? AppColors.onTerracotta
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
                        color: AppColors.inkMuted,
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
          ShoppingAisleHeader(
            title: title,
            count: count,
            expanded: expanded,
            onToggle: onToggle,
            icon: icon,
            iconColor: iconColor,
            iconBackground: iconBackground,
            complete: complete,
            trailing: trailing,
          ),
          AnimatedSize(
            duration: AppMotion.effectiveDuration(
              AppMotion.slow,
              reduceMotion: AppMotion.reduceMotionOf(context),
            ),
            curve: AppMotion.springCurve(AppMotion.fluidDefault),
            alignment: Alignment.topCenter,
            child: expanded
                ? Container(
                    decoration: AppTheme.surfaceDecoration(
                      radius: AppRadius.lg,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0; i < children.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              indent: 56,
                              endIndent: 16,
                              color: AppColors.line,
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

/// Fila de un producto: se marca tocando la fila (sin animaciones pesadas
/// por cada fila), lleva foto/ilustración y una píldora compacta de cantidad
/// que se expande a − / + al tocarla cuando [compactQuantity] es true.
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
    this.packSize,
    this.compactQuantity = false,
    this.quantityExpanded = true,
    this.onQuantityTap,
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

  /// Envase del súper (ver [ShoppingListItem.packSize]): − / + van de envase
  /// en envase.
  final double? packSize;

  /// Si true, en reposo muestra la píldora compacta y expande a − / + solo
  /// cuando [quantityExpanded] es true (al tocar la píldora).
  final bool compactQuantity;
  final bool quantityExpanded;
  final VoidCallback? onQuantityTap;

  @override
  Widget build(BuildContext context) {
    final qty = quantityLabel?.trim() ?? '';
    final showStepper =
        onQuantityChanged != null &&
        !checked &&
        (!compactQuantity || quantityExpanded);
    final showCompactQty =
        onQuantityChanged != null &&
        !checked &&
        compactQuantity &&
        !quantityExpanded;
    return Semantics(
      checked: checked,
      label: name,
      child: Material(
        color: AppColors.card,
        child: InkWell(
          onTap: onToggle,
          onLongPress: onLongPress,
          child: Container(
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
            child: Row(
              children: [
                _CheckCircle(checked: checked),
                const SizedBox(width: AppSpacing.md),
                if (leading != null) ...[
                  AnimatedOpacity(
                    opacity: checked ? 0.55 : 1,
                    duration: AppMotion.fast,
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
                  child: AnimatedOpacity(
                    opacity: checked ? 0.55 : 1,
                    duration: AppMotion.fast,
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
                            decoration: checked
                                ? TextDecoration.lineThrough
                                : null,
                            decorationThickness: 2,
                            decorationColor: AppColors.ink,
                          ),
                        ),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                if (showStepper) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _LiveQuantityStepper(
                    quantity: quantity,
                    unit: unit,
                    packSize: packSize,
                    onCommit: onQuantityChanged!,
                  ),
                ] else if (showCompactQty) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Semantics(
                    button: true,
                    label: qty.isEmpty ? '1' : qty,
                    child: Material(
                      color: AppColors.iconTile,
                      shape: StadiumBorder(
                        side: BorderSide(color: AppColors.cardEdge),
                      ),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: onQuantityTap,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          child: Text(
                            qty.isEmpty ? '1 ud' : qty,
                            style: TextStyle(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ),
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
                            : AppColors.inkMuted,
                      ),
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

/// Círculo de 26 px que se rellena de verde al marcar.
class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.easeOut,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? AppColors.done : Colors.transparent,
        border: Border.all(
          color: checked
              ? AppColors.done
              : AppColors.woodDark.withValues(alpha: 0.45),
          width: 2,
        ),
      ),
      child: checked
          ? const Icon(
              Icons.check_rounded,
              size: 18,
              color: AppColors.onTerracotta,
            )
          : null,
    );
  }
}

/// Pastilla − / + de una fila de la compra que cambia el número AL INSTANTE
/// por su cuenta y avisa a la lista una sola vez, cuando se deja de tocar.
/// Antes cada toque repintaba la lista entera y, si se tocaba rápido, el
/// siguiente toque partía de la cantidad vieja.
class _LiveQuantityStepper extends StatefulWidget {
  const _LiveQuantityStepper({
    required this.quantity,
    required this.unit,
    required this.packSize,
    required this.onCommit,
  });

  final double? quantity;
  final String? unit;
  final double? packSize;
  final ValueChanged<double> onCommit;

  @override
  State<_LiveQuantityStepper> createState() => _LiveQuantityStepperState();
}

class _LiveQuantityStepperState extends State<_LiveQuantityStepper> {
  static const _settle = Duration(milliseconds: 450);
  late double? _value = widget.quantity;
  Timer? _timer;

  @override
  void didUpdateWidget(_LiveQuantityStepper old) {
    super.didUpdateWidget(old);
    // Mientras se toca manda lo local; luego, lo que diga la lista.
    if (!(_timer?.isActive ?? false)) _value = widget.quantity;
  }

  @override
  void dispose() {
    if (_timer?.isActive ?? false) {
      _timer!.cancel();
      final v = _value;
      final commit = widget.onCommit;
      // Fuera del desmontaje: la lista no puede repintarse en mitad de él.
      if (v != null) scheduleMicrotask(() => commit(v));
    }
    super.dispose();
  }

  void _step(bool up) {
    final next = shoppingQtyNext(
      _value,
      widget.unit,
      up: up,
      packSize: widget.packSize,
    );
    if (next == null) return;
    HapticFeedback.selectionClick();
    setState(() => _value = next);
    _timer?.cancel();
    _timer = Timer(_settle, () => widget.onCommit(next));
  }

  @override
  Widget build(BuildContext context) {
    final label = shoppingQtyLabel(
      _value,
      widget.unit,
      packSize: widget.packSize,
    );
    final canDown =
        shoppingQtyNext(
          _value,
          widget.unit,
          up: false,
          packSize: widget.packSize,
        ) !=
        null;
    return QuantityStepper(
      label: label.isEmpty ? '1' : label,
      onMinus: canDown ? () => _step(false) : null,
      onPlus: () => _step(true),
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
            color: onTap == null
                ? AppColors.inkMuted.withValues(alpha: 0.32)
                : AppColors.ink,
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
        color: AppColors.iconTile,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardEdge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _button(Icons.remove_rounded, context.l.less, widget.onMinus, false),
          ClipRect(
            // Ancho fijo: si cambiara con el texto ("900 ml" / "1,1 L"), el
            // botón − se movería bajo el dedo entre toque y toque.
            child: SizedBox(
              width: MediaQuery.textScalerOf(context).scale(58),
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
                child: FittedBox(
                  key: ValueKey(widget.label),
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
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
          ),
          _button(Icons.add_rounded, context.l.more, widget.onPlus, true),
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
      label: added ? context.l.shopAdded(label) : context.l.shopAdd(label),
      excludeSemantics: true,
      child: Material(
        color: added ? AppColors.sageBg : AppColors.paper,
        shape: StadiumBorder(side: BorderSide(color: AppColors.cardEdge)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onAdd,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
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

/// Tarjeta de sugerencia: foto, nombre, precio y por qué se sugiere. Tocarla
/// la añade; enseña un check mientras [added] siga a true.
class SuggestionCard extends StatelessWidget {
  const SuggestionCard({
    super.key,
    required this.name,
    required this.added,
    this.photo,
    required this.onAdd,
    this.price,
    this.reason,
    this.expand = false,
  });

  final String name;

  /// Ocupa todo el ancho que le den (celda de una rejilla) en vez del suyo.
  final bool expand;

  /// Sin foto (la persona las quitó) la tarjeta es solo texto.
  final Widget? photo;
  final bool added;
  final VoidCallback onAdd;
  final String? price;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final addButton = Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: added ? AppColors.done : AppColors.terracotta,
        shape: BoxShape.circle,
        border: AppElevation.border,
      ),
      child: Icon(
        added ? Icons.check_rounded : Icons.add_rounded,
        size: 18,
        color: AppColors.onTerracotta,
      ),
    );
    final title = Text(
      name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12.5,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    );
    return Semantics(
      button: true,
      label: added ? context.l.shopAdded(name) : context.l.shopAdd(name),
      excludeSemantics: true,
      child: Material(
        color: added ? AppColors.sageBg : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: expand ? null : (photo == null ? 128 : 108),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: added ? AppColors.done : AppColors.cardEdge,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photo != null) ...[
                  Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.iconTile,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          clipBehavior: Clip.antiAlias,
                          alignment: Alignment.center,
                          child: photo,
                        ),
                      ),
                      Positioned(top: 4, right: 4, child: addButton),
                    ],
                  ),
                  const SizedBox(height: 5),
                  title,
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: title),
                      const SizedBox(width: 4),
                      addButton,
                    ],
                  ),
                for (final (text, color) in [
                  (price, AppColors.ink),
                  (reason, AppColors.done),
                ])
                  if (text != null)
                    Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: color,
                        fontFeatures: const [FontFeature.tabularFigures()],
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

/// Producto en la vista de cuadrícula: foto grande, nombre, cantidad y
/// precio. Tocar lo pasa al carro (o lo devuelve); mantener abre acciones.
class ShoppingGridTile extends StatelessWidget {
  const ShoppingGridTile({
    super.key,
    required this.name,
    required this.checked,
    required this.onToggle,
    this.onLongPress,
    this.photo,
    this.quantityLabel,
    this.price,
    this.compact = false,
  });

  final String name;
  final bool checked;

  /// Ficha pequeña de tres por fila: foto redonda centrada y, ya en el
  /// carro, borde verde en vez de atenuarse.
  final bool compact;
  final VoidCallback onToggle;
  final VoidCallback? onLongPress;
  final Widget? photo;
  final String? quantityLabel;
  final String? price;

  Widget _compact(BuildContext context) {
    final qty = quantityLabel?.trim() ?? '';
    final radius = BorderRadius.circular(20);
    return Semantics(
      checked: checked,
      label: name,
      child: Material(
        color: checked ? AppColors.sageBg : AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: checked
              ? BorderSide(color: AppColors.sage, width: 2)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onToggle,
          onLongPress: onLongPress,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
            child: Column(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.iconTile,
                          shape: BoxShape.circle,
                        ),
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.center,
                        child: photo,
                      ),
                      if (checked)
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: _CheckCircle(checked: checked),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Text(
                  checked
                      ? context.l.shopInCart
                      : [qty, ?price].where((t) => t.isNotEmpty).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: checked ? AppColors.sage : AppColors.inkMuted,
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
    if (compact && photo != null) return _compact(context);
    final qty = quantityLabel?.trim() ?? '';
    final details = [
      Text(
        name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13.5,
          height: 1.2,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          decoration: checked ? TextDecoration.lineThrough : null,
        ),
      ),
      const SizedBox(height: 2),
      Row(
        children: [
          Expanded(
            child: Text(
              qty,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.woodDark,
              ),
            ),
          ),
          if (price != null)
            Text(
              price!,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    ];
    return Semantics(
      checked: checked,
      label: name,
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onToggle,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.cardEdge),
            ),
            child: Opacity(
              opacity: checked ? 0.5 : 1,
              child: photo == null
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CheckCircle(checked: checked),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: details,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.iconTile,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                clipBehavior: Clip.antiAlias,
                                alignment: Alignment.center,
                                child: photo,
                              ),
                              Positioned(
                                top: 6,
                                left: 6,
                                child: _CheckCircle(checked: checked),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...details,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
