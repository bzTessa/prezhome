import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/l10n/app_localizations.dart';
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
    expect(taskKindFor('Pasar la aspiradora'), TaskKind.limpieza);
  });

  test('las tareas típicas tienen tipo en todos los idiomas', () async {
    for (final locale in AppLocalizations.supportedLocales) {
      final l = await AppLocalizations.delegate.load(locale);
      for (final p in taskPresets) {
        final title = l.taskPreset(p.key);
        expect(taskKindFor(title), isNot(TaskKind.otra), reason: title);
      }
    }
    expect(taskKindFor('Clean the bathroom'), TaskKind.bano);
    expect(taskKindFor('Bettwäsche wechseln'), TaskKind.cama);
    expect(taskKindFor('Očistiti kupatilo'), TaskKind.bano);
  });
}
