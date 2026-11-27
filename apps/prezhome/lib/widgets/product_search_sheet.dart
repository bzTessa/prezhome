import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/l10n.dart';

import '../models/supermarket.dart';
import '../services/home_country.dart';
import '../services/product_photo_resolver.dart';
import '../services/product_search_service.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';
import 'food_image.dart';
import 'list_skeleton.dart';

/// Abre el buscador de productos del súper. Devuelve el producto elegido o
/// null si se cierra sin elegir. Con [pickPhotoMode] en true filtra solo
/// productos con foto válida y oculta el botón de "añadir sin elegir producto".
Future<SupermarketProduct?> showProductSearchSheet(
  BuildContext context, {
  required String initialQuery,
  String? supermarketKey,
  ProductSearchService? service,
  bool pickPhotoMode = false,
}) {
  return showModalBottomSheet<SupermarketProduct>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ProductSearchSheet(
      initialQuery: initialQuery,
      supermarketKey: supermarketKey,
      service: service ?? ProductSearchService(),
      pickPhotoMode: pickPhotoMode,
    ),
  );
}

class ProductSearchSheet extends StatefulWidget {
  const ProductSearchSheet({
    super.key,
    required this.initialQuery,
    required this.service,
    this.supermarketKey,
    this.pickPhotoMode = false,
  });

  final String initialQuery;
  final String? supermarketKey;
  final ProductSearchService service;
  final bool pickPhotoMode;

  @override
  State<ProductSearchSheet> createState() => _ProductSearchSheetState();
}

