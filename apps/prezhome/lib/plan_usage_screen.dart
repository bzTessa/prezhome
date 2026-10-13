import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme/app_theme.dart';
import 'utils/friendly_error.dart';

/// Una función con cupo mensual: cuántas veces se ha usado este mes.
class PlanUsage {
  const PlanUsage(this.label, this.used, this.limit);

  final String label;
  final int used;
  final int limit;

  int get left => (limit - used).clamp(0, limit);
}

/// Nombres para la persona, en el orden en que se muestran.
const planFeatureLabels = {
  'scan_ticket': 'Escanear tickets',
  'recipes': 'Ideas y recetas',
  'meal_photo': 'Foto de lo que comes',
  'import_link': 'Recetas desde un enlace',
};

/// Une los cupos del plan con el uso del mes (filas de plan_quotas y ai_usage).
List<PlanUsage> buildPlanUsage(
  String plan,
  List<Map<String, dynamic>> quotas,
  List<Map<String, dynamic>> usage,
) {
  final limits = {
    for (final q in quotas)
      if (q['plan'] == plan) q['feature']: q['monthly_limit'] as int,
  };
  final used = {for (final u in usage) u['feature']: u['used'] as int};
  return [
    for (final e in planFeatureLabels.entries)
      if (limits[e.key] != null)
        PlanUsage(e.value, used[e.key] ?? 0, limits[e.key]!),
  ];
}

/// "Tu plan": qué plan tiene el hogar y cuántos usos quedan este mes.
class PlanUsageScreen extends StatefulWidget {
  const PlanUsageScreen({super.key, required this.homeId});

  final String homeId;

  @override
  State<PlanUsageScreen> createState() => _PlanUsageScreenState();
}

class _PlanUsageScreenState extends State<PlanUsageScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  late final Future<(String, List<PlanUsage>)> _future = _load();

  Future<(String, List<PlanUsage>)> _load() async {
    // El servidor cuenta por mes en UTC (date_trunc sobre now()).
    final now = DateTime.now().toUtc();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    final sub = await _client
        .from('subscriptions')
        .select('plan')
        .eq('home_id', widget.homeId)
        .maybeSingle();
    final plan = (sub?['plan'] as String?) ?? 'free';
    final quotas = await _client.from('plan_quotas').select();
    final usage = await _client
        .from('ai_usage')
        .select('feature, used')
        .eq('home_id', widget.homeId)
        .eq('period_start', month);
    return (plan, buildPlanUsage(plan, quotas, usage));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Tu plan')),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(friendlyError(snapshot.error)));
          }
          final (plan, rows) = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                plan == 'pro' ? 'Plan Pro' : 'Plan gratis',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'La despensa, la compra, las tareas y el plan no tienen '
                'límite. Esto es lo que te queda este mes; se renueva el '
                'día 1. Si algo falla, no cuenta.',
                style: TextStyle(color: AppColors.inkMuted),
              ),
              const SizedBox(height: 20),
              for (final r in rows) _usageRow(r),
            ],
          );
        },
      ),
    );
  }

  Widget _usageRow(PlanUsage r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text('Te quedan ${r.left} de ${r.limit}'),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: r.limit == 0 ? 1 : r.used / r.limit,
              minHeight: 8,
              backgroundColor: AppColors.sageBg,
              color: r.left == 0 ? AppColors.expired : AppColors.sage,
            ),
          ),
        ],
      ),
    );
  }
}
