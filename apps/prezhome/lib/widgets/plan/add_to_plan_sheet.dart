import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/l10n.dart';
import '../../models/meal_plan_entry.dart';
import '../../models/recipe.dart';
import '../../theme/app_theme.dart';
import '../../utils/friendly_error.dart';

/// "Poner en el plan" desde una receta: elige día (esta semana) y comida.
/// Si ya hay algo en esa comida, se añade como otro plato.
Future<void> addRecipeToPlan(BuildContext context, Recipe recipe) => addToPlan(
  context,
  homeId: recipe.homeId,
  title: recipe.title,
  recipeId: recipe.id,
  servings: recipe.servings,
  mealTypes: recipe.mealTypes,
);

/// Lo mismo para una receta ([recipeId]) o un preparado ([readyMealId]).
Future<void> addToPlan(
  BuildContext context, {
  required String homeId,
  required String title,
  String? recipeId,
  String? readyMealId,
  int servings = 2,
  List<String> mealTypes = const [],
}) async {
  const meals = ['breakfast', 'lunch', 'snack', 'dinner', 'dessert'];
  final today = DateTime.now();
  final days = [
    for (var i = 0; i < 7; i++)
      DateTime(today.year, today.month, today.day + i),
  ];
  var day = days.first;
  var meal = mealTypes.firstWhere(
    meals.contains,
    orElse: () => today.hour < 16 ? 'lunch' : 'dinner',
  );
  final locale = Localizations.localeOf(context).toString();
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ctx.l.apTitle, style: AppTextStyles.headline),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 16),
            Text(ctx.l.apDay, style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (i, d) in days.indexed)
                  ChoiceChip(
                    label: Text(
                      i == 0
                          ? ctx.l.apToday
                          : i == 1
                          ? ctx.l.apTomorrow
                          : DateFormat.E(locale).format(d),
                    ),
                    selected: d == day,
                    onSelected: (_) => set(() => day = d),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(ctx.l.apMeal, style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in meals)
                  ChoiceChip(
                    label: Text(ctx.l.mealType(m)),
                    selected: m == meal,
                    onSelected: (_) => set(() => meal = m),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(ctx.l.apAdd),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (ok != true || !context.mounted) return;
  final l = context.l;
  final messenger = ScaffoldMessenger.of(context);
  final client = Supabase.instance.client;
  final dayKey = day.toIso8601String().split('T').first;
  try {
    final slot = await client
        .from('meal_plan_entries')
        .select('id')
        .eq('home_id', homeId)
        .eq('plan_date', dayKey)
        .eq('meal_type', meal);
    await client
        .from('meal_plan_entries')
        .insert(
          MealPlanEntry(
            homeId: homeId,
            date: day,
            mealType: meal,
            recipeId: recipeId,
            readyMealId: readyMealId,
            servings: servings,
            position: (slot as List).length,
          ).toMap(),
        );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          l.apDone(
            l.mealType(meal).toLowerCase(),
            DateFormat.EEEE(locale).format(day),
          ),
        ),
      ),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(friendlyError(e, l.couldNotSave)),
        backgroundColor: AppColors.expired,
      ),
    );
  }
}
