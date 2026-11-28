import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/nutrition_profile.dart';
import '../models/supermarket.dart';
import '../utils/ticket_date.dart';
import 'streak.dart';

/// Lo gastado en un súper (6 meses).
class StoreSpend {
  const StoreSpend(this.name, this.total, this.tickets);
  final String name;
  final double total;
  final int tickets;
}

/// Un producto que ha cambiado de precio entre la primera y la última compra
/// en el mismo súper.
class PriceChange {
  const PriceChange(this.name, this.before, this.now, this.since);
  final String name;
  final double before, now;
  final DateTime since;
  double get pct => before <= 0 ? 0 : (now - before) / before * 100;
}

/// El mismo producto, más barato en un súper que en otro.
class CheaperAt {
  const CheaperAt(
    this.name,
    this.cheapStore,
    this.cheap,
    this.dearStore,
    this.dear,
  );
  final String name, cheapStore, dearStore;
  final double cheap, dear;
  double get saving => dear - cheap;
}

/// El ticket más caro.
class RecordTicket {
  const RecordTicket(this.amount, this.store, this.day);
  final double amount;
  final String? store;
  final DateTime day;
}

/// Aprovechado y tirado de un mes.
class WasteMonth {
  const WasteMonth(this.month, this.rescued, this.thrown);
  final DateTime month;
  final int rescued, thrown;
}

/// Calorías de la persona en los últimos 30 días.
class KcalStats {
  const KcalStats({
    required this.byDay,
    required this.target,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.topFoods,
  });

  /// Del más antiguo (hace 29 días) a hoy; 0 = sin apuntar.
  final List<double> byDay;
  final int? target;
  final double protein, carbs, fat;
  final List<(String, double)> topFoods;

  Iterable<double> get _logged => byDay.where((v) => v > 0);
  int get daysLogged => _logged.length;
  double get average =>
      daysLogged == 0 ? 0 : _logged.reduce((a, b) => a + b) / daysLogged;

  /// Días apuntados que quedaron dentro del objetivo (±10 %).
  int get daysOnTarget {
    final t = target;
    if (t == null || t <= 0) return 0;
    return _logged.where((v) => (v - t).abs() <= t * 0.1).length;
  }
}

/// Datos curiosos de la casa, sacados de lo que ya se apunta: tickets,
/// despensa, plan de comidas, tareas, diario y peso.
class FunStats {
  const FunStats({
    this.stores = const [],
    this.ticketsByWeekday = const [0, 0, 0, 0, 0, 0, 0],
    this.ticketCount = 0,
    this.avgTicket = 0,
    this.record,
    this.priceUps = const [],
    this.priceDowns = const [],
    this.cheaperAt = const [],
    this.boughtThisMonth = const [],
    this.distinctProducts = 0,
    this.topRecipes = const [],
    this.recipesThisMonth = 0,
    this.recipesLastMonth = 0,
    this.waste = const [],
    this.mostThrown = const [],
    this.topTasks = const [],
    this.tasksByDayPart = const [0, 0, 0],
    this.tasksByWeekday = const [0, 0, 0, 0, 0, 0, 0],
    this.activity = const {},
    this.streak = 0,
    this.bestStreak = 0,
    this.kcal,
    this.weights = const [],
  });

  // Dinero (6 meses).
  final List<StoreSpend> stores;

  /// Tickets por día de la semana, lunes primero.
  final List<double> ticketsByWeekday;
  final int ticketCount;
  final double avgTicket;
  final RecordTicket? record;
  final List<PriceChange> priceUps, priceDowns;
  final List<CheaperAt> cheaperAt;

  // Compra.
  /// Unidades compradas este mes por producto, de más a menos.
  final List<(String, double)> boughtThisMonth;

  /// Productos distintos comprados en 6 meses.
  final int distinctProducts;

  // Cocina (90 días).
  final List<(String, double)> topRecipes;
  final int recipesThisMonth, recipesLastMonth;

  // Despensa.
  /// Los 6 últimos meses, el actual al final.
  final List<WasteMonth> waste;
  final List<(String, double)> mostThrown;

  // Hogar (90 días).
  final List<(String, double)> topTasks;

  /// Mañana (antes de las 14 h), tarde (de 14 a 20 h) y noche.
  final List<double> tasksByDayPart;

  /// Tareas por día de la semana, lunes primero.
  final List<double> tasksByWeekday;

