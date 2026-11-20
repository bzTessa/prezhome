import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/inventory_item.dart';
import '../models/shopping_list_item.dart';
import '../utils/offline_actions.dart';
import '../utils/shopping_display.dart';
import '../utils/ticket_reconcile.dart';
import '../widgets/food_category_icon.dart';
import 'count_prefs.dart';
import 'file_local_store.dart';
import 'local_store.dart';
import 'offline_provider.dart';
import 'offline_repository.dart';
import 'pantry_usage.dart';
import 'shelf_life.dart';
import 'shelf_life_memory.dart';

export '../utils/ticket_reconcile.dart' show ticketCovers;

/// ¿Es [title] la tarea de hacer la compra? ("Hacer la compra", "Compra
/// semanal"…). Al completarla se da por comprada toda la lista.
bool isShoppingTask(String title) {
  final t = CategoryIcons.normalize(title);
  return RegExp(r'\bcompra(s)?\b').hasMatch(t);
}

/// Guarda en el dispositivo un histórico corto de los últimos envíos a
/// "En casa", para detectar si un ticket escaneado poco después ya fue
/// contabilizado y evitar duplicados.
class RecentCheckoutStore {
  RecentCheckoutStore({LocalStore? store})
    : _store = store ?? FileLocalStore(folderName: 'settings');

  final LocalStore _store;
  static const _key = 'recent_pantry_checkouts';

  Future<List<RecentCheckoutRecord>> load({DateTime? now}) async {
    try {
      final raw = await _store.read(_key);
      if (raw == null || raw.trim().isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final parsed = <RecentCheckoutRecord>[
        for (final e in decoded)
          if (e is Map)
            ?RecentCheckoutRecord.fromJson(Map<String, dynamic>.from(e)),
      ];
      return pruneRecentCheckouts(parsed, now ?? DateTime.now());
    } catch (_) {
      return const [];
    }
  }

  Future<void> record(List<String> names, {DateTime? now}) async {
    final clean = [
      for (final n in names)
        if (n.trim().isNotEmpty) n.trim(),
    ];
    if (clean.isEmpty) return;
    try {
      final ts = now ?? DateTime.now();
      final current = await load(now: ts);
      final updated = pruneRecentCheckouts([
        ...current,
        RecentCheckoutRecord(at: ts, names: clean),
      ], ts);
      await _store.write(
        _key,
        jsonEncode([for (final r in updated) r.toJson()]),
      );
    } catch (_) {
      // Best-effort: nunca bloquea terminar la compra o guardar un ticket.
    }
  }

  /// Elimina la entrada exacta registrada en [at] (para "Deshacer" compra).
  Future<void> removeAt(DateTime at) async {
    try {
      final targetIso = at.toUtc().toIso8601String();
      final current = await load(now: DateTime.now());
      final updated = [
        for (final r in current)
          if (r.at.toUtc().toIso8601String() != targetIso) r,
      ];
      await _store.write(
        _key,
        jsonEncode([for (final r in updated) r.toJson()]),
      );
    } catch (_) {
      // Best-effort.
    }
  }
}

/// Cambio individual hecho en "En casa" al guardar una compra, para poder
/// revertirlo con precisión al pulsar "Deshacer".
class PantryCheckoutChange {
  const PantryCheckoutChange({
    required this.inventoryId,
    required this.created,
    this.previousQuantity,
    this.previousUnit,
  });

  final String inventoryId;
  final bool created;
  final double? previousQuantity;
  final String? previousUnit;
}

/// Recibo de una operación "Guardar en casa" completo.
class PantryCheckoutResult {
  const PantryCheckoutResult({required this.changes, required this.recordAt});

  final List<PantryCheckoutChange> changes;
  final DateTime recordAt;

