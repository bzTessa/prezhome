import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/nutrition_profile.dart';

class NutritionProfileScreen extends StatefulWidget {
  const NutritionProfileScreen({super.key});

  @override
  State<NutritionProfileScreen> createState() => _NutritionProfileScreenState();
}

class _NutritionProfileScreenState extends State<NutritionProfileScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String? _sex;
  DateTime? _birthDate;
  String _activity = 'moderate';
  String _goal = 'maintain';
  int _mealsPerDay = 4;
  bool _isPublic = false;
  Map<String, int> _mealSplit = {
    'breakfast': 20,
    'lunch': 40,
    'dinner': 40,
    'snack': 0,
    'dessert': 0,
  };
  // Días (1..7) en que cada comida se hace en casa. Vacío = todos los días.
  Map<String, List<int>> _mealsAtHome = {};
  String _cookingMode = 'daily';
  String _portionMode = 'practical';

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw 'No autenticado';
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      final p = NutritionProfile.fromMap(data);
      setState(() {
        _nameController.text = p.fullName ?? '';
        _heightController.text = p.heightCm?.toStringAsFixed(0) ?? '';
        _weightController.text = p.weightKg?.toStringAsFixed(1) ?? '';
        _sex = p.sex;
        _birthDate = p.birthDate;
        _activity = p.activityLevel;
        _goal = p.goal;
        _mealsPerDay = p.mealsPerDay;
        _isPublic = p.isPublic;
        _mealSplit = Map<String, int>.from(p.mealSplit);
        _mealsAtHome = {
          for (final e in p.mealsAtHome.entries) e.key: List<int>.from(e.value),
        };
        _cookingMode = p.cookingMode;
        _portionMode = p.portionMode;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar el perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Perfil actual reconstruido desde los campos, para calcular en vivo.
  NutritionProfile get _current => NutritionProfile(
    id: _client.auth.currentUser?.id ?? '',
    fullName: _nameController.text.trim(),
    sex: _sex,
    birthDate: _birthDate,
    heightCm: double.tryParse(_heightController.text.trim().replaceAll(',', '.')),
    weightKg: double.tryParse(_weightController.text.trim().replaceAll(',', '.')),
    activityLevel: _activity,
    goal: _goal,
    mealsPerDay: _mealsPerDay,
    isPublic: _isPublic,
    mealSplit: _mealSplit,
    mealsAtHome: _mealsAtHome,
    cookingMode: _cookingMode,
    portionMode: _portionMode,
  );

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw 'No autenticado';
      await _client
          .from('profiles')
          .update(_current.toUpdateMap())
          .eq('id', user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil guardado')),
        );
      }
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

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: 'Fecha de nacimiento',
    );
    if (picked != null) setState(() => _birthDate = picked);
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

  static const _weekdayShort = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  Widget _buildMealDaysRow(String mealKey) {
    final label = NutritionProfile.mealLabels[mealKey] ?? mealKey;
    // Lista actual; vacía = todos los días.
    final current = _mealsAtHome[mealKey] ?? [];
    final allDays = current.isEmpty; // vacío = todos

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: List.generate(7, (i) {
              final day = i + 1;
              final selected = allDays || current.contains(day);
              return FilterChip(
                label: Text(_weekdayShort[i]),
                selected: selected,
                selectedColor: const Color(0xFFE2C792),
                backgroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                onSelected: (v) => setState(() {
                  // Si estaba en "todos", materializamos la lista completa antes de quitar.
                  final list = allDays ? [1, 2, 3, 4, 5, 6, 7] : [...current];
                  if (v) {
                    if (!list.contains(day)) list.add(day);
                  } else {
                    list.remove(day);
                  }
                  // Si quedan los 7, lo dejamos como vacío (= todos, por defecto).
                  _mealsAtHome[mealKey] = (list.length == 7) ? [] : list;
                }),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8E1),
      appBar: AppBar(
        title: const Text(
          'Mi Perfil Nutricional',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFDF8E1),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // --- Modo de cocina ---
                const Text(
                  '¿Cómo cocinas?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _ModeCard(
                  title: 'Del día',
                  subtitle:
                      'Cocino y lo que sobra lo guardo para el día siguiente. '
                      'Interfaz sencilla.',
                  icon: Icons.wb_sunny_outlined,
                  selected: _cookingMode == 'daily',
                  onTap: () => setState(() => _cookingMode = 'daily'),
                ),
                const SizedBox(height: 8),
                _ModeCard(
                  title: 'Meal prep',
                  subtitle:
                      'Cocino en lote y congelo para varios días. Se activan '
                      'congelador, lotes y planificación.',
                  icon: Icons.ac_unit,
                  selected: _cookingMode == 'mealprep',
                  onTap: () => setState(() => _cookingMode = 'mealprep'),
                ),
                const SizedBox(height: 16),

                // --- Modo de porciones ---
                const Text(
                  'Cantidades',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Prácticas'),
                        subtitle: const Text('Formatos de súper'),
                        value: 'practical',
                        groupValue: _portionMode,
                        activeColor: const Color(0xFFB58A3C),
                        onChanged: (v) => setState(() => _portionMode = v!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Exactas'),
                        subtitle: const Text('Al gramo'),
                        value: 'strict',
                        groupValue: _portionMode,
                        activeColor: const Color(0xFFB58A3C),
                        onChanged: (v) => setState(() => _portionMode = v!),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),

                TextField(
                  controller: _nameController,
                  decoration: _dec('Nombre'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _sex,
                  decoration: _dec('Sexo'),
                  items: const [
                    DropdownMenuItem(value: 'female', child: Text('Mujer')),
                    DropdownMenuItem(value: 'male', child: Text('Hombre')),
                  ],
                  onChanged: (v) => setState(() => _sex = v),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickBirthDate,
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: _dec('Fecha de nacimiento'),
                    child: Text(
                      _birthDate == null
                          ? 'Seleccionar…'
                          : '${_birthDate!.day.toString().padLeft(2, '0')}/'
                                '${_birthDate!.month.toString().padLeft(2, '0')}/'
                                '${_birthDate!.year}'
                                '${_current.age != null ? '  (${_current.age} años)' : ''}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        decoration: _dec('Altura (cm)'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _dec('Peso (kg)'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _activity,
                  isExpanded: true,
                  decoration: _dec('Nivel de actividad'),
                  items: NutritionProfile.activityLabels.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(
                            e.value,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _activity = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _goal,
                  decoration: _dec('Objetivo'),
                  items: NutritionProfile.goalLabels.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _goal = v!),
                ),
                const SizedBox(height: 24),

                // --- Reparto de calorías por comida ---
                Row(
                  children: [
                    const Text(
                      'Reparto de calorías por comida',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Total: ${_mealSplit.values.fold(0, (a, b) => a + b)}%',
                      style: TextStyle(
                        color:
                            _mealSplit.values.fold(0, (a, b) => a + b) == 100
                            ? Colors.green[700]
                            : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Pon 0% en las comidas que no haces. La suma debería ser 100%.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 8),
                ...NutritionProfile.splitOrder.map((key) {
                  final label = NutritionProfile.mealLabels[key] ?? key;
                  final value = _mealSplit[key] ?? 0;
                  return Row(
                    children: [
                      SizedBox(width: 90, child: Text(label)),
                      Expanded(
                        child: Slider(
                          value: value.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 20,
                          label: '$value%',
                          activeColor: const Color(0xFFE2C792),
                          onChanged: (v) => setState(
                            () => _mealSplit[key] = v.round(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '$value%',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 24),

                // --- Comidas en casa por día (comer fuera) ---
                const Text(
                  'Comidas en casa',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Marca los días que haces cada comida en casa. Si comes fuera '
                  '(p. ej. en el trabajo), desmarca ese día y no se contará.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 8),
                ...NutritionProfile.splitOrder
                    .where((k) => (_mealSplit[k] ?? 0) > 0)
                    .map(_buildMealDaysRow),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Compartir mi perfil con el hogar'),
                  subtitle: const Text(
                    'Si está desactivado, tu perfil es privado.',
                  ),
                  value: _isPublic,
                  activeThumbColor: const Color(0xFFE2C792),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _isPublic = v),
                ),
                const SizedBox(height: 16),

                _ResultCard(profile: _current),
                const SizedBox(height: 24),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE2C792),
                    foregroundColor: const Color(0xFF1E1E1E),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Guardar Perfil',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE2C792) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFFB58A3C) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1E1E1E)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: selected ? Colors.black87 : Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Color(0xFFB58A3C)),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final NutritionProfile profile;
  const _ResultCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final kcal = profile.targetCalories;
    final macros = profile.targetMacros;
    final perMeal = profile.caloriesPerMeal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: kcal == null
          ? const Text(
              'Completa sexo, fecha de nacimiento, altura y peso para calcular '
              'tus calorías y macros diarios.',
              style: TextStyle(color: Color(0xFF1E1E1E)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu objetivo diario (aprox.)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$kcal kcal / día',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB58A3C),
                  ),
                ),
                if (perMeal != null)
                  Text(
                    '≈ $perMeal kcal por comida (${profile.mealsPerDay} comidas)',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                const SizedBox(height: 12),
                if (macros != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Macro(label: 'Proteína', value: '${macros.protein} g'),
                      _Macro(label: 'Carbos', value: '${macros.carbs} g'),
                      _Macro(label: 'Grasa', value: '${macros.fat} g'),
                    ],
                  ),
              ],
            ),
    );
  }
}

class _Macro extends StatelessWidget {
  final String label;
  final String value;
  const _Macro({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1E1E1E),
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
    );
  }
}
