import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/home_invites.dart';
import 'package:prezhome/utils/shopping_share.dart';

void main() {
  test('lista por pasillos con cantidades', () {
    final text = shoppingShareText(
      title: 'Lista de la compra: Semanal',
      groups: [
        ('Frutas y verduras', [('Tomates', '1 kg'), ('Plátanos', '')]),
        ('Lácteos', [('Leche', '2 × 1 L')]),
        ('Vacía', []),
      ],
      footer: 'Hecha con PrezHome',
    );
    expect(
      text,
      '*Lista de la compra: Semanal*\n\n'
      '_Frutas y verduras_\n- Tomates · 1 kg\n- Plátanos\n\n'
      '_Lácteos_\n- Leche · 2 × 1 L\n\n'
      'Hecha con PrezHome',
    );
  });

  test('un solo grupo va sin título de pasillo', () {
    final text = shoppingShareText(
      title: 'Compra',
      groups: [
        ('', [('Pan', '1 ud')]),
      ],
      footer: '',
    );
    expect(text, '*Compra*\n\n- Pan · 1 ud');
  });

  test('encuentra el código de invitación dentro del mensaje', () {
    expect(
      inviteCodeIn('¡Únete a nuestra casa!\n\nCódigo: ABCD-EF23'),
      'ABCDEF23',
    );
    expect(inviteCodeIn('sin código aquí'), isNull);
    expect(inviteCodeIn(null), isNull);
  });
}
