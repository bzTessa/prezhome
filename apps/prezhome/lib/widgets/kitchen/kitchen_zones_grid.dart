import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../utils/kitchen_zones.dart';
import '../animations/press_scale.dart';

/// "Mi cocina": cuadrícula de zonas (nevera, congelador, despensa…) con las
/// ilustraciones propias de cada zona. Tocar una muestra debajo su contenido.
class KitchenZonesGrid extends StatelessWidget {
  const KitchenZonesGrid({
    super.key,
    required this.zones,
    required this.selected,
    required this.onSelect,
    this.onAdd,
    this.trailing,
  });

  final List<ZoneSummary> zones;
  final KitchenZone? selected;
  final ValueChanged<KitchenZone> onSelect;

  /// Botón rápido "+" en la cabecera (p. ej. dentro de Compra > En casa).
  final VoidCallback? onAdd;

  /// Acciones de la cabecera (p. ej. el menú para limpiar).
  final Widget? trailing;

  static ({Color bg, Color fg, IconData icon}) styleOf(KitchenZone z) =>
      switch (z) {
        KitchenZone.nevera => (
          bg: AppColors.sageBg,
          fg: AppColors.sage,
          icon: Icons.kitchen_rounded,
        ),
        KitchenZone.congelador => (
          bg: AppColors.frostBg,
          fg: AppColors.frost,
          icon: Icons.ac_unit_rounded,
        ),
        KitchenZone.despensa => (
          bg: AppColors.peachBg,
          fg: AppColors.peach,
          icon: Icons.inventory_2_rounded,
        ),
        KitchenZone.especias => (
          bg: AppColors.soonBg,
          fg: AppColors.soon,
          icon: Icons.grass_rounded,
        ),
        KitchenZone.limpieza => (
          bg: AppColors.lilacBg,
          fg: AppColors.lilac,
          icon: Icons.cleaning_services_rounded,
        ),
        KitchenZone.hogar => (
          bg: AppColors.frostBg,
          fg: AppColors.frost,
          icon: Icons.soap_rounded,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final total = zones.fold<int>(0, (s, z) => s + z.count);
    final rows = <List<ZoneSummary>>[
      for (var i = 0; i < zones.length; i += 3) zones.skip(i).take(3).toList(),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      context.l.kzMyKitchen,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.display,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '$total productos',
                    style: TextStyle(color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
            if (onAdd != null)
              IconButton(
                tooltip: context.l.panAddTooltip,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.add_rounded, color: AppColors.ink),
                onPressed: onAdd,
              ),
            ?trailing,
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (var c = 0; c < 3; c++) ...[
                if (c > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: c < rows[r].length
                      ? _ZoneTile(
                          summary: rows[r][c],
                          selected: selected == rows[r][c].zone,
                          onTap: () => onSelect(rows[r][c].zone),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _ZoneTile extends StatelessWidget {
  const _ZoneTile({
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  final ZoneSummary summary;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final z = summary;
    final s = KitchenZonesGrid.styleOf(z.zone);
    final label = context.l.kitchenZone(z.zone.name);
    final count = z.count;
    // Un punto avisa de lo caducado (rojo) o de lo que caduca pronto (ámbar).
    final alert = z.expired > 0
        ? AppColors.expired
        : z.soon > 0
        ? AppColors.soon
        : null;
    final empty = count == 0 && !selected;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label: $count productos',
      excludeSemantics: true,
      child: PressScale(
        onTap: onTap,
        pressedScale: 0.97,
        child: AnimatedOpacity(
          duration: AppMotion.effectiveDuration(
            AppMotion.fast,
            reduceMotion: AppMotion.reduceMotionOf(context),
          ),
          opacity: empty ? 0.65 : 1,
          child: AnimatedContainer(
            duration: AppMotion.effectiveDuration(
              AppMotion.fast,
              reduceMotion: AppMotion.reduceMotionOf(context),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? s.bg : AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: selected
                  ? Border.all(color: s.fg, width: 1.75)
                  : AppElevation.border,
              boxShadow: selected ? AppElevation.level1 : AppElevation.level0,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        z.zone.assetPath,
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                        cacheWidth: 96,
                        errorBuilder: (_, _, _) =>
                            Icon(s.icon, size: 28, color: s.fg),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$count',
                        style: AppTextStyles.numeric(
                          TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (alert != null)
                  Positioned(
                    top: 0,
                    right: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: alert,
                        shape: BoxShape.circle,
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
