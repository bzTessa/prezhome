import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../utils/kitchen_zones.dart';

/// "Mi cocina": fila de chips con todas las zonas (nevera, congelador,
/// despensa…) que funciona como pestañas: debajo solo se ve la zona elegida.
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
        const SizedBox(height: AppSpacing.sm),
        // Una fila de chips: la lista de la zona queda justo debajo, en la
        // primera pantalla.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              // Las vacías también, para poder entrar y añadir.
              for (final z in zones)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: _ZoneChip(
                    summary: z,
                    selected: selected == z.zone,
                    onTap: () => onSelect(z.zone),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ZoneChip extends StatelessWidget {
  const _ZoneChip({
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
    // Un punto avisa de lo caducado (rojo) o de lo que caduca pronto.
    final alert = z.expired > 0
        ? AppColors.expired
        : z.soon > 0
        ? AppColors.soon
        : null;
    final empty = count == 0 && !selected;
    final fg = selected ? AppColors.card : AppColors.ink;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label: $count productos',
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: AppMotion.fast,
        opacity: empty ? 0.55 : 1,
        child: Material(
          color: selected ? AppColors.ink : AppColors.card,
          shape: StadiumBorder(
            side: BorderSide(
              color: selected ? AppColors.ink : AppColors.line,
              width: 1.5,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(s.icon, size: 18, color: selected ? fg : s.fg),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? fg.withValues(alpha: 0.75)
                            : AppColors.inkMuted,
                      ),
                    ),
                    if (alert != null) ...[
                      const SizedBox(width: 5),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: alert,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
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
