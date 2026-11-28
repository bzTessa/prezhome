import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n.dart';
import 'file_local_store.dart';

/// Aprende de la compra: lo que se compra ya hecho (pizza, lasaña, coulant…)
/// se ofrece una vez para guardarlo en "Tus preparados". Lo que se rechaza
/// no se vuelve a preguntar.
class ReadyLearning {
  static final _store = FileLocalStore(folderName: 'settings');
  static const _declinedKey = 'ready_declined';

  static String fold(String s) => s
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ñ', 'n')
      .trim();

  static const _mains = [
    'pizza',
    'lasana',
    'lasagna',
    'canelon',
    'croqueta',
    'empanadilla',
    'empanada',
    'nugget',
    'san jacobo',
    'gazpacho',
    'salmorejo',
    'sushi',
    'ensaladilla',
    'tortilla de patata',
    'tortilla espanola',
    'precocinad',
    'plato preparado',
    'listo para',
    'arroz tres delicias',
    'noodles',
    'fideos orientales',
    'burrito',
    'pollo asado',
    'crema de verduras',
    'crema de calabaza',
    'hummus',
  ];

  static const _desserts = [
    'coulant',
    'tiramisu',
    'helado',
    'tarta',
    'natillas',
    'flan',
    'mousse',
    'arroz con leche',
    'cheesecake',
    'profiterol',
    'brownie',
  ];

  /// Ingredientes que llevan esas palabras pero no son un plato hecho.
  static const _notReady = ['masa', 'base ', 'harina', 'salsa', 'tomate'];

  /// 'main' o 'dessert' si [name] parece comprado ya hecho; si no, null.
  static String? kindOf(String name) {
    final n = ' ${fold(name)}';
    if (_notReady.any(n.contains)) return null;
    bool has(String w) => n.contains(' $w');
    if (_desserts.any(has)) return 'dessert';
    if (_mains.any(has)) return 'main';
    return null;
  }

  /// Lo de [bought] que parece un preparado y aún no está guardado ni
  /// rechazado. Sin repetidos.
  static List<({String name, String kind})> candidates(
    Iterable<String> bought, {
    Iterable<String> saved = const [],
    Iterable<String> declined = const [],
  }) {
    final skip = {...saved.map(fold), ...declined.map(fold)};
    final out = <({String name, String kind})>[];
    for (final b in bought) {
      final name = b.trim();
      final kind = kindOf(name);
      if (kind == null || skip.contains(fold(name))) continue;
      skip.add(fold(name));
      out.add((name: name, kind: kind));
    }
    return out;
  }

  static Future<List<String>> _declined() async {
    try {
      final raw = await _store.read(_declinedKey);
      if (raw == null) return const [];
      return [for (final s in jsonDecode(raw) as List) s.toString()];
    } catch (_) {
      return const [];
    }
  }

  /// Tras guardar un ticket: si trae preparados nuevos, pregunta una vez si
  /// se guardan. No lanza.
  static Future<void> offer(
    BuildContext context,
    SupabaseClient client, {
    required String homeId,
    required List<String> bought,
  }) async {
    try {
      final saved = await client
          .from('ready_meals')
          .select('name')
          .eq('home_id', homeId);
      final declined = await _declined();
      final found = candidates(
        bought,
        saved: [for (final r in saved as List) (r['name'] ?? '').toString()],
        declined: declined,
      );
      if (found.isEmpty || !context.mounted) return;
      final keep = {for (final f in found) f.name};
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, set) => AlertDialog(
            title: Text(ctx.l.rlTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ctx.l.rlBody),
                  const SizedBox(height: 8),
                  for (final f in found)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: keep.contains(f.name),
                      title: Text(f.name),
                      onChanged: (v) => set(
                        () =>
                            v == true ? keep.add(f.name) : keep.remove(f.name),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(ctx.l.rlNo),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(ctx.l.rlYes),
              ),
            ],
          ),
        ),
      );
      final chosen = ok == true ? keep : <String>{};
      final rows = [
        for (final f in found)
          if (chosen.contains(f.name))
            {'home_id': homeId, 'name': f.name, 'kind': f.kind},
      ];
      if (rows.isNotEmpty) await client.from('ready_meals').insert(rows);
      await _store.write(
        _declinedKey,
        jsonEncode([
          ...declined,
          for (final f in found)
            if (!chosen.contains(f.name)) f.name,
        ]),
      );
    } catch (e) {
      debugPrint('ReadyLearning.offer: $e');
    }
  }
}
