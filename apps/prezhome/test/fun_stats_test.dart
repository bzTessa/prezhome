import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:prezhome/l10n/app_localizations.dart';
import 'package:prezhome/models/supermarket.dart';
import 'package:prezhome/services/fun_stats.dart';
import 'package:prezhome/widgets/stats/fun_sections.dart';
import 'package:prezhome/widgets/stats/stat_charts.dart';

final now = DateTime(2026, 11, 28, 12);

/// Un hogar de ejemplo con un poco de todo.
FunStats sample() => FunStats.fromRows(
  now: now,
  tickets: [
    // 3 de Mercadona (dos en sábado) y 1 de Lidl (martes).
    {
      'id': 't1',
      'merchant': 'MERCADONA, S.A.',
      'total_amount': 54.2,
      'purchased_at': '2026-11-07',
    },
    {
      'id': 't2',
      'merchant': 'Mercadona',
      'total_amount': 120.5,
      'purchased_at': '2026-11-14',
    },
    {
      'id': 't3',
      'merchant': 'mercadona s.a.',
      'total_amount': 33,
      'purchased_at': '2026-08-01',
    },
    {
      'id': 't4',
      'merchant': 'LIDL SUPERMERCADOS S.A.U.',
      'total_amount': 40,
      'purchased_at': '2026-11-10',
    },
  ],
  ticketItems: [
    // Huevos: 2 este mes; el precio sube de 2,00 a 2,30 desde agosto.
    {
      'ticket_id': 't3',
      'name': 'HUEVOS',
      'quantity': 1,
      'unit_price': 2.0,
      'tickets': {'purchased_at': '2026-08-01'},
    },
    {
      'ticket_id': 't2',
      'name': 'Huevos',
      'quantity': 2,
      'unit_price': 2.3,
      'tickets': {'purchased_at': '2026-11-14'},
    },
    // Leche: más barata en Lidl.
    {
      'ticket_id': 't1',
      'name': 'Leche',
      'quantity': 6,
      'unit_price': 0.95,
      'tickets': {'purchased_at': '2026-11-07'},
    },
    {
      'ticket_id': 't4',
      'name': 'leche',
      'quantity': 1,
      'unit_price': 0.79,
      'tickets': {'purchased_at': '2026-11-10'},
    },
    // Lo que se pesa cuenta como una compra.
    {
      'ticket_id': 't2',
      'name': 'Plátanos',
      'quantity': 0.84,
      'total_price': 1.6,
      'tickets': {'purchased_at': '2026-11-14'},
    },
  ],
  meals: [
    for (final d in ['2026-11-02', '2026-11-09', '2026-11-16'])
      {
        'plan_date': d,
        'skipped': false,
        'recipe_id': 'r1',
        'recipes': {'title': 'Lentejas'},
      },
    {
      'plan_date': '2026-10-20',
      'skipped': false,
      'recipe_id': 'r2',
      'recipes': {'title': 'Tortilla'},
    },
    {
      'plan_date': '2026-11-20',
      'skipped': true,
      'recipe_id': 'r2',
      'recipes': {'title': 'Tortilla'},
    },
    // Futuro: no cuenta.
    {
      'plan_date': '2026-12-01',
      'skipped': false,
      'recipe_id': 'r2',
      'recipes': {'title': 'Tortilla'},
    },
  ],
  pantryLog: [
    {
      'name': 'Yogur',
      'reason': 'consumido',
      'rescued': true,
      'used_on': '2026-11-03',
    },
    {
      'name': 'Lechuga',
      'reason': 'tirado',
      'rescued': false,
      'used_on': '2026-11-05',
    },
    {
      'name': 'Lechuga',
      'reason': 'tirado',
      'rescued': false,
      'used_on': '2026-10-05',
    },
    {
      'name': 'Pan',
      'reason': 'tirado',
      'rescued': false,
      'used_on': '2026-09-05',
    },
  ],
  taskPoints: [
    for (var i = 0; i < 6; i++)
      {
        'user_id': 'u1',
        // Por la mañana (hora local).
        'created_at': DateTime(2026, 11, 20 + i, 9).toUtc().toIso8601String(),
        'tasks': {'title': i.isEven ? 'Fregar' : 'Poner lavadora'},
      },
    {
      'user_id': 'u1',
      'created_at': DateTime(2026, 11, 21, 22).toUtc().toIso8601String(),
      'tasks': {'title': 'Fregar'},
    },
  ],
  foodLog: [
    for (var i = 0; i < 5; i++)
      {
        'log_date': '2026-11-${24 + i}',
        'name': 'Tostada',
        'calories': 1800 + i * 100,
        'protein': 80,
        'carbs': 200,
        'fat': 60,
      },
  ],
  weights: [
    {'measured_on': '2026-10-01', 'weight_kg': 70.4},
    {'measured_on': '2026-11-27', 'weight_kg': 68.9},
  ],
  myActivity: {
    for (var i = 0; i < 4; i++) DateTime(2026, 11, 28 - i, 10),
    DateTime(2026, 9, 1, 10),
  },
  kcalTarget: 2000,
  bestStreak: 9,
);

