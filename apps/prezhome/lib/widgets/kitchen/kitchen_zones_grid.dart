import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../utils/kitchen_zones.dart';

/// "Mi cocina": rejilla con todas las zonas (nevera, congelador, despensa…)
/// que funciona como pestañas: debajo solo se ve la zona elegida. Si algo
/// caduca, la primera es "Revisar", con lo urgente de todas las zonas.
class KitchenZonesGrid extends StatelessWidget {
  const KitchenZonesGrid({
    super.key,
    required this.zones,
    required this.selected,
    required this.onSelect,
    this.trailing,
  });

  final List<ZoneSummary> zones;

  /// Zona elegida, o null para "Revisar" (lo que caduca, de todas las zonas).
  final KitchenZone? selected;
  final ValueChanged<KitchenZone?> onSelect;

  /// Acciones de la cabecera (p. ej. el menú para vaciar).
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
        KitchenZone.bebidas => (
          bg: AppColors.terracottaBg,
          fg: AppColors.terracotta,
          icon: Icons.local_drink_rounded,
        ),
        KitchenZone.especias => (
          bg: AppColors.soonBg,
          fg: AppColors.soon,
          icon: Icons.grass_rounded,
        ),
        KitchenZone.hogar => (
          bg: AppColors.lilacBg,
          fg: AppColors.lilac,
          icon: Icons.cleaning_services_rounded,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final total = zones.fold<int>(0, (s, z) => s + z.count);
    final visible = zones.where((z) => z.count > 0 || z.zone == selected);
    final urgent = ZoneSummary(
      zone: KitchenZone.despensa,
      count: zones.fold(0, (s, z) => s + z.soon + z.expired),
      soon: zones.fold(0, (s, z) => s + z.soon),
      expired: zones.fold(0, (s, z) => s + z.expired),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Mi cocina',
              style: TextStyle(
                fontSize: 26,
                letterSpacing: -0.6,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '$total productos',
              style: TextStyle(color: AppColors.inkMuted),
            ),
            const Spacer(),
            ?trailing,
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Todas las zonas a la vista, en rejilla de tres: sin deslizar para
        // encontrar las bebidas o las especias.
        LayoutBuilder(
          builder: (context, c) {
            const gap = AppSpacing.sm;
            final w = (c.maxWidth - gap * 2) / 3;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                if (urgent.expired + urgent.soon > 0)
                  _ZoneTile.all(
                    total: urgent,
                    width: w,
                    selected: selected == null,
                    onTap: () => onSelect(null),
                  ),
                for (final z in visible)
                  _ZoneTile(
                    summary: z,
                    width: w,
                    selected: selected == z.zone,
                    onTap: () => onSelect(z.zone),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ZoneTile extends StatelessWidget {
  const _ZoneTile({
    required ZoneSummary this.summary,
    required this.width,
    required this.selected,
    required this.onTap,
  }) : total = null;

  const _ZoneTile.all({
    required ZoneSummary this.total,
    required this.width,
    required this.selected,
    required this.onTap,
  }) : summary = null;

  /// Null en la tarjeta "Revisar".
  final ZoneSummary? summary;

  /// Lo urgente de todas las zonas, solo en la tarjeta "Revisar".
  final ZoneSummary? total;
  final double width;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final z = summary ?? total!;
    final isAll = summary == null;
    final s = isAll
        ? (
            bg: AppColors.expiredBg,
            fg: AppColors.expired,
            icon: Icons.notifications_active_rounded,
          )
        : KitchenZonesGrid.styleOf(z.zone);
    final label = isAll ? 'Revisar' : z.zone.label;
    final count = z.count;
    final alert = z.expired > 0
        ? (
            '${z.expired} caducado${z.expired == 1 ? '' : 's'}',
            AppColors.expired,
          )
        : z.soon > 0
        ? ('${z.soon} pronto', AppColors.soon)
        : null;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label: $count productos',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            width: width,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: s.bg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected ? s.fg : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isAll)
                      SizedBox.square(
                        dimension: 30,
                        child: Icon(s.icon, color: s.fg, size: 20),
                      )
                    else
                      // Ilustración de la zona: assets/images/zona_<etiqueta>.png
                      Image.asset(
                        'assets/images/zona_${z.zone.label.toLowerCase()}.png',
                        width: 30,
                        height: 30,
                        errorBuilder: (_, _, _) =>
                            Icon(s.icon, color: s.fg, size: 20),
                      ),
                    const Spacer(),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontSize: 18,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: s.fg,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  alert?.$1 ?? 'Al día',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: alert == null
                        ? FontWeight.w500
                        : FontWeight.w800,
                    color: alert?.$2 ?? AppColors.inkMuted,
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
