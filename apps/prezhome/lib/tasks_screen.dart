import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/dashboard_prefs.dart';
import 'models/task.dart';
import 'services/calendar_sync.dart';
import 'services/plan_prefs.dart';
import 'services/shopping_checkout.dart';
import 'services/task_scheduler.dart';
import 'services/home_people.dart';
import 'theme/app_motion.dart';
import 'theme/app_theme.dart';
import 'widgets/animations/animated_counter.dart';
import 'widgets/animations/celebrate.dart';
import 'widgets/animations/press_scale.dart';
import 'widgets/animations/staggered_entrance.dart';
import 'widgets/animations/swipe_action.dart';
import 'widgets/empty_state.dart';
import 'widgets/segmented_pill.dart';
import 'widgets/skeleton.dart';
import 'utils/realtime_sync.dart';
import 'widgets/miau_character.dart';
import 'utils/friendly_error.dart';
import 'utils/task_kinds.dart';
import 'l10n/l10n.dart';

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

  // Vista elegida en la píldora de arriba.
  _TaskView _view = _TaskView.pending;

  // Tareas que se están marcando como hechas: su tarjeta se ve hecha al
  // instante, sin esperar a la base de datos.
  final Set<String> _completing = {};

  // Canal Realtime de las tareas del hogar. Se abre UNA sola vez en initState
  // (filtrado por home_id) y se cierra en dispose. Si el otro miembro del hogar
  // completa o cambia una tarea, recargamos al instante.
  // TasksScreen es hijo directo del IndexedStack siempre vivo: abrir una vez,
  // cerrar en dispose, nunca dejar canales colgando.
  RealtimeChannel? _channel;
  Timer? _realtimeDebounce;

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
              // Un cambio de varias tareas llega como varios avisos seguidos:
              // una sola recarga para todos (como la lista de la compra).
              _realtimeDebounce?.cancel();
              _realtimeDebounce = Timer(const Duration(milliseconds: 600), () {
                if (mounted) _reload();
              });
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
        content: Text(context.l.shopLiveOffline),
      ),
    );
  }

  @override
  void dispose() {
    _realtimeDebounce?.cancel();
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
    unawaited(CalendarSync.sync(_client));
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
    members.addAll(await HomePeople(_client).load(homeId));

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
            title: context.l.tskWhoDid,
          );
    if (doneBy == null) return; // Cancelado.

    HapticFeedback.mediumImpact();
    setState(() => _completing.add(task.id));
    try {
      await TaskScheduler(_client).completeAttributed(task, doneBy);
      if (mounted) {
        Celebrate.check(
          context,
          points: data.pointsEnabled ? task.points : null,
        );
      }
      // Hacer la compra: se tacha la lista y lo comprado va a la despensa.
      final bought = isShoppingTask(task.title)
          ? await ShoppingCheckout().markAllBoughtForCurrentUser()
          : 0;

      if (!mounted) return;
      final who = data.members[doneBy] ?? context.l.tskTheHome;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bought > 0
                ? context.l.tskPointsForPantry(task.points, who, bought)
                : context.l.tskPointsFor(task.points, who),
          ),
        ),
      );
      _reload();
      // Se quita la marca cuando llega la lista nueva, para que no parpadee.
      _future.whenComplete(() {
        if (mounted) setState(() => _completing.remove(task.id));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _completing.remove(task.id));
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
                    leading: _Avatar(name: e.value, size: 36),
                    title: Text(
                      e.key == currentUserId
                          ? context.l.tskYou(e.value)
                          : e.value,
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
    final name = data.members[userId] ?? context.l.tskThisMember;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l.tskResetPoints),
        content: Text(context.l.tskResetAsk(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l.tskReset),
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
      ).showSnackBar(SnackBar(content: Text(context.l.tskResetDone(name))));
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
        title: Text(context.l.tskDeleteTitle),
        content: Text(context.l.tskDeleteAsk(task.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l.delete),
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, context.l.couldNotUpdate)),
          backgroundColor: AppColors.expired,
        ),
      );
    }
  }

  /// "Me la pido": una tarea de la bolsa del hogar pasa a ser tuya.
  Future<void> _claim(HomeTask task, _TasksData data) async {
    final uid = data.currentUserId;
    if (uid == null) return;
    try {
      await _client
          .from('tasks')
          .update({'assigned_to': uid})
          .eq('id', task.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l.tskClaimed(task.title))));
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

  /// Crear o editar ([task]) en la misma hoja.
  Future<void> _openNew(_TasksData data, [HomeTask? task]) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _TaskSheet(
        homeId: data.homeId!,
        members: data.members,
        currentUserId: data.currentUserId,
        pointsEnabled: data.pointsEnabled,
        task: task,
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
                    context.l.tskDone,
                    color: AppColors.sage,
                  ),
                if (!t.isDone) ...[
                  item(
                    'tomorrow',
                    Icons.wb_twilight_rounded,
                    context.l.tskToTomorrow,
                  ),
                  item(
                    'week',
                    Icons.next_week_rounded,
                    context.l.tskToNextWeek,
                  ),
                ],
                item('edit', Icons.edit_rounded, context.l.edit),
                item(
                  'delete',
                  Icons.delete_outline_rounded,
                  context.l.delete,
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
        await _openNew(data, t);
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
      appBar: AppBar(title: Text(context.l.tskTitle)),
      body: FutureBuilder<_TasksData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const TasksSkeleton();
          }
          if (snapshot.hasError) {
            return Center(child: Text(friendlyError(snapshot.error)));
          }
          final data = snapshot.data!;
          if (data.homeId == null) {
            return Center(child: Text(context.l.planNoHome));
          }
          if (data.tasks.isEmpty) {
            return EmptyState(
              title: context.l.tskEmptyTitle,
              message: context.l.tskEmptyHint,
              image: 'assets/images/vacio_tareas.png',
              actionLabel: context.l.tskNew,
              onAction: () => _openNew(data),
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
              ? context.l.tskAnyone
              : (data.members[t.assignedTo] ?? context.l.rdMember);

          final pool = pending.where((t) => t.isInPool).toList();
          final views = [
            _TaskView.pending,
            if (showWho) _TaskView.pool,
            _TaskView.done,
          ];
          final view = views.contains(_view) ? _view : _TaskView.pending;

          Widget tile(HomeTask t) => _TaskTile(
            key: ValueKey(t.id),
            task: t,
            who: who(t),
            overdue: _isOverdue(t),
            completing: _completing.contains(t.id),
            points: data.pointsEnabled ? t.points : null,
            onDone: () => _complete(t, data),
            onMore: () => _showActions(t, data),
            onClaim: showWho && t.isInPool && data.currentUserId != null
                ? () => _claim(t, data)
                : null,
          );

          Widget grid(List<HomeTask> tasks) => LayoutBuilder(
            builder: (context, c) {
              final w = (c.maxWidth - AppSpacing.md) / 2;
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (final (i, t) in tasks.indexed)
                    SizedBox(
                      key: ValueKey(t.id),
                      width: w,
                      child: StaggeredEntrance(index: i, child: tile(t)),
                    ),
                ],
              );
            },
          );

          final List<Widget> section = switch (view) {
            _TaskView.pending => [
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
                _SectionTitle(context.l.tskForToday, count: today.length),
                grid(today),
              ],
              if (upcoming.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                _SectionTitle(context.l.tskUpcoming, count: upcoming.length),
                Container(
                  decoration: AppTheme.tactileDecoration(radius: AppRadius.lg),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (gi, g) in groupUpcomingByDay(
                        upcoming,
                      ).indexed) ...[
                        if (gi > 0) Divider(height: 1, color: AppColors.line),
                        _DayHeader(g.key),
                        for (final t in g.value)
                          _UpcomingRow(
                            task: t,
                            who: who(t),
                            onTap: () => _showActions(t, data),
                          ),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                    ],
                  ),
                ),
              ],
            ],
            _TaskView.pool => [
              const SizedBox(height: AppSpacing.lg),
              if (pool.isEmpty)
                _ViewEmpty(context.l.tskPoolEmpty)
              else ...[
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.xs,
                    bottom: AppSpacing.md,
                  ),
                  child: Text(
                    context.l.tskSwipeToClaim,
                    style: AppTextStyles.bodyMuted,
                  ),
                ),
                grid(pool),
              ],
            ],
            _TaskView.done => [
              const SizedBox(height: AppSpacing.lg),
              if (doneToday.isEmpty)
                _ViewEmpty(context.l.tskNothingDone)
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final (i, t) in doneToday.indexed)
                      StaggeredEntrance(
                        index: i,
                        child: _DoneChip(task: t),
                      ),
                  ],
                ),
            ],
          };

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
              const SizedBox(height: AppSpacing.lg),
              SegmentedPill(
                labels: [for (final v in views) context.l.tskView(v.name)],
                selected: views.indexOf(view),
                onChanged: (i) => setState(() => _view = views[i]),
              ),
              // Al cambiar de vista, la nueva entra con un fundido y un leve
              // deslizamiento en lugar de aparecer de golpe.
              AnimatedSwitcher(
                duration: AppMotion.effectiveDuration(
                  AppMotion.base,
                  reduceMotion: AppMotion.reduceMotionOf(context),
                ),
                switchInCurve: AppMotion.easeOut,
                switchOutCurve: AppMotion.easeOut,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, ?current],
                ),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.02),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: Column(
                  key: ValueKey(view),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: section,
                ),
              ),
              // Marcador de puntos solo con el "Modo Puntos".
              if (data.pointsEnabled) ...[
                const SizedBox(height: AppSpacing.xl),
                _Scoreboard(
                  members: data.members,
                  scores: data.scores,
                  currentUserId: data.currentUserId,
                  onResetPoints: (userId) => _resetPoints(data, userId),
                ),
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
            icon: const Icon(Icons.add_rounded),
            label: Text(
              context.l.tskNew,
              style: const TextStyle(fontWeight: FontWeight.bold),
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
          chip(context.l.tskAll, null),
          if (currentUserId != null) chip(context.l.tskMine, currentUserId),
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
                decoration: AppTheme.tactileDecoration(
                  radius: AppRadius.lg,
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
                            context.l.tskAllDoneToday,
                            style: AppTextStyles.title,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            nothingToday
                                ? context.l.tskNextBelow
                                : context.l.tskNothingLeft,
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

/// Marcador del hogar: cada persona con su barra de puntos, de más a menos.
/// La barra crece al aparecer y quien va primero lleva la estrella dorada.
class _Scoreboard extends StatelessWidget {
  final Map<String, String> members;
  final Map<String, int> scores;
  final String? currentUserId;

  /// Reinicia los puntos del miembro indicado (tras confirmar en el padre).
  final void Function(String userId) onResetPoints;
  const _Scoreboard({
    required this.members,
    required this.scores,
    required this.currentUserId,
    required this.onResetPoints,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    final entries = members.entries.toList()
      ..sort((a, b) => (scores[b.key] ?? 0).compareTo(scores[a.key] ?? 0));
    final top = scores[entries.first.key] ?? 0;
    final reduce = AppMotion.reduceMotionOf(context);

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: AppTheme.tactileDecoration(radius: AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l.tskScoreboard, style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.md),
          if (top == 0)
            Row(
              children: [
                const MiauCharacter(mood: MiauMood.curious, size: 64),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l.tskNoPoints, style: AppTextStyles.title),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        context.l.tskNoPointsHint,
                        style: AppTextStyles.bodyMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          for (final (i, e) in entries.indexed)
            if (top > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    _Avatar(name: e.value, size: 36, leader: i == 0),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  e.key == currentUserId
                                      ? context.l.tskYou(e.value)
                                      : e.value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyStrong,
                                ),
                              ),
                              AnimatedCounter(
                                value: (scores[e.key] ?? 0).toDouble(),
                                formatter: (v) => context.l.tskPts(v.round()),
                                style: AppTextStyles.numeric(
                                  AppTextStyles.bodyStrong,
                                ).copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0,
                              end: (scores[e.key] ?? 0) / top,
                            ),
                            duration: AppMotion.effectiveDuration(
                              Duration(milliseconds: 600 + i * 120),
                              reduceMotion: reduce,
                            ),
                            curve: AppMotion.springCurve(
                              AppMotion.fluidDefault,
                            ),
                            builder: (context, v, _) => ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: v,
                                minHeight: 8,
                                backgroundColor: AppColors.line,
                                color: i == 0 ? AppColors.gold : AppColors.wood,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.restart_alt,
                        size: 20,
                        color: AppColors.inkMuted,
                      ),
                      tooltip: context.l.tskResetPoints,
                      onPressed: () => onResetPoints(e.key),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

/// Inicial de la persona en un círculo de color estable (el mismo nombre,
/// siempre el mismo color). Quien va primero lleva una estrella dorada.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.size = 36, this.leader = false});
  final String name;
  final double size;
  final bool leader;

  @override
  Widget build(BuildContext context) {
    final palette = [
      (AppColors.terracottaBg, AppColors.terracottaText),
      (AppColors.sageBg, AppColors.sage),
      (AppColors.goldBg, AppColors.ink),
      (AppColors.lilacBg, AppColors.lilac),
      (AppColors.frostBg, AppColors.frost),
    ];
    final (bg, fg) = palette[name.hashCode.abs() % palette.length];
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return SizedBox.square(
      dimension: size + 6,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: AppElevation.border,
            ),
            child: Text(
              initial,
              style: TextStyle(
                fontSize: size * 0.42,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ),
          if (leader)
            Positioned(
              right: 0,
              bottom: 0,
              child: Icon(Icons.star_rounded, size: 18, color: AppColors.gold),
            ),
        ],
      ),
    );
  }
}

String taskRepeatLabel(BuildContext context, HomeTask t) =>
    switch (t.recurrence) {
      'daily' => context.l.planEveryDays(1),
      'weekly' => context.l.planEveryWeeks(1),
      'custom_interval' =>
        t.intervalUnit == 'week'
            ? context.l.planEveryWeeks(t.intervalCount ?? 1)
            : context.l.planEveryDays(t.intervalCount ?? 1),
      'custom_weekdays' => context.l.tskSomeDays,
      _ => context.l.tskOnce,
    };

/// Icono de la tarea en su color: así se reconoce sin leer.
class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.kind, this.size = 48, this.faded = false});
  final TaskKind kind;
  final double size;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = kind.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: faded ? AppColors.line : bg,
        borderRadius: BorderRadius.circular(size * 0.32),
        border: faded ? null : AppElevation.border,
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
  const _SectionTitle(this.text, {this.count});
  final String text;
  final int? count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
    child: Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 18,
            letterSpacing: -0.3,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        if (count case final c?) ...[
          const SizedBox(width: AppSpacing.sm),
          _Pill(text: '$c', bg: AppColors.line, fg: AppColors.inkMuted),
        ],
      ],
    ),
  );
}

