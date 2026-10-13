import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/home_invites.dart';

void main() {
  test('normaliza lo escrito', () {
    expect(normalizeInviteCode('abcd-efgh'), 'ABCDEFGH');
    expect(normalizeInviteCode(' AB CD EF GH '), 'ABCDEFGH');
  });

  test('formatea en dos bloques', () {
    expect(formatInviteCode('ABCDEFGH'), 'ABCD-EFGH');
    expect(formatInviteCode('abcd efgh'), 'ABCD-EFGH');
  });

  test('reconoce códigos válidos', () {
    expect(looksLikeInviteCode('K7PQ-2MZX'), isTrue);
    // Sin O, 0, I ni 1 (se confunden).
    expect(looksLikeInviteCode('ABCD-EFG0'), isFalse);
    expect(looksLikeInviteCode('ABCDEFG'), isFalse);
    expect(
      looksLikeInviteCode('11111111-1111-1111-1111-111111111111'),
      isFalse,
    );
  });
}
