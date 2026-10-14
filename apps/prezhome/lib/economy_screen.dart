import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'product_stats_screen.dart';
import 'scan_ticket_screen.dart';
import 'services/task_scheduler.dart';
import 'theme/app_theme.dart';
import 'widgets/animations/animated_counter.dart';
import 'widgets/animations/celebrate.dart';
import 'widgets/animations/press_scale.dart';
import 'widgets/animations/spring_value.dart';
import 'widgets/animations/staggered_entrance.dart';
import 'widgets/miau_character.dart';
import 'utils/friendly_error.dart';
import 'utils/ticket_date.dart';

class EconomyScreen extends StatefulWidget {
  const EconomyScreen({super.key, this.showPoints = true});

  /// Recompensas y puntos solo si el hogar usa el "Modo Puntos"; los gastos y
  /// tickets se ven siempre.
  final bool showPoints;

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

    // Presupuesto
    final budgetRow = await _client
        .from('budgets')
        .select('monthly_amount')
        .eq('home_id', homeId)
        .maybeSingle();
    final budget = (budgetRow?['monthly_amount'] as num?)?.toDouble() ?? 0;

    // Tickets del mes que se ve, por la fecha de la compra.
    final ticketsRes = await _client
        .from('tickets')
        .select('id, merchant, total_amount, purchased_at, created_at')
        .eq('home_id', homeId)
        .or(ticketRangeFilter(monthStart, monthEnd))
        .order('purchased_at', ascending: false)
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
    final trendRes = await _client
        .from('tickets')
        .select('total_amount, purchased_at, created_at')
        .eq('home_id', homeId)
        .or(ticketRangeFilter(rangeStart, rangeEnd));
    final trendRows = (trendRes as List).cast<Map<String, dynamic>>();

    // Clave año-mes -> gasto acumulado.
    final byMonth = <String, double>{};
    for (final row in trendRows) {
      final created = ticketDate(row);
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

    // --- Marketplace de Recompensas ----------------------------------------
    // Miembros del hogar (id -> nombre) para la balanza de puntos.
    final profs = await _client
        .from('profiles')
        .select('id, full_name')
        .eq('home_id', homeId);
    final memberNames = <String, String>{};
    for (final p in (profs as List)) {
      memberNames[p['id']
          as String] = (p['full_name'] as String?)?.trim().isNotEmpty == true
          ? p['full_name'] as String
          : 'Miembro';
    }

    // Puntos ganados por usuario (suma de task_points.points).
    final earnedRes = await _client
        .from('task_points')
        .select('user_id, points')
        .eq('home_id', homeId);
    final earned = <String, int>{};
    for (final row in (earnedRes as List)) {
      final uid = row['user_id'] as String;
      earned[uid] =
          (earned[uid] ?? 0) + ((row['points'] as num?)?.toInt() ?? 0);
    }

    // Puntos canjeados por usuario (suma de reward_redemptions.cost_points).
    final redeemedRes = await _client
        .from('reward_redemptions')
        .select('redeemed_by, cost_points')
        .eq('home_id', homeId);
    final redeemed = <String, int>{};
    for (final row in (redeemedRes as List)) {
      final uid = row['redeemed_by'] as String;
      redeemed[uid] =
          (redeemed[uid] ?? 0) + ((row['cost_points'] as num?)?.toInt() ?? 0);
    }

    // Saldo disponible por usuario con el helper puro de FEAT-003.
    final balances = <String, int>{};
    for (final uid in memberNames.keys) {
      balances[uid] = PointsBalance.forUser(
        earned: earned[uid] ?? 0,
        redeemed: redeemed[uid] ?? 0,
      );
    }

    // Catalogo de recompensas activas del hogar, ordenado por coste.
    final rewardsRes = await _client
        .from('rewards')
        .select('id, title, description, cost_points')
        .eq('home_id', homeId)
        .eq('is_active', true)
        .order('cost_points');
    final rewards = (rewardsRes as List).cast<Map<String, dynamic>>();

    return _EconomyData(
      homeId: homeId,
      budget: budget,
      tickets: tickets,
      totalThisMonth: total,
      historicalTotal: historicalTotal,
      historicalTicketCount: all.length,
      last6Months: last6Months,
      memberNames: memberNames,
      balances: balances,
      rewards: rewards,
      currentUserId: user.id,
    );
  }

