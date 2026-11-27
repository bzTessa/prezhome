import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'l10n/l10n.dart';
import 'services/shared_expenses.dart';
import 'theme/app_theme.dart';
import 'utils/friendly_error.dart';
import 'utils/money.dart';

/// Gastos compartidos: quién ha pagado qué, quién debe a quién (a partes
/// iguales entre la gente de casa) y "Saldar cuentas".
class SharedExpensesScreen extends StatefulWidget {
  const SharedExpensesScreen({super.key, required this.homeId});

  final String homeId;

  @override
  State<SharedExpensesScreen> createState() => _SharedExpensesScreenState();
}

class _SharedExpensesScreenState extends State<SharedExpensesScreen> {
  late final _api = SharedExpenses(Supabase.instance.client);
  Map<String, String> _people = const {};
  List<SharedExpense> _expenses = const [];
  bool _loading = true;
  Object? _error;

  String get _me => Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final (people, expenses) = await (
        _api.people(widget.homeId),
        _api.pending(widget.homeId),
      ).wait;
      if (!mounted) return;
      setState(() {
        _people = people;
        _expenses = expenses;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e;
        });
      }
    }
  }

  String _name(String id) =>
      id == _me ? context.l.sxYou : (_people[id] ?? context.l.someone);

  void _fail(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(friendlyError(e)),
        backgroundColor: AppColors.expired,
      ),
    );
  }

  Future<void> _add() async {
    if (_people.isEmpty) return;
    final r =
        await showModalBottomSheet<
          ({String paidBy, double amount, String concept})
        >(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) =>
              _AddExpenseSheet(people: _people, me: _me, nameOf: _name),
        );
    if (r == null) return;
    try {
      await _api.add(
        homeId: widget.homeId,
        paidBy: r.paidBy,
        amount: r.amount,
        concept: r.concept,
      );
      HapticFeedback.lightImpact();
      await _load();
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _delete(SharedExpense e) async {
    setState(() => _expenses = [..._expenses]..remove(e));
    try {
      await _api.delete(e.id);
    } catch (err) {
      _fail(err);
      await _load();
    }
  }

  Future<void> _settle() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l.sxSettleTitle),
        content: Text(context.l.sxSettleBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l.sxSettle),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.settleAll(widget.homeId);
      HapticFeedback.mediumImpact();
      await _load();
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balances = expenseBalances(_expenses, _people.keys.toList());
    final transfers = settleUp(balances);
    final total = _expenses.fold<double>(0, (a, e) => a + e.amount);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(context.l.sxTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-shared-expenses',
        onPressed: _loading ? null : _add,
        icon: const Icon(Icons.add_rounded),
        label: Text(context.l.sxAdd),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(friendlyError(_error)))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  _summary(transfers, total),
                  const SizedBox(height: 20),
                  if (_expenses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        context.l.sxEmpty,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMuted,
                      ),
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                      child: Text(
                        context.l.sxPending.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: AppTheme.surfaceDecoration(radius: 18),
                      child: Column(
                        children: [
                          for (var i = 0; i < _expenses.length; i++) ...[
                            if (i > 0) const Divider(height: 1, indent: 16),
                            _row(_expenses[i]),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _summary(List<Transfer> transfers, double total) {
    final even = transfers.isEmpty;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: even ? AppColors.sageBg : AppColors.terracottaBg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            even ? context.l.sxEven : context.l.sxToSettle,
            style: AppTextStyles.headline,
          ),
          if (total > 0) ...[
            const SizedBox(height: 4),
            Text(
              context.l.sxTotal(money(total), _people.length),
              style: AppTextStyles.bodyMuted,
            ),
          ],
          for (final t in transfers) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: AppColors.terracottaText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l.sxOwes(
                      _name(t.from),
                      money(t.amount),
                      _name(t.to),
                    ),
                    style: AppTextStyles.bodyStrong,
                  ),
                ),
              ],
            ),
          ],
          if (!even) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _settle,
              icon: const Icon(Icons.handshake_outlined),
              label: Text(context.l.sxSettle),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(SharedExpense e) {
    final date = DateFormat.MMMd(
      Localizations.localeOf(context).toString(),
    ).format(e.day);
    return ListTile(
      title: Text(e.concept, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        context.l.sxPaidBy(_name(e.paidBy), date),
        style: AppTextStyles.labelMuted,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            money(e.amount),
            style: AppTextStyles.numeric(AppTextStyles.bodyStrong),
          ),
          IconButton(
            tooltip: context.l.sxDelete,
            onPressed: () => _delete(e),
            icon: Icon(Icons.delete_outline_rounded, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet({
    required this.people,
    required this.me,
    required this.nameOf,
  });

  final Map<String, String> people;
  final String me;
  final String Function(String id) nameOf;

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _amount = TextEditingController();
  final _concept = TextEditingController();
  late String _payer = widget.people.containsKey(widget.me)
      ? widget.me
      : widget.people.keys.first;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _concept.dispose();
    super.dispose();
  }

  void _save() {
    final v = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    if (v == null || v <= 0) {
      setState(() => _error = context.l.sxAmountInvalid);
      return;
    }
    final concept = _concept.text.trim().isEmpty
        ? context.l.sxDefaultConcept
        : _concept.text.trim();
    Navigator.of(context).pop((
      paidBy: _payer,
      amount: double.parse(v.toStringAsFixed(2)),
      concept: concept,
    ));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l.sxAdd, style: AppTextStyles.headline),
        const SizedBox(height: 16),
        TextField(
          controller: _amount,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: InputDecoration(
            labelText: context.l.sxAmount,
            errorText: _error,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _concept,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: context.l.sxConcept,
            hintText: context.l.sxConceptHint,
          ),
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 16),
        Text(context.l.sxWhoPaid, style: AppTextStyles.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final id in widget.people.keys)
              ChoiceChip(
                label: Text(widget.nameOf(id)),
                selected: _payer == id,
                onSelected: (_) => setState(() => _payer = id),
              ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: _save, child: Text(context.l.save)),
        ),
      ],
    ),
  );
}