/// Cabecera de un día dentro del bloque "Próximos días".
class _DayHeader extends StatelessWidget {
  const _DayHeader(this.day);

  /// Día sin hora; null = tareas sin fecha.
  final DateTime? day;

  String _label(BuildContext context) {
    final d = day;
    if (d == null) return context.l.tskNoDate;
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    if (d == tomorrow) return context.l.tomorrow;
    final locale = Localizations.localeOf(context).toString();
    return toBeginningOfSentenceCase(
      DateFormat.MMMEd(locale).format(d),
      locale,
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.xs,
    ),
    child: Text(
      _label(context),
      style: AppTextStyles.label.copyWith(color: AppColors.terracottaText),
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
      decoration: AppTheme.tactileDecoration(radius: AppRadius.lg),
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
              curve: AppMotion.springCurve(AppMotion.fluidDefault),
              builder: (context, v, _) => Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: v,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    backgroundColor: AppColors.line,
                    color: AppColors.done,
                  ),
                  Center(
                    child: AnimatedCounter(
                      value: done.toDouble(),
                      formatter: (v) => '${v.round()}/$total',
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
                  context.l.today,
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
                      ? (total == 0
                            ? context.l.tskNothingToday
                            : context.l.tskAllDone)
                      : context.l.tskLeft(left),
                  style: AppTextStyles.bodyMuted,
                ),
                if (overdue > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _Pill(
                    text: context.l.tskOverdueCount(overdue),
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

/// Tarjeta de tarea estilo "calendario del logo": papel con borde de trazo,
/// franja superior del color de su tipo, botón de hecha y, con puntos, la
/// insignia dorada. Deslizar a la derecha la completa y, si está en la bolsa,
/// a la izquierda te la pides.
class _TaskTile extends StatelessWidget {
  const _TaskTile({
    super.key,
    required this.task,
    required this.who,
    required this.overdue,
    required this.onDone,
    required this.onMore,
    this.completing = false,
    this.points,
    this.onClaim,
  });
  final HomeTask task;
  final String? who;
  final bool overdue;

  /// Se está marcando como hecha: el botón se rellena y la tarjeta se apaga.
  final bool completing;
  final VoidCallback onDone;
  final VoidCallback onMore;
  final int? points;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final kind = taskKindFor(task.title);
    final (_, fg) = kind.colors;
    final meta = [
      if (task.recurrence != 'once') taskRepeatLabel(context, task),
      ?who,
    ].join(' · ');
    return SwipeAction(
      radius: AppRadius.lg,
      toRight: SwipeSide(
        icon: Icons.check_rounded,
        color: AppColors.done,
        label: context.l.tskMarkDone(task.title),
        onTrigger: onDone,
      ),
      toLeft: onClaim == null
          ? null
          : SwipeSide(
              icon: Icons.back_hand_rounded,
              color: AppColors.terracotta,
              label: context.l.tskClaim(task.title),
              onTrigger: onClaim!,
            ),
      child: PressScale(
        onTap: completing ? null : onMore,
        pressedScale: 0.97,
        child: AnimatedOpacity(
          opacity: completing ? 0.55 : 1,
          duration: AppMotion.base,
          curve: AppMotion.easeOut,
          child: Container(
            // El relleno deja el borde por encima de la franja de color.
            padding: const EdgeInsets.all(1.5),
            decoration: AppTheme.tactileDecoration(radius: AppRadius.lg),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg - 1.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Franja de color, como el lomo del calendario.
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: fg,
                      border: Border(bottom: BorderSide(color: AppColors.line)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _KindBadge(kind: kind),
                            const Spacer(),
                            Semantics(
                              button: true,
                              label: context.l.tskMarkDone(task.title),
                              child: PressScale(
                                onTap: completing ? null : onDone,
                                pressedScale: 0.85,
                                child: AnimatedContainer(
                                  duration: AppMotion.base,
                                  curve: AppMotion.easeOutBack,
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: completing
                                        ? AppColors.done
                                        : AppColors.paper,
                                    border: Border.all(
                                      color: AppColors.stroke,
                                      width: 2,
                                    ),
                                  ),
                                  child: AnimatedScale(
                                    scale: completing ? 1.15 : 1,
                                    duration: AppMotion.base,
                                    curve: AppMotion.easeOutBack,
                                    child: Icon(
                                      Icons.check_rounded,
                                      color: completing
                                          ? AppColors.cream
                                          : AppColors.done,
                                      size: 24,
                                    ),
                                  ),
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
                            text: context.l.tskOverdue,
                            bg: AppColors.expiredBg,
                            fg: AppColors.expired,
                          )
                        else
                          Text(
                            meta.isEmpty ? context.l.taskKind(kind.name) : meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMuted.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        if (points case final p? when p > 0) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _PointsBadge(points: p),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Insignia "corona dorada" con los puntos de una tarea.
class _PointsBadge extends StatelessWidget {
  const _PointsBadge({required this.points});
  final int points;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(6, 3, 10, 3),
    decoration: BoxDecoration(
      color: AppColors.goldBg,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppColors.gold, width: 1.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 16, color: AppColors.gold),
        const SizedBox(width: 3),
        Text(
          context.l.tskPts(points),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ],
    ),
  );
}

/// Texto suave cuando una vista de la píldora está vacía.
class _ViewEmpty extends StatelessWidget {
  const _ViewEmpty(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: AppTextStyles.bodyMuted,
    ),
  );
}

/// Vistas de la píldora de arriba.
enum _TaskView { pending, pool, done }

/// Fila de una tarea de otro día.
class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({
    required this.task,
    required this.who,
    required this.onTap,
  });
  final HomeTask task;
  final String? who;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kind = taskKindFor(task.title);
    final meta = [
      if (task.recurrence != 'once') taskRepeatLabel(context, task),
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
            Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
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

/// La única hoja de tareas, para crear y para editar: lo de siempre a la
/// vista (qué, cuándo, cada cuánto, quién) y el resto en "Detalles".
class _TaskSheet extends StatefulWidget {
  const _TaskSheet({
    required this.homeId,
    required this.members,
    required this.currentUserId,
    required this.pointsEnabled,
    this.task,
  });
  final String homeId;
  final Map<String, String> members;
  final String? currentUserId;
  final bool pointsEnabled;
  final HomeTask? task;

  @override
  State<_TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends State<_TaskSheet> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  int _when = 0; // 0 hoy, 1 mañana, 2 fecha elegida, -1 sin fecha
  DateTime? _date;
  String _repeat = 'once';
  final Set<int> _weekdays = {}; // 1=Lun..7=Dom
  String? _assigned;
  TimeOfDay? _time;
  int _points = 10;
  bool _details = false;
  bool _saving = false;

  bool get _editing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    if (t == null) return;
    _title.text = t.title;
    _notes.text = t.notes ?? '';
    _repeat = t.recurrence;
    _weekdays.addAll(t.weekdays);
    _assigned = widget.members.containsKey(t.assignedTo) ? t.assignedTo : null;
    _points = t.points;
    final parts = t.dueTime?.split(':');
    if (parts != null && parts.length >= 2) {
      _time = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    final d = t.dueDate;
    final today = DateUtils.dateOnly(DateTime.now());
    if (d == null) {
      _when = -1;
    } else if (DateUtils.isSameDay(d, today)) {
      _when = 0;
    } else if (DateUtils.isSameDay(d, today.add(const Duration(days: 1)))) {
      _when = 1;
    } else {
      _when = 2;
      _date = d;
    }
    _details = _notes.text.isNotEmpty || _time != null;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  DateTime? get _due {
    final n = DateTime.now();
    return switch (_when) {
      -1 => null,
      1 => DateTime(n.year, n.month, n.day + 1),
      2 => _date ?? DateTime(n.year, n.month, n.day),
      _ => DateTime(n.year, n.month, n.day),
    };
  }

  bool get _canSave =>
      _title.text.trim().isNotEmpty &&
      !_saving &&
      !(_repeat == 'custom_weekdays' && _weekdays.isEmpty);

  Future<void> _pickDate() async {
    final n = DateTime.now();
    final first = DateTime(n.year, n.month, n.day);
    final d = await showDatePicker(
      context: context,
      initialDate: _date != null && !_date!.isBefore(first) ? _date! : n,
      firstDate: first,
      lastDate: DateTime(n.year + 2),
    );
    if (d == null) return;
    setState(() {
      _date = d;
      _when = 2;
    });
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (t != null) setState(() => _time = t);
  }

  static String? _dayKey(DateTime? d) => d?.toIso8601String().split('T').first;

  Future<int?>? _free;
  String? _freeKey;

  /// Primer hueco libre del día elegido según el calendario del móvil.
  Future<int?> _freeSlot(DateTime day) {
    if (_freeKey != _dayKey(day)) {
      _freeKey = _dayKey(day);
      _free = CalendarSync.busyOn(day).then(
        (events) => CalendarSync.freeSlot(
          [
            for (final e in events)
              if (!e.isAllDay) (start: e.startDate, end: e.endDate),
          ],
          day,
          DateTime.now(),
        ),
      );
    }
    return _free!;
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (!_canSave || uid == null) return;
    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    final original = widget.task;
    try {
      final task = HomeTask(
        id: original?.id ?? '',
        homeId: widget.homeId,
        title: title[0].toUpperCase() + title.substring(1),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        points: _points,
        effortPoints: original?.effortPoints ?? 10,
        recurrence: _repeat,
        intervalCount: original?.intervalCount,
        intervalUnit: original?.intervalUnit,
        weekdays: _weekdays.toList()..sort(),
        assignedTo: _assigned,
        dueDate: _due,
        dueTime: _time == null
            ? null
            : '${_time!.hour.toString().padLeft(2, '0')}:'
                  '${_time!.minute.toString().padLeft(2, '0')}',
      );
      final map = task.toInsertMap(createdBy: uid);
      final client = Supabase.instance.client;
      if (original == null) {
        await client.from('tasks').insert(map);
      } else {
        map
          ..remove('created_by')
          ..remove('home_id');
        // Si no se tocó la fecha, la recurrente sigue donde iba.
        if (_dayKey(original.dueDate) == _dayKey(_due) &&
            original.nextDue != null) {
          map['next_due'] = _dayKey(original.nextDue);
        }
        await client.from('tasks').update(map).eq('id', original.id);
      }
      unawaited(CalendarSync.sync(client, force: true));
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

  Widget _chip(
    String label,
    bool selected,
    VoidCallback onTap, {
    IconData? icon,
  }) => ChoiceChip(
    avatar: icon == null ? null : Icon(icon, size: 18),
    label: Text(label),
    selected: selected,
    onSelected: (_) {
      HapticFeedback.selectionClick();
      onTap();
    },
  );

  @override
  Widget build(BuildContext context) {
    final dateLabel = _when == 2 && _date != null
        ? '${_date!.day}/${_date!.month}'
        : context.l.tskOtherDay;
    final repeats = [
      ('once', context.l.no),
      ('daily', context.l.planEveryDays(1)),
      ('weekly', context.l.planEveryWeeks(1)),
      ('custom_weekdays', context.l.tskSomeDays),
      // Las de "cada N días" se crearon antes; se conservan al editarlas.
      if (widget.task?.recurrence == 'custom_interval')
        ('custom_interval', taskRepeatLabel(context, widget.task!)),
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _editing ? context.l.tskEdit : context.l.tskNew,
              style: AppTextStyles.headline,
            ),
            const SizedBox(height: AppSpacing.md),
            if (!_editing) ...[
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
                            title: context.l.taskPreset(p.key),
                            selected:
                                _title.text == context.l.taskPreset(p.key),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _title.text = context.l.taskPreset(p.key);
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
            ],
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                hintText: _editing
                    ? context.l.tskNameHint
                    : context.l.tskOrTypeAnother,
                prefixIcon: Icon(taskKindFor(_title.text).icon),
              ),
            ),
            _label(context.l.tskWhen),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _chip(
                  context.l.today,
                  _when == 0,
                  () => setState(() => _when = 0),
                ),
                _chip(
                  context.l.tomorrow,
                  _when == 1,
                  () => setState(() => _when = 1),
                ),
                _chip(
                  dateLabel,
                  _when == 2,
                  _pickDate,
                  icon: Icons.event_rounded,
                ),
                _chip(
                  context.l.tskNoDate,
                  _when == -1,
                  () => setState(() => _when = -1),
                ),
              ],
            ),
            _label(context.l.tskRepeats),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final r in repeats)
                  _chip(
                    r.$2,
                    _repeat == r.$1,
                    () => setState(() => _repeat = r.$1),
                  ),
              ],
            ),
            if (_repeat == 'custom_weekdays') ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var day = 1; day <= 7; day++)
                    _WeekdayDot(
                      // 2024-01-01 fue lunes.
                      label: DateFormat.EEEEE(
                        Localizations.localeOf(context).toString(),
                      ).format(DateTime(2024, 1, day)),
                      tooltip: DateFormat.EEEE(
                        Localizations.localeOf(context).toString(),
                      ).format(DateTime(2024, 1, day)),
                      selected: _weekdays.contains(day),
                      onTap: () => setState(
                        () => _weekdays.contains(day)
                            ? _weekdays.remove(day)
                            : _weekdays.add(day),
                      ),
                    ),
                ],
              ),
            ],
            if (widget.members.length > 1) ...[
              _label(context.l.tskWho),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  _chip(
                    context.l.tskAnyone,
                    _assigned == null,
                    () => setState(() => _assigned = null),
                  ),
                  for (final e in widget.members.entries)
                    _chip(
                      e.key == widget.currentUserId ? context.l.tskMe : e.value,
                      _assigned == e.key,
                      () => setState(() => _assigned = e.key),
                    ),
                ],
              ),
            ] else ...[
              _label(context.l.tskWho),
              Text(context.l.tskAddPersonHint, style: AppTextStyles.bodyMuted),
            ],
            const SizedBox(height: AppSpacing.md),
            // Lo menos habitual, un nivel más abajo y en la misma hoja.
            InkWell(
              onTap: () => setState(() => _details = !_details),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Text(context.l.tskDetails, style: AppTextStyles.label),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _details ? 0.5 : 0,
                      duration: AppMotion.fast,
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: AppMotion.fast,
              alignment: Alignment.topCenter,
              child: !_details
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: AppSpacing.sm,
                          children: [
                            _chip(
                              _time == null
                                  ? context.l.tskNoTime
                                  : _time!.format(context),
                              _time != null,
                              _pickTime,
                              icon: Icons.schedule_rounded,
                            ),
                            if (_time != null)
                              IconButton(
                                tooltip: context.l.tskRemoveTime,
                                onPressed: () => setState(() => _time = null),
                                icon: const Icon(Icons.close_rounded, size: 20),
                              ),
                            if (_time == null &&
                                _due != null &&
                                PlanPrefs.current.value.calendarId != null)
                              FutureBuilder<int?>(
                                future: _freeSlot(_due!),
                                builder: (context, snap) {
                                  final m = snap.data;
                                  if (m == null) return const SizedBox.shrink();
                                  return _chip(
                                    context.l.tskFreeAt(
                                      PlanPrefs.formatMinutes(m),
                                    ),
                                    false,
                                    () => setState(
                                      () => _time = TimeOfDay(
                                        hour: m ~/ 60,
                                        minute: m % 60,
                                      ),
                                    ),
                                    icon: Icons.event_available_rounded,
                                  );
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _notes,
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 2,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: context.l.tskNotes,
                          ),
                        ),
                        if (widget.pointsEnabled)
                          Row(
                            children: [
                              Text(
                                context.l.tskPoints,
                                style: AppTextStyles.body,
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: context.l.less,
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: _points > 5
                                    ? () => setState(() => _points -= 5)
                                    : null,
                              ),
                              Text('$_points', style: AppTextStyles.title),
                              IconButton(
                                tooltip: context.l.more,
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: _points < 100
                                    ? () => setState(() => _points += 5)
                                    : null,
                              ),
                            ],
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _canSave ? _save : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.cream,
              ),
              child: Text(
                _editing ? context.l.save : context.l.tskAdd,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Día de la semana como círculo que se marca con un toque.
class _WeekdayDot extends StatelessWidget {
  const _WeekdayDot({
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltip,
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: AppMotion.fast,
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? AppColors.wood : AppColors.card,
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyStrong.copyWith(color: AppColors.ink),
          ),
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
