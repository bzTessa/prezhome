import 'dart:convert';

import 'dashboard_prefs.dart';

/// Respuestas del cuestionario inicial (antes de crear la cuenta). Se guardan
/// en el dispositivo y, cuando el usuario ya tiene hogar, se aplican a sus
/// preferencias (módulos, estilo de cocina, tarjetas de Inicio) y al hogar
/// (supermercados). Lógica PURA para poder testearla.

enum HousingType {
  piso('piso', 'Piso', 'En un edificio'),
  casa('casa', 'Casa', 'Con o sin jardín'),
  compartido('compartido', 'Piso compartido', 'Con compañeros o residencia');

  const HousingType(this.id, this.label, this.subtitle);
  final String id;
  final String label;
  final String subtitle;
}

/// Lo que la persona quiere quitarse de la cabeza. Cada objetivo activa
/// partes concretas de la app.
enum HomeGoal {
  comidas('comidas', 'Qué comemos', 'Plan de comidas y recetas'),
  compra('compra', 'La compra', 'Lista que se escribe sola'),
  despensa('despensa', 'Lo que hay en casa', 'Despensa, nevera y caducidades'),
  tareas('tareas', 'Tareas del hogar', 'Reparto justo y recordatorios'),
  lote('lote', 'Cocinar en lote', 'Tuppers y congelador organizados'),
  gastos('gastos', 'El gasto de la casa', 'Presupuesto y tickets');

  const HomeGoal(this.id, this.label, this.subtitle);
  final String id;
  final String label;
  final String subtitle;
}

enum CookingHabit {
  diario('diario', 'Cada día', 'Cocino lo del momento'),
  lote('lote', 'En lote', 'Preparo varios días de una vez'),
  mixto('mixto', 'Un poco de todo', 'Algunos días en lote'),
  poco('poco', 'Casi nunca', 'Como fuera o algo rápido');

  const CookingHabit(this.id, this.label, this.subtitle);
  final String id;
  final String label;
  final String subtitle;
}

enum ShoppingFrequency {
  pocosDias('pocos_dias', 'Cada pocos días', '2-3 veces por semana', 3),
  semanal('semanal', 'Una vez por semana', 'La compra grande del finde', 7),
  quincenal('quincenal', 'Cada dos semanas', 'Compra grande y reposición', 14),
  mensual('mensual', 'Una vez al mes', 'Gran compra mensual', 30);

  const ShoppingFrequency(this.id, this.label, this.subtitle, this.days);
  final String id;
  final String label;
  final String subtitle;

  /// Días que debería cubrir la lista de la compra.
  final int days;
}

/// Resultado del cuestionario que se enseña al final.
class HouseholdProfile {
  const HouseholdProfile({
    required this.name,
    required this.description,
    required this.loadToday,
    required this.loadWithApp,
  });

  final String name;
  final String description;

  /// Carga mental estimada hoy y con la app, de 1 a 10.
  final int loadToday;
  final int loadWithApp;
}

class OnboardingAnswers {
  const OnboardingAnswers({
    this.housing,
    this.people = 2,
    this.goals = const {},
    this.cooking,
    this.supermarkets = const [],
    this.shopping,
    this.reminders = true,
  });

  final HousingType? housing;
  final int people;
  final Set<HomeGoal> goals;
  final CookingHabit? cooking;

  /// Claves de `Supermarket` en el orden elegido (el primero es el principal).
  final List<String> supermarkets;
  final ShoppingFrequency? shopping;
  final bool reminders;

  static const String storageKey = 'onboarding_answers';

  OnboardingAnswers copyWith({
    HousingType? housing,
    int? people,
    Set<HomeGoal>? goals,
    CookingHabit? cooking,
    List<String>? supermarkets,
    ShoppingFrequency? shopping,
    bool? reminders,
  }) => OnboardingAnswers(
    housing: housing ?? this.housing,
    people: people ?? this.people,
    goals: goals ?? this.goals,
    cooking: cooking ?? this.cooking,
    supermarkets: supermarkets ?? this.supermarkets,
    shopping: shopping ?? this.shopping,
    reminders: reminders ?? this.reminders,
  );

  // ---- Perfil de hogar ------------------------------------------------------

