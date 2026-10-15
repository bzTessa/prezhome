import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/inventory_item.dart';
import '../models/shopping_list_item.dart';
import '../utils/offline_actions.dart';
import '../widgets/food_category_icon.dart';
import 'offline_provider.dart';
import 'offline_repository.dart';
import 'shelf_life.dart';

/// ¿Es [title] la tarea de hacer la compra? ("Hacer la compra", "Compra
/// semanal"…). Al completarla se da por comprada toda la lista.
bool isShoppingTask(String title) {
  final t = CategoryIcons.normalize(title);
  return RegExp(r'\bcompra(s)?\b').hasMatch(t);
}

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

/// Pasa lo comprado de la lista a la despensa, cada cosa a su zona (nevera,
/// congelador, especias…). Funciona sin conexión: todo va por la cola local.
class ShoppingCheckout {
  ShoppingCheckout({
    OfflineRepository? shopping,
    OfflineRepository? inventory,
    SupabaseClient? client,
  }) : _shopping = shopping ?? OfflineProvider.instance.shopping,
       _inventory = inventory ?? OfflineProvider.instance.inventory,
       _client = client ?? Supabase.instance.client;

  final OfflineRepository _shopping;
  final OfflineRepository _inventory;
  final SupabaseClient _client;

  static int _seq = 0;
  int _nextSeq() => _seq++;

  /// Marca [item] como comprado (o no) y, si se compra, lo suma a la
  /// despensa.
  Future<void> setBought(
    ShoppingListItem item,
    bool bought, {
    required String homeId,
  }) async {
    if (item.id == null) return;
    await _shopping.applyLocalWrite(
      buildUpdateOp(
        table: kShoppingTable,
        id: item.id!,
        changes: {'checked': bought},
        nowMillis: DateTime.now().millisecondsSinceEpoch,
        seq: _nextSeq(),
      ),
    );
    // Al desmarcar no se quita de la despensa (ya está en casa).
    if (bought) await addToPantry(item, homeId: homeId);
  }

  /// Da por comprado todo lo pendiente de [listId] (null = lista principal).
  /// Devuelve cuántos productos pasaron a la despensa.
  Future<int> markAllBought({required String homeId, String? listId}) async {
    final rows = await _shopping.readCached();
    final pending = [
      for (final r in rows)
        if (r['checked'] != true && r['list_id'] == listId)
          ShoppingListItem.fromMap(r),
    ];
    for (final item in pending) {
      await setBought(item, true, homeId: homeId);
    }
    return pending.length;
  }

  /// Tacha de la lista lo que viene en un ticket, sin sumarlo otra vez a la
  /// despensa (de eso ya se encarga el ticket). Devuelve cuántos tachó.
  Future<int> markBoughtFromTicket(List<String> ticketNames) async {
    final rows = await _shopping.readCached();
    var n = 0;
    for (final r in rows) {
      final item = ShoppingListItem.fromMap(r);
      if (r['checked'] == true || item.id == null) continue;
      if (!ticketNames.any((t) => ticketCovers(t, item.name))) continue;
      await _shopping.applyLocalWrite(
        buildUpdateOp(
          table: kShoppingTable,
          id: item.id!,
          changes: {'checked': true},
          nowMillis: DateTime.now().millisecondsSinceEpoch,
          seq: _nextSeq(),
        ),
      );
      n++;
    }
    return n;
  }

  /// Igual que [markAllBought] pero averigua el hogar del usuario.
  Future<int> markAllBoughtForCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;
    final profile = await _client
        .from('profiles')
        .select('home_id')
        .eq('id', user.id)
        .maybeSingle();
    final homeId = profile?['home_id'] as String?;
    if (homeId == null) return 0;
    return markAllBought(homeId: homeId);
  }

  /// Suma [item] a la despensa. Si ya hay un producto con ese nombre (del
  /// mismo tipo) se suma la cantidad; si no, se crea en su zona con una
  /// caducidad estimada.
  Future<void> addToPantry(
    ShoppingListItem item, {
    required String homeId,
  }) async {
    final nKey = CategoryIcons.normalize(item.name);
    // La categoría de la compra es el pasillo; en la despensa va a su zona.
    final zone = ShelfLife.pantryZoneFor(
      name: item.name,
      itemType: item.itemType,
      category: item.category,
    );
    // Lo de limpieza o higiene apuntado como comida se guarda como de casa.
    final isHome =
        item.itemType == 'hogar' || zone == 'Limpieza' || zone == 'Hogar';
    final existing = await _inventory.readCached();
    String? foundId;
    double foundQty = 0;
    for (final m in existing) {
      final rowIsHome = (m['item_type'] ?? 'comida').toString() == 'hogar';
      if (rowIsHome != isHome) continue;
      if (CategoryIcons.normalize((m['name'] ?? '').toString()) == nKey) {
        foundId = m['id'] as String?;
        foundQty = (m['quantity'] as num?)?.toDouble() ?? 0;
        break;
      }
    }

    final addQty = item.quantity ?? 1;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (foundId != null) {
      await _inventory.applyLocalWrite(
        buildUpdateOp(
          table: kInventoryTable,
          id: foundId,
          changes: {'quantity': foundQty + addQty},
          nowMillis: now,
          seq: _nextSeq(),
        ),
      );
      return;
    }

    final localId = newLocalId(nowMillis: now, seq: _nextSeq());
    final inv = InventoryItem(
      id: localId,
      homeId: homeId,
      name: item.name,
      category: zone,
      itemType: isHome ? 'hogar' : 'comida',
      quantity: addQty,
      unit: item.unit ?? 'unidades',
      kind: 'ingredient',
      expirationDate: isHome ? null : ShelfLife.estimateDate(item.name, zone),
      imageUrl: item.imageUrl,
    );
    await _inventory.applyLocalWrite(
      buildInsertOp(
        table: kInventoryTable,
        id: localId,
        payload: inv.toCacheMap(),
        nowMillis: now,
        seq: _nextSeq(),
      ),
    );
  }
}
