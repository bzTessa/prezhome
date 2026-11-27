import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/supermarket.dart';
import '../../services/store_comparison.dart';
import '../../theme/app_theme.dart';
import '../../utils/money.dart';
import '../segmented_pill.dart';
import '../supermarket_badge.dart';

/// Hoja "¿Dónde sale más barata?": compara cada producto por igual cantidad y
/// formato entre súpers, deja alternar entre coste comparable ("Misma
/// cantidad") o total real en caja, y permite repartir la lista en 2 súpers.
class StoreComparisonSheet extends StatefulWidget {
  const StoreComparisonSheet({
    super.key,
    required this.load,
    required this.itemNames,
    this.currentStore,
    this.onPickStore,
    this.onSplitIntoTwoLists,
  });

  final Future<BasketComparison> Function() load;

  /// Nombres de la lista comparada, en el mismo orden.
  final List<String> itemNames;

  /// Súper principal del hogar ("mercadona"), si hay.
  final String? currentStore;
  final ValueChanged<String>? onPickStore;

  /// Separa los productos encontrados en 2 listas del hogar (una por súper).
  final Future<void> Function(TwoStoreSplit split)? onSplitIntoTwoLists;

  @override
  State<StoreComparisonSheet> createState() => _StoreComparisonSheetState();
}

class _StoreComparisonSheetState extends State<StoreComparisonSheet> {
  late Future<BasketComparison> _future = widget.load();
  String? _open;
  int _tab = 0; // 0 = 1 súper, 1 = Repartir en 2
  CompareBasis _basis = CompareBasis.sameQuantity;
  String? _storeA;
  String? _storeB;
  bool _splitting = false;

  void _retry() => setState(() => _future = widget.load());

  void _toggle(String store) =>
      setState(() => _open = _open == store ? null : store);

