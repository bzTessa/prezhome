import 'package:flutter/material.dart';

import '../models/inventory_item.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../utils/expiry_bar.dart';
import '../utils/shopping_display.dart';
import 'animations/press_scale.dart';
import 'food_image.dart';

/// Tarjeta visual de un producto del inventario para el GRID de la despensa.
///
/// Muestra, de arriba a abajo: la [FoodImage] del alimento (foto real o
/// ilustración cozy) ENVUELTA en un [Hero] con tag único `inv-<id>` para que la
/// transición hacia la pantalla de edición case; el nombre limpio
/// ([shoppingCleanName]); la cantidad legible ([inventoryQtyLabel]); y, salvo
/// en secciones sin caducidad ([showExpiryBar] = false), la BARRA DE CADUCIDAD
/// de color ([_ExpiryBar]).
///
/// Las interacciones (toque y pulsación larga) se delegan en [onTap] y
/// [onLongPress], que abren el menú de acciones del producto. Un icono de "más
/// acciones" en la esquina insinúa que la tarjeta es pulsable, y la pastilla
/// "No se compra" se mantiene para los básicos ([InventoryItem.isStaple]).
class InventoryItemCard extends StatelessWidget {
  final InventoryItem item;

  /// Si la sección muestra caducidad (las especias y el hogar no la muestran,
  /// igual que no mostraban chip de caducidad).
  final bool showExpiryBar;

  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const InventoryItemCard({
    super.key,
    required this.item,
    required this.showExpiryBar,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final name = shoppingCleanName(item.name);
    final qty = inventoryQtyLabel(item.quantity, item.unit);
    // El Hero necesita un tag ÚNICO por item (MainShell usa IndexedStack, así
    // que varias pantallas conviven vivas). Solo lo ponemos si el item tiene id.
    final hasId = item.id.isNotEmpty;

    final image = FoodImage(
      name: item.name,
      itemType: item.itemType,
      imageUrl: item.imageUrl,
      // La imagen ocupa toda la zona superior de la tarjeta.
      width: double.infinity,
      height: double.infinity,
      radius: AppRadius.md,
      // Las especias usan siempre ilustración (sus fotos salen genéricas).
      forceIllustration: item.category == 'Especias',
    );

    final card = Container(
      decoration: AppTheme.cardDecoration(radius: AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zona superior: imagen + indicador de "más acciones". Va en Expanded
          // (no en AspectRatio fijo) para que, con fuente del sistema grande, la
          // imagen CEDA altura al bloque de texto en vez de desbordar la celda;
          // con fuente normal ocupa casi todo el alto disponible (≈ cuadrada).
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                hasId ? Hero(tag: 'inv-${item.id}', child: image) : image,
                if (item.isStaple)
                  const Positioned(top: 6, left: 6, child: _StapleBadge()),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: const Icon(
                      Icons.more_vert,
                      size: 18,
                      color: AppColors.woodDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
                if (qty.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    qty,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
                if (showExpiryBar) ...[
                  const SizedBox(height: 8),
                  _ExpiryBar(item: item),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return PressScale(
      onTap: onTap,
      child: GestureDetector(onLongPress: onLongPress, child: card),
    );
  }
}

/// Pastilla compacta "No se compra" para los básicos (is_staple) sobre la
/// imagen de la tarjeta.
class _StapleBadge extends StatelessWidget {
  const _StapleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.woodDark),
      ),
      child: const Icon(
        Icons.remove_shopping_cart,
        size: 12,
        color: AppColors.woodDark,
      ),
    );
  }
}

/// BARRA DE CADUCIDAD de color para la tarjeta del grid.
///
/// El ancho relleno sale de [expiryBarFractionFor] (lógica pura de FEAT-002) y
/// el color del estado de caducidad del item:
/// - fresco  -> [AppColors.fresh] sobre [AppColors.freshBg]
/// - pronto  -> [AppColors.soon] sobre [AppColors.soonBg]
/// - caducado-> [AppColors.expired] sobre [AppColors.expiredBg]
/// - sinFecha-> barra neutra (madera sobre crema), sin señal de alarma.
///
/// La pista es una pastilla redondeada. El relleno puede animar con
/// [AppMotion.base], pero respeta "reducir movimiento": con reduce-motion se
/// pinta directamente el estado final sin animar.
class _ExpiryBar extends StatelessWidget {
  final InventoryItem item;
  const _ExpiryBar({required this.item});

  @override
  Widget build(BuildContext context) {
    final status = item.expiryStatus;
    final fraction = expiryBarFractionFor(item);

    final Color trackColor;
    final Color fillColor;
    switch (status) {
      case ExpiryStatus.fresco:
        trackColor = AppColors.freshBg;
        fillColor = AppColors.fresh;
        break;
      case ExpiryStatus.pronto:
        trackColor = AppColors.soonBg;
        fillColor = AppColors.soon;
        break;
      case ExpiryStatus.caducado:
        trackColor = AppColors.expiredBg;
        fillColor = AppColors.expired;
        break;
      case ExpiryStatus.sinFecha:
        trackColor = AppColors.cream;
        fillColor = AppColors.wood;
        break;
    }

    final reduceMotion = AppMotion.reduceMotionOf(context);

    return ClipRRect(
      borderRadius: AppRadius.pillRadius,
      child: Container(
        height: 8,
        color: trackColor,
        child: Align(
          alignment: Alignment.centerLeft,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final targetWidth = constraints.maxWidth * fraction;
              final fill = Container(
                height: 8,
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: AppRadius.pillRadius,
                ),
              );
              if (reduceMotion) {
                return SizedBox(width: targetWidth, child: fill);
              }
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: targetWidth),
                duration: AppMotion.base,
                curve: AppMotion.easeOut,
                builder: (context, width, child) =>
                    SizedBox(width: width, child: child),
                child: fill,
              );
            },
          ),
        ),
      ),
    );
  }
}
