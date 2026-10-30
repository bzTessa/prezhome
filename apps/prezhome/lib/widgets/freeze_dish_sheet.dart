import 'package:flutter/material.dart';

import '../models/inventory_item.dart';
import '../models/recipe.dart';
import '../services/meal_prep_planner.dart';
import '../theme/app_theme.dart';
import 'shopping/shopping_parts.dart';
import 'tactile_button.dart';

/// Pregunta cuántas raciones de [recipe] van al congelador. Devuelve las
/// raciones, o null si se cierra con "Ahora no".
Future<int?> askFreezeServings(
  BuildContext context, {
  required Recipe recipe,
  required int initial,
  String title = '¿Guardas raciones en el congelador?',
}) {
  var servings = initial < 1 ? 1 : initial;
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(recipe.title, style: TextStyle(color: AppColors.inkMuted)),
              const SizedBox(height: 16),
              QuantityStepper(
                label: servings == 1 ? '1 ración' : '$servings raciones',
                onMinus: servings <= 1
                    ? null
                    : () => setSheet(() => servings -= 1),
                onPlus: () => setSheet(() => servings += 1),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TactileButton(
                  label: 'Guardar en el congelador',
                  icon: Icons.ac_unit,
                  onPressed: () => Navigator.of(ctx).pop(servings),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Ahora no'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Plato listo en el congelador con la foto y el nombre de la receta, para que
/// el plan de comidas pueda tirar de él.
InventoryItem frozenDishItem(Recipe recipe, int servings, {String? homeId}) {
  final now = DateTime.now();
  final days = recipe.freezerDays ?? kDiasCongeladorPorDefecto;
  return InventoryItem(
    id: '',
    homeId: homeId ?? recipe.homeId,
    name: recipe.title,
    category: 'Congelador',
    quantity: 1,
    unit: 'comidas',
    kind: 'dish',
    recipeId: recipe.id,
    servings: servings.toDouble(),
    frozenOn: now,
    bestBefore: days > 0 ? DateTime(now.year, now.month, now.day + days) : null,
    imageUrl: recipe.imageUrl,
  );
}
