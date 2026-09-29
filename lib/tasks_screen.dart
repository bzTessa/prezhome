import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_task_screen.dart';
import 'models/task.dart';
import 'theme/app_theme.dart';
import 'widgets/miau_character.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  late Future<_TasksData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  void _reload() => setState(() => _future = _load());

  Future<_TasksData> _load() async {
    final user = _client.auth.currentUser;
    if (user == null) throw 'No autenticado';
    final profile = await _client
        .from('profiles')
        .select('home_id')
        .eq('id', user.id)
        .maybeSingle();
    final homeId = profile?['home_id'] as String?;
    if (homeId == null) return _TasksData(homeId: null);

    // Miembros del hogar (id -> nombre)
    final profs = await _client
        .from('profiles')
        .select('id, full_name')
        .eq('home_id', homeId);
    final members = <String, String>{};
    for (final p in (profs as List)) {
      members[p['id'] as String] =
          (p['full_name'] as String?)?.trim().isNotEmpty == true
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
    final tasks =
        (tasksRes as List).map((m) => HomeTask.fromMap(m)).toList();

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
      scores: scores,
      currentUserId: user.id,
    );
  }

  Future<void> _complete(HomeTask task) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      // Registrar puntos ganados
      await _client.from('task_points').insert({
        'home_id': task.homeId,
        'user_id': user.id,
        'points': task.points,
        'task_id': task.id,
      });

      if (task.recurrence == 'once') {
        // Puntual: marcar como hecha
        await _client.from('tasks').update({
          'is_done': true,
          'completed_by': user.id,
          'completed_at': DateTime.now().toIso8601String(),
        }).eq('id', task.id);
      } else {
        // Recurrente: se mantiene activa (solo suma puntos al completarla)
        await _client.from('tasks').update({
          'completed_by': user.id,
          'completed_at': DateTime.now().toIso8601String(),
        }).eq('id', task.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡+${task.points} puntos!')),
        );
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

          return Column(
            children: [
              _Scoreboard(members: data.members, scores: data.scores),
              Expanded(
                child: data.tasks.isEmpty
                    ? _empty()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: data.tasks.length,
                        itemBuilder: (context, i) {
                          final t = data.tasks[i];
                          return _TaskCard(
                            task: t,
                            memberName: t.assignedTo == null
                                ? 'Cualquiera'
                                : (data.members[t.assignedTo] ?? 'Miembro'),
                            onComplete: () => _complete(t),
                            onDelete: () => _delete(t),
                          );
                        },
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

class _TasksData {
  final String? homeId;
  final Map<String, String> members;
  final List<HomeTask> tasks;
  final Map<String, int> scores;
  final String? currentUserId;
  _TasksData({
    required this.homeId,
    this.members = const {},
    this.tasks = const [],
    this.scores = const {},
    this.currentUserId,
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
