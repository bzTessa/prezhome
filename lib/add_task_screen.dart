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
  int _intervalCount = 2;
  String _intervalUnit = 'day';
  final Set<int> _weekdays = {}; // 1=Lun..7=Dom
  String? _assignedTo; // null = cualquiera
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
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

      // Validaciones de la recurrencia personalizada
      if (_recurrence == 'custom_weekdays' && _weekdays.isEmpty) {
        throw 'Elige al menos un día de la semana.';
      }

      final task = HomeTask(
        id: '',
        homeId: homeId,
        title: _titleController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        points: _points,
        recurrence: _recurrence,
        intervalCount: _intervalCount,
        intervalUnit: _intervalUnit,
        weekdays: _weekdays.toList(),
        assignedTo: _assignedTo,
        dueDate: _dueDate,
        dueTime: _dueTime == null
            ? null
            : '${_dueTime!.hour.toString().padLeft(2, '0')}:'
                  '${_dueTime!.minute.toString().padLeft(2, '0')}',
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
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _recurrence = v!),
            ),

            // Ajustes de "Cada X días/semanas"
            if (_recurrence == 'custom_interval') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Cada', style: TextStyle(fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _intervalCount > 1
                        ? () => setState(() => _intervalCount--)
                        : null,
                  ),
                  Text(
                    '$_intervalCount',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _intervalCount < 30
                        ? () => setState(() => _intervalCount++)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _intervalUnit,
                      decoration: _dec('Unidad'),
                      items: const [
                        DropdownMenuItem(value: 'day', child: Text('días')),
                        DropdownMenuItem(value: 'week', child: Text('semanas')),
                      ],
                      onChanged: (v) => setState(() => _intervalUnit = v!),
                    ),
                  ),
                ],
              ),
            ],

            // Ajustes de "Días concretos"
            if (_recurrence == 'custom_weekdays') ...[
              const SizedBox(height: 12),
              const Text(
                'Elige los días:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(7, (i) {
                  final day = i + 1; // 1=Lun..7=Dom
                  final selected = _weekdays.contains(day);
                  return FilterChip(
                    label: Text(HomeTask.weekdayShort[i]),
                    selected: selected,
                    selectedColor: const Color(0xFFE2C792),
                    backgroundColor: Colors.white,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _weekdays.add(day);
                      } else {
                        _weekdays.remove(day);
                      }
                    }),
                  );
                }),
              ),
            ],

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
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _dueTime ?? TimeOfDay.now(),
                  helpText: 'Hora (opcional)',
                );
                if (picked != null) setState(() => _dueTime = picked);
              },
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: _dec('Hora (opcional)'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _dueTime == null ? 'Sin hora' : _dueTime!.format(context),
                    ),
                    if (_dueTime != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueTime = null),
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
