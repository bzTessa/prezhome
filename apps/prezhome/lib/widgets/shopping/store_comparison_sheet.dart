import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/supermarket.dart';
import '../../services/store_comparison.dart';
import '../../theme/app_theme.dart';
import '../../utils/money.dart';
import '../supermarket_badge.dart';

/// Hoja "¿Dónde sale más barata?": la lista de la compra en cada súper, del
/// más barato al más caro. Tocar un súper enseña qué se cogería; "Comprar
/// aquí" lo pone como súper principal. Recibe la carga inyectada para poder
/// probarla sin red.
class StoreComparisonSheet extends StatefulWidget {
  const StoreComparisonSheet({
    super.key,
    required this.load,
    required this.itemNames,
    this.currentStore,
    this.onPickStore,
  });

  final Future<BasketComparison> Function() load;

  /// Nombres de la lista comparada, en el mismo orden (para "Sin encontrar").
  final List<String> itemNames;

  /// Súper principal del hogar ("mercadona"), si hay.
  final String? currentStore;
  final ValueChanged<String>? onPickStore;

  @override
  State<StoreComparisonSheet> createState() => _StoreComparisonSheetState();
}

class _StoreComparisonSheetState extends State<StoreComparisonSheet> {
  late Future<BasketComparison> _future = widget.load();
  String? _open;

  void _retry() => setState(() => _future = widget.load());

  void _toggle(String store) =>
      setState(() => _open = _open == store ? null : store);

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) => FutureBuilder<BasketComparison>(
        future: _future,
        builder: (context, snap) {
          final children = <Widget>[
            Text(l.shopCompareTitle, style: AppTextStyles.headline),
            const SizedBox(height: AppSpacing.md),
          ];
          if (snap.connectionState != ConnectionState.done) {
            children.add(
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          } else if (snap.hasError) {
            children.addAll([
              Text(l.shopCompareError, style: AppTextStyles.bodyMuted),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: _retry,
                  child: Text(l.shopCompareRetry),
                ),
              ),
            ]);
          } else if (snap.data!.isEmpty) {
            children.add(Text(l.shopCompareEmpty, style: AppTextStyles.body));
          } else {
            children.addAll(_results(snap.data!));
          }
          return ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: children,
          );
        },
      ),
    );
  }

  List<Widget> _results(BasketComparison c) {
    final l = context.l;
    Widget card(StoreBasket b, {bool cheapest = false, bool partial = false}) {
      final key = homeKeyForCatalog(b.store);
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: _StoreCard(
          basket: b,
          comparison: c,
          cheapest: cheapest,
          partial: partial,
          isMain: key == widget.currentStore,
          expanded: _open == b.store,
          itemNames: widget.itemNames,
          onTap: () => _toggle(b.store),
          onPick: partial || widget.onPickStore == null
              ? null
              : () => widget.onPickStore!(key),
        ),
      );
    }

    return [
      if (c.common.isNotEmpty) ...[
        Text(
          l.shopCompareCommon(c.common.length),
          style: AppTextStyles.bodyMuted,
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      for (final (i, b) in c.ranked.indexed)
        card(b, cheapest: i == 0 && c.ranked.length > 1),
      if (c.partial.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        Text(l.shopComparePartial, style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        for (final b in c.partial) card(b, partial: true),
      ],
      const SizedBox(height: AppSpacing.md),
      Text(l.shopCompareNote, style: AppTextStyles.labelMuted),
    ];
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.basket,
    required this.comparison,
    required this.cheapest,
    required this.partial,
    required this.isMain,
    required this.expanded,
    required this.itemNames,
    required this.onTap,
    this.onPick,
  });

  final StoreBasket basket;
  final BasketComparison comparison;
  final bool cheapest;
  final bool partial;
  final bool isMain;
  final bool expanded;
  final List<String> itemNames;
  final VoidCallback onTap;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final key = homeKeyForCatalog(basket.store);
    final market = Supermarket.byKey(key);
    final label = market?.label ?? Supermarket.labelFor(key);
    final extra = comparison.extraOver(basket);
    final total = partial ? basket.total : comparison.comparableTotal(basket);
    final missing = [
      for (var i = 0; i < itemNames.length; i++)
        if (!basket.lines.containsKey(i)) itemNames[i],
    ];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: AppTheme.surfaceDecoration(
            radius: AppRadius.md,
            elevation: cheapest ? 2 : 1,
            color: cheapest ? AppColors.sageBg : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (market != null)
                    SupermarketBadge(supermarket: market, size: 36)
                  else
                    Icon(
                      Icons.storefront_outlined,
                      size: 36,
                      color: AppColors.woodDark,
                    ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: AppTextStyles.title),
                        Text(
                          [
                            l.shopCompareFound(
                              basket.found,
                              comparison.itemCount,
                            ),
                            if (isMain) l.shopCompareIsMain,
                          ].join(' · '),
                          style: AppTextStyles.labelMuted,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '≈ ${money(total)}',
                        style: AppTextStyles.numeric(AppTextStyles.title),
                      ),
                      if (cheapest)
                        Text(
                          l.shopCompareCheapest,
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.sage,
                          ),
                        )
                      else if (!partial && extra > 0.005)
                        Text(
                          '+${money(extra)}',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.terracottaText,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: AppSpacing.md),
                for (final line in basket.lines.values)
                  _LineRow(line: line, query: itemNames[line.index]),
                if (missing.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l.shopCompareMissing(missing.join(', ')),
                    style: AppTextStyles.labelMuted,
                  ),
                ],
                if (onPick != null && !isMain) ...[
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.storefront_rounded, size: 18),
                    label: Text(l.shopCompareSetMain),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      backgroundColor: AppColors.terracotta,
                      foregroundColor: AppColors.onBrand,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line, required this.query});

  final BasketLine line;
  final String query;

  @override
  Widget build(BuildContext context) {
    final p = line.product;
    final ticket = isTicketPrice(p);
    final detail = [
      if (ticket) context.l.shopCompareFromTickets else p.displayName,
      if (!ticket && (p.quantity ?? '').isNotEmpty) p.quantity!,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(query, style: AppTextStyles.bodyStrong),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMuted,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            line.packs > 1
                ? '${line.packs} × ${money(p.price!)}'
                : money(line.cost),
            style: AppTextStyles.numeric(AppTextStyles.body),
          ),
        ],
      ),
    );
  }
}
