import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'scan_ticket_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/miau_character.dart';

class EconomyScreen extends StatefulWidget {
  const EconomyScreen({super.key});

  @override
  State<EconomyScreen> createState() => _EconomyScreenState();
}

class _EconomyScreenState extends State<EconomyScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  late Future<_EconomyData> _future;

  // Mes que se está viendo (1 = primer día de ese mes).
  late DateTime _viewMonth;

  static const _monthNames = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewMonth = DateTime(now.year, now.month);
    _future = _load();
  }

  void _reload() {
    final future = _load();
    setState(() {
      _future = future;
    });
  }

  void _changeMonth(int delta) {
    _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta);
    final future = _load();
    setState(() {
      _future = future;
    });
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _viewMonth.year == now.year && _viewMonth.month == now.month;
  }

  Future<_EconomyData> _load() async {
    final user = _client.auth.currentUser;
    if (user == null) throw 'No autenticado';
    final profile = await _client
        .from('profiles')
        .select('home_id')
        .eq('id', user.id)
        .maybeSingle();
    final homeId = profile?['home_id'] as String?;
    if (homeId == null) return _EconomyData(homeId: null);

    // Rango del mes que se está viendo.
    final monthStart = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final monthEnd = DateTime(_viewMonth.year, _viewMonth.month + 1, 1);
    final startStr = monthStart.toIso8601String().split('T').first;
    final endStr = monthEnd.toIso8601String().split('T').first;

    // Presupuesto
    final budgetRow = await _client
        .from('budgets')
        .select('monthly_amount')
        .eq('home_id', homeId)
        .maybeSingle();
    final budget = (budgetRow?['monthly_amount'] as num?)?.toDouble() ?? 0;

    // Tickets del mes que se ve (por created_at, dato fiable).
    final ticketsRes = await _client
        .from('tickets')
        .select('id, merchant, total_amount, purchased_at, created_at')
        .eq('home_id', homeId)
        .gte('created_at', startStr)
        .lt('created_at', endStr)
        .order('created_at', ascending: false);
    final tickets = (ticketsRes as List).cast<Map<String, dynamic>>();

    final total = tickets.fold<double>(
      0,
      (a, t) => a + ((t['total_amount'] as num?)?.toDouble() ?? 0),
    );

    // Histórico: gasto total de TODOS los meses (memoria) + nº de tickets.
    final allRes = await _client
        .from('tickets')
        .select('total_amount')
        .eq('home_id', homeId);
    final all = (allRes as List);
    final historicalTotal = all.fold<double>(
      0,
      (a, t) => a + ((t['total_amount'] as num?)?.toDouble() ?? 0),
    );

    // Tendencia: gasto por mes de los últimos 6 meses (el mes visible incluido
    // como último). Una sola consulta por rango y agregación en Dart.
    final rangeStart = DateTime(_viewMonth.year, _viewMonth.month - 5, 1);
    final rangeEnd = DateTime(_viewMonth.year, _viewMonth.month + 1, 1);
    final rangeStartStr = rangeStart.toIso8601String().split('T').first;
    final rangeEndStr = rangeEnd.toIso8601String().split('T').first;

    final trendRes = await _client
        .from('tickets')
        .select('total_amount, created_at')
        .eq('home_id', homeId)
        .gte('created_at', rangeStartStr)
        .lt('created_at', rangeEndStr);
    final trendRows = (trendRes as List).cast<Map<String, dynamic>>();

    // Clave año-mes -> gasto acumulado.
    final byMonth = <String, double>{};
    for (final row in trendRows) {
      final createdStr = row['created_at'] as String?;
      final created = createdStr != null ? DateTime.tryParse(createdStr) : null;
      if (created == null) continue;
      final key = '${created.year}-${created.month}';
      final amount = (row['total_amount'] as num?)?.toDouble() ?? 0;
      byMonth[key] = (byMonth[key] ?? 0) + amount;
    }

    // Lista ordenada de 6 meses, rellenando con 0.0 los meses sin tickets.
    final last6Months = <_MonthSpend>[];
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(_viewMonth.year, _viewMonth.month - i, 1);
      final key = '${m.year}-${m.month}';
      last6Months.add(
        _MonthSpend(
          label: _monthNames[m.month - 1].substring(0, 3),
          total: byMonth[key] ?? 0.0,
        ),
      );
    }

    return _EconomyData(
      homeId: homeId,
      budget: budget,
      tickets: tickets,
      totalThisMonth: total,
      historicalTotal: historicalTotal,
      historicalTicketCount: all.length,
      last6Months: last6Months,
    );
  }

  Future<void> _editBudget(double current) async {
    final controller = TextEditingController(
      text: current > 0 ? current.toStringAsFixed(0) : '',
    );
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text('Presupuesto mensual'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Importe (€)',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final n = double.tryParse(
                controller.text.trim().replaceAll(',', '.'),
              );
              Navigator.of(context).pop(n);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (value == null) return;
    final user = _client.auth.currentUser;
    final homeId =
        (await _client
                .from('profiles')
                .select('home_id')
                .eq('id', user!.id)
                .single())['home_id']
            as String;
    await _client.from('budgets').upsert({
      'home_id': homeId,
      'monthly_amount': value,
      'updated_at': DateTime.now().toIso8601String(),
    });
    _reload();
  }

  Future<void> _openScan() async {
    final added = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const ScanTicketScreen()));
    if (added == true) _reload();
  }

  Future<void> _deleteTicket(String id) async {
    await _client.from('tickets').delete().eq('id', id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Economía')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-economy',
        onPressed: _openScan,
        backgroundColor: AppColors.wood,
        foregroundColor: AppColors.ink,
        icon: const Icon(Icons.document_scanner_outlined),
        label: const Text(
          'Escanear ticket',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<_EconomyData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data!;
          if (data.homeId == null) {
            return const Center(child: Text('No perteneces a ningún hogar.'));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _monthNavigator(),
              const SizedBox(height: 12),
              _budgetCard(data),
              const SizedBox(height: 12),
              if (data.last6Months.any((m) => m.total > 0))
                _spendChartCard(data)
              else
                _spendChartEmpty(),
              const SizedBox(height: 12),
              _historicalCard(data),
              const SizedBox(height: 16),
              Text(
                'TICKETS DE ${_monthNames[_viewMonth.month - 1].toUpperCase()}',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 8),
              if (data.tickets.isEmpty)
                _empty()
              else
                ...data.tickets.map((t) => _ticketCard(t)),
            ],
          );
        },
      ),
    );
  }

  Widget _monthNavigator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: AppTheme.cardDecoration(radius: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            '${_monthNames[_viewMonth.month - 1]} ${_viewMonth.year}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            // No dejar avanzar más allá del mes actual.
            onPressed: _isCurrentMonth ? null : () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _historicalCard(_EconomyData data) {
    if (data.historicalTicketCount == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(radius: 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.history, color: AppColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gasto total registrado',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                Text(
                  '${data.historicalTotal.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '${data.historicalTicketCount} tickets en total',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _budgetCard(_EconomyData data) {
    final budget = data.budget;
    final spent = data.totalThisMonth;
    final ratio = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final over = budget > 0 && spent > budget;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Este mes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _editBudget(budget),
                icon: const Icon(Icons.edit, size: 18),
                label: Text(
                  budget > 0
                      ? 'Presupuesto: ${budget.toStringAsFixed(0)} €'
                      : 'Fijar presupuesto',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.woodDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${spent.toStringAsFixed(2)} €',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          if (budget > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
                backgroundColor: const Color(0xFFEFE7CC),
                color: over ? Colors.redAccent : AppColors.wood,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              over
                  ? 'Te has pasado ${(spent - budget).toStringAsFixed(2)} € del presupuesto'
                  : 'Te quedan ${(budget - spent).toStringAsFixed(2)} €',
              style: TextStyle(
                color: over ? Colors.redAccent : Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Tarjeta con la tendencia de gasto de los últimos 6 meses en barras, con
  /// una marca horizontal del presupuesto mensual cuando existe. Si no hay
  /// ningún gasto en el rango, muestra un mensaje amable en vez de una gráfica
  /// vacía.
  Widget _spendChartCard(_EconomyData data) {
    final months = data.last6Months;
    final budget = data.budget;
    final hasBudget = budget > 0;

    final maxMonth = months.fold<double>(
      0,
      (a, m) => m.total > a ? m.total : a,
    );
    final maxValue = (maxMonth > budget ? maxMonth : budget);
    // Un poco de aire por encima para que la barra o la línea no toque el
    // borde superior.
    final maxY = maxValue <= 0 ? 100.0 : maxValue * 1.2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gasto de los últimos meses',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (hasBudget) ...[
            const SizedBox(height: 4),
            Text(
              'Presupuesto: ${budget.toStringAsFixed(0)} € al mes',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(2)} €',
                        const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= months.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            months[i].label,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                extraLinesData: hasBudget
                    ? ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: budget,
                            color: AppColors.woodDark,
                            strokeWidth: 2,
                            dashArray: [6, 4],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              style: const TextStyle(
                                color: AppColors.woodDark,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              labelResolver: (_) => 'Presupuesto',
                            ),
                          ),
                        ],
                      )
                    : const ExtraLinesData(),
                barGroups: [
                  for (int i = 0; i < months.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: months[i].total,
                          color: AppColors.wood,
                          width: 18,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Estado vacío amable cuando no hay gasto en los últimos 6 meses, para no
  /// mostrar una gráfica rota.
  Widget _spendChartEmpty() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gasto de los últimos meses',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Aún no hay gasto registrado en los últimos meses.\n'
            'Cuando escanees tickets verás aquí tu tendencia.',
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _ticketCard(Map<String, dynamic> t) {
    final merchant = (t['merchant'] as String?)?.trim();
    final amount = (t['total_amount'] as num?)?.toDouble() ?? 0;
    final dateStr = t['purchased_at'] as String?;
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(radius: 18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchant?.isNotEmpty == true ? merchant! : 'Ticket',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (date != null)
                  Text(
                    '${date.day.toString().padLeft(2, '0')}/'
                    '${date.month.toString().padLeft(2, '0')}/${date.year}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
              ],
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} €',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _deleteTicket(t['id'] as String),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          const MiauCharacter(mood: MiauMood.curious, size: 110),
          const SizedBox(height: 12),
          Text(
            'Aún no hay tickets este mes.\nEscanea el primero.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

class _EconomyData {
  final String? homeId;
  final double budget;
  final List<Map<String, dynamic>> tickets;
  final double totalThisMonth;
  final double historicalTotal;
  final int historicalTicketCount;
  final List<_MonthSpend> last6Months;
  _EconomyData({
    required this.homeId,
    this.budget = 0,
    this.tickets = const [],
    this.totalThisMonth = 0,
    this.historicalTotal = 0,
    this.historicalTicketCount = 0,
    this.last6Months = const [],
  });
}

/// Gasto agregado de un mes para la gráfica de tendencia.
class _MonthSpend {
  final String label;
  final double total;
  const _MonthSpend({required this.label, required this.total});
}
