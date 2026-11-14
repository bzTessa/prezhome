import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/utils/quick_capture.dart';

void main() {
  test('la compra se parte por comas y por "y"', () {
    expect(splitCapture('leche, pan y huevos', CaptureTarget.shopping), [
      'Leche',
      'Pan',
      'Huevos',
    ]);
  });

  test('una tarea no se parte', () {
    expect(
      splitCapture('llamar al fontanero y al seguro', CaptureTarget.task),
      ['llamar al fontanero y al seguro'],
    );
  });

  test('vacío no apunta nada', () {
    expect(splitCapture('  ', CaptureTarget.pantry), isEmpty);
  });
}