  Future<void> _editBudget(double current) async {
    final controller = TextEditingController(
      text: current > 0 ? current.toStringAsFixed(0) : '',
    );
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        backgroundColor: AppColors.cream,
        title: const Text('Presupuesto mensual'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Importe (€)',
            filled: true,
            fillColor: AppColors.card,
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

  /// Canjea una recompensa mediante la RPC SECURITY DEFINER redeem_reward, que
  /// valida el saldo en el servidor. Metodo con cuerpo de bloque para no caer
  /// en el fallo conocido de setState tras el await.
  Future<void> _redeem(Map<String, dynamic> reward) async {
    try {
      await _client.rpc('redeem_reward', params: {'p_reward_id': reward['id']});
      if (mounted) {
        Celebrate.show(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Has canjeado "${reward['title']}"')),
        );
      }
      _reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se ha podido canjear. Puede que te falte saldo.'),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    }
  }

  /// Dialogo para crear una recompensa nueva en el catalogo del hogar. Inserta
  /// en rewards {home_id, title, description?, cost_points, created_by}; el
  /// resto de campos los pone la base de datos por defecto (is_active, etc.).
  Future<void> _createReward(String homeId) async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final costController = TextEditingController(text: '50');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        backgroundColor: AppColors.cream,
        title: const Text('Nueva recompensa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: _rewardFieldDecoration('Título'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: _rewardFieldDecoration('Descripción (opcional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: costController,
              keyboardType: TextInputType.number,
              decoration: _rewardFieldDecoration('Coste en puntos'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (saved != true) return;
    final title = titleController.text.trim();
    final desc = descController.text.trim();
    final cost = int.tryParse(costController.text.trim()) ?? 0;
    if (title.isEmpty) return;

    final user = _client.auth.currentUser;
    try {
      await _client.from('rewards').insert({
        'home_id': homeId,
        'title': title,
        if (desc.isNotEmpty) 'description': desc,
        'cost_points': cost < 0 ? 0 : cost,
        'created_by': user?.id,
      });
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e)),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    }
  }

  InputDecoration _rewardFieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Gastos y tickets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_rounded),
            tooltip: 'Estadísticas de la compra',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProductStatsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FutureBuilder<_EconomyData>(
        future: _future,
        builder: (context, snap) {
          final homeId = snap.data?.homeId;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (homeId != null && widget.showPoints)
                FloatingActionButton.extended(
                  heroTag: 'fab-reward',
                  onPressed: () => _createReward(homeId),
                  backgroundColor: AppColors.card,
                  foregroundColor: AppColors.ink,
                  icon: const Icon(Icons.card_giftcard_outlined),
                  label: const Text(
                    'Nueva recompensa',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 12),
              FloatingActionButton.extended(
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
            ],
          );
        },
      ),
      body: FutureBuilder<_EconomyData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(friendlyError(snapshot.error)));
          }
          final data = snapshot.data!;
          if (data.homeId == null) {
            return const Center(child: Text('No perteneces a ningún hogar.'));
          }

