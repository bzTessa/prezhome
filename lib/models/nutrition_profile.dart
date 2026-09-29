/// Perfil nutricional del usuario. Calcula las calorías y macros diarios
/// aproximados usando la fórmula Mifflin-St Jeor + factor de actividad.
class NutritionProfile {
  final String id; // = auth user id
  final String? fullName;
  final String? sex; // 'male' | 'female'
  final DateTime? birthDate;
  final double? heightCm;
  final double? weightKg;
  final String activityLevel; // sedentary..very_active
  final String goal; // maintain | lose | gain
  final int mealsPerDay;
  final bool isPublic;

  /// % de las calorías diarias por comida (breakfast/lunch/dinner/snack/dessert).
  final Map<String, int> mealSplit;

  NutritionProfile({
    required this.id,
    this.fullName,
    this.sex,
    this.birthDate,
    this.heightCm,
    this.weightKg,
    this.activityLevel = 'moderate',
    this.goal = 'maintain',
    this.mealsPerDay = 4,
    this.isPublic = false,
    Map<String, int>? mealSplit,
  }) : mealSplit = mealSplit ?? const {
         'breakfast': 20,
         'lunch': 40,
         'dinner': 40,
         'snack': 0,
         'dessert': 0,
       };

  factory NutritionProfile.fromMap(Map<String, dynamic> map) {
    return NutritionProfile(
      id: map['id'],
      fullName: map['full_name'],
      sex: map['sex'],
      birthDate: map['birth_date'] != null
          ? DateTime.tryParse(map['birth_date'])
          : null,
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      activityLevel: map['activity_level'] ?? 'moderate',
      goal: map['goal'] ?? 'maintain',
      mealsPerDay: (map['meals_per_day'] as int?) ?? 4,
      isPublic: map['is_public'] ?? false,
      mealSplit: _parseSplit(map['meal_split']),
    );
  }

  static Map<String, int>? _parseSplit(dynamic raw) {
    if (raw is Map) {
      return raw.map((k, v) =>
          MapEntry(k.toString(), (v as num?)?.round() ?? 0));
    }
    return null;
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'full_name': fullName,
      'sex': sex,
      'birth_date': birthDate?.toIso8601String().split('T').first,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'activity_level': activityLevel,
      'goal': goal,
      'meals_per_day': mealsPerDay,
      'is_public': isPublic,
      'meal_split': mealSplit,
    };
  }

  static const Map<String, String> activityLabels = {
    'sedentary': 'Sedentario (poco o nada de ejercicio)',
    'light': 'Ligero (1-3 días/semana)',
    'moderate': 'Moderado (3-5 días/semana)',
    'active': 'Activo (6-7 días/semana)',
    'very_active': 'Muy activo (ejercicio intenso o trabajo físico)',
  };

  static const Map<String, double> _activityFactor = {
    'sedentary': 1.2,
    'light': 1.375,
    'moderate': 1.55,
    'active': 1.725,
    'very_active': 1.9,
  };

  static const Map<String, String> goalLabels = {
    'maintain': 'Mantener peso',
    'lose': 'Perder peso',
    'gain': 'Ganar peso',
  };

  bool get isComplete =>
      sex != null &&
      birthDate != null &&
      heightCm != null &&
      heightCm! > 0 &&
      weightKg != null &&
      weightKg! > 0;

  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    var years = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      years--;
    }
    return years;
  }

  /// BMR (metabolismo basal) según Mifflin-St Jeor.
  double? get bmr {
    if (!isComplete || age == null) return null;
    final base = 10 * weightKg! + 6.25 * heightCm! - 5 * age!;
    return sex == 'male' ? base + 5 : base - 161;
  }

  /// TDEE = BMR × factor de actividad (calorías de mantenimiento).
  double? get maintenanceCalories {
    final b = bmr;
    if (b == null) return null;
    return b * (_activityFactor[activityLevel] ?? 1.55);
  }

  /// Calorías objetivo según el goal (aprox: -15% perder, +10% ganar).
  int? get targetCalories {
    final tdee = maintenanceCalories;
    if (tdee == null) return null;
    switch (goal) {
      case 'lose':
        return (tdee * 0.85).round();
      case 'gain':
        return (tdee * 1.10).round();
      default:
        return tdee.round();
    }
  }

  /// Reparto de macros aproximado: 30% proteína, 40% carbos, 30% grasa.
  /// Devuelve gramos diarios de cada macro.
  ({int protein, int carbs, int fat})? get targetMacros {
    final kcal = targetCalories;
    if (kcal == null) return null;
    final protein = (kcal * 0.30 / 4).round(); // 4 kcal/g
    final carbs = (kcal * 0.40 / 4).round();
    final fat = (kcal * 0.30 / 9).round(); // 9 kcal/g
    return (protein: protein, carbs: carbs, fat: fat);
  }

  /// Calorías objetivo por comida (repartidas entre las comidas del día).
  int? get caloriesPerMeal {
    final kcal = targetCalories;
    if (kcal == null || mealsPerDay <= 0) return null;
    return (kcal / mealsPerDay).round();
  }

  /// Calorías que te tocan para un tipo de comida concreto, según el reparto (%).
  /// Para recetas con varios tipos, usa el tipo de mayor %.
  int? caloriesForMealTypes(List<String> types) {
    final kcal = targetCalories;
    if (kcal == null || types.isEmpty) return null;
    // Elegimos el porcentaje más alto entre los tipos aplicables.
    int bestPct = 0;
    for (final t in types) {
      final pct = mealSplit[t] ?? 0;
      if (pct > bestPct) bestPct = pct;
    }
    if (bestPct == 0) return null;
    return (kcal * bestPct / 100).round();
  }

  static const List<String> splitOrder = [
    'breakfast',
    'lunch',
    'dinner',
    'snack',
    'dessert',
  ];

  static const Map<String, String> mealLabels = {
    'breakfast': 'Desayuno',
    'lunch': 'Comida',
    'dinner': 'Cena',
    'snack': 'Snack',
    'dessert': 'Postre',
  };

  /// Suma de porcentajes (para validar que sumen ~100).
  int get splitTotal =>
      mealSplit.values.fold(0, (a, b) => a + b);
}
