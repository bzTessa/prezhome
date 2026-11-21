import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'l10n/l10n.dart';
import 'services/inbox.dart';
import 'services/reminders.dart';
import 'theme/app_theme.dart';
import 'utils/friendly_error.dart';
import 'utils/quick_capture.dart';
import 'widgets/empty_state.dart';
import 'widgets/miau_character.dart';
import 'widgets/quick_capture_sheet.dart';

/// Bandeja: lo apuntado con el "+" sin decidir qué era. Cada apunte se pasa a
/// la compra, a tareas, se programa un aviso o se borra.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key, this.allowTasks = true});

  /// Sin el módulo de tareas no se ofrece "Hacerlo tarea".
  final bool allowTasks;

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  late Future<List<InboxNote>> _future = Inbox(_client).list();
  String? _homeId;

  void _reload() => setState(() => _future = Inbox(_client).list());

  Future<String?> _home() async {
    if (_homeId != null) return _homeId;
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final p = await _client
        .from('profiles')
        .select('home_id')
        .eq('id', uid)
        .maybeSingle();
    return _homeId = p?['home_id'] as String?;
  }

  Future<void> _convert(InboxNote n, CaptureTarget target) async {
    final homeId = await _home();
    final uid = _client.auth.currentUser?.id;
    if (homeId == null || uid == null) return;
    try {
      await saveCapture(
        _client,
        target: target,
        items: splitCapture(n.text, target),
        homeId: homeId,
        userId: uid,
      );
      await Inbox(_client).remove(n.id);
    } catch (e) {
      _error(e);
      return;
    }
    // Ya no es un apunte: su aviso, si lo tenía, se quita.
    if (n.remindAt != null) unawaited(Reminders.sync(_client));
    HapticFeedback.mediumImpact();
    _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            target == CaptureTarget.task
                ? context.l.inboxToTaskDone
                : context.l.inboxToShoppingDone,
          ),
        ),
      );
  }

  Future<void> _remind(InboxNote n) async {
    final now = DateTime.now();
    final base = n.remindAt ?? now.add(const Duration(days: 1));
    final day = await showDatePicker(
      context: context,
      initialDate: base.isBefore(now) ? now : base,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        n.remindAt ?? DateTime(now.year, now.month, now.day, 10),
      ),
    );
    if (time == null || !mounted) return;
    final at = DateTime(day.year, day.month, day.day, time.hour, time.minute);
    try {
      await Inbox(_client).setRemind(n.id, at);
    } catch (e) {
      _error(e);
      return;
    }
    // Los avisos se programan en el móvil: se rehacen con el nuevo.
    await Reminders.sync(_client);
    _reload();
  }

  Future<void> _delete(InboxNote n) async {
    final homeId = await _home();
    try {
      await Inbox(_client).remove(n.id);
    } catch (e) {
      _error(e);
      return;
    }
    if (n.remindAt != null) unawaited(Reminders.sync(_client));
    _reload();
    if (!mounted || homeId == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.l.shopRemovedOne(n.text)),
          action: SnackBarAction(
            label: context.l.undo,
            onPressed: () async {
              try {
                await Inbox(_client).restore(homeId, n);
                if (n.remindAt != null) await Reminders.sync(_client);
              } catch (_) {}
              if (mounted) _reload();
            },
          ),
        ),
      );
  }

  Future<void> _actions(InboxNote n) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(n.text, style: AppTextStyles.title),
            ),
            ListTile(
              leading: Icon(
                Icons.shopping_cart_outlined,
                color: AppColors.woodDark,
              ),
              title: Text(ctx.l.inboxToShopping),
              onTap: () => Navigator.pop(ctx, 'shopping'),
            ),
            if (widget.allowTasks)
              ListTile(
                leading: Icon(
                  Icons.check_circle_outline,
                  color: AppColors.woodDark,
                ),
                title: Text(ctx.l.inboxToTask),
                onTap: () => Navigator.pop(ctx, 'task'),
              ),
            ListTile(
              leading: Icon(
                Icons.notifications_none_rounded,
                color: AppColors.woodDark,
              ),
              title: Text(ctx.l.inboxRemind),
              onTap: () => Navigator.pop(ctx, 'remind'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.expired),
              title: Text(ctx.l.inboxDone),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'shopping':
        await _convert(n, CaptureTarget.shopping);
      case 'task':
        await _convert(n, CaptureTarget.task);
      case 'remind':
        await _remind(n);
      case 'delete':
        await _delete(n);
    }
  }

  void _error(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(friendlyError(e, context.l.couldNotUpdate)),
        backgroundColor: AppColors.expired,
      ),
    );
  }

  Future<void> _add() async {
    final saved = await showQuickCapture(
      context,
      initialTarget: CaptureTarget.note,
      allowTasks: widget.allowTasks,
    );
    if (saved && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(context.l.inboxTitle),
        actions: [
          IconButton(
            tooltip: context.l.captureTitle,
            icon: const Icon(Icons.add_rounded),
            onPressed: _add,
          ),
        ],
      ),
      body: FutureBuilder<List<InboxNote>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(friendlyError(snap.error, context.l.couldNotLoad)),
            );
          }
          final notes = snap.data ?? const [];
          if (notes.isEmpty) {
            return EmptyState(
              mood: MiauMood.sleeping,
              title: context.l.inboxEmptyTitle,
              message: context.l.inboxEmptyHint,
              actionLabel: context.l.captureTitle,
              onAction: _add,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    context.l.inboxHint,
                    style: TextStyle(color: AppColors.inkMuted),
                  ),
                ),
                Container(
                  decoration: AppTheme.cardDecoration(),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      children: [
                        for (final (i, n) in notes.indexed) ...[
                          if (i > 0) Divider(height: 1, color: AppColors.line),
                          ListTile(
                            title: Text(
                              n.text,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: n.remindAt == null
                                ? null
                                : Row(
                                    children: [
                                      Icon(
                                        Icons.notifications_active_outlined,
                                        size: 14,
                                        color: AppColors.terracotta,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat.MMMEd(
                                          locale,
                                        ).add_Hm().format(n.remindAt!),
                                      ),
                                    ],
                                  ),
                            trailing: Icon(
                              Icons.more_horiz_rounded,
                              color: AppColors.inkMuted,
                            ),
                            onTap: () => _actions(n),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
