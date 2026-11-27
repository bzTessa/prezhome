import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/recipe.dart';
import '../services/pantry_usage.dart';
import '../theme/app_theme.dart';
import '../utils/measure_format.dart';
import '../utils/shopping_display.dart';
import 'miau_character.dart';
import 'tactile_button.dart';

/// Elección de la usuaria tras terminar de cocinar un plato.
class PostCookChoice {
  const PostCookChoice({
    required this.deductPantry,
    required this.fridgeServings,
    required this.freezerServings,
    this.logToDiary = false,
  });

  final bool deductPantry;
  final int fridgeServings;
  final int freezerServings;

  /// Apuntar una ración en el diario de calorías de quien cocina.
  final bool logToDiary;

  bool get hasAction =>
      deductPantry || fridgeServings > 0 || freezerServings > 0 || logToDiary;
}

/// Hoja modal tras cocinar: propone descontar ingredientes usados de En casa y
/// repartir sobras entre Nevera (táper) y Congelador.
Future<PostCookChoice?> showPostCookSheet(
  BuildContext context, {
  required Recipe recipe,
  required int servingsCooked,
  required List<PantryUse> uses,
  int? diaryKcal,
}) {
  return showModalBottomSheet<PostCookChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => PostCookSheetContent(
      recipe: recipe,
      servingsCooked: servingsCooked,
      uses: uses,
      diaryKcal: diaryKcal,
      onDone: (choice) => Navigator.of(ctx).pop(choice),
    ),
  );
}

/// Contenido del cierre post-cocina, reutilizable en tests sin modal.
class PostCookSheetContent extends StatefulWidget {
  const PostCookSheetContent({
    super.key,
    required this.recipe,
    required this.servingsCooked,
    required this.uses,
    required this.onDone,
    this.diaryKcal,
  });

  /// Calorías de una ración, si quien cocina lleva el diario. Con null no se
  /// ofrece apuntarlo.
  final int? diaryKcal;

  final Recipe recipe;
  final int servingsCooked;
  final List<PantryUse> uses;
  final ValueChanged<PostCookChoice?> onDone;

  @override
  State<PostCookSheetContent> createState() => _PostCookSheetContentState();
}

class _PostCookSheetContentState extends State<PostCookSheetContent> {
  static const int _maxServings = 20;
  late bool _deduct = widget.uses.isNotEmpty;
  int _fridge = 0;
  int _freezer = 0;
  bool _diary = false;

  bool get _hasEffectiveDeduct => _deduct && widget.uses.isNotEmpty;
  bool get _hasEffectiveDiary => _diary && widget.diaryKcal != null;
  bool get _hasAction =>
      _hasEffectiveDeduct || _fridge > 0 || _freezer > 0 || _hasEffectiveDiary;

  String _formatUsed(PantryUse u) {
    final rounded = (u.used * 100).roundToDouble() / 100;
    final clean = (rounded - rounded.round()).abs() < 0.01
        ? rounded.roundToDouble()
        : rounded;
    return formatQuantityUnit(clean, u.unitOut);
  }

  void _stepFridge(int delta) {
    final next = (_fridge + delta).clamp(0, _maxServings);
    if (next == _fridge) return;
    HapticFeedback.selectionClick();
    setState(() => _fridge = next);
  }

  void _stepFreezer(int delta) {
    final next = (_freezer + delta).clamp(0, _maxServings);
    if (next == _freezer) return;
    HapticFeedback.selectionClick();
    setState(() => _freezer = next);
  }

