import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../utils/kitchen_zones.dart';

/// "Mi cocina": una tarjeta grande por zona (nevera, congelador, despensa…)
/// con cuántos productos hay y cuántos caducan. Tocar una zona la filtra;
/// tocarla de nuevo (o "Ver todo") quita el filtro.
class KitchenZonesGrid extends StatelessWidget {
  const KitchenZonesGrid({
    super.key,
    required this.zones,
    required this.selected,
    required this.onSelect,
  });

  final List<ZoneSummary> zones;

  /// Zona filtrada o null si se ve todo.
  final KitchenZone? selected;
  final ValueChanged<KitchenZone?> onSelect;

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
          bg: const Color(0xFFEDE7F3),
          fg: const Color(0xFF6E5A8A),
          icon: Icons.cleaning_services_rounded,
        ),
      };

  // Esquinas distintas por posición: formas más orgánicas que un rectángulo.
  static const _shapes = [
    BorderRadius.only(
      topLeft: Radius.circular(36),
      topRight: Radius.circular(18),
      bottomLeft: Radius.circular(22),
      bottomRight: Radius.circular(40),
    ),
    BorderRadius.only(
      topLeft: Radius.circular(18),
      topRight: Radius.circular(40),
      bottomLeft: Radius.circular(36),
      bottomRight: Radius.circular(20),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final total = zones.fold<int>(0, (s, z) => s + z.count);
    final visible = zones.where((z) => z.count > 0 || z.zone == selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              'Mi cocina',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '$total productos',
              style: const TextStyle(color: AppColors.inkMuted),
            ),
            const Spacer(),
            if (selected != null)
              TextButton(
                onPressed: () => onSelect(null),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.woodDark,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Ver todo'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, c) {
            const gap = AppSpacing.md;
            final w = (c.maxWidth - gap) / 2;
            var i = 0;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final z in visible)
                  SizedBox(
                    width: w,
                    child: _ZoneTile(
                      summary: z,
                      shape: _shapes[i++ % 2],
                      selected: selected == z.zone,
                      dimmed: selected != null && selected != z.zone,
                      onTap: () => onSelect(selected == z.zone ? null : z.zone),
                    ),
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
    required this.summary,
    required this.shape,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final ZoneSummary summary;
  final BorderRadius shape;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = KitchenZonesGrid.styleOf(summary.zone);
    final alert = summary.expired > 0
        ? (
            '${summary.expired} caducado${summary.expired == 1 ? '' : 's'}',
            AppColors.terracotta,
          )
        : summary.soon > 0
        ? ('${summary.soon} caduca${summary.soon == 1 ? '' : 'n'} pronto', s.fg)
        : null;

    return Semantics(
      button: true,
      selected: selected,
      label: '${summary.zone.label}: ${summary.count} productos',
      child: AnimatedOpacity(
        duration: AppMotion.fast,
        opacity: dimmed ? 0.55 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: shape,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              height: 132,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: s.bg,
                borderRadius: shape,
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
                      Expanded(
                        child: Text(
                          summary.zone.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      Icon(s.icon, color: s.fg, size: 22),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '${summary.count}',
                    style: TextStyle(
                      fontSize: 34,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color: s.fg,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert?.$1 ??
                        (summary.count == 1 ? 'producto' : 'productos'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
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
      ),
    );
  }
}