  // Tú.
  /// Cosas hechas por día (tareas y comidas apuntadas), últimas 12 semanas.
  final Map<DateTime, int> activity;
  final int streak, bestStreak;
  final KcalStats? kcal;
  final List<(DateTime, double)> weights;

  /// Índice (0 = lunes) del día con más tickets.
  int get busiestWeekday => _argMax(ticketsByWeekday);

  /// Índice (0 = lunes) del día con más tareas hechas.
  int get busiestTaskWeekday => _argMax(tasksByWeekday);

  /// 0 mañana, 1 tarde, 2 noche.
  int get favouriteDayPart => _argMax(tasksByDayPart);
  double get tasksTotal => tasksByDayPart.fold(0, (a, b) => a + b);

  /// Cuántos de cada 10 tickets son del súper de cabecera.
  int get topStoreShare {
    if (stores.isEmpty || ticketCount == 0) return 0;
    final top = stores.reduce((a, b) => b.tickets > a.tickets ? b : a);
    return (top.tickets / ticketCount * 10).round();
  }

  /// El súper donde más veces se compra.
  String? get usualStore => stores.isEmpty
      ? null
      : stores.reduce((a, b) => b.tickets > a.tickets ? b : a).name;

  int get rescuedThisMonth => waste.isEmpty ? 0 : waste.last.rescued;
  int get rescuedTotal => waste.fold(0, (a, w) => a + w.rescued);
  int get thrownTotal => waste.fold(0, (a, w) => a + w.thrown);

  static int _argMax(List<double> v) {
    var best = 0;
    for (var i = 1; i < v.length; i++) {
      if (v[i] > v[best]) best = i;
    }
    return best;
  }