  void _submit() {
    if (!_hasAction) {
      widget.onDone(null);
      return;
    }
    widget.onDone(
      PostCookChoice(
        deductPantry: _hasEffectiveDeduct,
        fridgeServings: _fridge,
        freezerServings: _freezer,
        logToDiary: _hasEffectiveDiary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uses = widget.uses;
    final preview = uses.take(4).toList();
    final extraCount = uses.length - preview.length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const MiauCharacter(
                  mood: MiauMood.celebrating,
                  size: 78,
                  float: false,
                  interactive: true,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l.pcTitle,
                        style: AppTextStyles.display.copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        shoppingCleanName(widget.recipe.title),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Tarjeta 1: Descontar de En casa.
            Container(
              padding: uses.isNotEmpty
                  ? const EdgeInsets.fromLTRB(4, 4, 4, 12)
                  : const EdgeInsets.all(16),
              decoration: AppTheme.surfaceDecoration(),
              child: uses.isEmpty
                  ? Row(
                      children: [
                        Icon(
                          Icons.kitchen_outlined,
                          color: AppColors.inkMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.l.pcNoIngredients,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Material(
                      type: MaterialType.transparency,
                      borderRadius: AppRadius.lgRadius,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile.adaptive(
                            value: _deduct,
                            activeThumbColor: AppColors.sage,
                            onChanged: (v) {
                              HapticFeedback.selectionClick();
                              setState(() => _deduct = v);
                            },
                            title: Text(
                              context.l.pcDeductTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.ink,
                              ),
                            ),
                            subtitle: Text(
                              context.l.pcDeductSubtitle(uses.length),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ),
                          if (_deduct)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final u in preview)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 3,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              shoppingCleanName(u.item.name),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '−${_formatUsed(u)}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.sage,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (extraCount > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        context.l.pcMoreItems(extraCount),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.inkMuted,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            // Tarjeta 2: Guardar sobras como platos listos (Nevera / Congelador).
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.surfaceDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l.pcLeftoversTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l.pcLeftoversHint,
                    style: TextStyle(fontSize: 12.5, color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: 14),
                  _LeftoverRow(
                    icon: Icons.kitchen_rounded,
                    iconBg: AppColors.sageBg,
                    iconColor: AppColors.sage,
                    title: context.l.pcFridgeLabel,
                    subtitle: context.l.pcFridgeHint,
                    countLabel: context.l.pcServingsCount(_fridge),
                    minusKey: const ValueKey('post-cook-fridge-minus'),
                    plusKey: const ValueKey('post-cook-fridge-plus'),
                    onMinus: _fridge > 0 ? () => _stepFridge(-1) : null,
                    onPlus: _fridge < _maxServings
                        ? () => _stepFridge(1)
                        : null,
                  ),
                  Divider(height: 20, color: AppColors.line),
                  _LeftoverRow(
                    icon: Icons.ac_unit_rounded,
                    iconBg: AppColors.frostBg,
                    iconColor: AppColors.frost,
                    title: context.l.pcFreezerLabel,
                    subtitle: widget.recipe.freezesWell
                        ? context.l.pcFreezerGreat
                        : context.l.pcFreezerHint,
                    countLabel: context.l.pcServingsCount(_freezer),
                    minusKey: const ValueKey('post-cook-freezer-minus'),
                    plusKey: const ValueKey('post-cook-freezer-plus'),
                    onMinus: _freezer > 0 ? () => _stepFreezer(-1) : null,
                    onPlus: _freezer < _maxServings
                        ? () => _stepFreezer(1)
                        : null,
                  ),
                ],
              ),
            ),
            if (widget.diaryKcal case final kcal?) ...[
              const SizedBox(height: 12),
              // Tarjeta 3: apuntarlo en el diario (solo si se lleva).
              Container(
                decoration: AppTheme.surfaceDecoration(),
                child: Material(
                  type: MaterialType.transparency,
                  borderRadius: AppRadius.lgRadius,
                  clipBehavior: Clip.antiAlias,
                  child: SwitchListTile.adaptive(
                    key: const ValueKey('post-cook-diary'),
                    value: _diary,
                    activeThumbColor: AppColors.sage,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _diary = v);
                    },
                    title: Text(
                      context.l.pcDiaryTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.ink,
                      ),
                    ),
                    subtitle: Text(
                      context.l.pcDiarySub(kcal),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            TactileButton(
              label: !_hasAction
                  ? context.l.pcJustClose
                  : (_hasEffectiveDeduct || _fridge > 0 || _freezer > 0)
                  ? context.l.pcConfirm
                  : context.l.pcDiaryOnly,
              icon: _hasAction ? Icons.check_rounded : null,
              onPressed: _submit,
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: () => widget.onDone(null),
                child: Text(context.l.notNow),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftoverRow extends StatelessWidget {
  const _LeftoverRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.countLabel,
    required this.minusKey,
    required this.plusKey,
    required this.onMinus,
    required this.onPlus,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String countLabel;
  final Key minusKey;
  final Key plusKey;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: iconBg,
          child: Icon(icon, size: 19, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _CompactStepper(
          label: countLabel,
          minusKey: minusKey,
          plusKey: plusKey,
          onMinus: onMinus,
          onPlus: onPlus,
        ),
      ],
    );
  }
}

class _CompactStepper extends StatelessWidget {
  const _CompactStepper({
    required this.label,
    required this.minusKey,
    required this.plusKey,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final Key minusKey;
  final Key plusKey;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.iconTile,
      shape: StadiumBorder(side: BorderSide(color: AppColors.cardEdge)),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(
            key: minusKey,
            icon: Icons.remove_rounded,
            tooltip: context.l.less,
            onTap: onMinus,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          _StepBtn(
            key: plusKey,
            icon: Icons.add_rounded,
            tooltip: context.l.more,
            onTap: onPlus,
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 18,
            color: onTap == null ? AppColors.line : AppColors.woodDark,
          ),
        ),
      ),
    );
  }
}
