import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/utils/task_kinds.dart';

void main() {
  test('el tipo de tarea sale del título', () {
    expect(taskKindFor('Limpiar el baño'), TaskKind.bano);
    expect(taskKindFor('Lavadora Ropa Blanca'), TaskKind.ropa);
    expect(taskKindFor('Hacer la compra'), TaskKind.compra);
    expect(taskKindFor('Fregar los platos'), TaskKind.platos);
    expect(taskKindFor('Fregar suelos'), TaskKind.limpieza);
    expect(taskKindFor('Cocinar para la semana'), TaskKind.cocinar);
    expect(taskKindFor('Llamar al fontanero'), TaskKind.otra);
    for (final p in taskPresets) {
      expect(taskKindFor(p.title), isNot(TaskKind.otra), reason: p.title);
    }
  });
}
