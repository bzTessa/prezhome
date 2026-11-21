import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../add_recipe_chooser.dart';
import '../l10n/l10n.dart';
import '../models/inventory_item.dart';
import '../models/shopping_list_item.dart';
import '../models/task.dart';
import '../scan_barcode_screen.dart';
import '../scan_ticket_screen.dart';
import '../services/offline_provider.dart';
import '../services/shopping_checkout.dart';
import '../theme/app_theme.dart';
import '../utils/friendly_error.dart';
import '../utils/offline_actions.dart';
import '../utils/quick_capture.dart';
import '../utils/shopping_categories.dart';
import '../utils/shopping_display.dart';
import 'miau_character.dart';
import 'segmented_pill.dart';
import '../services/inbox.dart';

enum _QuickCaptureResult { saved, ticket, barcode, recipe }

/// Hoja de "Apuntar": campo rápido (texto o voz) para mandar algo a la compra,
/// a "En casa" o a tareas, más accesos directos a ticket, código de barras y
/// receta. Devuelve true si guardó algo.
Future<bool> showQuickCapture(
  BuildContext context, {
  CaptureTarget initialTarget = CaptureTarget.shopping,
  bool allowTasks = true,
}) async {
  final result = await showModalBottomSheet<_QuickCaptureResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => _QuickCaptureSheet(
      initialTarget: !allowTasks && initialTarget == CaptureTarget.task
          ? CaptureTarget.shopping
          : initialTarget,
      allowTasks: allowTasks,
    ),
  );
  if (!context.mounted || result == null) return false;
  switch (result) {
    case _QuickCaptureResult.saved:
      return true;
    case _QuickCaptureResult.ticket:
      final saved = await Navigator.of(
        context,
      ).push<bool>(MaterialPageRoute(builder: (_) => const ScanTicketScreen()));
      return saved == true;
    case _QuickCaptureResult.barcode:
      final item = await Navigator.of(context).push<InventoryItem>(
        MaterialPageRoute(builder: (_) => const ScanBarcodeScreen()),
      );
      if (item == null) return false;
      final nowMillis = DateTime.now().millisecondsSinceEpoch;
      final localId = newLocalId(nowMillis: nowMillis, seq: 0);
      final withId = InventoryItem(
        id: localId,
        homeId: item.homeId,
        name: item.name,
        category: item.category,
        itemType: item.itemType,
        quantity: item.quantity,
        unit: item.unit,
        expirationDate: item.expirationDate,
        isStaple: item.isStaple,
        kind: item.kind,
        recipeId: item.recipeId,
        servings: item.servings,
        frozenOn: item.frozenOn,
        bestBefore: item.bestBefore,
        imageUrl: item.imageUrl,
      );
      await OfflineProvider.instance.inventory.applyLocalWrite(
        buildInsertOp(
          table: kInventoryTable,
          id: localId,
          payload: withId.toCacheMap(),
          nowMillis: nowMillis,
          seq: 0,
        ),
      );
      unawaited(OfflineProvider.instance.inventory.tryDrain());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l.shopAdded(shoppingCleanName(item.name))),
          ),
        );
      }
      return true;
    case _QuickCaptureResult.recipe:
      final added = await AddRecipeChooser.show(context);
      return added == true;
  }
}

class _QuickCaptureSheet extends StatefulWidget {
  const _QuickCaptureSheet({
    required this.initialTarget,
    this.allowTasks = true,
  });

  final CaptureTarget initialTarget;

  /// Sin el módulo de tareas no se ofrece "a Tareas".
  final bool allowTasks;

  @override
  State<_QuickCaptureSheet> createState() => _QuickCaptureSheetState();
}

class _QuickCaptureSheetState extends State<_QuickCaptureSheet> {
  final _text = TextEditingController();
  final _client = Supabase.instance.client;
  late CaptureTarget _target = widget.initialTarget;
  bool _saving = false;
  SpeechToText? _stt;
  bool _listening = false;

  @override
  void dispose() {
    _stt?.cancel();
    _text.dispose();
    super.dispose();
  }

