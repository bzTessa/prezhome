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

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  void _reload() {
    final future = _load();
    setState(() => _future = future);
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

    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final firstStr = firstOfMonth.toIso8601String().split('T').first;

    // Presupuesto
    final budgetRow = await _client
        .from('budgets')
        .select('monthly_amount')
        .eq('home_id', homeId)
        .maybeSingle();
    final budget = (budgetRow?['monthly_amount'] as num?)?.toDouble() ?? 0;

    // Tickets del mes actual. Filtramos por created_at (cuándo se escaneó, dato
    // siempre fiable) en vez de purchased_at (la fecha del ticket, que la IA
    // puede leer mal o dejar vacía y haría desaparecer el ticket).
    final ticketsRes = await _client
        .from('tickets')
        .select('id, merchant, total_amount, purchased_at, created_at')
        .eq('home_id', homeId)
        .gte('created_at', firstStr)
        .order('created_at', ascending: false);
    final tickets = (ticketsRes as List).cast<Map<String, dynamic>>();

    final total = tickets.fold<double>(
      0,
      (a, t) => a + ((t['total_amount'] as num?)?.toDouble() ?? 0),
    );

    return _EconomyData(
      homeId: homeId,
      budget: budget,
      tickets: tickets,
      totalThisMonth: total,
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
    final homeId = (await _client
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
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ScanTicketScreen()),
    );
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
              _budgetCard(data),
              const SizedBox(height: 16),
              Text(
                'TICKETS DE ESTE MES',
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
  _EconomyData({
    required this.homeId,
    this.budget = 0,
    this.tickets = const [],
    this.totalThisMonth = 0,
  });
}
