import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../animations/spring_value.dart';
import '../../l10n/l10n.dart';
import '../../utils/kitchen_zones.dart';

/// "Mi cocina": rejilla con todas las zonas (nevera, congelador, despensa…)
/// que funciona como pestañas: debajo solo se ve la zona elegida.
class KitchenZonesGrid extends StatelessWidget {
  const KitchenZonesGrid({
    super.key,
    required this.zones,
    required this.selected,
    required this.onSelect,
    this.trailing,
  });

  final List<ZoneSummary> zones;

  final KitchenZone? selected;
  final ValueChanged<KitchenZone> onSelect;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(context.l.kzMyKitchen, style: AppTextStyles.display),
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
        // Todas las zonas a la vista, de dos en dos y con su dibujo grande.
        LayoutBuilder(
          builder: (context, c) {
            const gap = AppSpacing.sm;
            final w = (c.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                // Las vacías también, para poder entrar y añadir.
                for (final z in zones)
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
    required this.summary,
    required this.width,
    required this.selected,
    required this.onTap,
  });

  final ZoneSummary summary;
  final double width;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final z = summary;
    final s = KitchenZonesGrid.styleOf(z.zone);
    final label = context.l.kitchenZone(z.zone.name);
    final count = z.count;
    final alert = z.expired > 0
        ? (
            '${z.expired} caducado${z.expired == 1 ? '' : 's'}',
            AppColors.expired,
          )
        : z.soon > 0
        ? ('${z.soon} pronto', AppColors.soon)
        : null;
    final empty = count == 0 && !selected;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label: $count productos',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          // Pieza táctil: la elegida queda "hundida" con un muelle.
          child: SpringValue(
            value: selected ? 1 : 0,
            spring: AppMotion.fluidBouncy,
            builder: (context, p, child) => Transform.translate(
              offset: Offset(0, AppElevation.restOffset * p),
              child: child,
            ),
            child: AnimatedOpacity(
              duration: AppMotion.fast,
              opacity: empty ? 0.6 : 1,
              child: AnimatedContainer(
                duration: AppMotion.fast,
                width: width,
                height: 118,
                clipBehavior: Clip.antiAlias,
                decoration: AppTheme.tactileDecoration(
                  radius: AppRadius.lg,
                  color: AppColors.card,
                  borderWidth: selected ? 2 : 1.5,
                  shadow: selected ? 0 : AppElevation.restOffset,
                ),
                child: Stack(
                  children: [
                    // Mitad de abajo con el color de la zona y su dibujo.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 58,
                      child: ColoredBox(color: s.bg),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 4,
                      child: Image.asset(
                        // assets/images/zona_<1.ª palabra>.png
                        'assets/images/zona_${z.zone.label.split(' ').first.toLowerCase()}.png',
                        width: 64,
                        height: 64,
                        errorBuilder: (_, _, _) =>
                            Icon(s.icon, color: s.fg, size: 40),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.headline.copyWith(
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: count == 0
                                      ? context.l.kzEmpty
                                      : alert != null
                                      ? '$count'
                                      : '$count producto${count == 1 ? '' : 's'}',
                                ),
                                if (alert != null) ...[
                                  const TextSpan(text: ' · '),
                                  TextSpan(
                                    text: alert.$1,
                                    style: TextStyle(
                                      color: alert.$2,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
