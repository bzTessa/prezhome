import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/nutrition_profile.dart';
import 'theme/app_theme.dart';
import 'widgets/miau_character.dart';

/// Cuestionario guiado paso a paso para crear el perfil nutricional la primera
/// vez. Recoge sexo, fecha de nacimiento, altura, peso, nivel de actividad y
/// objetivo en pantallas separadas y termina mostrando el objetivo de calorias
/// y macros calculados, guardando el perfil en Supabase.
///
/// El formulario clasico (NutritionProfileScreen) se conserva intacto para
/// editar ajustes mas adelante; este wizard es para la primera configuracion
/// y el onboarding.
///
/// API: si se pasa [onFinished], se invoca tras guardar con exito (la pantalla
/// que lo lanza decide a donde navegar). Si no se pasa, por defecto hace
/// Navigator.pop(context, true) para indicar que se completo el cuestionario.
class ProfileWizardScreen extends StatefulWidget {
  /// Callback opcional que se llama tras guardar el perfil con exito. Pensado
  /// para que el flujo de onboarding (FEAT-002) decida la navegacion siguiente
  /// (p. ej. ir a MainShell). Si es null, el wizard hace Navigator.pop(true).
  final VoidCallback? onFinished;

  const ProfileWizardScreen({super.key, this.onFinished});

  @override
  State<ProfileWizardScreen> createState() => _ProfileWizardScreenState();
}

