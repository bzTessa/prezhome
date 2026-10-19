import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'plan_usage_screen.dart';
import 'services/pro_purchases.dart';
import 'theme/app_theme.dart';
import 'utils/friendly_error.dart';
import 'widgets/tactile_button.dart';

/// Condiciones de uso estándar de Apple para suscripciones (EULA).
const _termsUrl =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
const _privacyUrl = String.fromEnvironment('PRIVACY_URL');

/// Nombre de cada periodo para la persona.
String proPeriodLabel(PackageType type) => switch (type) {
  PackageType.annual => 'Al año',
  PackageType.sixMonth => 'Cada 6 meses',
  PackageType.threeMonth => 'Cada 3 meses',
  PackageType.twoMonth => 'Cada 2 meses',
  PackageType.monthly => 'Al mes',
  PackageType.weekly => 'A la semana',
  PackageType.lifetime => 'Para siempre',
  _ => 'Pro',
};

/// Pasar a Pro: qué da (cupos de `plan_quotas`), opciones de pago y
/// restaurar compras. Devuelve true al cerrarse si la persona ya tiene Pro.
class ProScreen extends StatefulWidget {
  const ProScreen({super.key});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  late final Future<(List<Map<String, dynamic>>, List<Package>)> _future =
      _load();
  bool _busy = false;

  Future<(List<Map<String, dynamic>>, List<Package>)> _load() async {
    final quotas = await Supabase.instance.client.from('plan_quotas').select();
    final packages = ProPurchases.available
        ? await ProPurchases.packages()
        : const <Package>[];
    return (quotas, packages);
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
        ).showSnackBar(const SnackBar(content: Text('Ya tienes Pro')));
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
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(friendlyError(snapshot.error)));
          }
          final (quotas, packages) = snapshot.data!;
          final free = {
            for (final f in buildPlanUsage('free', quotas, const []))
              f.label: f.limit,
          };
          final pro = buildPlanUsage('pro', quotas, const []);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Más usos cada mes',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Lo demás sigue igual: sin límite y para todo el hogar.',
                style: TextStyle(color: AppColors.inkMuted),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.tactileDecoration(),
                child: Column(
                  children: [
                    _row('', 'Gratis', 'Pro', header: true),
                    for (final r in pro)
                      _row(r.label, '${free[r.label] ?? 0}', '${r.limit}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (packages.isEmpty)
                Text(
                  'Pro estará disponible muy pronto.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkMuted),
                )
              else
                for (final p in packages)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TactileButton(
                      label:
                          '${proPeriodLabel(p.packageType)} · '
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
                          'No hay compras que restaurar.',
                        ),
                  child: const Text('Restaurar compras'),
                ),
              const SizedBox(height: 8),
              Text(
                'Se renueva solo. Puedes cancelar cuando quieras desde la '
                'tienda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _link('Condiciones', _termsUrl),
                  if (_privacyUrl.isNotEmpty) _link('Privacidad', _privacyUrl),
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
