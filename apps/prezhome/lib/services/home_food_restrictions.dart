import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/food_restrictions.dart';

/// Alergias, dieta y lo que no gusta de todo el hogar (función del servidor
/// `home_food_restrictions`, que solo devuelve esas tres cosas de cada
/// persona). Si falla se devuelve vacío para no bloquear el plan.
class HomeFoodRestrictions {
  HomeFoodRestrictions._();

  static Future<FoodRestrictions> load(SupabaseClient client) async {
    try {
      final rows = await client.rpc('home_food_restrictions');
      if (rows is! List) return FoodRestrictions.empty;
      return FoodRestrictions.fromRows([
        for (final r in rows)
          if (r is Map) Map<String, dynamic>.from(r),
      ]);
    } catch (e) {
      debugPrint('HomeFoodRestrictions: $e');
      return FoodRestrictions.empty;
    }
  }
}
