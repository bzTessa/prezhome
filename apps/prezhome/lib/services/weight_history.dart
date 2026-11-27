import 'package:supabase_flutter/supabase_flutter.dart';

class WeightEntry {
  const WeightEntry(this.day, this.kg);

  final DateTime day;
  final double kg;
}

/// Historial de peso de la persona (tabla weight_entries, privada).
class WeightHistory {
  WeightHistory(this.client);

  final SupabaseClient client;

  /// Lo de los últimos [days] días, del más antiguo al más reciente.
  Future<List<WeightEntry>> load({int days = 120}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final rows = await client
        .from('weight_entries')
        .select('measured_on, weight_kg')
        .gte('measured_on', since.toIso8601String().split('T').first)
        .order('measured_on');
    return [
      for (final r in rows as List)
        WeightEntry(
          DateTime.parse('${r['measured_on']}'),
          (r['weight_kg'] as num).toDouble(),
        ),
    ];
  }

  /// Apunta el peso de hoy (corrige si ya había uno) y lo deja también en el
  /// perfil, para que el objetivo de calorías siga al peso real.
  Future<void> save(double kg) async {
    final user = client.auth.currentUser;
    if (user == null) return;
    final today = DateTime.now().toIso8601String().split('T').first;
    await client.from('weight_entries').upsert({
      'user_id': user.id,
      'measured_on': today,
      'weight_kg': kg,
    }, onConflict: 'user_id,measured_on');
    await client.from('profiles').update({'weight_kg': kg}).eq('id', user.id);
  }
}

/// Cambio de peso frente al apunte más cercano a hace [days] días (null si
/// no hay con qué comparar).
double? weightChange(List<WeightEntry> entries, {int days = 30}) {
  if (entries.length < 2) return null;
  final last = entries.last;
  final target = last.day.subtract(Duration(days: days));
  WeightEntry? ref;
  for (final e in entries) {
    if (identical(e, last)) break;
    if (ref == null ||
        (e.day.difference(target).inDays.abs() <
            ref.day.difference(target).inDays.abs())) {
      ref = e;
    }
  }
  if (ref == null) return null;
  return double.parse((last.kg - ref.kg).toStringAsFixed(1));
}
