import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ingredient.dart';
import '../models/recipe.dart';
import 'home_invites.dart' show formatInviteCode;

/// Compartir recetas con un código de 8 caracteres (mismo formato que las
/// invitaciones al hogar). El servidor guarda una copia de la receta.
class RecipeShare {
  RecipeShare(this._client);

  final SupabaseClient _client;

  /// Código de la receta, listo para leer ("ABCD-EFGH").
  Future<String> share(String recipeId) async {
    final code = await _client.rpc(
      'share_recipe',
      params: {'p_recipe_id': recipeId},
    );
    return formatInviteCode(code as String);
  }

  /// Copia compartida, o null si el código no existe.
  Future<Map<String, dynamic>?> fetch(String code) async {
    final res = await _client.rpc(
      'get_shared_recipe',
      params: {'p_code': code},
    );
    return res is Map ? Map<String, dynamic>.from(res) : null;
  }

  /// Guarda la copia en tu hogar y devuelve la receta nueva.
  Future<Recipe> import(Map<String, dynamic> shared, String homeId) async {
    final map = sharedRecipeRow(shared, homeId);
    final row = await _client.from('recipes').insert(map).select().single();
    final recipe = Recipe.fromMap(row);
    final ingredients = (shared['ingredients'] as List?) ?? const [];
    if (ingredients.isNotEmpty) {
      await _client.from('recipe_ingredients').insert([
        for (final (i, m) in ingredients.indexed)
          Ingredient(
            name: m['name'] as String,
            quantity: (m['quantity'] as num?)?.toDouble(),
            unit: m['unit'] as String?,
            position: i,
          ).toInsertMap(recipeId: recipe.id, homeId: homeId),
      ]);
    }
    return recipe;
  }
}

/// Fila para insertar en `recipes` a partir de la copia compartida: solo
/// columnas conocidas, en tu hogar, sin favorita, y con la foto como enlace
/// (la foto subida sigue siendo de quien la compartió).
Map<String, dynamic> sharedRecipeRow(
  Map<String, dynamic> shared,
  String homeId,
) {
  final original = Recipe.fromMap({...shared, 'id': '', 'home_id': homeId});
  return {
    ...original.toMap(),
    'is_favorite': false,
    'image_url': original.imageUrl,
  };
}
