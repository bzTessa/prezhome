import '../models/shopping_list_item.dart';
import '../widgets/food_category_icon.dart';

/// ¿El producto [ticketName] de un ticket es [listName] de la lista? Cada
/// palabra de la lista ha de estar en el ticket ("garbanzos" ⊂ "Garbanzos
/// cocidos"; "tomate" ~ "tomates").
bool ticketCovers(String ticketName, String listName) {
  List<String> words(String s) => CategoryIcons.normalize(
    s,
  ).split(RegExp(r'[^a-z0-9]+')).where((w) => w.length >= 3).toList();
  final ticket = words(ticketName);
  final list = words(listName);
  if (list.isEmpty) return false;
  // Igual o en plural: "tomate" ~ "tomates", pero "pan" no es "panceta".
  bool same(String a, String b) =>
      a == b || a == '${b}s' || a == '${b}es' || b == '${a}s' || b == '${a}es';
  return list.every((l) => ticket.any((t) => same(t, l)));
}

/// Registro reciente de productos pasados del carrito o ticket a "En casa",
/// para evitar duplicarlos si después se escanea el mismo ticket.
class RecentCheckoutRecord {
  const RecentCheckoutRecord({required this.at, required this.names});

  final DateTime at;
  final List<String> names;

  Map<String, dynamic> toJson() => {
    'at': at.toUtc().toIso8601String(),
    'names': names,
  };

  static RecentCheckoutRecord? fromJson(Map<String, dynamic> map) {
    final rawAt = map['at'];
    final at = rawAt is String ? DateTime.tryParse(rawAt) : null;
    final rawNames = map['names'];
    if (at == null || rawNames is! List) return null;
    final names = [
      for (final n in rawNames)
        if (n != null && n.toString().trim().isNotEmpty) n.toString().trim(),
    ];
    if (names.isEmpty) return null;
    return RecentCheckoutRecord(at: at.toLocal(), names: names);
  }
}

/// Descarta registros anteriores a [maxAge] para mantener el histórico ligero.
List<RecentCheckoutRecord> pruneRecentCheckouts(
  List<RecentCheckoutRecord> list,
  DateTime now, {
  Duration maxAge = const Duration(hours: 24),
}) {
  final cutoff = now.subtract(maxAge);
  return [
    for (final r in list)
      if (!r.at.isBefore(cutoff)) r,
  ];
}

/// Resultado de cruzar un ticket escaneado contra la lista/carrito y las
/// compras pasadas recientemente a despensa.
class TicketReconcileResult {
  const TicketReconcileResult({
    required this.alreadyInPantryIndices,
    required this.matchedListItems,
    required this.totalTicketItems,
  });

  /// Índices del ticket cuyos productos ya se guardaron en casa recientemente.
  final Set<int> alreadyInPantryIndices;

  /// Índice del ticket -> mejor fila coincidente de la lista/carrito
  /// (priorizando los marcados en el carrito) para heredar envase y medida.
  final Map<int, ShoppingListItem> matchedListItems;

  final int totalTicketItems;

  /// `true` cuando es muy probable que esta compra ya esté guardada en casa
  /// y añadir el ticket entero la duplicaría.
  bool get likelyAlreadySavedToPantry =>
      alreadyInPantryIndices.length >= 2 ||
      (totalTicketItems > 0 &&
          alreadyInPantryIndices.length * 2 >= totalTicketItems);
}

/// Cruza las líneas de un ticket con la lista actual y las guardadas recientes.
TicketReconcileResult reconcileTicket({
  required List<String> ticketNames,
  required List<ShoppingListItem> listItems,
  required List<RecentCheckoutRecord> recentCheckouts,
  required DateTime now,
  Duration window = const Duration(hours: 12),
}) {
  final cutoff = now.subtract(window);
  final recentNames = <String>[
    for (final r in recentCheckouts)
      if (!r.at.isBefore(cutoff)) ...r.names,
  ];

  final alreadyInPantry = <int>{};
  final matched = <int, ShoppingListItem>{};
  var nonEmptyCount = 0;

  for (var i = 0; i < ticketNames.length; i++) {
    final tName = ticketNames[i].trim();
    if (tName.isEmpty) continue;
    nonEmptyCount++;

    final isRecent = recentNames.any(
      (r) => ticketCovers(tName, r) || ticketCovers(r, tName),
    );
    if (isRecent) alreadyInPantry.add(i);

    ShoppingListItem? best;
    var bestScore = -1;
    final normTicket = CategoryIcons.normalize(tName);
    for (final item in listItems) {
      if (!(ticketCovers(tName, item.name) || ticketCovers(item.name, tName))) {
        continue;
      }
      var score = 0;
      if (item.checked) score += 100;
      if (item.packSize != null && item.packSize! > 0) score += 20;
      if (CategoryIcons.normalize(item.name) == normTicket) score += 10;
      if (score > bestScore) {
        bestScore = score;
        best = item;
      }
    }
    if (best != null) matched[i] = best;
  }

  return TicketReconcileResult(
    alreadyInPantryIndices: alreadyInPantry,
    matchedListItems: matched,
    totalTicketItems: nonEmptyCount,
  );
}
