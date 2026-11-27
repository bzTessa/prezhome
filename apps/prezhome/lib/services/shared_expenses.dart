import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_people.dart';

class SharedExpense {
  const SharedExpense({
    required this.id,
    required this.paidBy,
    required this.amount,
    required this.concept,
    required this.day,
  });

  factory SharedExpense.fromMap(Map<String, dynamic> m) => SharedExpense(
    id: m['id'] as String,
    paidBy: m['paid_by'] as String,
    amount: (m['amount'] as num).toDouble(),
    concept: (m['concept'] ?? '') as String,
    day: DateTime.tryParse('${m['spent_on']}') ?? DateTime.now(),
  );

  final String id;
  final String paidBy;
  final double amount;
  final String concept;
  final DateTime day;
}

/// Un pago para quedar en paz: [from] le da [amount] a [to].
class Transfer {
  const Transfer(this.from, this.to, this.amount);

  final String from;
  final String to;
  final double amount;
}

double _cents(double v) => (v * 100).roundToDouble() / 100;

/// Saldo de cada persona (lo que pagó menos lo que le toca, a partes iguales
/// entre [people]). Positivo: le deben; negativo: debe.
Map<String, double> expenseBalances(
  List<SharedExpense> expenses,
  List<String> people,
) {
  if (people.isEmpty) return const {};
  final total = expenses.fold<double>(0, (a, e) => a + e.amount);
  final share = total / people.length;
  final paid = <String, double>{for (final p in people) p: 0};
  for (final e in expenses) {
    paid[e.paidBy] = (paid[e.paidBy] ?? 0) + e.amount;
  }
  return {for (final p in people) p: _cents((paid[p] ?? 0) - share)};
}

/// Los menos pagos posibles para quedar en paz: quien más debe paga a quien
/// más le deben, hasta que no quede nada (céntimos sueltos fuera).
List<Transfer> settleUp(Map<String, double> balances) {
  final debtors = [
    for (final e in balances.entries)
      if (e.value < -0.004) [e.key, -e.value],
  ]..sort((a, b) => (b[1] as double).compareTo(a[1] as double));
  final creditors = [
    for (final e in balances.entries)
      if (e.value > 0.004) [e.key, e.value],
  ]..sort((a, b) => (b[1] as double).compareTo(a[1] as double));
  final out = <Transfer>[];
  var i = 0, j = 0;
  while (i < debtors.length && j < creditors.length) {
    final owe = debtors[i][1] as double;
    final get = creditors[j][1] as double;
    final pay = _cents(owe < get ? owe : get);
    if (pay >= 0.01) {
      out.add(
        Transfer(debtors[i][0] as String, creditors[j][0] as String, pay),
      );
    }
    debtors[i][1] = owe - pay;
    creditors[j][1] = get - pay;
    if ((debtors[i][1] as double) < 0.01) i++;
    if ((creditors[j][1] as double) < 0.01) j++;
  }
  return out;
}

/// Lectura y escritura de home_expenses y de quién vive en casa.
class SharedExpenses {
  SharedExpenses(this.client);

  final SupabaseClient client;

  /// id -> nombre de las personas de casa (con y sin cuenta).
  Future<Map<String, String>> people(String homeId) async {
    final profs = await client
        .from('profiles')
        .select('id, full_name')
        .eq('home_id', homeId);
    return {
      for (final p in profs as List)
        p['id']
            as String: ((p['full_name'] as String?)?.trim().isNotEmpty ?? false)
            ? (p['full_name'] as String).trim()
            : '?',
      ...await HomePeople(client).load(homeId),
    };
  }

  Future<List<SharedExpense>> pending(String homeId) async {
    final rows = await client
        .from('home_expenses')
        .select()
        .eq('home_id', homeId)
        .eq('settled', false)
        .order('spent_on', ascending: false)
        .order('created_at', ascending: false);
    return [for (final r in rows as List) SharedExpense.fromMap(r)];
  }

  Future<void> add({
    required String homeId,
    required String paidBy,
    required double amount,
    required String concept,
  }) => client.from('home_expenses').insert({
    'home_id': homeId,
    'paid_by': paidBy,
    'amount': amount,
    'concept': concept.trim(),
  });

  Future<void> delete(String id) =>
      client.from('home_expenses').delete().eq('id', id);

  /// Todo lo pendiente pasa a saldado.
  Future<void> settleAll(String homeId) => client
      .from('home_expenses')
      .update({'settled': true})
      .eq('home_id', homeId)
      .eq('settled', false);
}
