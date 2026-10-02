import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Categoría visual de un producto, con su emoji representativo.
///
/// No existe un campo "categoría" en los modelos (ni en [ShoppingListItem] ni
/// en [InventoryItem]), así que la deducimos por palabras clave del nombre.
/// El objetivo es puramente estético: dar un toque visual tipo "apps de la
/// compra" sin saturar ni pretender ser exhaustivo.
enum FoodCategory {
  verdura('🥦'),
  fruta('🍎'),
  carne('🥩'),
  pescado('🐟'),
  lacteos('🧀'),
  bebidas('🥤'),
  panaderia('🥖'),
  limpieza('🧽'),
  hogar('🏠'),
  otros('🛒');

  const FoodCategory(this.emoji);

  /// Emoji representativo de la categoría.
  final String emoji;
}

/// Helper reutilizable para asignar un emoji/icono de categoría a un producto
/// a partir de su nombre. Se usa en la lista de la compra y en el inventario
/// para que cada item muestre un pequeño distintivo visual consistente.
class CategoryIcons {
  CategoryIcons._();

  /// Normaliza un texto a minúsculas y sin acentos para comparar de forma
  /// razonable (no cubre todos los casos, pero sí los habituales en español).
  static String _normalize(String input) {
    final lower = input.toLowerCase().trim();
    const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const to = 'aaaaaeeeeiiiiooooouuuunc';
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      final idx = from.indexOf(char);
      buffer.write(idx >= 0 ? to[idx] : char);
    }
    return buffer.toString();
  }

  /// Palabras clave por categoría. El orden importa: evaluamos las categorías
  /// más específicas antes que las genéricas (p.ej. "leche" antes que fallback).
  static const Map<FoodCategory, List<String>> _keywords = {
    FoodCategory.limpieza: [
      'limpia',
      'detergente',
      'lejia',
      'jabon',
      'fregona',
      'estropajo',
      'bayeta',
      'suavizante',
      'friegaplatos',
      'lavavajillas',
      'papel higienico',
      'servilleta',
      'basura',
      'escoba',
      'ambientador',
    ],
    FoodCategory.hogar: [
      'bombilla',
      'pila',
      'bateria',
      'cargador',
      'pañal',
      'panal',
      'toallita',
      'champu',
      'gel',
      'pasta de dientes',
      'cepillo',
      'desodorante',
      'mascarilla',
    ],
    FoodCategory.bebidas: [
      'agua',
      'refresco',
      'cola',
      'zumo',
      'cerveza',
      'vino',
      'cafe',
      'te ',
      'infusion',
      'bebida',
      'leche de avena',
      'horchata',
      'batido',
    ],
    FoodCategory.lacteos: [
      'leche',
      'yogur',
      'queso',
      'mantequilla',
      'nata',
      'cuajada',
      'kefir',
      'requeson',
      'mozzarella',
    ],
    FoodCategory.pescado: [
      'pescado',
      'merluza',
      'salmon',
      'atun',
      'bacalao',
      'gamba',
      'marisco',
      'sardina',
      'dorada',
      'lubina',
      'calamar',
      'pulpo',
      'mejillon',
      'trucha',
    ],
    FoodCategory.carne: [
      'pollo',
      'carne',
      'ternera',
      'cerdo',
      'jamon',
      'chorizo',
      'salchicha',
      'pavo',
      'bacon',
      'lomo',
      'costilla',
      'hamburguesa',
      'embutido',
      'huevo',
    ],
    FoodCategory.verdura: [
      'verdura',
      'lechuga',
      'tomate',
      'cebolla',
      'ajo',
      'patata',
      'zanahoria',
      'pimiento',
      'calabacin',
      'brocoli',
      'espinaca',
      'pepino',
      'champinon',
      'seta',
      'judia',
      'guisante',
      'berenjena',
      'puerro',
      'apio',
      'col',
    ],
    FoodCategory.fruta: [
      'fruta',
      'manzana',
      'platano',
      'banana',
      'naranja',
      'pera',
      'fresa',
      'uva',
      'melon',
      'sandia',
      'kiwi',
      'limon',
      'mandarina',
      'melocoton',
      'piña',
      'pina',
      'cereza',
      'aguacate',
    ],
    FoodCategory.panaderia: [
      'pan',
      'harina',
      'arroz',
      'pasta',
      'macarron',
      'espagueti',
      'cereal',
      'avena',
      'galleta',
      'bolleria',
      'croissant',
      'tostada',
      'bizcocho',
      'magdalena',
    ],
  };

  /// Devuelve la categoría inferida del nombre del producto.
  ///
  /// Si [itemType] es 'hogar' y no hay una coincidencia más específica, se
  /// usa la categoría [FoodCategory.hogar] como respaldo razonable.
  static FoodCategory categoryFor(String name, {String? itemType}) {
    final normalized = _normalize(name);
    for (final entry in _keywords.entries) {
      for (final keyword in entry.value) {
        if (normalized.contains(keyword)) return entry.key;
      }
    }
    if (itemType == 'hogar') return FoodCategory.hogar;
    return FoodCategory.otros;
  }

  /// Emoji directo para un nombre de producto.
  static String emojiFor(String name, {String? itemType}) =>
      categoryFor(name, itemType: itemType).emoji;

  /// Pequeño distintivo visual (emoji dentro de un círculo cozy) listo para
  /// usar como leading de un ListTile. Consistente entre compra e inventario.
  static Widget badge(String name, {String? itemType, double size = 40}) {
    final emoji = emojiFor(name, itemType: itemType);
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}
