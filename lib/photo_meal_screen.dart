import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/food_log_entry.dart';
import 'theme/app_theme.dart';

/// Registra comida a partir de una foto del plato: la IA estima los alimentos
/// y sus calorías/macros, y luego la persona REVISA y CORRIGE lo detectado
/// antes de guardarlo en su diario. La estimación por foto es aproximada, por
/// eso todo es editable. Replica el patrón de lib/scan_ticket_screen.dart:
/// foto -> IA -> revisión editable -> guardar.
class PhotoMealScreen extends StatefulWidget {
  /// Día del diario sobre el que se registrará la comida (por defecto el que
  /// se está viendo). Se puede cambiar en la pantalla de revisión.
  final DateTime logDate;

  const PhotoMealScreen({super.key, required this.logDate});

  @override
  State<PhotoMealScreen> createState() => _PhotoMealScreenState();
}

class _PhotoMealScreenState extends State<PhotoMealScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  final _picker = ImagePicker();

  bool _processing = false;
  bool _saving = false;

  // Datos estimados (editables).
  List<_MealItemRow> _items = [];
  bool _hasResult = false;
  String _note = '';

  // Tipo de comida y día elegidos para el registro.
  String? _mealType;
  late DateTime _logDate;

  @override
  void initState() {
    super.initState();
    _logDate = DateTime(
      widget.logDate.year,
      widget.logDate.month,
      widget.logDate.day,
    );
  }

  @override
  void dispose() {
    for (final it in _items) {
      it.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (file == null) return;

      setState(() {
        _processing = true;
      });
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mime = file.mimeType ?? 'image/jpeg';

      final res = await _client.functions.invoke(
        'analyze-meal',
        body: {'image_base64': base64Image, 'mime_type': mime},
      );

      final data = res.data;
      if (data is Map && data['meal'] is Map) {
        _applyResult(Map<String, dynamic>.from(data['meal'] as Map));
      } else {
        final msg = (data is Map && data['error'] != null)
            ? data['error'].toString()
            : 'No se pudo analizar la comida';
        throw msg;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al analizar la foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  void _applyResult(Map<String, dynamic> meal) {
    String s(dynamic v) => v == null ? '' : v.toString();
    for (final it in _items) {
      it.dispose();
    }
    final items = <_MealItemRow>[];
    final rawItems = meal['items'];
    if (rawItems is List) {
      for (final raw in rawItems) {
        final m = raw is Map ? raw : {};
        items.add(
          _MealItemRow(
            name: s(m['name']),
            calories: s(m['calories']),
            protein: s(m['protein']),
            carbs: s(m['carbs']),
            fat: s(m['fat']),
          ),
        );
      }
    }
    setState(() {
      _items = items;
      _note = s(meal['note']);
      _hasResult = true;
    });
  }

  double _num(String v) => double.tryParse(v.trim().replaceAll(',', '.')) ?? 0;

  double? _nullableNum(String v) {
    final t = v.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  double get _totalCalories =>
      _items.fold(0.0, (a, it) => a + _num(it.calories.text));

  Future<void> _save() async {
    setState(() {
      _saving = true;
    });
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw 'No autenticado';

      final rows = <Map<String, dynamic>>[];
      for (final it in _items) {
        final name = it.name.text.trim();
        if (name.isEmpty) continue;
        final entry = FoodLogEntry(
          userId: user.id,
          logDate: _logDate,
          mealType: _mealType,
          name: name,
          calories: _nullableNum(it.calories.text),
          protein: _nullableNum(it.protein.text),
          carbs: _nullableNum(it.carbs.text),
          fat: _nullableNum(it.fat.text),
          source: 'foto',
        );
        rows.add(entry.toInsertMap());
      }

      if (rows.isEmpty) {
        throw 'Añade al menos un alimento con nombre.';
      }

      await _client.from('food_log_entries').insert(rows);

      if (!mounted) return;
      Navigator.of(context).pop(true);
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
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Registrar con foto')),
      body: _processing
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analizando la foto con IA…'),
                ],
              ),
            )
          : _hasResult
          ? _buildReview()
          : _buildStart(),
    );
  }

  Widget _buildStart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_camera_outlined,
              size: 72,
              color: AppColors.wood,
            ),
            const SizedBox(height: 16),
            const Text(
              'Haz una foto a tu plato',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'La IA estimará los alimentos y sus calorías. La estimación por '
              'foto es aproximada, así que después podrás revisar y corregir '
              'todo antes de guardarlo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _pickAndAnalyze(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Hacer foto'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _pickAndAnalyze(ImageSource.gallery),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                minimumSize: const Size.fromHeight(50),
                side: const BorderSide(color: AppColors.wood, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Elegir de la galería'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReview() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Revisa y corrige lo detectado',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Las calorías son una ESTIMACIÓN aproximada hecha por la '
                      'IA. Ajústalas si hace falta antes de guardar.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    if (_note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              size: 18,
                              color: AppColors.wood,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _note,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _mealType,
                      isExpanded: true,
                      decoration: _dec('Tipo de comida (opcional)'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Sin tipo'),
                        ),
                        ...FoodLogEntry.mealTypeLabels.entries.map(
                          (e) => DropdownMenuItem<String>(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() {
                        _mealType = v;
                      }),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _logDate,
                          firstDate: DateTime(now.year - 3),
                          lastDate: DateTime(now.year, now.month, now.day),
                        );
                        if (!mounted) return;
                        if (picked != null) {
                          setState(() {
                            _logDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                            );
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: InputDecorator(
                        decoration: _dec('Día'),
                        child: Text(
                          '${_logDate.day.toString().padLeft(2, '0')}/'
                          '${_logDate.month.toString().padLeft(2, '0')}/'
                          '${_logDate.year}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'La IA no detectó alimentos en la foto. Añádelos a mano '
                    'con el botón de abajo.',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              Row(
                children: [
                  Text(
                    'ALIMENTOS (${_items.length})',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _items.add(_MealItemRow());
                    }),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Añadir alimento'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._items.asMap().entries.map((e) => _itemCard(e.key, e.value)),
            ],
          ),
        ),
        _bottomBar(),
      ],
    );
  }

  Widget _itemCard(int index, _MealItemRow it) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardDecoration(radius: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: it.name,
                  decoration: _dec('Alimento'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.redAccent),
                onPressed: () => setState(() {
                  _items.removeAt(index);
                  it.dispose();
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 90,
                child: TextField(
                  controller: it.calories,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _dec('kcal'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: it.protein,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _dec('P (g)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: it.carbs,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _dec('C (g)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: it.fat,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _dec('G (g)'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total', style: TextStyle(color: Colors.grey[600])),
                Text(
                  '${_totalCalories.round()} kcal',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('Guardar en el diario'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    isDense: true,
    filled: true,
    fillColor: AppColors.cream,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
}

/// Una fila editable de alimento detectado (o añadido a mano). Cada campo
/// numérico es un TextEditingController que hay que liberar con dispose().
class _MealItemRow {
  final TextEditingController name;
  final TextEditingController calories;
  final TextEditingController protein;
  final TextEditingController carbs;
  final TextEditingController fat;

  _MealItemRow({
    String name = '',
    String calories = '',
    String protein = '',
    String carbs = '',
    String fat = '',
  }) : name = TextEditingController(text: name),
       calories = TextEditingController(text: calories),
       protein = TextEditingController(text: protein),
       carbs = TextEditingController(text: carbs),
       fat = TextEditingController(text: fat);

  void dispose() {
    name.dispose();
    calories.dispose();
    protein.dispose();
    carbs.dispose();
    fat.dispose();
  }
}
