import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/inventory_item.dart';
import '../utils/approx_price.dart';
import '../utils/ticket_date.dart';
import 'price_memory.dart';

/// Lo que el generador del plan necesita saber de la casa además de las
/// recetas: qué caduca pronto, cuánto cuesta cada receta y cómo va el mes.
class PlanHints {
  const PlanHints({
    this.expiring = const {},
    this.costPerServing = const {},
    this.budgetPressure = 0,
  });

  final Set<String> expiring;
  final Map<String, double> costPerServing;

  /// 0 = sin presupuesto, 1 = hay presupuesto, 2 = el mes va por encima.
  final int budgetPressure;

  /// Best-effort: si algo falla, el plan se genera como siempre.
  static Future<PlanHints> load(SupabaseClient client, String homeId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final monthStart = DateTime(now.year, now.month);
      final monthEnd = DateTime(now.year, now.month + 1);
      final (inv, recipes, budgetRow, tickets, prices) = await (
        client
            .from('inventory_items')
            .select()
            .eq('home_id', homeId)
            .neq('kind', 'dish')
            .neq('category', 'Congelador'),
        client
            .from('recipes')
            .select('id, servings, recipe_ingredients(name, quantity, unit)')
            .eq('home_id', homeId),
        client
            .from('budgets')
            .select('monthly_amount')
            .eq('home_id', homeId)
            .maybeSingle(),
        client
            .from('tickets')
            .select('total_amount')
            .eq('home_id', homeId)
            .or(ticketRangeFilter(monthStart, monthEnd)),
        PriceMemory(client).loadAll(homeId),
      ).wait;

      final expiring = <String>{};
      for (final m in inv as List) {
        final item = InventoryItem.fromMap(m as Map<String, dynamic>);
        final exp = item.effectiveExpiry;
        if (item.isStaple || item.name.trim().isEmpty || exp == null) continue;
        final days = exp.difference(today).inDays;
        if (days >= 0 && days <= 4)
          expiring.add(item.name.trim().toLowerCase());
      }

      final costs = <String, double>{};
      for (final r in recipes as List) {
        final ings = (r['recipe_ingredients'] as List?) ?? const [];
        if (ings.isEmpty) continue;
        final cost = computeRecipeCost(
          ingredients: [
            for (final i in ings)
              (
                name: '${i['name'] ?? ''}',
                quantity: (i['quantity'] as num?)?.toDouble(),
                unit: i['unit'] as String?,
              ),
          ],
          prices: prices,
          servings: (r['servings'] as num?)?.toInt() ?? 1,
          approxOf: ApproxPrice.estimate,
        );
        if (cost.perServing > 0) costs[r['id'] as String] = cost.perServing;
      }

      final budget = (budgetRow?['monthly_amount'] as num?)?.toDouble() ?? 0;
      final spent = (tickets as List).fold<double>(
        0,
        (a, t) => a + ((t['total_amount'] as num?)?.toDouble() ?? 0),
      );
      final daysInMonth = monthEnd.difference(monthStart).inDays;
      return PlanHints(
        expiring: expiring,
        costPerServing: costs,
        budgetPressure: budgetPressureFor(
          budget: budget,
          spent: spent,
          monthProgress: now.day / daysInMonth,
        ),
      );
    } catch (_) {
      return const PlanHints();
    }
  }
}

/// Va justo si se ha gastado más parte del presupuesto que del mes.
int budgetPressureFor({
  required double budget,
  required double spent,
  required double monthProgress,
}) {
  if (budget <= 0) return 0;
  return spent / budget > monthProgress ? 2 : 1;
}