void main() {
  test('el súper del ticket se reconoce aunque venga con razón social', () {
    expect(Supermarket.fromMerchant('MERCADONA, S.A.')?.label, 'Mercadona');
    expect(Supermarket.fromMerchant('Lidl Supermercados SAU')?.label, 'Lidl');
    expect(Supermarket.fromMerchant('DIA RETAIL ESPAÑA')?.label, 'Dia');
    // "dia" dentro de otra palabra no es Dia.
    expect(Supermarket.fromMerchant('Frutería Mediano'), isNull);
    expect(FunStats.storeName('frutería pepe'), 'Frutería pepe');
  });

  group('FunStats.fromRows', () {
    final s = sample();

    test('súper, día de compra, ticket medio y récord', () {
      expect(s.stores.first.name, 'Mercadona');
      expect(s.stores.first.tickets, 3);
      expect(s.usualStore, 'Mercadona');
      expect(s.topStoreShare, 8); // 3 de 4 → 7,5 → 8 de cada 10.
      expect(s.busiestWeekday, 5); // Sábado.
      expect(s.avgTicket, closeTo(61.93, 0.01));
      expect(s.record!.amount, 120.5);
      expect(s.record!.store, 'Mercadona');
    });

    test('precios que suben y dónde es más barato', () {
      expect(s.priceUps.single.name, 'Huevos');
      expect(s.priceUps.single.pct, closeTo(15, 0.01));
      expect(s.priceDowns, isEmpty);
      final milk = s.cheaperAt.single;
      expect(milk.name, 'Leche');
      expect(milk.cheapStore, 'Lidl');
      expect(milk.dearStore, 'Mercadona');
      expect(milk.saving, closeTo(0.16, 0.001));
    });

    test('lo comprado este mes cuenta unidades y lo pesado como una', () {
      expect(s.boughtThisMonth.first, ('Leche', 7.0));
      expect(s.boughtThisMonth, contains(('Huevos', 2.0)));
      expect(s.boughtThisMonth, contains(('Plátanos', 1.0)));
      expect(s.distinctProducts, 3);
    });

    test('recetas: sin comidas fuera ni futuras', () {
      expect(s.topRecipes.first, ('Lentejas', 3.0));
      expect(s.topRecipes, contains(('Tortilla', 1.0)));
      expect(s.recipesThisMonth, 1);
      expect(s.recipesLastMonth, 1);
    });

    test('aprovechado y tirado por mes, y lo que más se tira', () {
      expect(s.waste.length, 6);
      expect(s.waste.last.rescued, 1);
      expect(s.waste.last.thrown, 1);
      expect(s.thrownTotal, 3);
      expect(s.mostThrown.first, ('Lechuga', 2.0));
    });

    test('tareas: las que más se hacen y a qué hora', () {
      expect(s.topTasks.first, ('Fregar', 4.0));
      expect(s.tasksByDayPart, [6, 0, 1]);
      expect(s.favouriteDayPart, 0);
    });

    test('actividad, racha y mejor racha', () {
      expect(s.streak, 4);
      expect(s.bestStreak, 9);
      // Lo de septiembre queda fuera de las 12 semanas.
      expect(s.activity.length, 4);
    });

    test('calorías y peso', () {
      final k = s.kcal!;
      expect(k.daysLogged, 5);
      expect(k.average, 2000);
      expect(k.daysOnTarget, 5); // 1800..2200, todos a ±10 %.
      expect(s.weights.first.$2, 70.4);
    });

    test('sin datos no hay nada que contar', () {
      final e = FunStats.fromRows(now: now);
      expect(e.stores, isEmpty);
      expect(e.kcal, isNull);
      expect(e.topStoreShare, 0);
      expect(e.usualStore, isNull);
      expect(e.waste.every((w) => w.rescued == 0 && w.thrown == 0), isTrue);
    });
  });

  for (final reduce in [false, true]) {
    testWidgets('todas las tarjetas caben en un móvil (reducir movimiento: '
        '$reduce)', (tester) async {
      await initializeDateFormatting('es');
      Intl.defaultLocale = 'es';
      addTearDown(() => Intl.defaultLocale = null);
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
              child: Scaffold(
                body: Builder(
                  builder: (context) {
                    final f = FunSections(context, sample(), now: now);
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        ?f.facts(),
                        ?f.byStore(),
                        ?f.shopDays(),
                        ?f.prices(),
                        ?f.cheaper(),
                        ?f.boughtThisMonth(),
                        f.topRecipes(),
                        ?f.waste(),
                        ?f.topTasks(),
                        ?f.taskWhen(),
                        f.activity(),
                        ?f.kcal(),
                        ?f.weight(),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Datos curiosos'), findsOneWidget);
      expect(find.text('7 leche'), findsOneWidget);
      expect(find.text('Mercadona'), findsWidgets);
      expect(find.text('Sábado'), findsOneWidget);
      expect(find.text('De mañanas'), findsOneWidget);

      // El final de la lista también se pinta sin errores.
      await tester.scrollUntilVisible(
        find.text('Tu peso'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(TrendLine), findsWidgets);
    });
  }
}
