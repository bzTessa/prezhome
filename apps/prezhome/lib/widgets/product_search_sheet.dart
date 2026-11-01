import 'package:flutter/material.dart';

import '../models/supermarket.dart';
import '../services/product_search_service.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';
import 'food_image.dart';
import 'list_skeleton.dart';

/// Abre el buscador de productos del súper. Devuelve el producto elegido o
/// null si se cierra sin elegir (quien llama añade entonces el texto tal cual,
/// con una foto representativa).
Future<SupermarketProduct?> showProductSearchSheet(
  BuildContext context, {
  required String initialQuery,
  String? supermarketKey,
  ProductSearchService? service,
}) {
  return showModalBottomSheet<SupermarketProduct>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.cream,
    // Hoja táctil: esquinas de 24 y trazo carbón de 2 px arriba.
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      side: BorderSide(color: AppColors.stroke, width: 2),
    ),
    builder: (_) => ProductSearchSheet(
      initialQuery: initialQuery,
      supermarketKey: supermarketKey,
      service: service ?? ProductSearchService(),
    ),
  );
}

class ProductSearchSheet extends StatefulWidget {
  const ProductSearchSheet({
    super.key,
    required this.initialQuery,
    required this.service,
    this.supermarketKey,
  });

  final String initialQuery;
  final String? supermarketKey;
  final ProductSearchService service;

  @override
  State<ProductSearchSheet> createState() => _ProductSearchSheetState();
}

class _ProductSearchSheetState extends State<ProductSearchSheet> {
  late final _controller = TextEditingController(text: widget.initialQuery);
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
    final r = await widget.service.search(
      q,
      supermarketKey: widget.supermarketKey,
    );
    if (!mounted) return;
    setState(() {
      _result = r;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final storeLabel = widget.supermarketKey == null
        ? null
        : Supermarket.labelFor(widget.supermarketKey!);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        // Cabe con el teclado abierto.
        height:
            (MediaQuery.sizeOf(context).height -
                MediaQuery.viewInsetsOf(context).bottom) *
            0.82,
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
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: Text(
                storeLabel == null
                    ? 'Productos del súper'
                    : 'Productos de $storeLabel',
                style: TextStyle(
                  fontSize: 22,
                  letterSpacing: -0.4,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
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
                  hintText: 'Leche, yogur griego, detergente…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    tooltip: 'Buscar',
                    icon: const Icon(Icons.arrow_forward_rounded),
                    onPressed: _search,
                  ),
                ),
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
      return _message(
        Icons.storefront_rounded,
        'Escribe un producto y pulsa buscar.',
      );
    }
    if (r.throttled) {
      return _message(
        Icons.hourglass_top_rounded,
        'Demasiadas búsquedas seguidas. Prueba en un minuto.',
      );
    }
    if (r.offline) {
      return _message(
        Icons.wifi_off_rounded,
        'Sin conexión a internet. Puedes añadirlo igualmente.',
      );
    }
    if (r.failed) {
      return _message(
        Icons.cloud_off_rounded,
        'El buscador de productos no responde ahora. Prueba en un rato o '
        'añádelo igualmente.',
      );
    }
    if (r.products.isEmpty) {
      return _message(
        Icons.search_off_rounded,
        'No está en el súper. Puedes añadirlo igualmente.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      children: [
        if (widget.supermarketKey != null && !r.filteredByStore)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              _searchable(widget.supermarketKey!)
                  ? 'Sin resultados en '
                        '${Supermarket.labelFor(widget.supermarketKey!)}. '
                        'Estos son de otros súper.'
                  : 'Aún no tenemos los productos de '
                        '${Supermarket.labelFor(widget.supermarketKey!)}. '
                        'Estos son de otros súper.',
              style: AppTextStyles.bodyMuted,
            ),
          ),
        for (final p in r.products) _ProductTile(product: p),
        if (r.products.any((p) => p.store == null))
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              'Datos de Open Food Facts.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
            ),
          ),
      ],
    );
  }

  /// Si hay forma de buscar en ese súper (catálogo propio u OFF).
  bool _searchable(String key) =>
      catalogStores.contains(key) || offStoreTag(key) != null;

  Widget _message(IconData icon, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.woodDark),
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
          ),
          child: Text(
            q.isEmpty ? 'Cerrar' : 'Añadir "$q" sin elegir producto',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});

  final SupermarketProduct product;

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  // Solo fotos reales: los dibujos genéricos no dicen qué
                  // producto es.
                  child: FoodImage(
                    name: p.name,
                    imageUrl: p.imageUrl,
                    size: 64,
                    radius: 14,
                    fit: BoxFit.contain,
                    photoOnly: true,
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
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (p.store != null) Supermarket.labelFor(p.store!),
                          ?p.brand,
                          ?p.quantity,
                          if (p.price != null) '${money(p.price!)} aprox.',
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.add_circle_rounded,
                  color: AppColors.woodDark,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
