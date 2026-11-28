import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/data_export.dart';

void main() {
  test('el archivo lleva fecha, recuentos y los datos', () {
    final out = DataExport.buildExport(
      {
        'recipes': [
          {'id': 'r1', 'title': 'Lentejas'},
        ],
        'tasks': <Map<String, dynamic>>[],
        'home': {'id': 'h', 'name': 'Casa'},
      },
      exportedAt: DateTime.utc(2026, 11, 28, 12),
      errors: ['tickets'],
    );
    expect(out['app'], 'PrezHome');
    expect(out['exported_at'], '2026-11-28T12:00:00.000Z');
    expect(out['counts'], {'recipes': 1, 'tasks': 0});
    expect(out['errors'], ['tickets']);
    final back = jsonDecode(DataExport.encode(out)) as Map;
    expect((back['recipes'] as List).single['title'], 'Lentejas');
  });

  test('nombre del archivo con la fecha', () {
    expect(
      DataExport.fileName(DateTime(2026, 3, 5)),
      'prezhome-datos-2026-03-05.json',
    );
  });

  test('sin errores no sale la clave', () {
    final out = DataExport.buildExport({}, exportedAt: DateTime.utc(2026));
    expect(out.containsKey('errors'), isFalse);
  });
}