  Future<void> _split(TwoStoreSplit split) async {
    final cb = widget.onSplitIntoTwoLists;
    if (cb == null || _splitting) return;
    setState(() => _splitting = true);
    try {
      await cb(split);
    } finally {
      if (mounted) setState(() => _splitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.86,
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
    final autoSplit = computeTwoStoreSplit(
      c,
      basis: _basis,
      storeA: _storeA,
      storeB: _storeB,
    );
    final effectiveTab = autoSplit == null ? 0 : _tab;

    return [
      if (autoSplit != null) ...[
        SegmentedPill(
          labels: [l.shopCompareOneStore, l.shopCompareTwoStores],
          selected: effectiveTab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      _BasisToggle(basis: _basis, onChanged: (b) => setState(() => _basis = b)),
      const SizedBox(height: AppSpacing.md),
      if (effectiveTab == 0)
        ..._singleStoreList(c)
      else if (autoSplit != null)
        ..._twoStoreView(c, autoSplit),
      const SizedBox(height: AppSpacing.md),
      Text(l.shopCompareNote, style: AppTextStyles.labelMuted),
    ];
  }

  List<Widget> _singleStoreList(BasketComparison c) {
    final l = context.l;
    final ranked = c.rankedFor(_basis);

    Widget card(StoreBasket b, {bool cheapest = false, bool partial = false}) {
      final key = homeKeyForCatalog(b.store);
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: _StoreCard(
          basket: b,
          comparison: c,
          basis: _basis,
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
      for (final (i, b) in ranked.indexed)
        card(b, cheapest: i == 0 && ranked.length > 1),
      if (c.partial.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        Text(l.shopComparePartial, style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        for (final b in c.partial) card(b, partial: true),
      ],
    ];
  }

  List<Widget> _twoStoreView(BasketComparison c, TwoStoreSplit split) {
    final l = context.l;
    final marketA = _marketFor(split.storeA);
    final marketB = _marketFor(split.storeB);
    final canSplit =
        widget.onSplitIntoTwoLists != null &&
        split.linesA.isNotEmpty &&
        split.linesB.isNotEmpty;

    void pickA(String store) {
      setState(() {
        if (store == split.storeB) {
          _storeB = split.storeA;
        } else {
          _storeB = split.storeB;
        }
        _storeA = store;
      });
    }

    void pickB(String store) {
      setState(() {
        if (store == split.storeA) {
          _storeA = split.storeB;
        } else {
          _storeA = split.storeA;
        }
        _storeB = store;
      });
    }

    return [
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: AppTheme.surfaceDecoration(
          radius: AppRadius.md,
          elevation: 1,
          color: split.savings > 0.01 ? AppColors.sageBg : AppColors.card,
        ),
        child: Row(
          children: [
            _PairBadges(storeA: split.storeA, storeB: split.storeB),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    split.savings > 0.01
                        ? l.shopCompareSplitSave(money(split.savings))
                        : l.shopCompareSplitSame,
                    style: AppTextStyles.title.copyWith(
                      color: split.savings > 0.01
                          ? AppColors.sage
                          : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.shopCompareSplitCombined(money(split.combinedTotal)),
                    style: AppTextStyles.labelMuted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      if (split.selectableStores.length > 2) ...[
        const SizedBox(height: AppSpacing.md),
        _PairSelector(
          stores: split.selectableStores,
          selected: split.storeA,
          onSelect: pickA,
        ),
        const SizedBox(height: AppSpacing.xs),
        _PairSelector(
          stores: split.selectableStores,
          selected: split.storeB,
          onSelect: pickB,
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      _SplitStoreCard(
        store: split.storeA,
        label: marketA.label,
        market: marketA.market,
        total: split.totalA,
        lines: split.linesA,
        basis: _basis,
        itemNames: widget.itemNames,
      ),
      const SizedBox(height: AppSpacing.sm),
      _SplitStoreCard(
        store: split.storeB,
        label: marketB.label,
        market: marketB.market,
        total: split.totalB,
        lines: split.linesB,
        basis: _basis,
        itemNames: widget.itemNames,
      ),
      if (split.missingIndices.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(
          l.shopCompareSplitMissing(
            [
              for (final i in split.missingIndices) widget.itemNames[i],
            ].join(', '),
          ),
          style: AppTextStyles.labelMuted,
        ),
      ],
      if (widget.onSplitIntoTwoLists != null) ...[
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: canSplit && !_splitting ? () => _split(split) : null,
          icon: _splitting
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onBrand,
                  ),
                )
              : const Icon(Icons.call_split_rounded, size: 18),
          label: Text(l.shopCompareSplitBtn),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: AppColors.terracotta,
            foregroundColor: AppColors.onBrand,
          ),
        ),
      ],
    ];
  }
}

({Supermarket? market, String label}) _marketFor(String store) {
  final key = homeKeyForCatalog(store);
  final market = Supermarket.byKey(key);
  return (market: market, label: market?.label ?? Supermarket.labelFor(key));
}

class _BasisToggle extends StatelessWidget {
  const _BasisToggle({required this.basis, required this.onChanged});

  final CompareBasis basis;
  final ValueChanged<CompareBasis> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    Widget chip(String label, CompareBasis value) {
      final selected = basis == value;
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChanged(value),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Ink(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: selected ? AppColors.terracottaBg : AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: selected
                      ? AppColors.terracotta.withValues(alpha: 0.45)
                      : AppColors.cardEdge,
                ),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(
                  color: selected
                      ? AppColors.terracottaText
                      : AppColors.inkMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(l.shopCompareSameQty, CompareBasis.sameQuantity),
        const SizedBox(width: AppSpacing.xs),
        chip(l.shopCompareCheckout, CompareBasis.checkoutTotal),
      ],
    );
  }
}

class _PairBadges extends StatelessWidget {
  const _PairBadges({required this.storeA, required this.storeB});

  final String storeA;
  final String storeB;

  @override
  Widget build(BuildContext context) {
    final ma = _marketFor(storeA).market;
    final mb = _marketFor(storeB).market;
    return SizedBox(
      width: 56,
      height: 36,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 2,
            child: ma != null
                ? SupermarketBadge(supermarket: ma, size: 32)
                : Icon(
                    Icons.storefront_outlined,
                    size: 32,
                    color: AppColors.woodDark,
                  ),
          ),
          Positioned(
            left: 22,
            top: 2,
            child: mb != null
                ? SupermarketBadge(supermarket: mb, size: 32)
                : Icon(
                    Icons.storefront_outlined,
                    size: 32,
                    color: AppColors.woodDark,
                  ),
          ),
        ],
      ),
    );
  }
}

class _PairSelector extends StatelessWidget {
  const _PairSelector({
    required this.stores,
    required this.selected,
    required this.onSelect,
  });

  final List<String> stores;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stores.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final store = stores[i];
          final active = store == selected;
          final info = _marketFor(store);
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelect(store),
              borderRadius: BorderRadius.circular(999),
              child: Ink(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: active ? AppColors.terracottaBg : AppColors.card,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: active ? AppColors.terracotta : AppColors.cardEdge,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (info.market != null) ...[
                      SupermarketBadge(supermarket: info.market!, size: 18),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      info.label,
                      style: AppTextStyles.label.copyWith(
                        color: active
                            ? AppColors.terracottaText
                            : AppColors.ink,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SplitStoreCard extends StatelessWidget {
  const _SplitStoreCard({
    required this.store,
    required this.label,
    required this.market,
    required this.total,
    required this.lines,
    required this.basis,
    required this.itemNames,
  });

  final String store;
  final String label;
  final Supermarket? market;
  final double total;
  final List<SplitLine> lines;
  final CompareBasis basis;
  final List<String> itemNames;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppTheme.surfaceDecoration(
        radius: AppRadius.md,
        elevation: 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (market != null)
                SupermarketBadge(supermarket: market!, size: 32)
              else
                Icon(
                  Icons.storefront_outlined,
                  size: 32,
                  color: AppColors.woodDark,
                ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.title),
                    Text(
                      l.shopCompareFound(lines.length, itemNames.length),
                      style: AppTextStyles.labelMuted,
                    ),
                  ],
                ),
              ),
              Text(
                '≈ ${money(total)}',
                style: AppTextStyles.numeric(AppTextStyles.title),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            for (final line in lines)
              _LineRow(
                line: line.chosen,
                query: itemNames[line.itemIndex],
                basis: basis,
                badgeText: line.saved > 0.01
                    ? '−${money(line.saved)}'
                    : (line.alternative == null
                          ? l.shopCompareSplitOnlyHere
                          : null),
                badgePositive: line.saved > 0.01,
              ),
          ],
        ],
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.basket,
    required this.comparison,
    required this.basis,
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
  final CompareBasis basis;
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
    final extra = comparison.extraOver(basket, basis: basis);
    final total = partial
        ? basket.totalForBasis(basis)
        : comparison.comparableTotal(basket, basis: basis);
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
                  _LineRow(
                    line: line,
                    query: itemNames[line.index],
                    basis: basis,
                  ),
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
  const _LineRow({
    required this.line,
    required this.query,
    required this.basis,
    this.badgeText,
    this.badgePositive = false,
  });

  final BasketLine line;
  final String query;
  final CompareBasis basis;
  final String? badgeText;
  final bool badgePositive;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final p = line.product;
    final ticket = isTicketPrice(p);
    final packText = line.packLabel ?? p.quantity ?? '';
    final unitText = line.unitPrice != null && line.unitLabel != null
        ? '${money(line.unitPrice!)}/${line.unitLabel}'
        : '';
    final detail = [
      if (ticket) l.shopCompareFromTickets else p.displayName,
      if (!ticket && packText.isNotEmpty) packText,
      if (!ticket && unitText.isNotEmpty) unitText,
    ].join(' · ');
    final showEquiv =
        basis == CompareBasis.sameQuantity &&
        line.sizeAdjusted &&
        line.targetLabel != null &&
        !ticket;

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
                if (showEquiv)
                  Text(
                    l.shopCompareEquiv(
                      line.targetLabel!,
                      money(line.checkoutCost),
                    ),
                    style: AppTextStyles.labelMuted.copyWith(fontSize: 11),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                basis == CompareBasis.checkoutTotal && line.packs > 1
                    ? '${line.packs} × ${money(p.price!)}'
                    : money(line.costFor(basis)),
                style: AppTextStyles.numeric(AppTextStyles.body),
              ),
              if (badgeText != null)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: badgePositive
                        ? AppColors.sageBg
                        : AppColors.iconTile,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeText!,
                    style: AppTextStyles.label.copyWith(
                      fontSize: 11,
                      color: badgePositive
                          ? AppColors.sage
                          : AppColors.inkMuted,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