class _ProductSearchSheetState extends State<ProductSearchSheet> {
  late final _controller = TextEditingController(text: widget.initialQuery);
  late String? _selectedStore = widget.supermarketKey;
  ProductSearchResult? _result;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.trim().length >= 2) _search();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.length < 2) return;
    setState(() => _loading = true);
    final r = await widget.service.search(q, supermarketKey: _selectedStore);
    if (!mounted) return;
    setState(() {
      _result = r;
      _loading = false;
    });
  }

  List<String?> _storeChoices() {
    final country = HomeCountry.current.value.code;
    final catalogStores = catalogStoresByCountry[country] ?? const <String>[];
    final seen = <String>{};
    final ordered = <String?>[null];
    if (widget.supermarketKey != null && seen.add(widget.supermarketKey!)) {
      ordered.add(widget.supermarketKey!);
    }
    for (final raw in catalogStores) {
      final key = raw.contains('_') ? raw.split('_').first : raw;
      if (seen.add(key)) ordered.add(key);
    }
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    final storeLabel = _selectedStore == null
        ? null
        : Supermarket.labelFor(_selectedStore!);
    final storeChoices = _storeChoices();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height:
            (MediaQuery.sizeOf(context).height -
                MediaQuery.viewInsetsOf(context).bottom) *
            0.84,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inkMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: Text(
                storeLabel == null
                    ? context.l.psStoreTitle
                    : context.l.psStoreTitleOf(storeLabel),
                style: AppTextStyles.headline,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: TextField(
                controller: _controller,
                autofocus: widget.initialQuery.trim().isEmpty,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: context.l.psHint,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.terracotta,
                  ),
                  suffixIcon: IconButton(
                    tooltip: context.l.search,
                    icon: Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.terracotta,
                    ),
                    onPressed: _search,
                  ),
                ),
              ),
            ),
            if (storeChoices.length > 1)
              // Súpers en filas que saltan de línea: nada que deslizar.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  0,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final key in storeChoices)
                      Builder(
                        builder: (context) {
                          final selected = _selectedStore == key;
                          final label = key == null
                              ? context.l.recAll
                              : Supermarket.labelFor(key);
                          return ChoiceChip(
                            label: Text(label),
                            selected: selected,
                            showCheckmark: false,
                            visualDensity: VisualDensity.compact,
                            selectedColor: AppColors.terracottaBg,
                            backgroundColor: AppColors.card,
                            side: BorderSide(
                              color: selected
                                  ? AppColors.terracotta.withValues(alpha: 0.4)
                                  : AppColors.cardEdge,
                            ),
                            labelStyle: AppTextStyles.label.copyWith(
                              color: selected
                                  ? AppColors.terracottaText
                                  : AppColors.inkMuted,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                            onSelected: (_) {
                              if (_selectedStore == key) return;
                              setState(() => _selectedStore = key);
                              _search();
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(child: _body()),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const ListSkeleton(rows: 5);
    }
    final r = _result;
    if (r == null) {
      return _message(Icons.storefront_rounded, context.l.psTypeHint);
    }
    if (r.throttled) {
      return _message(Icons.hourglass_top_rounded, context.l.psThrottled);
    }
    if (r.offline) {
      return _message(Icons.wifi_off_rounded, context.l.psOffline);
    }
    if (r.failed) {
      return _message(Icons.cloud_off_rounded, context.l.psDown);
    }
    final products = widget.pickPhotoMode
        ? [
            for (final p in r.products)
              if ((p.imageUrl ?? '').trim().isNotEmpty &&
                  !isBrokenPhoto(p.imageUrl))
                p,
          ]
        : r.products;
    if (products.isEmpty) {
      return _message(Icons.search_off_rounded, context.l.psNotInStore);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      itemCount:
          products.length +
          (_selectedStore != null && !r.filteredByStore ? 1 : 0) +
          (products.any((p) => p.store == null) ? 1 : 0),
      itemBuilder: (context, index) {
        final showNotice = _selectedStore != null && !r.filteredByStore;
        var idx = index;
        if (showNotice) {
          if (idx == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                _searchable(_selectedStore!)
                    ? context.l.psNoResultsIn(
                        Supermarket.labelFor(_selectedStore!),
                      )
                    : context.l.psNotYet(Supermarket.labelFor(_selectedStore!)),
                style: AppTextStyles.bodyMuted,
              ),
            );
          }
          idx--;
        }
        if (idx >= products.length) {
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              context.l.psOffData,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
            ),
          );
        }
        return _ProductTile(
          product: products[idx],
          pickPhotoMode: widget.pickPhotoMode,
        );
      },
    );
  }

  /// Si hay forma de buscar en ese súper (catálogo propio u OFF).
  bool _searchable(String key) =>
      catalogKeyFor(key) != null || offStoreTag(key) != null;

  Widget _message(IconData icon, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.terracotta),
            const SizedBox(height: AppSpacing.md),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    final q = _controller.text.trim();
    final label = widget.pickPhotoMode || q.isEmpty
        ? context.l.close
        : context.l.psAddAsIs(q);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.md,
        ),
        child: OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            minimumSize: const Size.fromHeight(48),
            side: BorderSide(color: AppColors.cardEdge),
            backgroundColor: AppColors.card,
          ),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.pickPhotoMode});

  final SupermarketProduct product;
  final bool pickPhotoMode;

  /// "2,15 € aprox.", "1,49 € aprox. · 1,19 € con Lidl Plus" o, si aún no
  /// está a la venta, "6,99 € desde el 20 nov".
  static String? _priceLabel(BuildContext context, SupermarketProduct p) {
    final price = p.price;
    final member = p.memberPrice;
    if (price == null && member == null) return null;
    final from = p.upcomingPriceFrom(DateTime.now());
    final date = from == null
        ? null
        : DateFormat.MMMd(
            Localizations.localeOf(context).toString(),
          ).format(from.toLocal());
    return [
      if (price != null)
        date == null
            ? '${money(price)} aprox.'
            : '${money(price)} ${context.l.psPriceFrom(date)}',
      if (member != null) context.l.psMemberPrice(money(member)),
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: AppColors.cardEdge),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => Navigator.of(context).pop(p),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardEdge),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: FoodImage(
                    name: p.name,
                    imageUrl: p.imageUrl,
                    size: 64,
                    radius: 14,
                    fit: BoxFit.contain,
                    photoOnly: true,
                    illustrationFallback: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (p.store != null) Supermarket.labelFor(p.store!),
                          ?p.brand,
                          ?p.quantity,
                          ?_priceLabel(context, p),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  pickPhotoMode
                      ? Icons.check_circle_outline_rounded
                      : Icons.add_circle_rounded,
                  color: AppColors.terracotta,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