  Future<void> _toggleVoice() async {
    HapticFeedback.lightImpact();
    if (_listening) {
      await _stt?.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    try {
      final stt = _stt ??= SpeechToText();
      final ok = await stt.initialize(
        onStatus: (s) {
          if ((s == 'done' || s == 'notListening') && mounted) {
            setState(() => _listening = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
      );
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l.cmMicPermission), persist: false),
          );
        }
        return;
      }
      if (!mounted) return;
      setState(() => _listening = true);
      final lang = Localizations.localeOf(context).languageCode;
      final ids = (await stt.locales()).map((l) => l.localeId).toList();
      final localeId = ids.firstWhere(
        (id) => id.toLowerCase().startsWith(lang.toLowerCase()),
        orElse: () => '',
      );
      await stt.listen(
        onResult: (r) {
          if (!mounted) return;
          final words = r.recognizedWords.trim();
          if (words.isEmpty) return;
          _text.value = TextEditingValue(
            text: words,
            selection: TextSelection.collapsed(offset: words.length),
          );
          if (r.finalResult && mounted) {
            setState(() => _listening = false);
          }
        },
        listenOptions: SpeechListenOptions(
          localeId: localeId.isEmpty ? null : localeId,
          partialResults: true,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _listening = false);
    }
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
      await saveCapture(
        _client,
        target: _target,
        items: items,
        homeId: homeId,
        userId: user.id,
      );
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final msg = context.l.captureDone(items.length);
      Navigator.pop(context, _QuickCaptureResult.saved);
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
    // La nota va primero: es apuntar sin pensar dónde.
    final targets = [
      CaptureTarget.note,
      CaptureTarget.shopping,
      CaptureTarget.pantry,
      if (widget.allowTasks) CaptureTarget.task,
    ];
    final hint = switch (_target) {
      CaptureTarget.shopping => context.l.captureHintShopping,
      CaptureTarget.pantry => context.l.captureHintPantry,
      CaptureTarget.task => context.l.captureHintTask,
      CaptureTarget.note => context.l.captureHintNote,
    };
    final mood = switch (_target) {
      CaptureTarget.shopping => MiauMood.shopping,
      CaptureTarget.pantry => MiauMood.curious,
      CaptureTarget.task => MiauMood.greeting,
      CaptureTarget.note => MiauMood.neutral,
    };
    return SafeArea(
      child: SingleChildScrollView(
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
            Row(
              children: [
                MiauCharacter(mood: mood, size: 46, interactive: true),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    context.l.captureTitle,
                    style: AppTextStyles.headline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedPill(
              labels: [for (final t in targets) _label(context, t)],
              selected: targets.indexOf(_target).clamp(0, targets.length - 1),
              onChanged: (i) => setState(() => _target = targets[i]),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _text,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                hintText: hint,
                suffixIcon: kIsWeb
                    ? null
                    : IconButton(
                        tooltip: _listening
                            ? context.l.captureVoiceListening
                            : context.l.captureVoiceTooltip,
                        onPressed: _toggleVoice,
                        icon: Icon(
                          _listening
                              ? Icons.mic_rounded
                              : Icons.mic_none_rounded,
                          color: _listening
                              ? AppColors.terracotta
                              : AppColors.woodDark,
                        ),
                      ),
              ),
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
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _quickChip(
                  icon: Icons.document_scanner_outlined,
                  label: context.l.captureTicket,
                  onTap: () =>
                      Navigator.pop(context, _QuickCaptureResult.ticket),
                ),
                _quickChip(
                  icon: Icons.qr_code_scanner_rounded,
                  label: context.l.captureBarcode,
                  onTap: () =>
                      Navigator.pop(context, _QuickCaptureResult.barcode),
                ),
                _quickChip(
                  icon: Icons.restaurant_menu_rounded,
                  label: context.l.captureRecipe,
                  onTap: () =>
                      Navigator.pop(context, _QuickCaptureResult.recipe),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17, color: AppColors.woodDark),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: AppColors.cardEdge),
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.ink,
        textStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

String _label(BuildContext context, CaptureTarget t) => switch (t) {
  CaptureTarget.shopping => context.l.captureToShopping,
  CaptureTarget.pantry => context.l.captureToPantry,
  CaptureTarget.task => context.l.captureToTask,
  CaptureTarget.note => context.l.captureToNote,
};

/// Guarda lo apuntado en su sitio: lista de la compra, En casa, tareas o la
/// bandeja. Lo usan la hoja del "+" y la bandeja al convertir un apunte.
Future<void> saveCapture(
  SupabaseClient client, {
  required CaptureTarget target,
  required List<String> items,
  required String homeId,
  required String userId,
}) async {
  switch (target) {
    case CaptureTarget.shopping:
      final repo = OfflineProvider.instance.shopping;
      final nowMillis = DateTime.now().millisecondsSinceEpoch;
      for (var i = 0; i < items.length; i++) {
        final name = items[i];
        final localId = newLocalId(nowMillis: nowMillis, seq: i);
        final entry = ShoppingListItem(
          id: localId,
          homeId: homeId,
          name: name,
          category: defaultCategoryFor(name),
        );
        await repo.applyLocalWrite(
          buildInsertOp(
            table: kShoppingTable,
            id: localId,
            payload: entry.toCacheMap(),
            nowMillis: nowMillis,
            seq: i,
          ),
        );
      }
      unawaited(repo.tryDrain());
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
      unawaited(OfflineProvider.instance.inventory.tryDrain());
    case CaptureTarget.task:
      await client
          .from('tasks')
          .insert(
            HomeTask(
              id: '',
              homeId: homeId,
              title: items.single,
              dueDate: DateTime.now(),
            ).toInsertMap(createdBy: userId),
          );
    case CaptureTarget.note:
      await Inbox(client).add(homeId, items.single);
  }
}
