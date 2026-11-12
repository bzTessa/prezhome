import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/models/task.dart';
import 'package:prezhome/utils/task_rotation.dart';

void main() {
  test('el turno pasa a la siguiente y vuelve a empezar', () {
    const people = ['a', 'b', 'c'];
    expect(nextInRotation(people, 'a'), 'b');
    expect(nextInRotation(people, 'c'), 'a');
    expect(nextInRotation(people, null), 'a');
    expect(nextInRotation(people, 'x'), 'a');
    expect(nextInRotation(const [], 'a'), isNull);
  });

  test('orden de turnos estable por nombre', () {
    expect(rotationOrder({'2': 'Marta', '1': 'leo', '3': 'Ana'}), [
      '3',
      '1',
      '2',
    ]);
  });

  test('solo se guarda "por turnos" en tareas que se repiten', () {
    HomeTask t(String rec, bool rot) => HomeTask(
      id: '',
      homeId: 'h',
      title: 'Baño',
      recurrence: rec,
      rotates: rot,
    );
    expect(t('weekly', true).toInsertMap(createdBy: 'u')['rotates'], true);
    expect(
      t('once', true).toInsertMap(createdBy: 'u').containsKey('rotates'),
      false,
    );
    expect(
      t('weekly', false).toInsertMap(createdBy: 'u').containsKey('rotates'),
      false,
    );
    expect(
      HomeTask.fromMap({
        'id': '1',
        'home_id': 'h',
        'title': 'x',
        'rotates': true,
      }).rotates,
      true,
    );
  });
}