          final children = <Widget>[
            // --- Gastos y tickets ---------------------------------------
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
            _sectionLabel(
              'TICKETS DE ${_monthNames[_viewMonth.month - 1].toUpperCase()}',
            ),
            const SizedBox(height: 8),
            if (data.tickets.isEmpty)
              _empty()
            else
              ...data.tickets.map((t) => _ticketCard(t)),
            if (widget.showPoints) ...[
              const SizedBox(height: 24),
              _sectionLabel('PUNTOS Y RECOMPENSAS'),
              const SizedBox(height: 8),
              _balanceCard(data),
              const SizedBox(height: 12),
              _rewardsCard(data),
            ],
          ];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
            children: [
              for (var i = 0; i < children.length; i++)
                StaggeredEntrance(index: i, child: children[i]),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        letterSpacing: 1,
        fontWeight: FontWeight.w700,
        color: AppColors.inkMuted,
      ),
    );
  }

  /// Tarjeta "Balanza de puntos": comparacion visual del saldo disponible de
  /// cada miembro del hogar con barras de color madera y un contador animado.
  /// Si nadie tiene saldo todavia, muestra un estado amable con Miau.
  Widget _balanceCard(_EconomyData data) {
    final entries = data.memberNames.entries.toList()
      ..sort(
        (a, b) =>
            (data.balances[b.key] ?? 0).compareTo(data.balances[a.key] ?? 0),
      );
    final maxBalance = entries.fold<int>(
      0,
      (a, e) =>
          (data.balances[e.key] ?? 0) > a ? (data.balances[e.key] ?? 0) : a,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.tactileDecoration(radius: AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MiauCharacter(
                mood: MiauMood.celebrating,
                size: 56,
                float: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Balanza de puntos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Saldo de cada miembro para canjear recompensas.',
                      style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty || maxBalance == 0)
            _balanceEmpty()
          else
            for (var i = 0; i < entries.length; i++)
              _balanceRow(
                name: entries[i].value,
                balance: data.balances[entries[i].key] ?? 0,
                maxBalance: maxBalance,
                leader: i == 0,
              ),
        ],
      ),
    );
  }

  /// Fila de la balanza: la barra va en dorado para quien va primero y en
  /// terracota para el resto, y crece con un muelle.
  Widget _balanceRow({
    required String name,
    required int balance,
    required int maxBalance,
    bool leader = false,
  }) {
    final ratio = maxBalance > 0 ? (balance / maxBalance).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: leader ? AppColors.goldBg : AppColors.iconTile,
            child: Icon(
              leader ? Icons.emoji_events_rounded : Icons.person,
              size: 18,
              color: leader ? AppColors.gold : AppColors.ink,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.iconTile,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.stroke, width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SpringValue(
                    value: ratio,
                    from: 0,
                    builder: (context, v, _) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: v.clamp(0.0, 1.0),
                      child: ColoredBox(
                        color: leader ? AppColors.gold : AppColors.terracotta,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AnimatedCounter(
            value: balance.toDouble(),
            formatter: (v) => '${v.round()} pts',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceEmpty() {
    return Row(
      children: [
        const MiauCharacter(mood: MiauMood.curious, size: 72),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aún no hay puntos que repartir',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Completad tareas del hogar para llenar la balanza.',
                style: TextStyle(color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tarjeta "Recompensas": catalogo canjeable del hogar. Cada recompensa
  /// muestra titulo, descripcion opcional y coste, con un boton "Canjear" que
  /// solo se habilita cuando el saldo del usuario actual alcanza el coste. Si
  /// el catalogo esta vacio, invita a crear la primera recompensa.
  Widget _rewardsCard(_EconomyData data) {
    final myBalance = data.balances[data.currentUserId] ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.tactileDecoration(radius: AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recompensas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Tu saldo: $myBalance pts',
            style: TextStyle(
              color: AppColors.woodDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (data.rewards.isEmpty)
            _rewardsEmpty()
          else
            ...data.rewards.map(
              (r) => _rewardRow(reward: r, myBalance: myBalance),
            ),
        ],
      ),
    );
  }

  Widget _rewardRow({
    required Map<String, dynamic> reward,
    required int myBalance,
  }) {
    final title = (reward['title'] as String?)?.trim() ?? 'Recompensa';
    final desc = (reward['description'] as String?)?.trim();
    final cost = (reward['cost_points'] as num?)?.toInt() ?? 0;
    final canRedeem = myBalance >= cost;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.tactileDecoration(radius: 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (desc != null && desc.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '$cost pts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.woodDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PressScale(
            onTap: canRedeem ? () => _redeem(reward) : null,
            child: Opacity(
              opacity: canRedeem ? 1 : 0.4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: AppTheme.tactileDecoration(
                  radius: 999,
                  color: AppColors.gold,
                  shadow: 2,
                ),
                child: const Text(
                  'Canjear',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onBrand,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardsEmpty() {
    return Row(
      children: [
        const MiauCharacter(mood: MiauMood.greeting, size: 72),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Todavía no hay recompensas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Crea la primera con el botón "Nueva recompensa".',
                style: TextStyle(color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _monthNavigator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: AppTheme.tactileDecoration(radius: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: 'Anterior',
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            '${_monthNames[_viewMonth.month - 1]} ${_viewMonth.year}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            tooltip: 'Siguiente',
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
      decoration: AppTheme.tactileDecoration(radius: 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.history, color: AppColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gasto total registrado',
                  style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
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
                  style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
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
      decoration: AppTheme.tactileDecoration(radius: AppRadius.lg),
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
            style: TextStyle(
              fontSize: 32,
              letterSpacing: -0.6,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          if (budget > 0) ...[
            const SizedBox(height: 12),
            Container(
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.iconTile,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.stroke, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: SpringValue(
                value: ratio,
                from: 0,
                builder: (context, v, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: v.clamp(0.0, 1.0),
                  child: ColoredBox(
                    color: over ? AppColors.terracotta : AppColors.gold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              over
                  ? 'Te has pasado ${(spent - budget).toStringAsFixed(2)} € del presupuesto'
                  : 'Te quedan ${(budget - spent).toStringAsFixed(2)} €',
              style: TextStyle(
                color: over ? AppColors.expired : AppColors.inkMuted,
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
      decoration: AppTheme.tactileDecoration(radius: AppRadius.lg),
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
              style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
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
                        TextStyle(
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
                              color: AppColors.inkMuted,
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
                              style: TextStyle(
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
      decoration: AppTheme.tactileDecoration(radius: AppRadius.lg),
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
            style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
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
      decoration: AppTheme.tactileDecoration(radius: 18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.receipt_long_outlined, color: AppColors.ink),
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
                    style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
                  ),
              ],
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} €',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          IconButton(
            tooltip: 'Eliminar',
            icon: Icon(Icons.delete_outline, color: AppColors.expired),
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
            style: TextStyle(color: AppColors.inkMuted),
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
  // Marketplace de Recompensas.
  final Map<String, String> memberNames;
  final Map<String, int> balances;
  final List<Map<String, dynamic>> rewards;
  final String? currentUserId;
  _EconomyData({
    required this.homeId,
    this.budget = 0,
    this.tickets = const [],
    this.totalThisMonth = 0,
    this.historicalTotal = 0,
    this.historicalTicketCount = 0,
    this.last6Months = const [],
    this.memberNames = const {},
    this.balances = const {},
    this.rewards = const [],
    this.currentUserId,
  });
}

/// Gasto agregado de un mes para la gráfica de tendencia.
class _MonthSpend {
  final String label;
  final double total;
  const _MonthSpend({required this.label, required this.total});
}
