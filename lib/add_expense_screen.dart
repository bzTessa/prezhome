import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/expense.dart';
import 'theme/app_theme.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _client = Supabase.instance.client;

  final _amountController = TextEditingController();
  final _storeController = TextEditingController();
  final _noteController = TextEditingController();
  String _category = 'Supermercado';
  DateTime _spentOn = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _storeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw 'No autenticado';
      final profile = await _client
          .from('profiles')
          .select('home_id')
          .eq('id', user.id)
          .single();
      final homeId = profile['home_id'];
      if (homeId == null) throw 'No perteneces a ningún hogar.';

      final amount = double.tryParse(
        _amountController.text.trim().replaceAll(',', '.'),
      );
      if (amount == null || amount <= 0) throw 'Importe no válido.';

      final expense = Expense(
        id: '',
        homeId: homeId,
        amount: amount,
        category: _category,
        store: _storeController.text.trim().isEmpty
            ? null
            : _storeController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        spentOn: _spentOn,
      );
      await _client
          .from('expenses')
          .insert(expense.toInsertMap(createdBy: user.id));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Nuevo gasto')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _dec('Importe (€)'),
              validator: (v) {
                final n = double.tryParse(
                  (v ?? '').trim().replaceAll(',', '.'),
                );
                if (n == null || n <= 0) return 'Introduce un importe válido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: _dec('Categoría'),
              items: Expense.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _storeController,
              decoration: _dec('Tienda (opcional)'),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _spentOn,
                  firstDate: DateTime(now.year - 3),
                  lastDate: now,
                );
                if (picked != null) setState(() => _spentOn = picked);
              },
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: _dec('Fecha'),
                child: Text(
                  '${_spentOn.day.toString().padLeft(2, '0')}/'
                  '${_spentOn.month.toString().padLeft(2, '0')}/'
                  '${_spentOn.year}',
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: _dec('Nota (opcional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text('Guardar gasto'),
            ),
          ],
        ),
      ),
    );
  }
}
