import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';

import '../../services/meal_prep_planner.dart';
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < days.length; i++) Expanded(child: _day(context, i)),
      ],
    );
  }

  Widget _day(BuildContext context, int i) {
    final d = days[i];
    final abbr = _weekdayAbbr(context, d);
    final isSelected = i == selected;
    final isToday =
        d.year == today.year && d.month == today.month && d.day == today.day;
    final meals = mealsPerDay[i];
    return Semantics(
      button: true,
      selected: isSelected,
      label: context.l.ppDayMeals('$abbr ${d.day}', meals),
      child: InkWell(
        onTap: () => onSelect(i),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Text(
                abbr,
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
                        decoration: BoxDecoration(
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
    this.time,
    this.inFast = false,
  });

  final String mealType;

  /// Hora de la comida ("14:00") y si cae en el ayuno.
  final String? time;
  final bool inFast;
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
    // Hueco con receta: tarjeta táctil (trazo y sombra dura). Vacío: plano
    // y tenue, para que se vea que falta algo.
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: empty ? AppElevation.level0 : AppElevation.level1,
        ),
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
                  color: empty
                      ? s.fg.withValues(alpha: 0.35)
                      : AppColors.stroke,
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
                        borderRadius: BorderRadius.circular(16),
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
                              context.l.mealType(mealType).toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: s.fg,
                              ),
                            ),
                            if (time != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                inFast ? context.l.ppFastTime(time!) : time!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ],
                            if (skipped) ...[
                              const SizedBox(width: 6),
                              Text(
                                context.l.ppEatOut,
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
                          empty ? context.l.mealAdd(mealType) : title!,
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
                          Padding(
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
                                  context.l.ppFromFreezer,
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
      ),
    );
  }
}

/// Icono y color de cada aviso de la cocina en lote.
({IconData icon, Color fg, Color bg}) prepEventStyle(PrepEventKind k) =>
    switch (k) {
      PrepEventKind.compra => (
        icon: Icons.shopping_cart_outlined,
        fg: AppColors.sage,
        bg: AppColors.sageBg,
      ),
      PrepEventKind.cocina => (
        icon: Icons.outdoor_grill_outlined,
        fg: AppColors.terracotta,
        bg: AppColors.terracottaBg,
      ),
      PrepEventKind.sacar => (
        icon: Icons.ac_unit_rounded,
        fg: AppColors.frost,
        bg: AppColors.frostBg,
      ),
    };

/// Un aviso de la cocina en lote (compra, cocinar, pasar a la nevera): icono
/// en un círculo de color, fecha pequeña y el texto sobre la tarjeta, sin
/// bloque de color de fondo.
class PrepEventTile extends StatelessWidget {
  const PrepEventTile({
    super.key,
    required this.event,
    this.showDate = false,
    this.batches = const [],
  });

  final PrepEvent event;

  /// En la agenda de la semana se antepone el día ("JUE 29").
  final bool showDate;

  /// Tandas de ese día de cocina: si vienen, cada receta se pinta en su fila
  /// con chips de adónde va (en lugar de las líneas de texto del aviso).
  final List<PrepBatch> batches;

  @override
  Widget build(BuildContext context) {
    final s = prepEventStyle(event.kind);
    final d = event.date;
    final structured = batches.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: s.bg, shape: BoxShape.circle),
            child: Icon(s.icon, size: 19, color: s.fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showDate)
                  Text(
                    '${_weekdayAbbr(context, d)} ${d.day}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: s.fg,
                    ),
                  ),
                Text(
                  event.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
                if (structured) ...[
                  for (final b in batches) _BatchRow(batch: b, cookDay: d),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      context.l.ppTapersAuto,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                ] else
                  for (final l in event.lines)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        l,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Una receta del día de cocina: nombre, raciones y chips de adónde va.
class _BatchRow extends StatelessWidget {
  const _BatchRow({required this.batch, required this.cookDay});

  final PrepBatch batch;
  final DateTime cookDay;

  @override
  Widget build(BuildContext context) {
    final t = batch.title;
    final n = batch.totalServings;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  t.isEmpty ? t : t[0].toUpperCase() + t.substring(1),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.l.ppServings(n),
                style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (spot, days) in taperSpots(batch, cookDay))
                _spotChip(context, spot, days),
            ],
          ),
        ],
      ),
    );
  }

  Widget _spotChip(BuildContext context, TaperSpot spot, String days) {
    final (icon, label, fg, bg) = switch (spot) {
      TaperSpot.reciente => (
        Icons.restaurant_rounded,
        context.l.ppFresh,
        AppColors.woodDark,
        AppColors.goldBg,
      ),
      TaperSpot.nevera => (
        Icons.kitchen_outlined,
        context.l.ppFridge(days),
        AppColors.sage,
        AppColors.sageBg,
      ),
      TaperSpot.congelador => (
        Icons.ac_unit_rounded,
        context.l.ppFreezer(days),
        AppColors.frost,
        AppColors.frostBg,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Día de la semana abreviado en el idioma del dispositivo ("LUN", "MON").
String _weekdayAbbr(BuildContext context, DateTime d) => DateFormat.E(
  Localizations.localeOf(context).toString(),
).format(d).replaceAll('.', '').toUpperCase();