class _ProfileWizardScreenState extends State<ProfileWizardScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  final PageController _controller = PageController();

  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _dislikedController = TextEditingController();

  // Numero total de pasos:
  // 0 bienvenida, 1 sexo, 2 fecha, 3 altura, 4 peso, 5 actividad, 6 objetivo,
  // 7 dieta, 8 alergias, 9 ingredientes a evitar, 10 tiempo de cocina,
  // 11 resultado.
  static const int _totalPages = 12;
  static const int _resultPage = 11;

  int _page = 0;

  String? _sex;
  DateTime? _birthDate;
  String _activity = 'moderate';
  String _goal = 'maintain';

  // Preferencias alimentarias (opcionales).
  String? _diet;
  final Set<String> _allergies = {};
  String? _cookTimePref;

  bool _saving = false;

  /// Alergias e intolerancias mas comunes que se ofrecen en el paso de
  /// alergias. En espanol y con tono cercano.
  static const List<String> _commonAllergies = [
    'frutos secos',
    'lactosa',
    'gluten',
    'huevo',
    'marisco',
    'soja',
    'pescado',
  ];

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  /// Carga el perfil actual de Supabase para precargar los campos que el
  /// usuario ya tenga configurados (mejor UX) y, sobre todo, para no perder el
  /// resto de datos del perfil: al guardar solo enviamos los campos del wizard.
  Future<void> _loadExisting() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      final data = await _client
          .from('profiles')
          .select(
            'sex, birth_date, height_cm, weight_kg, activity_level, goal, '
            'diet, allergies, disliked, cook_time_pref',
          )
          .eq('id', user.id)
          .maybeSingle();
      if (data == null || !mounted) return;
      final p = NutritionProfile.fromMap({'id': user.id, ...data});
      setState(() {
        _sex = p.sex;
        _birthDate = p.birthDate;
        if (p.heightCm != null) {
          _heightController.text = p.heightCm!.toStringAsFixed(0);
        }
        if (p.weightKg != null) {
          _weightController.text = p.weightKg!.toStringAsFixed(1);
        }
        _activity = p.activityLevel;
        _goal = p.goal;
        _diet = p.diet;
        _allergies
          ..clear()
          ..addAll(p.allergies);
        _dislikedController.text = p.disliked.join(', ');
        _cookTimePref = p.cookTimePref;
      });
    } catch (_) {
      // Si falla la precarga, el wizard sigue funcionando con los valores por
      // defecto; el guardado parcial no pisa el resto del perfil igualmente.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _dislikedController.dispose();
    super.dispose();
  }

  /// Perfil reconstruido desde los campos del wizard, para calcular y guardar.
  NutritionProfile _buildProfile() {
    final user = _client.auth.currentUser;
    return NutritionProfile(
      id: user?.id ?? '',
      sex: _sex,
      birthDate: _birthDate,
      heightCm: double.tryParse(
        _heightController.text.trim().replaceAll(',', '.'),
      ),
      weightKg: double.tryParse(
        _weightController.text.trim().replaceAll(',', '.'),
      ),
      activityLevel: _activity,
      goal: _goal,
    );
  }

  double? get _height =>
      double.tryParse(_heightController.text.trim().replaceAll(',', '.'));

  double? get _weight =>
      double.tryParse(_weightController.text.trim().replaceAll(',', '.'));

  /// Edad calculada a partir de la fecha de nacimiento elegida.
  int? get _age {
    if (_birthDate == null) return null;
    final now = DateTime.now();
    var years = now.year - _birthDate!.year;
    if (now.month < _birthDate!.month ||
        (now.month == _birthDate!.month && now.day < _birthDate!.day)) {
      years--;
    }
    return years;
  }

  /// ¿El paso actual tiene el dato obligatorio relleno?
  bool get _currentStepValid {
    switch (_page) {
      case 1:
        return _sex != null;
      case 2:
        return _birthDate != null;
      case 3:
        return _height != null && _height! > 0;
      case 4:
        return _weight != null && _weight! > 0;
      default:
        // Bienvenida, actividad, objetivo y resultado siempre validos.
        return true;
    }
  }

  String get _missingDataMessage {
    switch (_page) {
      case 1:
        return 'Elige una opcion para continuar.';
      case 2:
        return 'Selecciona tu fecha de nacimiento.';
      case 3:
        return 'Escribe una altura valida en centimetros.';
      case 4:
        return 'Escribe un peso valido en kilos.';
      default:
        return 'Completa este paso para continuar.';
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
    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  void _goBack() {
    if (_page == 0) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _goNext() {
    if (!_currentStepValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_missingDataMessage)));
      return;
    }
    if (_page >= _resultPage) return;
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// Convierte el texto libre de ingredientes a evitar (separado por comas) en
  /// una lista limpia, descartando espacios y entradas vacias.
  List<String> _parseDisliked() {
    return _dislikedController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
    });
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw 'No autenticado';
      // Update PARCIAL: solo los seis campos que recoge el wizard. Asi no
      // sobreescribimos otros datos del perfil (nombre, reparto de comidas,
      // modo de cocina, etc.) que el usuario pudiera tener ya configurados.
      await _client
          .from('profiles')
          .update({
            'sex': _sex,
            'birth_date': _birthDate?.toIso8601String().split('T').first,
            'height_cm': _height,
            'weight_kg': _weight,
            'activity_level': _activity,
            'goal': _goal,
            'diet': _diet,
            'allergies': _allergies.toList(),
            'disliked': _parseDisliked(),
            'cook_time_pref': _cookTimePref,
          })
          .eq('id', user.id);
      if (!mounted) return;
      if (widget.onFinished != null) {
        widget.onFinished!();
      } else {
        Navigator.of(context).pop(true);
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
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isResult = _page == _resultPage;
    final isLastDataStep = _page == _resultPage - 1;

    final String primaryLabel = isResult
        ? 'Empezar a usar PrezHome'
        : (isLastDataStep ? 'Ver mi objetivo' : 'Siguiente');

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Barra de progreso superior.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_page + 1) / _totalPages,
                  minHeight: 8,
                  backgroundColor: AppColors.wood.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.wood,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() {
                  _page = i;
                }),
                children: [
                  _buildWelcomeStep(),
                  _buildSexStep(),
                  _buildBirthDateStep(),
                  _buildHeightStep(),
                  _buildWeightStep(),
                  _buildActivityStep(),
                  _buildGoalStep(),
                  _buildDietStep(),
                  _buildAllergiesStep(),
                  _buildDislikedStep(),
                  _buildCookTimeStep(),
                  _buildResultStep(),
                ],
              ),
            ),
            // Botones inferiores: Atras (desde el paso 2) + principal.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  if (_page >= 1 && !isResult) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : _goBack,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          minimumSize: const Size.fromHeight(52),
                          side: const BorderSide(color: AppColors.wood),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Atras'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saving ? null : (isResult ? _save : _goNext),
                      child: _saving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.ink,
                                ),
                              ),
                            )
                          : Text(primaryLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Pasos del wizard ---

  Widget _stepScroll({required List<Widget> children}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _stepHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(fontSize: 15, height: 1.4, color: Colors.grey[700]),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MiauCharacter(mood: MiauMood.greeting, size: 180),
          const SizedBox(height: 32),
          const Text(
            'Vamos a conocerte',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Te hare unas preguntas rapidas para calcular tu objetivo diario de '
            'calorias y adaptar PrezHome a ti. Sera cortito, lo prometo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSexStep() {
    return _stepScroll(
      children: [
        _stepHeader(
          'Tu sexo',
          'Lo usamos para calcular tu metabolismo con mas precision.',
        ),
        _OptionCard(
          title: 'Mujer',
          icon: Icons.female,
          selected: _sex == 'female',
          onTap: () => setState(() {
            _sex = 'female';
          }),
        ),
        const SizedBox(height: 12),
        _OptionCard(
          title: 'Hombre',
          icon: Icons.male,
          selected: _sex == 'male',
          onTap: () => setState(() {
            _sex = 'male';
          }),
        ),
      ],
    );
  }

  Widget _buildBirthDateStep() {
    final hasDate = _birthDate != null;
    final dateText = hasDate
        ? '${_birthDate!.day.toString().padLeft(2, '0')}/'
              '${_birthDate!.month.toString().padLeft(2, '0')}/'
              '${_birthDate!.year}'
        : 'Seleccionar fecha';
    return _stepScroll(
      children: [
        _stepHeader(
          '¿Cuando naciste?',
          'La edad nos ayuda a afinar el calculo de calorias.',
        ),
        InkWell(
          onTap: _pickBirthDate,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: AppTheme.cardDecoration(radius: 20),
            child: Row(
              children: [
                const Icon(Icons.cake_outlined, color: AppColors.woodDark),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    dateText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: hasDate ? FontWeight.bold : FontWeight.normal,
                      color: hasDate ? AppColors.ink : Colors.grey[600],
                    ),
                  ),
                ),
                const Icon(Icons.edit_calendar_outlined, color: AppColors.wood),
              ],
            ),
          ),
        ),
        if (_age != null) ...[
          const SizedBox(height: 16),
          Center(
            child: Text(
              '$_age años',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.woodDark,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeightStep() {
    return _stepScroll(
      children: [
        _stepHeader('¿Cuanto mides?', 'Indica tu altura en centimetros.'),
        TextField(
          controller: _heightController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
          decoration: _numberDecoration('cm'),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildWeightStep() {
    return _stepScroll(
      children: [
        _stepHeader('¿Cuanto pesas?', 'Indica tu peso actual en kilos.'),
        TextField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
          decoration: _numberDecoration('kg'),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildActivityStep() {
    return _stepScroll(
      children: [
        _stepHeader(
          'Tu nivel de actividad',
          'Elige la opcion que mejor describa tu semana.',
        ),
        ...NutritionProfile.activityLabels.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OptionCard(
              title: e.value,
              selected: _activity == e.key,
              onTap: () => setState(() {
                _activity = e.key;
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalStep() {
    const descriptions = {
      'lose': 'Deficit suave para bajar de peso poco a poco.',
      'maintain': 'Mantener tu peso actual y sentirte bien.',
      'gain': 'Superavit suave para ganar masa de forma sana.',
    };
    return _stepScroll(
      children: [
        _stepHeader(
          '¿Cual es tu objetivo?',
          'Ajustaremos tus calorias segun lo que quieras conseguir.',
        ),
        ...NutritionProfile.goalLabels.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OptionCard(
              title: e.value,
              subtitle: descriptions[e.key],
              selected: _goal == e.key,
              onTap: () => setState(() {
                _goal = e.key;
              }),
            ),
          ),
        ),
      ],
    );
  }

  /// Iconos para cada tipo de dieta (todos existen en Flutter 3.47.6).
  static const Map<String, IconData> _dietIcons = {
    'omnivora': Icons.restaurant_menu,
    'vegetariana': Icons.eco,
    'vegana': Icons.spa,
    'pescetariana': Icons.set_meal,
    'baja_carbo': Icons.local_fire_department,
    'sin_gluten': Icons.grass,
  };

  Widget _buildDietStep() {
    return _stepScroll(
      children: [
        _stepHeader(
          '¿Como te alimentas?',
          'Elige el tipo de dieta que mejor va contigo. Asi te propondre '
              'recetas que encajen.',
        ),
        ...NutritionProfile.dietLabels.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OptionCard(
              title: e.value,
              icon: _dietIcons[e.key],
              selected: _diet == e.key,
              onTap: () => setState(() {
                _diet = e.key;
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAllergiesStep() {
    return _stepScroll(
      children: [
        _stepHeader(
          'Alergias o intolerancias',
          'Marca lo que debamos evitar. Si no tienes ninguna, pasa al '
              'siguiente paso sin problema.',
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _commonAllergies.map((allergy) {
            final selected = _allergies.contains(allergy);
            return FilterChip(
              label: Text(allergy),
              selected: selected,
              onSelected: (value) => setState(() {
                if (value) {
                  _allergies.add(allergy);
                } else {
                  _allergies.remove(allergy);
                }
              }),
              showCheckmark: false,
              backgroundColor: AppColors.card,
              selectedColor: AppColors.wood,
              side: BorderSide(
                color: selected ? AppColors.woodDark : Colors.transparent,
                width: 1.5,
              ),
              labelStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDislikedStep() {
    return _stepScroll(
      children: [
        _stepHeader(
          'Ingredientes que no te gustan',
          'Escribe los que prefieras evitar, separados por comas (p. ej. '
              'cebolla, cilantro). Es opcional.',
        ),
        TextField(
          controller: _dislikedController,
          textCapitalization: TextCapitalization.sentences,
          minLines: 2,
          maxLines: 4,
          style: const TextStyle(fontSize: 16, color: AppColors.ink),
          decoration: _textDecoration('cebolla, cilantro...'),
        ),
      ],
    );
  }

  Widget _buildCookTimeStep() {
    const descriptions = {
      'rapido': 'Platos resueltos en poco tiempo.',
      'normal': 'Un equilibrio entre rapido y elaborado.',
      'elaborado': 'Disfruto cocinando con calma.',
    };
    return _stepScroll(
      children: [
        _stepHeader(
          '¿Cuanto tiempo quieres cocinar?',
          'Asi ajusto las recetas a tu ritmo. Puedes dejarlo sin elegir.',
        ),
        ...NutritionProfile.cookTimeLabels.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OptionCard(
              title: e.value,
              subtitle: descriptions[e.key],
              selected: _cookTimePref == e.key,
              onTap: () => setState(() {
                _cookTimePref = e.key;
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultStep() {
    final profile = _buildProfile();
    final kcal = profile.targetCalories;
    final macros = profile.targetMacros;

    return _stepScroll(
      children: [
        const Center(
          child: MiauCharacter(mood: MiauMood.celebrating, size: 150),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'Tu objetivo diario',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.cardDecoration(),
          child: Column(
            children: [
              Text(
                kcal != null ? '$kcal' : '--',
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: AppColors.woodDark,
                ),
              ),
              const Text(
                'kcal / dia',
                style: TextStyle(fontSize: 16, color: AppColors.woodDark),
              ),
              if (macros != null) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MacroStat(label: 'Proteina', value: '${macros.protein} g'),
                    _MacroStat(label: 'Carbos', value: '${macros.carbs} g'),
                    _MacroStat(label: 'Grasa', value: '${macros.fat} g'),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Es una estimacion para empezar. Siempre puedes ajustarla desde tu '
          'perfil cuando quieras.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
        ),
      ],
    );
  }

  /// Decoracion simple de texto (sin sufijo) para campos libres como los
  /// ingredientes a evitar, coherente con la estetica Cozy.
  InputDecoration _textDecoration(String hint) => InputDecoration(
    filled: true,
    fillColor: AppColors.card,
    hintText: hint,
    hintStyle: TextStyle(fontSize: 15, color: Colors.grey[500]),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide.none,
    ),
  );

  InputDecoration _numberDecoration(String suffix) => InputDecoration(
    filled: true,
    fillColor: AppColors.card,
    suffixText: suffix,
    suffixStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: AppColors.woodDark,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide.none,
    ),
  );
}

/// Tarjeta seleccionable Cozy para las opciones del wizard (sexo, actividad,
/// objetivo).
class _OptionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? AppColors.wood : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.woodDark : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.softShadow,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.woodDark),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: selected ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.woodDark),
          ],
        ),
      ),
    );
  }
}

/// Columna con un valor de macro y su etiqueta, para la tarjeta de resultado.
class _MacroStat extends StatelessWidget {
  final String label;
  final String value;

  const _MacroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }
}
