import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_expense_screen.dart';
import 'models/expense.dart';
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

  void _reload() => setState(() => _future = _load());

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

    // Gastos del mes actual
    final expRes = await _client
        .from('expenses')
        .select()
        .eq('home_id', homeId)
        .gte('spent_on', firstStr)
        .order('spent_on', ascending: false);
    final expenses =
        (expRes as List).map((m) => Expense.fromMap(m)).toList();

    final total = expenses.fold<double>(0, (a, e) => a + e.amount);

    return _EconomyData(
      homeId: homeId,
      budget: budget,
      expenses: expenses,
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

  Future<void> _openAdd() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );
    if (added == true) _reload();
  }

  Future<void> _delete(Expense e) async {
    await _client.from('expenses').delete().eq('id', e.id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Economía')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: AppColors.wood,
        foregroundColor: AppColors.ink,
        icon: const Icon(Icons.add),
        label: const Text(
          'Nuevo gasto',
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
                'GASTOS DE ESTE MES',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 8),
              if (data.expenses.isEmpty)
                _empty()
              else
                ...data.expenses.map((e) => _expenseCard(e)),
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

  Widget _expenseCard(Expense e) {
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
            child: Icon(_iconFor(e.category), color: AppColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.store?.isNotEmpty == true ? e.store! : e.category,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${e.category} · ${e.spentOn.day.toString().padLeft(2, '0')}/'
                  '${e.spentOn.month.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            '${e.amount.toStringAsFixed(2)} €',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _delete(e),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String category) {
    switch (category) {
      case 'Supermercado':
        return Icons.shopping_cart_outlined;
      case 'Hogar':
        return Icons.home_outlined;
      case 'Ocio':
        return Icons.celebration_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          const MiauCharacter(mood: MiauMood.curious, size: 110),
          const SizedBox(height: 12),
          Text(
            'Aún no hay gastos este mes.',
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
  final List<Expense> expenses;
  final double totalThisMonth;
  _EconomyData({
    required this.homeId,
    this.budget = 0,
    this.expenses = const [],
    this.totalThisMonth = 0,
  });
}
