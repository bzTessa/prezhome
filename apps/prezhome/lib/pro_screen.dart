import 'package:flutter/material.dart';
import 'l10n/l10n.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'plan_usage_screen.dart';
import 'services/month_wins.dart';
import 'services/pro_purchases.dart';
import 'theme/app_theme.dart';
import 'utils/friendly_error.dart';
import 'widgets/tactile_button.dart';
import 'widgets/list_skeleton.dart';
import 'widgets/month_wins_card.dart';

/// Condiciones de uso estándar de Apple para suscripciones (EULA).
const _termsUrl =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
const _privacyUrl = String.fromEnvironment('PRIVACY_URL');

/// Nombre de cada periodo para la persona.
String proPeriodLabel(BuildContext context, PackageType type) =>
    context.l.proPeriod(type.name);

/// Pasar a Pro: lo que la app ya hace por la casa este mes, qué da Pro (cupos
/// de `plan_quotas`), opciones de pago y restaurar compras. Devuelve true al cerrarse si la persona ya tiene Pro.
class ProScreen extends StatefulWidget {
  const ProScreen({super.key});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  late final Future<(List<Map<String, dynamic>>, List<Package>, MonthWins)>
  _future = _load();
  bool _busy = false;

  Future<(List<Map<String, dynamic>>, List<Package>, MonthWins)> _load() async {
    final client = Supabase.instance.client;
    final winsFuture = MonthWins.load(client);
    final quotas = await client.from('plan_quotas').select();
    final packages = ProPurchases.available
        ? await ProPurchases.packages()
        : const <Package>[];
    return (quotas, packages, await winsFuture);
  }

  Future<void> _run(Future<bool> Function() action, String notPro) async {
    setState(() => _busy = true);
    try {
      final pro = await action();
      if (!mounted) return;
      if (pro) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l.proAlready)));
        Navigator.of(context).pop(true);
      } else if (notPro.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(notPro)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('PrezHome Pro')),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ListSkeleton(rows: 4, leading: false);
          }
          if (snapshot.hasError) {
            return Center(child: Text(friendlyError(snapshot.error)));
          }
          final (quotas, packages, wins) = snapshot.data!;
          final free = {
            for (final f in buildPlanUsage('free', quotas, const []))
              f.feature: f.limit,
          };
          final pro = buildPlanUsage('pro', quotas, const []);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                context.l.proHeadline,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l.proHeadlineSub,
                style: TextStyle(color: AppColors.inkMuted, height: 1.35),
              ),
              if (!wins.isEmpty) ...[
                const SizedBox(height: 20),
                MonthWinsCard(wins: wins),
              ],
              const SizedBox(height: 24),
              Text(
                context.l.proMoreUses,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.tactileDecoration(),
                child: Column(
                  children: [
                    _row('', context.l.proFree, 'Pro', header: true),
                    for (final r in pro)
                      _row(
                        context.l.planFeature(r.feature),
                        '${free[r.feature] ?? 0}',
                        '${r.limit}',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.l.proRestSame,
                style: TextStyle(color: AppColors.inkMuted),
              ),
              const SizedBox(height: 24),
              if (packages.isEmpty)
                Text(
                  context.l.proSoon,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkMuted),
                )
              else
                for (final p in packages)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TactileButton(
                      label:
                          '${proPeriodLabel(context, p.packageType)} · '
                          '${p.storeProduct.priceString}',
                      color: p.packageType == PackageType.annual
                          ? AppColors.gold
                          : null,
                      onPressed: _busy
                          ? null
                          : () => _run(() => ProPurchases.buy(p), ''),
                    ),
                  ),
              if (ProPurchases.available)
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _run(
                          ProPurchases.restore,
                          context.l.proNothingToRestore,
                        ),
                  child: Text(context.l.proRestore),
                ),
              const SizedBox(height: 8),
              Text(
                context.l.proRenews,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _link(context.l.proTerms, _termsUrl),
                  if (_privacyUrl.isNotEmpty)
                    _link(context.l.proPrivacy, _privacyUrl),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String free, String pro, {bool header = false}) {
    final style = TextStyle(
      fontWeight: header ? FontWeight.w800 : FontWeight.w600,
      color: header ? AppColors.inkMuted : AppColors.ink,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          SizedBox(
            width: 56,
            child: Text(free, textAlign: TextAlign.end, style: style),
          ),
          SizedBox(
            width: 56,
            child: Text(
              pro,
              textAlign: TextAlign.end,
              style: style.copyWith(
                color: header ? null : AppColors.terracotta,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _link(String label, String url) => TextButton(
    onPressed: () =>
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    child: Text(label, style: const TextStyle(fontSize: 12)),
  );
}
