/// Lógica PURA de "¿qué cocino con lo que tengo?" y del súper principal del
/// hogar. Sin Flutter ni red, para poder testearla.
library;

import '../models/inventory_item.dart';
import '../widgets/food_category_icon.dart';

/// Nombres de la despensa que se mandan a la IA para proponer recetas.
///
/// - Solo comida (no productos de hogar/limpieza) y con cantidad > 0.
/// - Primero lo que caduca antes (para aprovecharlo); lo que no tiene fecha
///   va después, en el orden en que llegó.
/// - Sin duplicados (ignorando mayúsculas y acentos) y como mucho [max].
List<String> pantryNamesForIdeas(List<InventoryItem> items, {int max = 40}) {
  final food = items
      .where((i) => i.itemType != 'hogar' && i.quantity > 0)
      .toList();
  final indexed = food.asMap().entries.toList()
    ..sort((a, b) {
      final ea = a.value.expirationDate;
      final eb = b.value.expirationDate;
      if (ea != null && eb != null) {
        final c = ea.compareTo(eb);
        if (c != 0) return c;
      } else if (ea != null) {
        return -1;
      } else if (eb != null) {
        return 1;
      }
      return a.key.compareTo(b.key);
    });

  final seen = <String>{};
  final names = <String>[];
  for (final e in indexed) {
    final name = e.value.name.trim();
    final key = CategoryIcons.normalize(name);
    if (name.isEmpty || !seen.add(key)) continue;
    names.add(name);
    if (names.length >= max) break;
  }
  return names;
}

/// Básicos que se suponen en cualquier cocina: no cuentan como "te falta".
const Set<String> _pantryBasics = {
  'sal',
  'agua',
  'aceite',
  'aceite de oliva',
  'pimienta',
  'pimienta negra',
  'azucar',
  'vinagre',
};

/// Separa los ingredientes de una idea en los que ya hay en casa y los que
/// faltan. Un ingrediente "se tiene" si alguna palabra significativa coincide
/// con algo de la despensa ("pechuga de pollo" ↔ "pollo"). Los básicos
/// (sal, aceite, agua…) nunca cuentan como que faltan.
({List<String> have, List<String> missing}) splitByPantry(
  List<String> ingredients,
  List<String> pantry,
) {
  final pantryWords = <String>{for (final p in pantry) ..._significantWords(p)};
  final have = <String>[];
  final missing = <String>[];
  for (final raw in ingredients) {
    final name = raw.trim();
    if (name.isEmpty) continue;
    final norm = CategoryIcons.normalize(name);
    if (_pantryBasics.contains(norm)) continue;
    final words = _significantWords(name);
    if (words.any(pantryWords.contains)) {
      have.add(name);
    } else {
      missing.add(name);
    }
  }
  return (have: have, missing: missing);
}

/// Palabras que identifican el alimento, en singular aproximado
/// ("tomates" → "tomate"), sin conectores ni medidas.
Set<String> _significantWords(String name) {
  const stop = {
    'de',
    'del',
    'la',
    'el',
    'los',
    'las',
    'y',
    'con',
    'en',
    'al',
    'a',
    'fresco',
    'fresca',
    'frescos',
    'frescas',
    'natural',
    'cocido',
    'cocidos',
    'cocida',
    'cocidas',
    'picado',
    'picada',
    'entero',
    'entera',
  };
  return CategoryIcons.normalize(name)
      .split(RegExp(r'[^a-z0-9]+'))
      .where((w) => w.length > 2 && !stop.contains(w))
      .map(_singular)
      .toSet();
}

String _singular(String w) {
  if (w.endsWith('es') && w.length > 4) {
    final base = w.substring(0, w.length - 2);
    // "tomates" -> "tomate" (vocal antes de -s), "melones" -> "melon".
    if (base.endsWith('t') || base.endsWith('d')) return '${base}e';
    return base;
  }
  if (w.endsWith('s') && w.length > 3) return w.substring(0, w.length - 1);
  return w;
}

/// Lista de súper del hogar con [key] como principal (primero), sin
/// duplicados. Los demás conservan su orden. [key] vacío no cambia nada.
List<String> withPrimarySupermarket(List<String> current, String key) {
  final k = key.trim();
  if (k.isEmpty) return List.of(current);
  return [k, ...current.where((s) => s != k)];
}

/// "1,80 €" con coma decimal.
String formatEuros(double value) =>
    '${value.toStringAsFixed(2).replaceAll('.', ',')} €';