  int get count => changes.length;
}

/// Lo que ya estaba tachado al llegar el flujo carrito → "Guardar en casa".
/// Antes, tachar ya lo sumaba a la despensa, así que esas filas no se vuelven
/// a sumar al guardarlas. Se apunta una sola vez por dispositivo, antes del
/// primer cambio en el carrito.
class LegacyCartStore {
  LegacyCartStore({LocalStore? store})
    : _store = store ?? FileLocalStore(folderName: 'settings');

  final LocalStore _store;
  static const _key = 'legacy_cart_in_pantry';
  Set<String>? _cache;

  /// Ids de la lista que ya están en la despensa por el flujo antiguo. La
  /// primera vez los toma de lo tachado en [rows].
  Future<Set<String>> ids(
    Future<List<Map<String, dynamic>>> Function() rows,
  ) async {
    final cached = _cache;
    if (cached != null) return cached;
    try {
      final raw = await _store.read(_key);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return _cache = {for (final e in decoded) e.toString()};
        }
      }
      final legacy = {
        for (final r in await rows())
          if (r['checked'] == true && r['id'] != null) r['id'].toString(),
      };
      await _store.write(_key, jsonEncode(legacy.toList()));
      return _cache = legacy;
    } catch (_) {
      return _cache = <String>{};
    }
  }
}

/// Separa el carrito (tachar en el súper) del paso real a "En casa", evitando
/// duplicados al escanear el ticket y conservando gramos/envases del súper.
/// Funciona sin conexión: todo va por la cola local.
class ShoppingCheckout {
  ShoppingCheckout({
    OfflineRepository? shopping,
    OfflineRepository? inventory,
    SupabaseClient? client,
    RecentCheckoutStore? recentCheckouts,
    LegacyCartStore? legacyCart,
  }) : _shopping = shopping ?? OfflineProvider.instance.shopping,
       _inventory = inventory ?? OfflineProvider.instance.inventory,
       _client = client,
       _recentCheckouts = recentCheckouts ?? RecentCheckoutStore(),
       _legacyCart = legacyCart ?? _defaultLegacyCart;

  final OfflineRepository _shopping;
  final OfflineRepository _inventory;
  final SupabaseClient? _client;
  final RecentCheckoutStore _recentCheckouts;
  final LegacyCartStore _legacyCart;
  static final LegacyCartStore _defaultLegacyCart = LegacyCartStore();

  Future<Set<String>> _legacyIds() => _legacyCart.ids(_shopping.readCached);

  static int _seq = 0;
  int _nextSeq() => _seq++;

