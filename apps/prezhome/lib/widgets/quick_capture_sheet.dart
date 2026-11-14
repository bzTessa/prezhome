import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n.dart';
import '../models/shopping_list_item.dart';
import '../models/task.dart';
import '../services/shopping_checkout.dart';
import '../theme/app_theme.dart';
import '../utils/friendly_error.dart';
import '../utils/quick_capture.dart';
import '../utils/shopping_categories.dart';
import 'segmented_pill.dart';

/// Hoja de "Apuntar": un solo campo para mandar algo a la compra, a la
/// despensa o a tareas sin cambiar de pantalla. Devuelve true si apuntó algo.
Future<bool> showQuickCapture(BuildContext context) async {
  final done = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => const _QuickCaptureSheet(),
  );
  return done == true;
}

class _QuickCaptureSheet extends StatefulWidget {
  const _QuickCaptureSheet();

  @override
  State<_QuickCaptureSheet> createState() => _QuickCaptureSheetState();
}

class _QuickCaptureSheetState extends State<_QuickCaptureSheet> {
  final _text = TextEditingController();
  final _client = Supabase.instance.client;
  var _target = CaptureTarget.shopping;
  var _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final items = splitCapture(_text.text, _target);
    final user = _client.auth.currentUser;
    if (items.isEmpty || user == null || _saving) return;
    setState(() => _saving = true);
    try {
      final profile = await _client
          .from('profiles')
          .select('home_id')
          .eq('id', user.id)
          .maybeSingle();
      final homeId = profile?['home_id'] as String?;
      if (homeId == null) return;
      switch (_target) {
        case CaptureTarget.shopping:
          await _client.from('shopping_list_items').insert([
            for (final name in items)
              ShoppingListItem(
                homeId: homeId,
                name: name,
                category: defaultCategoryFor(name),
              ).toInsertMap(),
          ]);
        case CaptureTarget.pantry:
          final checkout = ShoppingCheckout();
          for (final name in items) {
            await checkout.addToPantry(
              ShoppingListItem(
                homeId: homeId,
                name: name,
                category: defaultCategoryFor(name),
              ),
              homeId: homeId,
            );
          }
        case CaptureTarget.task:
          await _client
              .from('tasks')
              .insert(
                HomeTask(
                  id: '',
                  homeId: homeId,
                  title: items.single,
                  dueDate: DateTime.now(),
                ).toInsertMap(createdBy: user.id),
              );
      }
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final msg = context.l.captureDone(items.length);
      Navigator.pop(context, true);
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e)),
          backgroundColor: AppColors.expired,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hint = switch (_target) {
      CaptureTarget.shopping => context.l.captureHintShopping,
      CaptureTarget.pantry => context.l.captureHintPantry,
      CaptureTarget.task => context.l.captureHintTask,
    };
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l.captureTitle, style: AppTextStyles.headline),
          const SizedBox(height: AppSpacing.md),
          SegmentedPill(
            labels: [
              context.l.captureToShopping,
              context.l.captureToPantry,
              context.l.captureToTask,
            ],
            selected: _target.index,
            onChanged: (i) => setState(() => _target = CaptureTarget.values[i]),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _text,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(hintText: hint),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check_rounded),
            label: Text(context.l.captureSave),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
