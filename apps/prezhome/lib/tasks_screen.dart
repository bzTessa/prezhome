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
import 'utils/task_kinds.dart';

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

    // Solo se pregunta quién la hizo si en casa sois más de uno.
    final doneBy = data.members.length <= 1
        ? (data.currentUserId ?? user.id)
        : await _pickMember(
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

  Future<void> _openNew(_TasksData data) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _NewTaskSheet(
        homeId: data.homeId!,
        members: data.members,
        currentUserId: data.currentUserId,
        onMoreOptions: () => _openAdd(data.members),
      ),
    );
    if (created == true) _reload();
  }

  /// Acciones de una tarea: hecha, aplazar, editar o eliminar.
  Future<void> _showActions(HomeTask t, _TasksData data) async {
    final kind = taskKindFor(t.title);
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        Widget item(String id, IconData icon, String label, {Color? color}) =>
            ListTile(
              leading: Icon(icon, color: color ?? AppColors.ink),
              title: Text(
                label,
                style: AppTextStyles.bodyStrong.copyWith(color: color),
              ),
              onTap: () => Navigator.of(ctx).pop(id),
            );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: _KindBadge(kind: kind, size: 44),
                  title: Text(t.title, style: AppTextStyles.title),
                ),
                const Divider(),
                if (!t.isDone)
                  item(
                    'done',
                    Icons.check_circle_rounded,
                    'Hecha',
                    color: AppColors.sage,
                  ),
                if (!t.isDone) ...[
                  item('tomorrow', Icons.wb_twilight_rounded, 'Pasar a mañana'),
                  item(
                    'week',
                    Icons.next_week_rounded,
                    'Pasar a la próxima semana',
                  ),
                ],
                item('edit', Icons.edit_rounded, 'Editar'),
                item(
                  'delete',
                  Icons.delete_outline_rounded,
                  'Eliminar',
                  color: AppColors.expired,
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted) return;
    switch (action) {
      case 'done':
        await _complete(t, data);
      case 'tomorrow':
        await _postpone(t, 1);
      case 'week':
        await _postpone(t, 7);
      case 'edit':
        await _openAdd(data.members, t);
      case 'delete':
        await _confirmDelete(t);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      // El teclado lo gestiona la hoja de nueva tarea; así el botón no sube.
      resizeToAvoidBottomInset: false,
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
              message: 'Añade la primera con el botón de abajo.',
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
          // Hechas hoy: las puntuales marcadas y las recurrentes completadas.
          final doneToday = visible
              .where((t) => _isToday(t.completedAt ?? t.lastCompletedAt))
              .toList();
          final overdue = today.where(_isOverdue).length;
          final showWho = data.members.length > 1;
          String? who(HomeTask t) => !showWho
              ? null
              : t.assignedTo == null
              ? 'Cualquiera'
              : (data.members[t.assignedTo] ?? 'Miembro');

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              120,
            ),
            children: [
              _TodayHero(
                done: doneToday.length,
                left: today.length,
                overdue: overdue,
              ),
              if (showWho)
                _FilterRow(
                  members: data.members,
                  currentUserId: data.currentUserId,
                  selected: _filterUser,
                  onSelected: (id) => setState(() => _filterUser = id),
                ),
              const SizedBox(height: AppSpacing.lg),
              if (today.isEmpty)
                _TareasCelebracion(
                  visible: true,
                  nothingToday: upcoming.isNotEmpty,
                )
              else ...[
                const _SectionTitle('Para hoy'),
                LayoutBuilder(
                  builder: (context, c) {
                    final w = (c.maxWidth - AppSpacing.md) / 2;
                    return Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        for (final t in today)
                          SizedBox(
                            width: w,
                            child: _TaskTile(
                              key: ValueKey(t.id),
                              task: t,
                              who: who(t),
                              overdue: _isOverdue(t),
                              onDone: () => _complete(t, data),
                              onMore: () => _showActions(t, data),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
              if (upcoming.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                const _SectionTitle('Próximos días'),
                Container(
                  decoration: AppTheme.surfaceDecoration(
                    radius: AppRadius.lg,
                    elevation: 1,
                  ),
                  child: Column(
                    children: [
                      for (final g in groupUpcomingByDay(
                        upcoming,
                        DateTime.now(),
                      ))
                        for (final t in g.value)
                          _UpcomingRow(
                            task: t,
                            day: g.key,
                            who: who(t),
                            onTap: () => _showActions(t, data),
                          ),
                    ],
                  ),
                ),
              ],
              if (doneToday.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                const _SectionTitle('Hechas hoy'),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [for (final t in doneToday) _DoneChip(task: t)],
                ),
              ],
              // Marcador y gráfica de puntos solo con el "Modo Puntos".
              if (data.pointsEnabled) ...[
                const SizedBox(height: AppSpacing.xl),
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
          final data = snap.data;
          if (data?.homeId == null) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            heroTag: 'fab-tasks',
            onPressed: () => _openNew(data!),
            backgroundColor: AppColors.ink,
            foregroundColor: AppColors.cream,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Nueva tarea',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  bool _isOverdue(HomeTask task) {
    final due = task.nextDue ?? task.dueDate;
    if (due == null) return false;
    final now = DateTime.now();
    return DateTime(
      due.year,
      due.month,
      due.day,
    ).isBefore(DateTime(now.year, now.month, now.day));
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

class _TareasCelebracion extends StatelessWidget {
  final bool visible;

  /// Hoy no queda nada pero hay tareas otros días.
  final bool nothingToday;
  const _TareasCelebracion({required this.visible, this.nothingToday = false});

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
                          Text(
                            'Hoy está todo hecho',
                            style: AppTextStyles.title,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            nothingToday
                                ? 'Lo siguiente, abajo.'
                                : 'No queda nada pendiente.',
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

String _repeatLabel(HomeTask t) => switch (t.recurrence) {
  'daily' => 'Cada día',
  'weekly' => 'Cada semana',
  'custom_interval' =>
    'Cada ${t.intervalCount ?? 1} ${t.intervalUnit == 'week' ? 'semanas' : 'días'}',
  'custom_weekdays' => 'Algunos días',
  _ => 'Una vez',
};

/// Icono de la tarea en su color: así se reconoce sin leer.
class _KindBadge extends StatelessWidget {
  const _KindBadge({
    required this.kind,
    this.size = 48,
    this.faded = false,
    this.onCard = false,
  });
  final TaskKind kind;
  final double size;
  final bool faded;

  /// Sobre una tarjeta ya teñida: fondo de tarjeta en vez del color suave.
  final bool onCard;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = kind.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: faded
            ? AppColors.line
            : onCard
            ? AppColors.card
            : bg,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        kind.icon,
        size: size * 0.55,
        color: faded ? AppColors.inkMuted : fg,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 18,
        letterSpacing: -0.3,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
    ),
  );
}

/// Resumen de hoy: anillo de progreso y lo que queda.
class _TodayHero extends StatelessWidget {
  const _TodayHero({
    required this.done,
    required this.left,
    required this.overdue,
  });
  final int done;
  final int left;
  final int overdue;

  @override
  Widget build(BuildContext context) {
    final total = done + left;
    final progress = total == 0 ? 1.0 : done / total;
    final reduce = AppMotion.reduceMotionOf(context);
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: AppTheme.surfaceDecoration(
        radius: AppRadius.lg,
        elevation: 1,
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 72,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: progress),
              duration: AppMotion.effectiveDuration(
                const Duration(milliseconds: 500),
                reduceMotion: reduce,
              ),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: v,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    backgroundColor: AppColors.line,
                    color: AppColors.sage,
                  ),
                  Center(
                    child: Text(
                      '$done/$total',
                      style: AppTextStyles.numeric(
                        AppTextStyles.bodyStrong,
                      ).copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoy',
                  style: TextStyle(
                    fontSize: 22,
                    letterSpacing: -0.4,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  left == 0
                      ? (total == 0 ? 'Nada para hoy' : 'Todo hecho')
                      : 'Queda${left == 1 ? '' : 'n'} $left',
                  style: AppTextStyles.bodyMuted,
                ),
                if (overdue > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _Pill(
                    text: '$overdue atrasada${overdue == 1 ? '' : 's'}',
                    bg: AppColors.expiredBg,
                    fg: AppColors.expired,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.bg, required this.fg});
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
    ),
  );
}

/// Tarjeta de una tarea de hoy: icono grande, nombre y botón de hecha.
class _TaskTile extends StatelessWidget {
  const _TaskTile({
    super.key,
    required this.task,
    required this.who,
    required this.overdue,
    required this.onDone,
    required this.onMore,
  });
  final HomeTask task;
  final String? who;
  final bool overdue;
  final VoidCallback onDone;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final kind = taskKindFor(task.title);
    final (bg, fg) = kind.colors;
    final meta = [
      if (task.recurrence != 'once') _repeatLabel(task),
      ?who,
    ].join(' · ');
    // La tarjeta lleva el color de su tipo; el icono va sobre blanco.
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onMore,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _KindBadge(kind: kind, onCard: true),
                  const Spacer(),
                  Semantics(
                    button: true,
                    label: 'Marcar ${task.title} como hecha',
                    child: InkResponse(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onDone();
                      },
                      radius: 26,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.card,
                          border: Border.all(color: fg, width: 2.5),
                        ),
                        child: Icon(Icons.check_rounded, color: fg, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (overdue)
                _Pill(
                  text: 'Atrasada',
                  bg: AppColors.expiredBg,
                  fg: AppColors.expired,
                )
              else
                Text(
                  meta.isEmpty ? kind.label : meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila de una tarea de otro día.
class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({
    required this.task,
    required this.day,
    required this.who,
    required this.onTap,
  });
  final HomeTask task;
  final String day;
  final String? who;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kind = taskKindFor(task.title);
    final meta = [
      if (task.recurrence != 'once') _repeatLabel(task),
      ?who,
    ].join(' · ');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        child: Row(
          children: [
            _KindBadge(kind: kind, size: 40),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyStrong,
                  ),
                  if (meta.isNotEmpty)
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _Pill(text: day, bg: AppColors.cream, fg: AppColors.ink),
          ],
        ),
      ),
    );
  }
}

/// Tarea hecha hoy, en pequeño y apagada.
class _DoneChip extends StatelessWidget {
  const _DoneChip({required this.task});
  final HomeTask task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _KindBadge(kind: taskKindFor(task.title), size: 28, faded: true),
          const SizedBox(width: AppSpacing.sm),
          Text(
            task.title,
            style: AppTextStyles.bodyMuted.copyWith(
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(Icons.check_rounded, size: 16, color: AppColors.sage),
        ],
      ),
    );
  }
}

/// Hoja para crear una tarea: tareas típicas con un toque, cuándo, cada
/// cuánto y quién. Lo demás (puntos, días concretos) en "Más opciones".
class _NewTaskSheet extends StatefulWidget {
  const _NewTaskSheet({
    required this.homeId,
    required this.members,
    required this.currentUserId,
    required this.onMoreOptions,
  });
  final String homeId;
  final Map<String, String> members;
  final String? currentUserId;
  final VoidCallback onMoreOptions;

  @override
  State<_NewTaskSheet> createState() => _NewTaskSheetState();
}

class _NewTaskSheetState extends State<_NewTaskSheet> {
  final _title = TextEditingController();
  int _when = 0; // 0 hoy, 1 mañana, 2 fecha elegida
  DateTime? _date;
  String _repeat = 'once';
  String? _assigned;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  DateTime get _due {
    final n = DateTime.now();
    return switch (_when) {
      1 => DateTime(n.year, n.month, n.day + 1),
      2 => _date ?? DateTime(n.year, n.month, n.day),
      _ => DateTime(n.year, n.month, n.day),
    };
  }

  Future<void> _pickDate() async {
    final n = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? n,
      firstDate: DateTime(n.year, n.month, n.day),
      lastDate: DateTime(n.year + 2),
    );
    if (d == null) return;
    setState(() {
      _date = d;
      _when = 2;
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (title.isEmpty || uid == null || _saving) return;
    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    try {
      final task = HomeTask(
        id: '',
        homeId: widget.homeId,
        title: title[0].toUpperCase() + title.substring(1),
        recurrence: _repeat,
        assignedTo: _assigned,
        dueDate: _due,
      );
      await Supabase.instance.client
          .from('tasks')
          .insert(task.toInsertMap(createdBy: uid));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e)),
          backgroundColor: AppColors.expired,
        ),
      );
    }
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
    child: Text(text, style: AppTextStyles.label),
  );

  @override
  Widget build(BuildContext context) {
    final dateLabel = _when == 2 && _date != null
        ? '${_date!.day}/${_date!.month}'
        : 'Otro día';
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nueva tarea', style: AppTextStyles.headline),
            const SizedBox(height: AppSpacing.md),
            // Tareas típicas: icono y nombre, un toque y listo.
            LayoutBuilder(
              builder: (context, c) {
                final w = (c.maxWidth - AppSpacing.sm * 3) / 4;
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final p in taskPresets)
                      SizedBox(
                        width: w,
                        child: _PresetTile(
                          title: p.title,
                          selected: _title.text == p.title,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _title.text = p.title;
                              _repeat = p.recurrence;
                            });
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                hintText: 'O escribe otra',
                prefixIcon: Icon(taskKindFor(_title.text).icon),
              ),
            ),
            _label('Cuándo'),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  label: const Text('Hoy'),
                  selected: _when == 0,
                  onSelected: (_) => setState(() => _when = 0),
                ),
                ChoiceChip(
                  label: const Text('Mañana'),
                  selected: _when == 1,
                  onSelected: (_) => setState(() => _when = 1),
                ),
                ChoiceChip(
                  avatar: const Icon(Icons.event_rounded, size: 18),
                  label: Text(dateLabel),
                  selected: _when == 2,
                  onSelected: (_) => _pickDate(),
                ),
              ],
            ),
            _label('Se repite'),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final r in const [
                  ('once', 'No'),
                  ('daily', 'Cada día'),
                  ('weekly', 'Cada semana'),
                ])
                  ChoiceChip(
                    label: Text(r.$2),
                    selected: _repeat == r.$1,
                    onSelected: (_) => setState(() => _repeat = r.$1),
                  ),
              ],
            ),
            if (widget.members.length > 1) ...[
              _label('Quién'),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  ChoiceChip(
                    label: const Text('Cualquiera'),
                    selected: _assigned == null,
                    onSelected: (_) => setState(() => _assigned = null),
                  ),
                  for (final e in widget.members.entries)
                    ChoiceChip(
                      label: Text(
                        e.key == widget.currentUserId ? 'Yo' : e.value,
                      ),
                      selected: _assigned == e.key,
                      onSelected: (_) => setState(() => _assigned = e.key),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _title.text.trim().isEmpty || _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.cream,
              ),
              child: const Text(
                'Añadir tarea',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                widget.onMoreOptions();
              },
              child: const Text('Más opciones'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kind = taskKindFor(title);
    final (bg, fg) = kind.colors;
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? fg : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(kind.icon, color: fg, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
