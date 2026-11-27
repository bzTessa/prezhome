import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/shared_expenses.dart';

SharedExpense _e(String who, double amount) => SharedExpense(
  id: '$who$amount',
  paidBy: who,
  amount: amount,
  concept: 'x',
  day: DateTime(2026, 11, 27),
);

void main() {
  test('two people: the one who paid less gives half the difference', () {
    final b = expenseBalances([_e('a', 60), _e('b', 20)], ['a', 'b']);
    expect(b, {'a': 20.0, 'b': -20.0});
    final t = settleUp(b);
    expect(t, hasLength(1));
    expect((t.single.from, t.single.to, t.single.amount), ('b', 'a', 20.0));
  });

  test('three people with one payer: two transfers to the payer', () {
    final t = settleUp(expenseBalances([_e('a', 90)], ['a', 'b', 'c']));
    expect(t.map((x) => (x.from, x.to, x.amount)).toSet(), {
      ('b', 'a', 30.0),
      ('c', 'a', 30.0),
    });
  });

  test('even split needs no transfers; stray cents are ignored', () {
    expect(
      settleUp(expenseBalances([_e('a', 10), _e('b', 10)], ['a', 'b'])),
      isEmpty,
    );
    final t = settleUp(expenseBalances([_e('a', 10)], ['a', 'b', 'c']));
    expect(t.fold<double>(0, (s, x) => s + x.amount), closeTo(6.66, 0.01));
  });

  test('a person without expenses still owes their share', () {
    final b = expenseBalances([_e('a', 30)], ['a', 'b', 'c']);
    expect(b['c'], -10.0);
  });

  test('no people, no balances', () {
    expect(expenseBalances([_e('a', 5)], []), isEmpty);
  });
}
