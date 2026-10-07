import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_task_screen.dart';
import 'models/dashboard_prefs.dart';
import 'models/task.dart';
import 'services/task_scheduler.dart';
import 'theme/app_theme.dart';
import 'theme/app_spacing.dart';
import 'theme/app_text_styles.dart';
import 'utils/realtime_sync.dart';
import 'widgets/miau_character.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  late Future<_TasksData> _future;

  // Canal Realtime de las tareas del hogar. Se abre UNA sola vez en initState
  // (filtrado por home_id) y se cierra en dispose. Si el otro miembro del hogar
  // completa o cambia una tarea, recargamos al instante.
  // TasksScreen es hijo directo del IndexedStack siempre vivo: abrir una vez,
  // cerrar en dispose, nunca dejar canales colgando.
  RealtimeChannel? _channel;

  // Guarda PURA que decide avisar de "sin conexión en vivo" una sola vez.
  final RealtimeNoticeGate _noticeGate = RealtimeNoticeGate();
  String _viewFilter = 'pendientes';

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

    final doneBy = await _pickMember(
      members: data.members,
      currentUserId: data.currentUserId ?? user.id,
      title: '¿Quién hizo la tarea?',
    );
    if (doneBy == null) return; // Cancelado.

    try {
      await TaskScheduler(_client).completeAttributed(task, doneBy);

      if (!mounted) return;
      final who = data.members[doneBy] ?? 'el hogar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡+${task.points} puntos para $who!')),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
                    leading: const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.wood,
                      child: Icon(
                        Icons.person,
                        size: 20,
                        color: AppColors.ink,
                      ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Puntos de $name reiniciados.')),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _delete(HomeTask task) async {
    try {
      await _client.from('tasks').delete().eq('id', task.id);
      _reload();
    } catch (_) {}
  }

  Future<void> _openAdd(Map<String, String> members) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddTaskScreen(members: members)),
    );
    if (added == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Tareas')),
      body: FutureBuilder<_TasksData>(
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

          // Todas las tareas puntuales estan hechas: no queda ninguna
          // pendiente de completar. Mostramos a Miau celebrando.
          final hayTareas = data.tasks.isNotEmpty;
          final todoHecho = hayTareas && data.tasks.every((t) => t.isDone);
          final visibleTasks = _filteredTasks(data);

          // Todo el contenido va dentro de UN solo scroll para que la bolsa,
          // el resumen y la lista se comporten bien con muchas tareas.
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              112,
            ),
            children: [
              _TasksOverview(data: data),
              // Marcador y gráfica de puntos solo con el "Modo Puntos"
              // activado. El resto (bolsa comun, lista de tareas, celebración)
              // permanece visible aunque el modo este desactivado.
              if (data.pointsEnabled) ...[
                _Scoreboard(
                  members: data.members,
                  scores: data.scores,
                  onResetPoints: (userId) => _resetPoints(data, userId),
                ),
                _PointsChart(members: data.members, scores: data.scores),
              ],
              _TareasCelebracion(visible: todoHecho),
              _taskFilterBar(data),
              if (visibleTasks.isEmpty)
                _empty()
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _viewFilter == 'completadas'
                          ? 'Ya está hecho'
                          : 'Lo que toca',
                      style: AppTextStyles.title,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final t in visibleTasks)
                      _TaskCard(
                        task: t,
                        memberName: t.assignedTo == null
                            ? 'Cualquiera'
                            : (data.members[t.assignedTo] ?? 'Miembro'),
                        onComplete: () => _complete(t, data),
                        onDelete: () => _delete(t),
                      ),
                  ],
                ),
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

  List<HomeTask> _filteredTasks(_TasksData data) {
    final tasks = data.listTasks.where((task) {
      switch (_viewFilter) {
        case 'hoy':
          return !task.isDone && _isDueTodayOrOverdue(task);
        case 'completadas':
          return task.isDone;
        default:
          return !task.isDone;
      }
    }).toList();

    tasks.sort((a, b) {
      if (_viewFilter == 'completadas') {
        return (b.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0));
      }
      final urgency = _urgencyRank(a).compareTo(_urgencyRank(b));
      if (urgency != 0) return urgency;
      final da = a.nextDue ?? a.dueDate;
      final db = b.nextDue ?? b.dueDate;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return tasks;
  }

  bool _isDueTodayOrOverdue(HomeTask task) {
    final due = task.nextDue ?? task.dueDate;
    if (due == null) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !DateTime(due.year, due.month, due.day).isAfter(today);
  }

  int _urgencyRank(HomeTask task) {
    final due = task.nextDue ?? task.dueDate;
    if (due == null) return 2;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(due.year, due.month, due.day);
    if (day.isBefore(today)) return 0;
    if (day == today) return 1;
    return 2;
  }

  Widget _taskFilterBar(_TasksData data) {
    final pending = data.listTasks.where((t) => !t.isDone).length;
    final today = data.listTasks
        .where((t) => !t.isDone && _isDueTodayOrOverdue(t))
        .length;
    final done = data.listTasks.where((t) => t.isDone).length;
    const filters = [
      ('pendientes', 'Pendientes'),
      ('hoy', 'Para hoy'),
      ('completadas', 'Hechas'),
    ];
    final counts = {'pendientes': pending, 'hoy': today, 'completadas': done};

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Row(
        children: [
          for (var i = 0; i < filters.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _TaskFilterChip(
                label: filters[i].$2,
                count: counts[filters[i].$1]!,
                selected: _viewFilter == filters[i].$1,
                onTap: () => setState(() => _viewFilter = filters[i].$1),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiauCharacter(mood: MiauMood.curious, size: 120),
          const SizedBox(height: 16),
          const Text(
            'No hay tareas todavía',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Añade la primera y repartíos el hogar.',
            style: AppTextStyles.bodyMuted,
          ),
        ],
      ),
    );
  }
}

class _TasksOverview extends StatelessWidget {
  final _TasksData data;
  const _TasksOverview({required this.data});

  @override
  Widget build(BuildContext context) {
    final pending = data.listTasks.where((t) => !t.isDone).length;
    final dueToday = data.listTasks.where((t) {
      if (t.isDone) return false;
      final due = t.nextDue ?? t.dueDate;
      if (due == null) return true;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return !DateTime(due.year, due.month, due.day).isAfter(today);
    }).length;
    final mood = pending == 0
        ? MiauMood.celebrating
        : dueToday > 0
        ? MiauMood.curious
        : MiauMood.neutral;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: AppTheme.surfaceDecoration(
        radius: AppRadius.lg,
        elevation: 2,
        color: AppColors.sageBg,
      ),
      child: Row(
        children: [
          MiauCharacter(mood: mood, size: 64),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tu casa, paso a paso', style: AppTextStyles.headline),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  pending == 0
                      ? 'Todo al día. Disfruta de la calma.'
                      : dueToday > 0
                      ? 'Hay $dueToday ${dueToday == 1 ? 'tarea' : 'tareas'} '
                            'que conviene resolver hoy.'
                      : 'Tienes $pending tareas pendientes.',
                  style: AppTextStyles.bodyMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _TaskFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $count',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.wood : AppColors.card,
            borderRadius: AppRadius.mdRadius,
            boxShadow: selected ? AppElevation.level1 : AppElevation.level0,
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: AppTextStyles.title.copyWith(
                  color: selected ? AppColors.ink : AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.label.copyWith(
                  color: selected ? AppColors.ink : AppColors.inkMuted,
                  fontWeight: selected
                      ? FontWeight.w800
                      : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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
                    const MiauCharacter(
                      mood: MiauMood.celebrating,
                      size: 72,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Todo hecho!',
                            style: AppTextStyles.title,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'No quedan tareas pendientes. Miau esta encantado.',
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
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 12),
          ...entries.map((e) {
            final pts = scores[e.key] ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const CircleAvatar(
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.woodDark,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
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
              color: Colors.grey[500],
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
                        const TextStyle(
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
                              color: Colors.grey[600],
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
              color: Colors.grey[500],
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
                    const Text(
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
                      style: TextStyle(color: Colors.grey[700]),
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

class _TaskCard extends StatelessWidget {
  final HomeTask task;
  final String memberName;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.memberName,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final done = task.isDone;
    final dueLabel = _dueLabel(task);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.cardPadding,
      decoration: AppTheme.surfaceDecoration(
        radius: AppRadius.md,
        elevation: done ? 0 : 1,
        color: done ? AppColors.card.withValues(alpha: 0.72) : AppColors.card,
      ),
      child: Row(
        children: [
          // Botón completar
          GestureDetector(
            onTap: done ? null : onComplete,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.wood : Colors.transparent,
                border: Border.all(
                  color: done ? AppColors.wood : AppColors.inkMuted,
                  width: 2,
                ),
              ),
              child: done
                  ? const Icon(Icons.check, size: 18, color: AppColors.ink)
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: AppTextStyles.title.copyWith(
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: done ? AppColors.inkMuted : AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (dueLabel != null) _mini(dueLabel),
                    _mini(task.recurrenceLabel),
                    if (task.dueTime != null) _mini(task.dueTime!),
                    _mini(memberName),
                    _mini('${task.points} pts'),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _mini(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: AppRadius.pillRadius,
      ),
      child: Text(
        text,
        style: AppTextStyles.label,
      ),
    );
  }

  String? _dueLabel(HomeTask task) {
    final due = task.nextDue ?? task.dueDate;
    if (due == null) return 'Sin fecha';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(due.year, due.month, due.day);
    final diff = day.difference(today).inDays;
    if (diff < 0) return 'Atrasada';
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    return '${due.day.toString().padLeft(2, '0')}/'
        '${due.month.toString().padLeft(2, '0')}';
  }
}