  static String _cap(String s) {
    final t = s.trim();
    return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1).toLowerCase();
  }

  /// "MERCADONA, S.A." → "Mercadona"; lo desconocido, con mayúscula inicial.
  static String storeName(String? merchant) {
    final m = merchant?.trim() ?? '';
    if (m.isEmpty) return '';
    return Supermarket.fromMerchant(m)?.label ?? _cap(m);
  }

  static List<(String, double)> _top(Map<String, double> m, int max) {
    final list = m.entries.map((e) => (e.key, e.value)).toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return list.take(max).toList();
  }

  static DateTime _date(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Todo el cálculo, a partir de las filas ya leídas (sin red: se prueba).
  factory FunStats.fromRows({
    required DateTime now,
    Iterable<Map<String, dynamic>> tickets = const [],
    Iterable<Map<String, dynamic>> ticketItems = const [],
    Iterable<Map<String, dynamic>> meals = const [],
    Iterable<Map<String, dynamic>> pantryLog = const [],
    Iterable<Map<String, dynamic>> taskPoints = const [],
    Iterable<Map<String, dynamic>> foodLog = const [],
    Iterable<Map<String, dynamic>> weights = const [],
    Set<DateTime> myActivity = const {},
    int? kcalTarget,
    int bestStreak = 0,
  }) {
    final today = _date(now);
    final monthStart = DateTime(now.year, now.month);
    final lastMonthStart = DateTime(now.year, now.month - 1);

    // --- Tickets: por súper, día de la semana, ticket medio y récord.
    final storeTotal = <String, double>{};
    final storeCount = <String, int>{};
    final storeById = <String, String>{};
    final weekday = List<double>.filled(7, 0);
    var count = 0;
    var sum = 0.0;
    RecordTicket? record;
    for (final t in tickets) {
      final d = ticketDate(t);
      final amount = (t['total_amount'] as num?)?.toDouble() ?? 0;
      final store = storeName(t['merchant'] as String?);
      if (t['id'] != null && store.isNotEmpty) storeById['${t['id']}'] = store;
      if (d == null) continue;
      count++;
      sum += amount;
      weekday[d.weekday - 1]++;
      if (store.isNotEmpty) {
        storeTotal[store] = (storeTotal[store] ?? 0) + amount;
        storeCount[store] = (storeCount[store] ?? 0) + 1;
      }
      if (amount > 0 && (record == null || amount > record.amount)) {
        record = RecordTicket(amount, store.isEmpty ? null : store, d);
      }
    }
    final stores = [
      for (final e in storeTotal.entries)
        StoreSpend(e.key, e.value, storeCount[e.key] ?? 0),
    ]..sort((a, b) => b.total.compareTo(a.total));

    // --- Líneas de ticket: precios, dónde es más barato, lo comprado este mes.
    final bought = <String, double>{};
    final distinct = <String>{};
    // Producto → compras (fecha, precio por unidad, súper).
    final buys = <String, List<(DateTime, double, String?)>>{};
    for (final it in ticketItems) {
      final name = _cap((it['name'] as String?) ?? '');
      if (name.isEmpty) continue;
      distinct.add(name.toLowerCase());
      final ticket = it['tickets'] as Map?;
      final d = ticketDate({...?ticket, ...it});
      if (d == null) continue;
      final qty = (it['quantity'] as num?)?.toDouble() ?? 1;
      if (!d.isBefore(monthStart)) {
        // Lo que se pesa (0,456 kg) cuenta como una compra.
        final units = qty >= 1 && qty == qty.roundToDouble() ? qty : 1.0;
        bought[name] = (bought[name] ?? 0) + units;
      }
      final total = (it['total_price'] as num?)?.toDouble();
      final unit =
          (it['unit_price'] as num?)?.toDouble() ??
          (total != null && qty > 0 ? total / qty : null);
      if (unit == null || unit <= 0) continue;
      final store =
          storeById['${it['ticket_id']}'] ??
          (ticket == null ? '' : storeName(ticket['merchant'] as String?));
      (buys[name] ??= []).add((d, unit, store.isEmpty ? null : store));
    }

    final changes = <PriceChange>[];
    final cheaper = <CheaperAt>[];
    for (final e in buys.entries) {
      final list = e.value..sort((a, b) => a.$1.compareTo(b.$1));
      final byStore = <String?, List<(DateTime, double, String?)>>{};
      for (final b in list) {
        (byStore[b.$3] ??= []).add(b);
      }
      // Mismo súper y al menos 3 semanas entre la primera y la última compra.
      PriceChange? best;
      for (final s in byStore.values) {
        if (s.length < 2) continue;
        final first = s.first, last = s.last;
        if (last.$1.difference(first.$1).inDays < 21) continue;
        final c = PriceChange(e.key, first.$2, last.$2, first.$1);
        // Menos de un 3 % es ruido (redondeos); más del triple, otro formato.
        if (c.pct.abs() < 3 || c.pct > 200) continue;
        if (best == null || c.pct.abs() > best.pct.abs()) best = c;
      }
      if (best != null) changes.add(best);

      // Precio más reciente en cada súper.
      final latest = <String, double>{};
      for (final b in list) {
        if (b.$3 != null) latest[b.$3!] = b.$2;
      }
      if (latest.length >= 2) {
        final sorted = latest.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
        final lo = sorted.first, hi = sorted.last;
        // Un precio 3 veces mayor suele ser otro formato del producto.
        if (hi.value - lo.value >= 0.05 && hi.value <= lo.value * 3) {
          cheaper.add(CheaperAt(e.key, lo.key, lo.value, hi.key, hi.value));
        }
      }
    }
    final ups = changes.where((c) => c.pct > 0).toList()
      ..sort((a, b) => b.pct.compareTo(a.pct));
    final downs = changes.where((c) => c.pct < 0).toList()
      ..sort((a, b) => a.pct.compareTo(b.pct));
    cheaper.sort((a, b) => b.saving.compareTo(a.saving));

    // --- Lo que más se come del plan (sin las comidas fuera).
    final recipeCount = <String, double>{};
    final thisMonth = <String>{}, lastMonth = <String>{};
    for (final m in meals) {
      if (m['skipped'] == true) continue;
      final day = DateTime.tryParse('${m['plan_date']}');
      if (day == null || day.isAfter(today)) continue;
      final title = _cap(((m['recipes'] as Map?)?['title'] as String?) ?? '');
      if (title.isEmpty) continue;
      final id = '${m['recipe_id'] ?? title}';
      recipeCount[title] = (recipeCount[title] ?? 0) + 1;
      if (!day.isBefore(monthStart)) {
        thisMonth.add(id);
      } else if (!day.isBefore(lastMonthStart)) {
        lastMonth.add(id);
      }
    }

    // --- Aprovechado y tirado, por mes.
    final months = [
      for (int i = 5; i >= 0; i--) DateTime(now.year, now.month - i),
    ];
    final rescued = List<int>.filled(6, 0), thrown = List<int>.filled(6, 0);
    final thrownNames = <String, double>{};
    for (final r in pantryLog) {
      final day = DateTime.tryParse('${r['used_on']}');
      if (day == null || day.isAfter(today)) continue;
      final i = months.lastIndexWhere((m) => !day.isBefore(m));
      if (i < 0) continue;
      if (r['reason'] == 'tirado') {
        thrown[i]++;
        final n = _cap((r['name'] as String?) ?? '');
        if (n.isNotEmpty) thrownNames[n] = (thrownNames[n] ?? 0) + 1;
      } else if (r['rescued'] == true) {
        rescued[i]++;
      }
    }

    // --- Tareas: las que más se hacen, a qué hora y qué día.
    final taskCount = <String, double>{};
    final parts = List<double>.filled(3, 0);
    final taskDays = List<double>.filled(7, 0);
    for (final r in taskPoints) {
      final d = DateTime.tryParse('${r['created_at']}')?.toLocal();
      if (d == null) continue;
      parts[d.hour < 14 ? 0 : (d.hour < 20 ? 1 : 2)]++;
      taskDays[d.weekday - 1]++;
      final title = _cap(((r['tasks'] as Map?)?['title'] as String?) ?? '');
      if (title.isNotEmpty) taskCount[title] = (taskCount[title] ?? 0) + 1;
    }

    // --- Actividad de las 12 últimas semanas y racha.
    final from = today.subtract(const Duration(days: 83));
    final activity = <DateTime, int>{};
    for (final d in myActivity) {
      final day = _date(d);
      if (day.isBefore(from) || day.isAfter(today)) continue;
      activity[day] = (activity[day] ?? 0) + 1;
    }
    final streak = Streak.count(myActivity, now).days;

    // --- Calorías (30 días).
    KcalStats? kcal;
    final byDay = List<double>.filled(30, 0);
    var p = 0.0, c = 0.0, f = 0.0;
    final foods = <String, double>{};
    final firstDay = today.subtract(const Duration(days: 29));
    for (final e in foodLog) {
      final day = DateTime.tryParse('${e['log_date']}');
      if (day == null) continue;
      final i = _date(day).difference(firstDay).inDays;
      if (i < 0 || i > 29) continue;
      byDay[i] += (e['calories'] as num?)?.toDouble() ?? 0;
      p += (e['protein'] as num?)?.toDouble() ?? 0;
      c += (e['carbs'] as num?)?.toDouble() ?? 0;
      f += (e['fat'] as num?)?.toDouble() ?? 0;
      final n = _cap((e['name'] as String?) ?? '');
      if (n.isNotEmpty) foods[n] = (foods[n] ?? 0) + 1;
    }
    if (byDay.any((v) => v > 0)) {
      kcal = KcalStats(
        byDay: byDay,
        target: kcalTarget,
        protein: p,
        carbs: c,
        fat: f,
        topFoods: _top(foods, 3),
      );
    }

    final weightList = [
      for (final w in weights)
        if (DateTime.tryParse('${w['measured_on']}') case final DateTime d)
          (d, (w['weight_kg'] as num).toDouble()),
    ]..sort((a, b) => a.$1.compareTo(b.$1));

    return FunStats(
      stores: stores.take(6).toList(),
      ticketsByWeekday: weekday,
      ticketCount: count,
      avgTicket: count == 0 ? 0 : sum / count,
      record: record,
      priceUps: ups.take(3).toList(),
      priceDowns: downs.take(3).toList(),
      cheaperAt: cheaper.take(4).toList(),
      boughtThisMonth: _top(bought, 6),
      distinctProducts: distinct.length,
      topRecipes: _top(recipeCount, 5),
      recipesThisMonth: thisMonth.length,
      recipesLastMonth: lastMonth.length,
      waste: [
        for (int i = 0; i < 6; i++)
          WasteMonth(months[i], rescued[i], thrown[i]),
      ],
      mostThrown: _top(thrownNames, 3),
      topTasks: _top(taskCount, 5),
      tasksByDayPart: parts,
      tasksByWeekday: taskDays,
      activity: activity,
      streak: streak,
      bestStreak: streak > bestStreak ? streak : bestStreak,
      kcal: kcal,
      weights: weightList,
    );
  }

  /// Lee lo necesario del hogar y de la persona. Lo que falle se queda vacío:
  /// son curiosidades y no deben romper la pantalla.
  static Future<FunStats> load(
    SupabaseClient client,
    String homeId, {
    DateTime? now,
  }) async {
    final n = now ?? DateTime.now();
    final user = client.auth.currentUser;
    String day(DateTime d) => d.toIso8601String().split('T').first;
    final sixAgo = DateTime(n.year, n.month - 5);
    final ninety = n.subtract(const Duration(days: 90));

    Future<List<Map<String, dynamic>>> safe(
      String what,
      Future<List<Map<String, dynamic>>> Function() q,
    ) async {
      try {
        return await q();
      } catch (e) {
        debugPrint('fun_stats $what: $e');
        return const [];
      }
    }

    // PostgREST corta en 1000 filas: se pide por páginas (hasta 5000).
    Future<List<Map<String, dynamic>>> paged(
      PostgrestTransformBuilder<List<Map<String, dynamic>>> Function() q,
    ) async {
      final out = <Map<String, dynamic>>[];
      for (var page = 0; page < 5; page++) {
        final rows = await q().range(page * 1000, page * 1000 + 999);
        out.addAll(rows);
        if (rows.length < 1000) break;
      }
      return out;
    }

    final none = Future.value(const <Map<String, dynamic>>[]);
    final res = await Future.wait<List<Map<String, dynamic>>>([
      safe(
        'tickets',
        () => paged(
          () => client
              .from('tickets')
              .select('id, merchant, total_amount, purchased_at, created_at')
              .eq('home_id', homeId)
              .or(ticketRangeFilter(sixAgo, DateTime(n.year, n.month + 1)))
              .order('created_at'),
        ),
      ),
      safe(
        'ticket_items',
        () => paged(
          () => client
              .from('ticket_items')
              .select(
                'ticket_id, name, quantity, unit_price, total_price, '
                'created_at, tickets(merchant, purchased_at)',
              )
              .eq('home_id', homeId)
              .gte('created_at', day(sixAgo))
              .order('created_at'),
        ),
      ),
      safe(
        'meals',
        () => paged(
          () => client
              .from('meal_plan_entries')
              .select('plan_date, skipped, recipe_id, recipes(title)')
              .eq('home_id', homeId)
              .gte('plan_date', day(ninety))
              .lte('plan_date', day(n))
              .order('plan_date'),
        ),
      ),
      safe(
        'pantry_log',
        () => paged(
          () => client
              .from('pantry_log')
              .select('name, reason, rescued, used_on')
              .eq('home_id', homeId)
              .gte('used_on', day(sixAgo))
              .order('used_on'),
        ),
      ),
      safe(
        'task_points',
        () => paged(
          () => client
              .from('task_points')
              .select('user_id, created_at, tasks(title)')
              .eq('home_id', homeId)
              .gt('points', 0)
              .gte('created_at', ninety.toUtc().toIso8601String())
              .order('created_at'),
        ),
      ),
      user == null
          ? none
          : safe(
              'food_log',
              () => paged(
                () => client
                    .from('food_log_entries')
                    .select(
                      'log_date, name, calories, protein, carbs, fat, '
                      'created_at',
                    )
                    .eq('user_id', user.id)
                    .gte('log_date', day(ninety))
                    .order('log_date'),
              ),
            ),
      user == null
          ? none
          : safe(
              'weights',
              () => client
                  .from('weight_entries')
                  .select('measured_on, weight_kg')
                  .eq('user_id', user.id)
                  .gte(
                    'measured_on',
                    day(n.subtract(const Duration(days: 180))),
                  )
                  .order('measured_on'),
            ),
      user == null
          ? none
          : safe('profile', () async {
              final row = await client
                  .from('profiles')
                  .select()
                  .eq('id', user.id)
                  .maybeSingle();
              return [?row];
            }),
    ]);

    final tasks = res[4], food = res[5];
    // Lo mío, como la racha: mis tareas y lo que apunto en el diario.
    final mine = <DateTime>{
      for (final r in tasks)
        if (r['user_id'] == user?.id)
          if (DateTime.tryParse('${r['created_at']}') case final DateTime d)
            d.toLocal(),
      for (final r in food)
        if (DateTime.tryParse('${r['created_at']}') case final DateTime d)
          d.toLocal(),
    };
    int? target;
    if (res[7].isNotEmpty) {
      try {
        target = NutritionProfile.fromMap(res[7].first).targetCalories;
      } catch (e) {
        debugPrint('fun_stats target: $e');
      }
    }
    var best = 0;
    try {
      best = await Streak.best();
    } catch (e) {
      debugPrint('fun_stats best: $e');
    }
    return FunStats.fromRows(
      now: n,
      tickets: res[0],
      ticketItems: res[1],
      meals: res[2],
      pantryLog: res[3],
      taskPoints: tasks,
      foodLog: food,
      weights: res[6],
      myActivity: mine,
      kcalTarget: target,
      bestStreak: best,
    );
  }
}
