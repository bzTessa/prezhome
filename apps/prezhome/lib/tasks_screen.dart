import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_task_screen.dart';
import 'models/dashboard_prefs.dart';
import 'models/task.dart';
import 'services/shopping_checkout.dart';
import 'services/task_scheduler.dart';
import 'theme/app_motion.dart';
import 'theme/app_theme.dart';
import 'widgets/empty_state.dart';
import 'widgets/list_skeleton.dart';
import 'utils/realtime_sync.dart';
import 'widgets/miau_character.dart';
import 'utils/friendly_error.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  late Future<_TasksData> _future;

  // Filtro de persona: null = todas; si no, id del miembro (Mías = uid).
  String? _filterUser;
  final _quickController = TextEditingController();

  // Canal Realtime de las tareas del hogar. Se abre UNA sola vez en initState
  // (filtrado por home_id) y se cierra en dispose. Si el otro miembro del hogar
  // completa o cambia una tarea, recargamos al instante.
  // TasksScreen es hijo directo del IndexedStack siempre vivo: abrir una vez,
  // cerrar en dispose, nunca dejar canales colgando.
  RealtimeChannel? _channel;

  // Guarda PURA que decide avisar de "sin conexión en vivo" una sola vez.
  final RealtimeNoticeGate _noticeGate = RealtimeNoticeGate();

  @override
  void initState() {
    super.initState();
    _future = _load();
    _subscribeRealtime();
  }

  /// Abre el canal Realtime filtrado por el hogar. Resuelve el home_id sin
  /// bloquear la UI; ante cualquier cambio en 'tasks' recarga de forma
  /// idempotente (reusa _reload, que vuelve a consultar la BD), de modo que la
  /// escritura propia y su eco Realtime convergen al mismo estado sin duplicar.
  Future<void> _subscribeRealtime() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;
      final profile = await _client
          .from('profiles')
          .select('home_id')
          .eq('id', user.id)
          .maybeSingle();
      final homeId = profile?['home_id'] as String?;
      if (homeId == null || !mounted) return;
      // TasksScreen es instancia única (main_shell), así que no hay colisión de
      // topic posible; aun así hacemos el topic único por instancia por
      // consistencia con la lista de la compra y robustez futura.
      final channel = _client
          .channel('public:tasks:$homeId:${identityHashCode(this)}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'tasks',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'home_id',
              value: homeId,
            ),
            callback: (_) {
              if (!mounted) return;
              _reload();
            },
          )
          .subscribe((status, [error]) {
            _onChannelStatus(status);
          });
      _channel = channel;
    } catch (_) {
      _notifyRealtimeDown();
    }
  }

  /// Traduce el estado de Supabase a nuestro estado PURO y, si el gate decide
  /// avisar, muestra el SnackBar discreto una sola vez.
  void _onChannelStatus(RealtimeSubscribeStatus status) {
    final RealtimeChannelState state;
    switch (status) {
      case RealtimeSubscribeStatus.subscribed:
        state = RealtimeChannelState.subscribed;
        break;
      case RealtimeSubscribeStatus.channelError:
        state = RealtimeChannelState.error;
        break;
      case RealtimeSubscribeStatus.closed:
        state = RealtimeChannelState.closed;
        break;
      case RealtimeSubscribeStatus.timedOut:
        state = RealtimeChannelState.timedOut;
        break;
    }
    if (_noticeGate.registerStatus(state)) {
      _showRealtimeDownNotice();
    }
  }

  void _notifyRealtimeDown() {
    if (_noticeGate.registerStatus(RealtimeChannelState.error)) {
      _showRealtimeDownNotice();
    }
  }

  /// Aviso DISCRETO con diseño de tarjeta de que no hay sincronización en vivo.
  /// La pantalla sigue funcionando con el FutureBuilder/_reload.
  void _showRealtimeDownNotice() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        content: const Text(
          'Sin conexión en vivo ahora mismo; se actualizará al recargar.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _quickController.dispose();
    final channel = _channel;
    if (channel != null) {
      _client.removeChannel(channel);
      _channel = null;
    }
    super.dispose();
  }

  void _reload() {
    final future = _load();
    setState(() {
      _future = future;
    });
  }

  Future<_TasksData> _load() async {
    final user = _client.auth.currentUser;
    if (user == null) throw 'No autenticado';
    final profile = await _client
        .from('profiles')
        .select('home_id')
        .eq('id', user.id)
        .maybeSingle();
    final homeId = profile?['home_id'] as String?;

    // Preferencias del hogar para saber si el "Modo Puntos" está activado y
    // mostrar/ocultar el marcador y la gráfica de puntos. Mismo patrón
    // tolerante que HomeTab._loadPrefs.
    final prefsRow = await _client
        .from('profiles')
        .select('dashboard_prefs')
        .eq('id', user.id)
        .maybeSingle();
    final rawPrefs = prefsRow?['dashboard_prefs'];
    final prefs = rawPrefs is Map
        ? DashboardPrefs.fromJson(Map<String, dynamic>.from(rawPrefs))
        : DashboardPrefs.defaults();
    final pointsEnabled = prefs.isModuleEnabled(HomeModule.points);

    if (homeId == null) {
      return _TasksData(homeId: null, pointsEnabled: pointsEnabled);
    }

    // Miembros del hogar (id -> nombre)
    final profs = await _client
        .from('profiles')
        .select('id, full_name')
        .eq('home_id', homeId);
    final members = <String, String>{};
    for (final p in (profs as List)) {
      members[p['id']
          as String] = (p['full_name'] as String?)?.trim().isNotEmpty == true
          ? p['full_name'] as String
          : 'Miembro';
    }

    // Tareas
    final tasksRes = await _client
        .from('tasks')
        .select()
        .eq('home_id', homeId)
        .order('is_done')
        .order('created_at', ascending: false);
    final tasks = (tasksRes as List).map((m) => HomeTask.fromMap(m)).toList();

    // Puntos por usuario
    final pointsRes = await _client
        .from('task_points')
        .select('user_id, points')
        .eq('home_id', homeId);
    final scores = <String, int>{};
    for (final row in (pointsRes as List)) {
      final uid = row['user_id'] as String;
      scores[uid] = (scores[uid] ?? 0) + (row['points'] as int);
    }

    return _TasksData(
      homeId: homeId,
      members: members,
      tasks: tasks,
      listTasks: tasks,
      scores: scores,
      currentUserId: user.id,
      pointsEnabled: pointsEnabled,
    );
  }

  /// Completa una tarea preguntando primero QUIEN la hizo. Abre un selector de
  /// miembro (por defecto el usuario actual) y atribuye los puntos a ese
  /// miembro vía la RPC award_task_points, no forzosamente a quien pulsa.
  Future<void> _complete(HomeTask task, _TasksData data) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final doneBy = await _pickMember(
      members: data.members,
      currentUserId: data.currentUserId ?? user.id,
      title: '¿Quién hizo la tarea?',
    );
    if (doneBy == null) return; // Cancelado.

    try {
      HapticFeedback.lightImpact();
      await TaskScheduler(_client).completeAttributed(task, doneBy);
      // Hacer la compra: se tacha la lista y lo comprado va a la despensa.
      final bought = isShoppingTask(task.title)
          ? await ShoppingCheckout().markAllBoughtForCurrentUser()
          : 0;

      if (!mounted) return;
      final who = data.members[doneBy] ?? 'el hogar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bought > 0
                ? '+${task.points} puntos para $who. $bought productos a la '
                      'despensa'
                : '+${task.points} puntos para $who',
          ),
        ),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e)),
          backgroundColor: AppColors.expired,
        ),
      );
    }
  }

  /// Selector de miembro del hogar en un bottom sheet. Devuelve el id elegido
  /// o null si se cierra sin elegir. El miembro actual aparece el primero y
  /// marcado como "Tú" para que el caso normal sea un solo toque.
  Future<String?> _pickMember({
    required Map<String, String> members,
    required String currentUserId,
    required String title,
  }) {
    final ordered = members.entries.toList()
      ..sort((a, b) {
        if (a.key == currentUserId) return -1;
        if (b.key == currentUserId) return 1;
        return a.value.compareTo(b.value);
      });

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.md),
                for (final e in ordered)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.wood,
                      child: Icon(Icons.person, size: 20, color: AppColors.ink),
                    ),
                    title: Text(
                      e.key == currentUserId ? '${e.value} (tú)' : e.value,
                      style: AppTextStyles.bodyStrong,
                    ),
                    onTap: () => Navigator.of(sheetContext).pop(e.key),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Reinicia (borra) los puntos de un miembro del hogar tras confirmar. Se
  /// apoya en la politica task_points_delete (0044). Metodo con cuerpo de
  /// bloque y guardas mounted tras los awaits.
  Future<void> _resetPoints(_TasksData data, String userId) async {
    final name = data.members[userId] ?? 'este miembro';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reiniciar puntos'),
        content: Text(
          'Se pondrán a 0 los puntos de $name. Esto no se puede deshacer. '
          '¿Seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _client
          .from('task_points')
          .delete()
          .eq('home_id', data.homeId!)
          .eq('user_id', userId);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Puntos de $name reiniciados.')));
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e)),
          backgroundColor: AppColors.expired,
        ),
      );
    }
  }

  Future<bool> _confirmDelete(HomeTask task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar tarea?'),
        content: Text('Se borrará "${task.title}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return false;
    HapticFeedback.mediumImpact();
    await _delete(task);
    return true;
  }

  Future<void> _delete(HomeTask task) async {
    try {
      await _client.from('tasks').delete().eq('id', task.id);
      _reload();
    } catch (_) {}
  }

  Future<void> _openAdd(Map<String, String> members, [HomeTask? task]) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddTaskScreen(members: members, task: task),
      ),
    );
    if (added == true) _reload();
  }

  /// Alta rápida: tarea puntual para hoy, sin asignar y con puntos por defecto.
  Future<void> _quickAdd(_TasksData data) async {
    final title = _quickController.text.trim();
    final uid = _client.auth.currentUser?.id;
    if (title.isEmpty || uid == null || data.homeId == null) return;
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final task = HomeTask(
      id: '',
      homeId: data.homeId!,
      title: title,
      dueDate: DateTime(now.year, now.month, now.day),
    );
    try {
      await _client.from('tasks').insert(task.toInsertMap(createdBy: uid));
      _quickController.clear();
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e)),
          backgroundColor: AppColors.expired,
        ),
      );
    }
  }

  /// Aplaza una tarea [days] días desde hoy (due_date y next_due).
  Future<void> _postpone(HomeTask task, int days) async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final key = DateTime(
      now.year,
      now.month,
      now.day + days,
    ).toIso8601String().split('T').first;
    try {
      await _client
          .from('tasks')
          .update({'due_date': key, 'next_due': key})
          .eq('id', task.id);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e)),
          backgroundColor: AppColors.expired,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Tareas')),
      body: FutureBuilder<_TasksData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const ListSkeleton();
          }
          if (snapshot.hasError) {
            return Center(child: Text(friendlyError(snapshot.error)));
          }
          final data = snapshot.data!;
          if (data.homeId == null) {
            return const Center(child: Text('No perteneces a ningún hogar.'));
          }
          if (data.tasks.isEmpty) {
            return const EmptyState(
              title: 'No hay tareas todavía',
              message: 'Añade la primera y repartíos el hogar.',
              image: 'assets/images/vacio_tareas.png',
            );
          }

          final visible = data.listTasks
              .where((t) => taskMatchesFilter(t, _filterUser))
              .toList();
          final pending = visible.where((t) => !t.isDone).toList()
            ..sort(_byDue);
          final today = pending.where(_isDueTodayOrOverdue).toList();
          final upcoming = pending
              .where((t) => !_isDueTodayOrOverdue(t))
              .toList();
          final done = visible.where((t) => t.isDone).toList()
            ..sort(
              (a, b) =>
                  (b.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                      .compareTo(
                        a.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
                      ),
            );
          // Solo las últimas hechas, para que la lista no crezca sin fin.
          final recentDone = done.take(10).toList();
          final doneToday = done.where((t) => _isToday(t.completedAt)).length;

          Widget row(HomeTask t) => _TaskRow(
            key: ValueKey(t.id),
            task: t,
            memberName: t.assignedTo == null
                ? 'Cualquiera'
                : (data.members[t.assignedTo] ?? 'Miembro'),
            onComplete: () => _complete(t, data),
            confirmDelete: () => _confirmDelete(t),
            onEdit: () => _openAdd(data.members, t),
            onPostpone: (days) => _postpone(t, days),
          );

          // Todo el contenido va dentro de UN solo scroll.
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              112,
            ),
            children: [
              _TodayProgress(
                doneToday: doneToday,
                pendingToday: today.length,
                pendingTotal: pending.length,
              ),
              _FilterRow(
                members: data.members,
                currentUserId: data.currentUserId,
                selected: _filterUser,
                onSelected: (id) => setState(() => _filterUser = id),
              ),
              _QuickAdd(
                controller: _quickController,
                onSubmit: () => _quickAdd(data),
              ),
              if (pending.isEmpty)
                const _TareasCelebracion(visible: true)
              else ...[
                _SectionHeader('Hoy', count: today.length),
                if (today.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      'Nada para hoy.',
                      style: AppTextStyles.bodyMuted,
                    ),
                  ),
                for (final t in today) row(t),
                if (upcoming.isNotEmpty) ...[
                  _SectionHeader('Próximas', count: upcoming.length),
                  for (final g in groupUpcomingByDay(
                    upcoming,
                    DateTime.now(),
                  )) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.xs,
                        bottom: AppSpacing.xs,
                      ),
                      child: Text(g.key, style: AppTextStyles.bodyMuted),
                    ),
                    for (final t in g.value) row(t),
                  ],
                ],
              ],
              if (recentDone.isNotEmpty) ...[
                _SectionHeader('Hechas', count: done.length),
                for (final t in recentDone) row(t),
              ],
              // Marcador y gráfica de puntos solo con el "Modo Puntos".
              if (data.pointsEnabled) ...[
                const SizedBox(height: AppSpacing.lg),
                _Scoreboard(
                  members: data.members,
                  scores: data.scores,
                  onResetPoints: (userId) => _resetPoints(data, userId),
                ),
                _PointsChart(members: data.members, scores: data.scores),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FutureBuilder<_TasksData>(
        future: _future,
        builder: (context, snap) {
          final members = snap.data?.members ?? {};
          return FloatingActionButton.extended(
            heroTag: 'fab-tasks',
            onPressed: () => _openAdd(members),
            backgroundColor: AppColors.wood,
            foregroundColor: AppColors.ink,
            icon: const Icon(Icons.add),
            label: const Text(
              'Nueva tarea',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  int _byDue(HomeTask a, HomeTask b) {
    final da = a.nextDue ?? a.dueDate;
    final db = b.nextDue ?? b.dueDate;
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return da.compareTo(db);
  }

  bool _isToday(DateTime? d) {
    if (d == null) return false;
    final l = d.toLocal();
    final n = DateTime.now();
    return l.year == n.year && l.month == n.month && l.day == n.day;
  }

  bool _isDueTodayOrOverdue(HomeTask task) {
    final due = task.nextDue ?? task.dueDate;
    if (due == null) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !DateTime(due.year, due.month, due.day).isAfter(today);
  }
}

/// Cabecera con el progreso de hoy: "3 de 5 hechas" y una barra.
class _TodayProgress extends StatelessWidget {
  final int doneToday;
  final int pendingToday;
  final int pendingTotal;
  const _TodayProgress({
    required this.doneToday,
    required this.pendingToday,
    required this.pendingTotal,
  });

  @override
  Widget build(BuildContext context) {
    final total = doneToday + pendingToday;
    final value = total == 0 ? 1.0 : doneToday / total;
    final mood = pendingTotal == 0
        ? MiauMood.celebrating
        : pendingToday > 0
        ? MiauMood.curious
        : MiauMood.neutral;
    final reduce = AppMotion.reduceMotionOf(context);
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: AppTheme.surfaceDecoration(
        radius: AppRadius.lg,
        elevation: 1,
        color: AppColors.sageBg,
      ),
      child: Row(
        children: [
          MiauCharacter(mood: mood, size: 56),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total == 0 ? 'Hoy, sin pendientes' : 'Hoy',
                  style: AppTextStyles.label.copyWith(color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  total == 0
                      ? 'Todo al día'
                      : '$doneToday de $total ${total == 1 ? 'hecha' : 'hechas'}',
                  style: AppTextStyles.headline,
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: AppRadius.pillRadius,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: value),
                    duration: reduce ? Duration.zero : AppMotion.slow,
                    curve: AppMotion.easeOut,
                    builder: (_, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 8,
                      backgroundColor: AppColors.card,
                      color: AppColors.sage,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chips de filtro por persona bajo la cabecera de progreso.
class _FilterRow extends StatelessWidget {
  final Map<String, String> members;
  final String? currentUserId;
  final String? selected;
  final ValueChanged<String?> onSelected;
  const _FilterRow({
    required this.members,
    required this.currentUserId,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final others = members.entries.where((e) => e.key != currentUserId);
    Widget chip(String label, String? id) => ChoiceChip(
      label: Text(label),
      selected: selected == id,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        onSelected(id);
      },
    );
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          chip('Todas', null),
          if (currentUserId != null) chip('Mías', currentUserId),
          for (final e in others) chip(e.value, e.key),
        ],
      ),
    );
  }
}

/// Campo compacto para crear una tarea puntual de hoy con Enter.
class _QuickAdd extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  const _QuickAdd({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => onSubmit(),
        decoration: InputDecoration(
          hintText: 'Añadir tarea…',
          isDense: true,
          suffixIcon: IconButton(
            tooltip: 'Añadir',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: onSubmit,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader(this.title, {required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xl,
        bottom: AppSpacing.sm,
        left: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Text(title, style: AppTextStyles.title),
          const SizedBox(width: AppSpacing.sm),
          Text('$count', style: AppTextStyles.bodyMuted),
        ],
      ),
    );
  }
}

/// Banner de celebración cuando todas las tareas están completadas. Aparece
/// con una animación sutil (tamaño + opacidad) y muestra a Miau celebrando.
class _TareasCelebracion extends StatelessWidget {
  final bool visible;
  const _TareasCelebracion({required this.visible});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: visible ? 1 : 0,
        child: visible
            ? Container(
                margin: const EdgeInsets.only(top: AppSpacing.xl),
                padding: AppSpacing.cardPadding,
                decoration: AppTheme.surfaceDecoration(
                  radius: AppRadius.lg,
                  elevation: 1,
                  color: AppColors.sageBg,
                ),
                child: Row(
                  children: [
                    const MiauCharacter(mood: MiauMood.celebrating, size: 72),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Todo hecho', style: AppTextStyles.title),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'No queda nada pendiente.',
                            style: AppTextStyles.bodyMuted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox(width: double.infinity),
      ),
    );
  }
}

class _TasksData {
  final String? homeId;
  final Map<String, String> members;
  final List<HomeTask> tasks;
  // Tareas de la lista principal (todas las del hogar; el filtro de la vista
  // decide cuales se muestran).
  final List<HomeTask> listTasks;
  final Map<String, int> scores;
  final String? currentUserId;

  /// "Modo Puntos" activado: controla si se muestran el marcador y la gráfica.
  final bool pointsEnabled;
  _TasksData({
    required this.homeId,
    this.members = const {},
    this.tasks = const [],
    this.listTasks = const [],
    this.scores = const {},
    this.currentUserId,
    this.pointsEnabled = true,
  });
}

class _Scoreboard extends StatelessWidget {
  final Map<String, String> members;
  final Map<String, int> scores;

  /// Reinicia los puntos del miembro indicado (tras confirmar en el padre).
  final void Function(String userId) onResetPoints;
  const _Scoreboard({
    required this.members,
    required this.scores,
    required this.onResetPoints,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    final entries = members.entries.toList()
      ..sort((a, b) => (scores[b.key] ?? 0).compareTo(scores[a.key] ?? 0));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MARCADOR',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 12),
          ...entries.map((e) {
            final pts = scores[e.key] ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.wood,
                    child: Icon(Icons.person, size: 18, color: AppColors.ink),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      e.value,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '$pts pts',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.woodDark,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.restart_alt,
                      size: 20,
                      color: AppColors.inkMuted,
                    ),
                    tooltip: 'Reiniciar puntos',
                    onPressed: () => onResetPoints(e.key),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Gráfica de barras de puntos por persona del hogar, estilo marcador visual.
/// Reutiliza los mismos datos que [_Scoreboard]: [members] (id -> nombre) y
/// [scores] (user_id -> suma de puntos). Los miembros sin puntos aparecen a 0 y
/// las barras se ordenan de mayor a menor. Cuando nadie tiene puntos todavía,
/// muestra un estado vacío amable con Miau en lugar de barras planas.
class _PointsChart extends StatelessWidget {
  final Map<String, String> members;
  final Map<String, int> scores;
  const _PointsChart({required this.members, required this.scores});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();

    // Pares (nombre, puntos) para TODOS los miembros, 0 si no tienen puntos,
    // ordenados de mayor a menor como el marcador textual.
    final entries = members.entries.toList()
      ..sort((a, b) => (scores[b.key] ?? 0).compareTo(scores[a.key] ?? 0));
    final data = [
      for (final e in entries)
        _PersonPoints(name: e.value, points: scores[e.key] ?? 0),
    ];

    final totalPoints = data.fold<int>(0, (a, p) => a + p.points);
    if (totalPoints == 0) return _empty();

    final maxPoints = data.fold<int>(0, (a, p) => p.points > a ? p.points : a);
    // Un poco de aire por encima para que la barra no toque el borde superior.
    final maxY = maxPoints <= 0 ? 10.0 : maxPoints * 1.2;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PUNTOS POR PERSONA',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: AppColors.inkMuted,
            ),
          ),
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
                        '${rod.toY.toInt()} pts',
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
                        if (i < 0 || i >= data.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _shortName(data[i].name),
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
                barGroups: [
                  for (int i = 0; i < data.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: data[i].points.toDouble(),
                          color: AppColors.wood,
                          width: 22,
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

  /// Acorta nombres largos para que no se solapen bajo las barras.
  String _shortName(String name) {
    final trimmed = name.trim();
    if (trimmed.length <= 8) return trimmed;
    final first = trimmed.split(' ').first;
    if (first.length <= 10) return first;
    return '${first.substring(0, 9)}…';
  }

  /// Estado vacío amable cuando nadie ha sumado puntos todavía, para no mostrar
  /// una gráfica plana de barras a cero.
  Widget _empty() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PUNTOS POR PERSONA',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const MiauCharacter(mood: MiauMood.curious, size: 72),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aún no hay puntos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Completa tareas para ir sumando.',
                      style: TextStyle(color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Par nombre + puntos usado por [_PointsChart].
class _PersonPoints {
  final String name;
  final int points;
  const _PersonPoints({required this.name, required this.points});
}

class _TaskRow extends StatelessWidget {
  final HomeTask task;
  final String memberName;
  final VoidCallback onComplete;
  final Future<bool> Function() confirmDelete;
  final VoidCallback onEdit;
  final void Function(int days) onPostpone;

  const _TaskRow({
    super.key,
    required this.task,
    required this.memberName,
    required this.onComplete,
    required this.confirmDelete,
    required this.onEdit,
    required this.onPostpone,
  });

  @override
  Widget build(BuildContext context) {
    final done = task.isDone;
    final due = _due(task);
    return Dismissible(
      key: ValueKey('dismiss-${task.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => confirmDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.expiredBg,
          borderRadius: AppRadius.mdRadius,
        ),
        child: Icon(Icons.delete_outline, color: AppColors.expired),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: done ? null : onEdit,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: AppTheme.surfaceDecoration(
            radius: AppRadius.md,
            elevation: done ? 0 : 1,
            color: done
                ? AppColors.card.withValues(alpha: 0.72)
                : AppColors.card,
          ),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: done ? 'Hecha' : 'Marcar como hecha',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: done ? null : onComplete,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: AnimatedContainer(
                      duration: AppMotion.effectiveDuration(
                        AppMotion.fast,
                        reduceMotion: AppMotion.reduceMotionOf(context),
                      ),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? AppColors.sage : Colors.transparent,
                        border: Border.all(
                          color: done ? AppColors.sage : AppColors.inkMuted,
                          width: 2,
                        ),
                      ),
                      child: done
                          ? Icon(Icons.check, size: 20, color: AppColors.ink)
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: AppTextStyles.bodyStrong.copyWith(
                        decoration: done ? TextDecoration.lineThrough : null,
                        color: done ? AppColors.inkMuted : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (!done && due != null) due,
                        _pill(memberName, icon: Icons.person_outline),
                        if (task.recurrence != 'once')
                          _pill(task.recurrenceLabel, icon: Icons.repeat),
                        if (task.dueTime != null)
                          _pill(task.dueTime!, icon: Icons.schedule),
                        _pill('${task.points} pts'),
                      ],
                    ),
                  ],
                ),
              ),
              if (!done)
                PopupMenuButton<String>(
                  tooltip: 'Más opciones',
                  icon: Icon(Icons.more_horiz, color: AppColors.inkMuted),
                  color: AppColors.card,
                  onSelected: (v) async {
                    switch (v) {
                      case 'tomorrow':
                        onPostpone(1);
                      case 'week':
                        onPostpone(7);
                      case 'edit':
                        onEdit();
                      case 'delete':
                        await confirmDelete();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'tomorrow', child: Text('Mañana')),
                    PopupMenuItem(value: 'week', child: Text('Próxima semana')),
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _pill(String text, {IconData? icon, Color? bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg ?? AppColors.cream,
        borderRadius: AppRadius.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: AppColors.inkMuted),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: AppTextStyles.label.copyWith(
              color: bg == null ? AppColors.inkMuted : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  /// Pastilla de fecha: tinte rojo si está atrasada, ámbar si es hoy.
  static Widget? _due(HomeTask task) {
    final due = task.nextDue ?? task.dueDate;
    if (due == null) return _pill('Sin fecha', icon: Icons.event_outlined);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = DateTime(
      due.year,
      due.month,
      due.day,
    ).difference(today).inDays;
    if (diff < 0) {
      return _pill('Atrasada', icon: Icons.event_busy, bg: AppColors.expiredBg);
    }
    if (diff == 0) {
      return _pill('Hoy', icon: Icons.today, bg: AppColors.soonBg);
    }
    final label = diff == 1
        ? 'Mañana'
        : '${due.day.toString().padLeft(2, '0')}/'
              '${due.month.toString().padLeft(2, '0')}';
    return _pill(label, icon: Icons.event_outlined);
  }
}
