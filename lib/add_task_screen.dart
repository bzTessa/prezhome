import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/task.dart';
import 'theme/app_theme.dart';

class AddTaskScreen extends StatefulWidget {
  /// Miembros del hogar para asignar: {userId: nombre}.
  final Map<String, String> members;
  const AddTaskScreen({super.key, required this.members});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _client = Supabase.instance.client;

  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  int _points = 10;
  String _recurrence = 'once';
  String? _assignedTo; // null = cualquiera
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw 'No autenticado';
      final profile = await _client
          .from('profiles')
          .select('home_id')
          .eq('id', user.id)
          .single();
      final homeId = profile['home_id'];
      if (homeId == null) throw 'No perteneces a ningún hogar.';

      final task = HomeTask(
        id: '',
        homeId: homeId,
        title: _titleController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        points: _points,
        recurrence: _recurrence,
        assignedTo: _assignedTo,
        dueDate: _dueDate,
      );
      await _client.from('tasks').insert(task.toInsertMap(createdBy: user.id));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Nueva tarea')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: _dec('Título'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ponle un título' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: _dec('Notas (opcional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _recurrence,
              decoration: _dec('Periodicidad'),
              items: HomeTask.recurrenceLabels.entries
                  .map(
                    (e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _recurrence = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _assignedTo,
              decoration: _dec('Asignar a'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Cualquiera del hogar'),
                ),
                ...widget.members.entries.map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                ),
              ],
              onChanged: (v) => setState(() => _assignedTo = v),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? now,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 2),
                  helpText: 'Fecha límite (opcional)',
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: _dec('Fecha límite (opcional)'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _dueDate == null
                          ? 'Sin fecha'
                          : '${_dueDate!.day.toString().padLeft(2, '0')}/'
                                '${_dueDate!.month.toString().padLeft(2, '0')}/'
                                '${_dueDate!.year}',
                    ),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: const Icon(Icons.clear, size: 20),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Puntos:', style: TextStyle(fontSize: 16)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _points > 5
                      ? () => setState(() => _points -= 5)
                      : null,
                ),
                Text(
                  '$_points',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _points < 100
                      ? () => setState(() => _points += 5)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text('Guardar tarea'),
            ),
          ],
        ),
      ),
    );
  }
}
