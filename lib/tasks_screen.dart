import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_task_screen.dart';
import 'models/dashboard_prefs.dart';
import 'models/task.dart';
import 'services/task_scheduler.dart';
import 'theme/app_theme.dart';
import 'utils/realtime_sync.dart';
import 'widgets/animations/press_scale.dart';
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
  // reclama una tarea de la Bolsa Común o completa algo, recargamos al instante.
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

    // Bolsa Comun: tareas sin responsable asignado y aun pendientes. Cualquiera
    // del hogar puede reclamarlas con "Yo me encargo".
    final pool = tasks.where((t) => t.isInPool && !t.isDone).toList();

    // Lista principal: todo MENOS lo que ya se muestra en la Bolsa Comun, para
    // que cada tarea sin asignar aparezca una sola vez. Las asignadas y las ya
    // completadas siguen apareciendo aqui como siempre.
    final listTasks = tasks.where((t) => !(t.isInPool && !t.isDone)).toList();

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
      listTasks: listTasks,
      pool: pool,
      scores: scores,
      currentUserId: user.id,
      pointsEnabled: pointsEnabled,
    );
  }

  Future<void> _complete(HomeTask task) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      // Registra puntos y reprograma (recurrentes) o marca hecha ('once')
      // con la misma logica compartida que usa el Dashboard de Inicio.
      await TaskScheduler(_client).complete(task);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('¡+${task.points} puntos!')));
      }
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Flujo "Yo me encargo" de la Bolsa Comun: reclama la tarea para el usuario
  /// actual, la completa y suma sus puntos en un solo gesto. Metodo con cuerpo
  /// de bloque (NO arrow que devuelva un Future) para no caer en el fallo
  /// conocido de setState tras el await.
  Future<void> _claim(HomeTask task) async {
    try {
      await TaskScheduler(_client).claimAndComplete(task);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('¡+${task.points} puntos!')));
      }
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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

          // Todo el contenido va dentro de UN solo scroll (incluida la Bolsa
          // Comun) para que ninguna seccion desborde el viewport cuando hay
          // muchas tarjetas. La cabecera (marcador, grafica, celebracion y
          // bolsa) son los primeros items de la lista; el resto son las tareas.
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              // Marcador y gráfica de puntos solo con el "Modo Puntos"
              // activado. El resto (bolsa comun, lista de tareas, celebración)
              // permanece visible aunque el modo este desactivado.
              if (data.pointsEnabled) ...[
                _Scoreboard(members: data.members, scores: data.scores),
                _PointsChart(members: data.members, scores: data.scores),
              ],
              _TareasCelebracion(visible: todoHecho),
              _BolsaComun(pool: data.pool, onClaim: _claim),
              if (data.listTasks.isEmpty)
                _empty()
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    children: [
                      for (final t in data.listTasks)
                        _TaskCard(
                          task: t,
                          memberName: t.assignedTo == null
                              ? 'Cualquiera'
                              : (data.members[t.assignedTo] ?? 'Miembro'),
                          onComplete: () => _complete(t),
                          onDelete: () => _delete(t),
                        ),
                    ],
                  ),
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
            style: TextStyle(color: Colors.grey[600]),
          ),
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
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(),
                child: Row(
                  children: const [
                    MiauCharacter(mood: MiauMood.celebrating, size: 72),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Todo hecho!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.ink,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'No quedan tareas pendientes. Miau esta encantado.',
                            style: TextStyle(color: AppColors.ink),
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

/// Seccion "Bolsa Comun" (Task Pool): lista las tareas sin responsable que
/// cualquiera del hogar puede reclamar. Cada tarea muestra su recurrencia, los
/// puntos que suma al completarla y un chip informativo con el esfuerzo
/// estimado, mas un boton "Yo me encargo" que reclama+completa la tarea.
///
/// Si la bolsa esta vacia muestra un estado amable con Miau curioso. Se mantiene
/// como seccion autocontenida y local para no reorganizar el resto del fichero.
class _BolsaComun extends StatelessWidget {
  final List<HomeTask> pool;
  final Future<void> Function(HomeTask) onClaim;
  const _BolsaComun({required this.pool, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BOLSA COMÚN',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 8),
          if (pool.isEmpty)
            _empty()
          else
            ...pool.map((t) => _poolCard(context, t)),
        ],
      ),
    );
  }

  Widget _poolCard(BuildContext context, HomeTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _mini(task.recurrenceLabel),
              if (task.dueTime != null) _mini(task.dueTime!),
              _mini('${task.points} pts'),
              _mini('Esfuerzo: ${task.effortPoints}'),
            ],
          ),
          const SizedBox(height: 12),
          PressScale(
            onTap: () => onClaim(task),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.wood,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pan_tool_alt_outlined, color: AppColors.ink),
                  SizedBox(width: 8),
                  Text(
                    'Yo me encargo',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mini(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _empty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(radius: 20),
      child: Row(
        children: [
          const MiauCharacter(mood: MiauMood.curious, size: 72),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'La bolsa común está vacía',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cuando haya tareas sin dueño aparecerán aquí para que '
                  'cualquiera se encargue.',
                  style: TextStyle(color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TasksData {
  final String? homeId;
  final Map<String, String> members;
  final List<HomeTask> tasks;
  // Tareas de la lista principal (todas menos las que se muestran en la Bolsa
  // Comun, para no duplicar las no asignadas pendientes).
  final List<HomeTask> listTasks;
  final List<HomeTask> pool;
  final Map<String, int> scores;
  final String? currentUserId;

  /// "Modo Puntos" activado: controla si se muestran el marcador y la gráfica.
  final bool pointsEnabled;
  _TasksData({
    required this.homeId,
    this.members = const {},
    this.tasks = const [],
    this.listTasks = const [],
    this.pool = const [],
    this.scores = const {},
    this.currentUserId,
    this.pointsEnabled = true,
  });
}

class _Scoreboard extends StatelessWidget {
  final Map<String, String> members;
  final Map<String, int> scores;
  const _Scoreboard({required this.members, required this.scores});

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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(radius: 20),
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
                  color: done ? AppColors.wood : Colors.grey,
                  width: 2,
                ),
              ),
              child: done
                  ? const Icon(Icons.check, size: 18, color: AppColors.ink)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: done ? Colors.grey : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
