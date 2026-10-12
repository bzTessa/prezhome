import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme/app_theme.dart';
import 'widgets/food_category_icon.dart';
import 'widgets/miau_character.dart';

/// Estadísticas curiosas de productos y precios del hogar, a partir de los
/// tickets escaneados (ticket_items). Muestra: lo que más compras, en qué más
/// gastas, los productos más caros y cuántos productos distintos has comprado.
/// Todo degradando con elegancia: si aún no hay tickets, invita a escanear.
class ProductStatsScreen extends StatefulWidget {
  const ProductStatsScreen({super.key});

  @override
  State<ProductStatsScreen> createState() => _ProductStatsScreenState();
}

/// Agregado de un producto a partir de sus líneas de ticket.
class _ProductStat {
  final String name;
  int times = 0; // nº de líneas (veces comprado)
  double totalSpent = 0; // suma de total_price
  double totalQty = 0; // suma de cantidades
  _ProductStat(this.name);

  /// Precio unitario medio (gasto / cantidad), o null si no hay cantidad.
  double? get avgUnitPrice => totalQty > 0 ? totalSpent / totalQty : null;
}

class _ProductStatsScreenState extends State<ProductStatsScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  late Future<List<_ProductStat>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_ProductStat>> _load() async {
    final res = await _client
        .from('ticket_items')
        .select('name, quantity, total_price');
    final byKey = <String, _ProductStat>{};
    for (final row in (res as List)) {
      final m = row as Map<String, dynamic>;
      final name = (m['name'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      final key = CategoryIcons.normalize(name);
      final stat = byKey.putIfAbsent(key, () => _ProductStat(name));
      stat.times += 1;
      stat.totalSpent += (m['total_price'] as num?)?.toDouble() ?? 0;
      stat.totalQty += (m['quantity'] as num?)?.toDouble() ?? 0;
    }
    return byKey.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Estadísticas de la compra')),
      body: FutureBuilder<List<_ProductStat>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final stats = snapshot.data ?? [];
          if (stats.isEmpty) {
            return _emptyState();
          }

          final totalDistintos = stats.length;
          final totalLineas = stats.fold<int>(0, (a, s) => a + s.times);
          final gastoTotal = stats.fold<double>(0, (a, s) => a + s.totalSpent);

          // Top listas.
          final masComprados = [...stats]
            ..sort((a, b) => b.times.compareTo(a.times));
          final masGasto = [...stats]
            ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
          final masCaros =
              stats.where((s) => (s.avgUnitPrice ?? 0) > 0).toList()..sort(
                (a, b) => (b.avgUnitPrice ?? 0).compareTo(a.avgUnitPrice ?? 0),
              );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _summaryCard(totalDistintos, totalLineas, gastoTotal),
              const SizedBox(height: 16),
              _barCard(
                'Lo que más compras',
                Icons.repeat_rounded,
                masComprados.take(6).toList(),
                (s) => s.times.toDouble(),
                (s) => '${s.times}',
              ),
              const SizedBox(height: 16),
              _barCard(
                'En lo que más gastas',
                Icons.euro_rounded,
                masGasto.take(6).toList(),
                (s) => s.totalSpent,
                (s) => '${s.totalSpent.toStringAsFixed(0)} €',
              ),
              const SizedBox(height: 16),
              _listCard(
                'Los más caros (por unidad)',
                Icons.trending_up_rounded,
                masCaros.take(6).toList(),
                (s) =>
                    '${s.avgUnitPrice!.toStringAsFixed(2).replaceAll('.', ',')} €',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard(int distintos, int lineas, double gasto) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        children: [
          const MiauCharacter(mood: MiauMood.celebrating, size: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu historial de compra',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  '$distintos productos distintos · $lineas compras\n'
                  'Gasto total registrado: ${gasto.toStringAsFixed(0)} €',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta con barras horizontales (más legibles que verticales para
  /// nombres de producto).
  Widget _barCard(
    String title,
    IconData icon,
    List<_ProductStat> items,
    double Function(_ProductStat) value,
    String Function(_ProductStat) label,
  ) {
    final maxV = items.fold<double>(0, (a, s) => value(s) > a ? value(s) : a);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(title, icon),
          const SizedBox(height: 12),
          for (final s in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      Text(
                        label(s),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.woodDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Barra proporcional al valor.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: maxV > 0 ? (value(s) / maxV).clamp(0.0, 1.0) : 0,
                      minHeight: 8,
                      backgroundColor: AppColors.cream,
                      valueColor: const AlwaysStoppedAnimation(AppColors.wood),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Lista simple (producto + valor) para "los más caros".
  Widget _listCard(
    String title,
    IconData icon,
    List<_ProductStat> items,
    String Function(_ProductStat) label,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(title, icon),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(
              'Aún no hay suficientes datos de precios.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            )
          else
            for (final s in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      CategoryIcons.styleFor(s.name).icon,
                      size: 18,
                      color: AppColors.woodDark,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      label(s),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.woodDark,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _cardTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.woodDark),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiauCharacter(mood: MiauMood.curious, size: 120),
            const SizedBox(height: 16),
            const Text(
              'Aún no hay estadísticas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Escanea tickets de la compra y aquí verás lo que más compras, '
              'en qué gastas más y los productos más caros.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
