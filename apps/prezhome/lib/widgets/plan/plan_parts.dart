import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';

/// Piezas visuales del plan semanal de comidas.

/// Estilo (etiqueta, icono, colores) de cada tipo de comida.
({String label, IconData icon, Color fg, Color bg}) mealStyle(String type) =>
    switch (type) {
      'breakfast' => (
        label: 'Desayuno',
        icon: Icons.free_breakfast_rounded,
        fg: AppColors.peach,
        bg: AppColors.peachBg,
      ),
      'lunch' => (
        label: 'Comida',
        icon: Icons.restaurant_rounded,
        fg: AppColors.sage,
        bg: AppColors.sageBg,
      ),
      'snack' => (
        label: 'Merienda',
        icon: Icons.cookie_rounded,
        fg: AppColors.terracotta,
        bg: AppColors.terracottaBg,
      ),
      'dinner' => (
        label: 'Cena',
        icon: Icons.dinner_dining_rounded,
        fg: AppColors.frost,
        bg: AppColors.frostBg,
      ),
      'dessert' => (
        label: 'Postre',
        icon: Icons.cake_rounded,
        fg: AppColors.soon,
        bg: AppColors.soonBg,
      ),
      _ => (
        label: type,
        icon: Icons.restaurant_menu_rounded,
        fg: AppColors.woodDark,
        bg: AppColors.cream,
      ),
    };

/// Tira de los 7 días de la semana. Cada día lleva puntitos con las comidas
/// planificadas; el elegido va relleno y hoy lleva aro.
class WeekDayStrip extends StatelessWidget {
  const WeekDayStrip({
    super.key,
    required this.days,
    required this.selected,
    required this.mealsPerDay,
    required this.onSelect,
    required this.today,
  });

  final List<DateTime> days;
  final int selected;

  /// Comidas planificadas por índice de día (0 = lunes).
  final List<int> mealsPerDay;
  final ValueChanged<int> onSelect;
  final DateTime today;

  static const _abbr = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < days.length; i++) Expanded(child: _day(i)),
      ],
    );
  }

  Widget _day(int i) {
    final d = days[i];
    final isSelected = i == selected;
    final isToday =
        d.year == today.year && d.month == today.month && d.day == today.day;
    final meals = mealsPerDay[i];
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${_abbr[d.weekday - 1]} ${d.day}, $meals comidas',
      child: InkWell(
        onTap: () => onSelect(i),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Text(
                _abbr[d.weekday - 1],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: isSelected ? AppColors.ink : AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: AppMotion.fast,
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.ink : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isToday && !isSelected
                        ? AppColors.woodDark
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(
                  '${d.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? AppColors.cream : AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var k = 0; k < meals.clamp(0, 4); k++)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: const BoxDecoration(
                          color: AppColors.woodDark,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hueco de una comida del día. Con receta: foto, título y raciones; vacío:
/// invitación a añadir.
class MealSlotCard extends StatelessWidget {
  const MealSlotCard({
    super.key,
    required this.mealType,
    required this.onTap,
    this.title,
    this.image,
    this.detail,
    this.skipped = false,
    this.fromFreezer = false,
  });

  final String mealType;
  final VoidCallback onTap;

  /// Título de la receta, o null si el hueco está vacío.
  final String? title;
  final Widget? image;
  final Widget? detail;
  final bool skipped;
  final bool fromFreezer;

  @override
  Widget build(BuildContext context) {
    final s = mealStyle(mealType);
    final empty = title == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: empty ? s.bg.withValues(alpha: 0.55) : AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: empty ? s.fg.withValues(alpha: 0.35) : s.bg,
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                if (!empty && image != null)
                  Opacity(opacity: skipped ? 0.4 : 1, child: image!)
                else
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: empty ? AppColors.card : s.bg,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(s.icon, color: s.fg, size: 28),
                  ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(s.icon, size: 14, color: s.fg),
                          const SizedBox(width: 4),
                          Text(
                            s.label.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: s.fg,
                            ),
                          ),
                          if (skipped) ...[
                            const SizedBox(width: 6),
                            const Text(
                              '· Fuera',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        empty ? 'Añadir ${s.label.toLowerCase()}' : title!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: empty ? AppColors.inkMuted : AppColors.ink,
                          decoration: skipped
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (!empty && detail != null) detail!,
                      if (fromFreezer)
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(
                                Icons.ac_unit_rounded,
                                size: 13,
                                color: AppColors.frost,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Del congelador',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.frost,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  empty ? Icons.add_circle_rounded : Icons.more_horiz_rounded,
                  color: empty ? s.fg : AppColors.inkMuted,
                  size: empty ? 28 : 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