  SupabaseClient? _tryClient() {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Marca o desmarca [item] en el carrito sin tocar todavía la despensa.
  Future<void> setInCart(ShoppingListItem item, bool inCart) async {
    if (item.id == null) return;
    await _legacyIds();
    await _shopping.applyLocalWrite(
      buildUpdateOp(
        table: kShoppingTable,
        id: item.id!,
        changes: {'checked': inCart},
        nowMillis: DateTime.now().millisecondsSinceEpoch,
        seq: _nextSeq(),
      ),
    );
  }

  /// Pasa todos los pendientes de [listId] al carrito (sin guardarlos aún en
  /// "En casa").
  Future<int> markAllInCart({required String homeId, String? listId}) async {
    await _legacyIds();
    final rows = await _shopping.readCached();
    final pending = [
      for (final r in rows)
        if (r['checked'] != true && r['list_id'] == listId)
          ShoppingListItem.fromMap(r),
    ];
    for (final item in pending) {
      await setInCart(item, true);
    }
    return pending.length;
  }

  /// Guarda [items] en "En casa" una sola vez (respetando gramos y envases),
  /// registra sus nombres en [RecentCheckoutStore] y devuelve el recibo para
  /// poder deshacer la operación.
  Future<PantryCheckoutResult> checkoutToPantryWithReceipt(
    List<ShoppingListItem> items, {
    required String homeId,
  }) async {
    if (items.isEmpty) {
      return PantryCheckoutResult(changes: const [], recordAt: DateTime.now());
    }
    if ((await _inventory.readCached()).isEmpty && _tryClient() != null) {
      try {
        await _inventory.refreshFromRemote();
      } catch (_) {}
    }
    final changes = <PantryCheckoutChange>[];
    final legacy = await _legacyIds();
    for (final item in items) {
      // Tachado con la versión anterior: ya se sumó a la despensa entonces.
      if (item.id != null && legacy.contains(item.id)) continue;
      changes.add(await addToPantry(item, homeId: homeId));
    }
    final ts = DateTime.now();
    await _recentCheckouts.record([for (final i in items) i.name], now: ts);
    return PantryCheckoutResult(changes: changes, recordAt: ts);
  }

  /// Guarda [items] en "En casa" una sola vez (respetando gramos y envases) y
  /// registra sus nombres en [RecentCheckoutStore]. Devuelve cuántos guardó.
  Future<int> checkoutToPantry(
    List<ShoppingListItem> items, {
    required String homeId,
  }) async {
    final result = await checkoutToPantryWithReceipt(items, homeId: homeId);
    return result.count;
  }

  /// Revierte en "En casa" los cambios de un [checkoutToPantryWithReceipt] y
  /// quita el registro del histórico de tickets recientes.
  Future<void> undoCheckout(PantryCheckoutResult receipt) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final c in receipt.changes.reversed) {
      if (c.created) {
        await _inventory.applyLocalWrite(
          buildDeleteOp(
            table: kInventoryTable,
            id: c.inventoryId,
            nowMillis: now,
            seq: _nextSeq(),
          ),
        );
      } else {
        await _inventory.applyLocalWrite(
          buildUpdateOp(
            table: kInventoryTable,
            id: c.inventoryId,
            changes: {
              'quantity': c.previousQuantity,
              if (c.previousUnit != null) 'unit': c.previousUnit,
            },
            nowMillis: now,
            seq: _nextSeq(),
          ),
        );
      }
    }
    await _recentCheckouts.removeAt(receipt.recordAt);
  }

  /// Compatibilidad: marca [item] y, si [bought] es `true`, lo guarda en casa.
  Future<void> setBought(
    ShoppingListItem item,
    bool bought, {
    required String homeId,
  }) async {
    await setInCart(item, bought);
    if (bought) await checkoutToPantry([item], homeId: homeId);
  }

  /// Pasa toda la lista (pendientes y en carrito) a "En casa" una sola vez y
  /// limpia esas filas de la compra. Lo usa completar la tarea "Hacer la compra".
  Future<int> markAllBought({required String homeId, String? listId}) async {
    final rows = await _shopping.readCached();
    final targets = [
      for (final r in rows)
        if (r['list_id'] == listId) ShoppingListItem.fromMap(r),
    ];
    if (targets.isEmpty) return 0;
    final saved = await checkoutToPantry(targets, homeId: homeId);
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final item in targets) {
      if (item.id == null) continue;
      await _shopping.applyLocalWrite(
        buildDeleteOp(
          table: kShoppingTable,
          id: item.id!,
          nowMillis: now,
          seq: _nextSeq(),
        ),
      );
    }
    return saved;
  }

  /// Quita de la lista y del carrito los productos cubiertos por [ticketNames]
  /// (en sentido ticket -> lista, para no borrar "Chocolate con leche" cuando
  /// el ticket dice "Leche"). Si se pasa [listId], limita la limpieza a esa lista.
  Future<int> clearCoveredByTicket(
    List<String> ticketNames, {
    String? listId,
  }) async {
    final clean = [
      for (final t in ticketNames)
        if (t.trim().isNotEmpty) t.trim(),
    ];
    if (clean.isEmpty) return 0;
    final rows = await _shopping.readCached();
    var n = 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final r in rows) {
      if (listId != null && r['list_id'] != listId) continue;
      final item = ShoppingListItem.fromMap(r);
      if (item.id == null) continue;
      final cleanName = shoppingCleanName(item.name);
      final covered = clean.any((t) => ticketCovers(t, cleanName));
      if (!covered) continue;
      await _shopping.applyLocalWrite(
        buildDeleteOp(
          table: kShoppingTable,
          id: item.id!,
          nowMillis: now,
          seq: _nextSeq(),
        ),
      );
      n++;
    }
    return n;
  }

  /// Igual que [markAllBought] pero averigua el hogar del usuario.
  Future<int> markAllBoughtForCurrentUser() async {
    final client = _tryClient();
    final user = client?.auth.currentUser;
    if (client == null || user == null) return 0;
    final profile = await client
        .from('profiles')
        .select('home_id')
        .eq('id', user.id)
        .maybeSingle();
    final homeId = profile?['home_id'] as String?;
    if (homeId == null) return 0;
    return markAllBought(homeId: homeId);
  }

  /// Suma [item] a "En casa". Si ya hay un producto con ese nombre (del mismo
  /// tipo) y medida compatible, suma la cantidad; si llega en envases/unidades
  /// con tamaño de envase guardado en el hogar, lo convierte a gramos o ml.
  Future<PantryCheckoutChange> addToPantry(
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
    var addQty = item.boughtQuantity ?? 1;
    var addUnit = item.unit ?? 'unidades';
    var packSize = item.packSize;

    final customPack = CountPrefs.customPackOf(item.name);
    if (!isHome &&
        isPackUnit(addUnit) &&
        customPack != null &&
        customPack.size > 0) {
      addQty = addQty * customPack.size;
      addUnit = customPack.unit;
      packSize ??= customPack.size;
    }

    final existing = await _inventory.readCached();
    String? foundId;
    ({double quantity, String unit})? merged;
    double? foundPrevQty;
    String? foundUnit;
    for (final m in existing) {
      final rowIsHome = (m['item_type'] ?? 'comida').toString() == 'hogar';
      if (rowIsHome != isHome) continue;
      if (CategoryIcons.normalize((m['name'] ?? '').toString()) != nKey) {
        continue;
      }
      // Se suma en la medida de la despensa (1 bote + 570 g = 2 botes, no
      // "571 botes"). Si no se puede, va en otra fila.
      final prevQty = (m['quantity'] as num?)?.toDouble() ?? 0;
      foundUnit = (m['unit'] ?? 'unidades').toString();
      final effectivePack =
          packSize ??
          (customPack != null
              ? convertMeasure(customPack.size, customPack.unit, addUnit)
              : null);
      merged = mergePantryQuantity(
        prevQty,
        foundUnit,
        addQty,
        addUnit,
        packSize: effectivePack,
      );
      if (merged != null) {
        foundId = m['id'] as String?;
        foundPrevQty = prevQty;
        break;
      }
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    if (foundId != null && merged != null) {
      await _inventory.applyLocalWrite(
        buildUpdateOp(
          table: kInventoryTable,
          id: foundId,
          changes: {
            'quantity': merged.quantity,
            if (merged.unit != foundUnit) 'unit': merged.unit,
          },
          nowMillis: now,
          seq: _nextSeq(),
        ),
      );
      return PantryCheckoutChange(
        inventoryId: foundId,
        created: false,
        previousQuantity: foundPrevQty,
        previousUnit: foundUnit,
      );
    }

    final client = _tryClient();
    if (!isHome && client != null) await ShelfLifeMemory.ensureLoaded(client);
    final localId = newLocalId(nowMillis: now, seq: _nextSeq());
    final inv = InventoryItem(
      id: localId,
      homeId: homeId,
      name: item.name,
      category: zone,
      itemType: isHome ? 'hogar' : 'comida',
      quantity: addQty,
      unit: addUnit,
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
    return PantryCheckoutChange(inventoryId: localId, created: true);
  }
}
