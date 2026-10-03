/// Lógica PURA para calcular las RACIONES por comida del plan del hogar.
///
/// No importa Flutter ni Supabase: solo recibe los datos que necesita y
/// devuelve números/etiquetas, de modo que sea fácil de testear con fechas
/// y configuraciones concretas.
///
/// Semántica (flexibilidad por encima de perfección):
/// - Cada miembro del hogar tiene un mapa [mealsAtHome] que dice en qué días
///   (1=Lun .. 7=Dom) hace cada comida EN CASA. Si una comida no aparece o su
///   lista está vacía, se asume que ese miembro come SIEMPRE en casa (por
///   defecto todos cuentan).
/// - Las raciones de una comida son el número de miembros que comen en casa
///   ese día/comida. Nunca es negativo; si por lo que sea nadie come en casa,
///   devolvemos 0 (quien genera el plan decide qué hacer con ello).
library;

/// Representa a un miembro del hogar de forma mínima para el cálculo de
/// raciones. [name] es el nombre a mostrar en la etiqueta; [isMe] marca al
/// usuario actual, que se muestra como "tú". [mealsAtHome] usa la misma
/// convención que `NutritionProfile.mealsAtHome` (clave = tipo de comida,
/// valor = días 1..7 en casa; vacío/ausente = todos los días).
class HouseholdMember {
  final String name;
  final bool isMe;
  final Map<String, List<int>> mealsAtHome;

  const HouseholdMember({
    required this.name,
    this.isMe = false,
    this.mealsAtHome = const {},
  });

  /// ¿Este miembro come la comida [type] en casa el día [weekday] (1=Lun..7=Dom)?
  /// Si no hay configuración para esa comida, se asume que sí.
  bool eatsAtHome(String type, int weekday) {
    final days = mealsAtHome[type];
    if (days == null || days.isEmpty) return true;
    return days.contains(weekday);
  }

  /// Etiqueta a mostrar: el usuario actual aparece como "tú".
  String get label => isMe ? 'tú' : name;
}

/// Resultado del cálculo de raciones de una comida: cuántas personas comen en
/// casa y sus etiquetas (en orden: primero "tú", luego el resto).
class ServingsResult {
  /// Número de miembros que comen en casa ese día/comida.
  final int count;

  /// Etiquetas de quienes comen en casa, "tú" primero. Ej.: ['tú', 'Pablo'].
  final List<String> names;

  const ServingsResult({required this.count, required this.names});

  /// Texto cozy para la UI, p.ej. "4 raciones: tú, Pablo". Si nadie come en
  /// casa devuelve "0 raciones". Usa "ración" en singular cuando toca.
  String get label {
    final unit = count == 1 ? 'ración' : 'raciones';
    if (names.isEmpty) return '$count $unit';
    return '$count $unit: ${names.join(', ')}';
  }
}

/// Calcula las raciones de la comida [type] para el día [weekday] (1=Lun..7=Dom)
/// dado el conjunto de [members] del hogar. El usuario actual (isMe) se coloca
/// primero en las etiquetas y se muestra como "tú".
ServingsResult servingsForMeal(
  List<HouseholdMember> members,
  String type,
  int weekday,
) {
  final eating = members.where((m) => m.eatsAtHome(type, weekday)).toList();
  // Orden EXPLÍCITO y determinista: "tú" (isMe) primero, luego el resto en el
  // mismo orden en que llegaron. No usamos List.sort porque Dart no garantiza
  // su estabilidad por contrato: construimos la lista a mano para que el orden
  // sea una garantía (p.ej. ['tú','Pablo','Ana']) y no un detalle del SDK.
  final ordered = <HouseholdMember>[
    ...eating.where((m) => m.isMe),
    ...eating.where((m) => !m.isMe),
  ];
  return ServingsResult(
    count: ordered.length,
    names: [for (final m in ordered) m.label],
  );
}

/// Atajo cuando solo interesa el número de raciones (sin etiquetas).
int servingsCountForMeal(
  List<HouseholdMember> members,
  String type,
  int weekday,
) {
  return members.where((m) => m.eatsAtHome(type, weekday)).length;
}
