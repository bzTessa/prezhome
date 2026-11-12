import 'package:flutter/material.dart';
import 'l10n/l10n.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pro_screen.dart';
import 'theme/app_theme.dart';
import 'utils/friendly_error.dart';
import 'widgets/tactile_button.dart';
import 'widgets/list_skeleton.dart';

/// Una función con cupo mensual: cuántas veces se ha usado este mes.
class PlanUsage {
  const PlanUsage(this.feature, this.used, this.limit);

  /// Id de la función (scan_ticket, recipes...); su nombre es l10n.planFeature.
  final String feature;
  final int used;
  final int limit;

  int get left => (limit - used).clamp(0, limit);
}

/// Funciones con cupo, en el orden en que se muestran.
const planFeatures = ['scan_ticket', 'recipes', 'meal_photo', 'import_link'];

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
    for (final f in planFeatures)
      if (limits[f] != null) PlanUsage(f, used[f] ?? 0, limits[f]!),
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
  late Future<(String, List<PlanUsage>)> _future = _load();

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
      appBar: AppBar(title: Text(context.l.hhYourPlan)),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ListSkeleton(rows: 4, leading: false);
          }
          if (snapshot.hasError) {
            return Center(child: Text(friendlyError(snapshot.error)));
          }
          final (plan, rows) = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                context.l.puPlanName(plan),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.l.puExplain,
                style: TextStyle(color: AppColors.inkMuted),
              ),
              const SizedBox(height: 20),
              for (final r in rows) _usageRow(r),
              if (plan != 'pro') ...[
                const SizedBox(height: 8),
                TactileButton(
                  label: context.l.puGoPro,
                  onPressed: () async {
                    final pro = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const ProScreen()),
                    );
                    // El servidor recibe la compra por webhook; se recarga.
                    if (pro == true) setState(() => _future = _load());
                  },
                ),
              ],
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
                  context.l.planFeature(r.feature),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(context.l.puLeft(r.left, r.limit)),
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