  HouseholdProfile get profile {
    final String name;
    final String description;
    if (housing == HousingType.compartido) {
      name = 'El Piso Compartido';
      description =
          'Varias personas, cada una con su ritmo. PrezHome deja claro quién '
          'hace qué y qué hay en la nevera, sin notas en la puerta.';
    } else if (people <= 1) {
      name = 'En Solitario';
      description =
          'Toda la casa depende de ti. PrezHome se acuerda de lo que hay, lo '
          'que caduca y lo que toca, para que tú no tengas que hacerlo.';
    } else if (people == 2) {
      name = 'El Dúo';
      description =
          'Dos personas y una casa. PrezHome reparte la carga a la vista, '
          'para que nadie lleve la cuenta de todo en la cabeza.';
    } else {
      name = people >= 5 ? 'La Tribu' : 'La Familia';
      description =
          'Muchas bocas y muchas cosas a la vez. PrezHome planifica comidas, '
          'compra y tareas para todos, y avisa a cada uno de lo suyo.';
    }
    final today = (3 + goals.length + (people - 1).clamp(0, 3)).clamp(3, 10);
    final withApp = (today - goals.length - 1).clamp(2, today);
    return HouseholdProfile(
      name: name,
      description: description,
      loadToday: today,
      loadWithApp: withApp,
    );
  }

  // ---- Aplicar a la app -------------------------------------------------------

  /// Preferencias de la app según las respuestas, partiendo de [base]. Sin
  /// objetivos elegidos se deja [base] tal cual (todo visible).
  DashboardPrefs applyTo(DashboardPrefs base) {
    final cookingStyle = switch (cooking) {
      CookingHabit.lote => CookingStyle.batch,
      CookingHabit.mixto => CookingStyle.mixed,
      _ => CookingStyle.daily,
    };
    if (goals.isEmpty) return base.copyWith(cookingStyle: cookingStyle);

    final modules = <HomeModule>{
      if (goals.contains(HomeGoal.tareas)) HomeModule.tasks,
      if (goals.contains(HomeGoal.tareas) && people >= 2) HomeModule.points,
      if (goals.contains(HomeGoal.lote) ||
          cooking == CookingHabit.lote ||
          cooking == CookingHabit.mixto)
        HomeModule.batchCooking,
    };

    final hidden = <DashboardCard>{
      if (!goals.contains(HomeGoal.comidas)) DashboardCard.meals,
      if (!goals.contains(HomeGoal.comidas)) DashboardCard.calories,
      if (!goals.contains(HomeGoal.despensa)) DashboardCard.expiry,
      if (!goals.contains(HomeGoal.tareas)) DashboardCard.tasks,
      if (!goals.contains(HomeGoal.gastos)) DashboardCard.spending,
    };

    final quick = <QuickAction>[
      if (goals.contains(HomeGoal.compra)) QuickAction.shopping,
      if (goals.contains(HomeGoal.despensa)) QuickAction.addInventory,
      if (goals.contains(HomeGoal.comidas)) QuickAction.mealPlan,
      if (goals.contains(HomeGoal.gastos)) QuickAction.scanTicket,
      if (goals.contains(HomeGoal.lote)) QuickAction.addRecipe,
    ];

    return base.copyWith(
      enabledModules: modules,
      hidden: hidden,
      quick: quick.isEmpty ? base.quick : quick.take(3).toList(),
      cookingStyle: cookingStyle,
    );
  }

  // ---- Guardado ----------------------------------------------------------------

  String encode() => jsonEncode({
    'housing': housing?.id,
    'people': people,
    'goals': goals.map((g) => g.id).toList(),
    'cooking': cooking?.id,
    'supermarkets': supermarkets,
    'shopping': shopping?.id,
    'reminders': reminders,
  });

  /// Tolerante: null si no hay datos o están corruptos.
  static OnboardingAnswers? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw);
      if (m is! Map) return null;
      T? byId<T>(List<T> values, String Function(T) id, Object? v) {
        for (final x in values) {
          if (id(x) == v) return x;
        }
        return null;
      }

      return OnboardingAnswers(
        housing: byId(HousingType.values, (h) => h.id, m['housing']),
        people: (m['people'] is int) ? (m['people'] as int).clamp(1, 12) : 2,
        goals: {
          for (final g in (m['goals'] is List ? m['goals'] as List : const []))
            ?byId(HomeGoal.values, (x) => x.id, g),
        },
        cooking: byId(CookingHabit.values, (c) => c.id, m['cooking']),
        supermarkets: (m['supermarkets'] is List)
            ? (m['supermarkets'] as List).map((e) => e.toString()).toList()
            : const [],
        shopping: byId(ShoppingFrequency.values, (s) => s.id, m['shopping']),
        reminders: m['reminders'] != false,
      );
    } catch (_) {
      return null;
    }
  }
}
