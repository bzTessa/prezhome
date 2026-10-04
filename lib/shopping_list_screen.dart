import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/ingredient.dart';
import 'models/inventory_item.dart';
import 'models/shopping_list_item.dart';
import 'services/food_photo_service.dart';
import 'services/price_memory.dart';
import 'services/shelf_life.dart';
import 'theme/app_motion.dart';
import 'theme/app_theme.dart';
import 'utils/shopping_celebration.dart';
import 'utils/shopping_display.dart';
import 'widgets/animations/confetti.dart';
import 'widgets/food_category_icon.dart';
import 'widgets/food_image.dart';
import 'widgets/miau_character.dart';

/// Lista de la compra del hogar (compartida por RLS).
///
/// Muestra los items pendientes y, debajo, los ya comprados (atenuados).
/// Permite anadir cosas a mano, marcarlas como compradas, borrarlas y
/// generar la lista automaticamente a partir del plan semanal de comidas:
/// junta los ingredientes de las recetas planificadas de la semana y descuenta
/// lo que ya hay en el inventario cuando el match es fiable.
class ShoppingListScreen extends StatefulWidget {
  final bool embedded;
  const ShoppingListScreen({super.key, this.embedded = false});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  late Future<List<ShoppingListItem>> _itemsFuture;
  bool _generating = false;

  // Panel "YA EN EL CARRO" colapsable: arranca COLAPSADO porque lo ya comprado
  // deja de ser urgente (NN/g: lo que no apremia no debe ocupar scroll). La
  // usuaria puede desplegarlo para desmarcar o borrar.
  bool _cartExpanded = false;

  // Overrides manuales de expandido/colapsado por categoría de la compra
  // (clave = FoodCategory.name). Las categorías de pendientes arrancan TODAS
  // expandidas (lo que falta por comprar sí apremia); lo que la usuaria plega a
  // mano se recuerda aquí mientras la pantalla viva.
  final Map<String, bool> _catCollapsed = {};

  // Precios conocidos del hogar (para estimar el coste de la compra).
  Map<String, ProductPrice> _prices = {};

  // Guarda para disparar la celebración (Miau + confeti) SOLO en la transición
  // a 0 pendientes (de >0 a 0), no en cada rebuild ni al cambiar de tab en el
  // IndexedStack. La detección de la transición es lógica PURA
  // (ShoppingCelebrationGate) y ocurre al COMPLETAR el fetch, NO dentro de
  // build(): así un rebuild que no cambia el conteo (p. ej. borrar un comprado
  // estando ya en 0 pendientes) no reproduce el confeti. El flag se CONSUME al
  // construir el sliver para no repetir el rebote.
  final ShoppingCelebrationGate _celebrationGate = ShoppingCelebrationGate();

  @override
  void initState() {
    super.initState();
    _itemsFuture = _fetch();
  }

  Future<List<ShoppingListItem>> _fetch() async {
    // RLS filtra por el hogar del usuario. Primero los pendientes y, dentro de
    // cada grupo, por orden de creacion.
    final res = await _client
        .from('shopping_list_items')
        .select()
        .order('checked', ascending: true)
        .order('created_at', ascending: true);

    // Cargamos los precios conocidos del hogar (best-effort) para estimar el
    // coste de la compra. No bloquea la lista si falla.
    try {
      final homeId = await _homeId();
      _prices = await PriceMemory(_client).loadAll(homeId);
    } catch (_) {
      _prices = {};
    }

    final items = (res as List)
        .map((m) => ShoppingListItem.fromMap(m as Map<String, dynamic>))
        .toList();

    // Detección de la transición a 0 pendientes FUERA de build(): al resolver
    // el fetch registramos los conteos en el gate puro. Si representa la
    // transición de >0 a 0 con comprados, queda una celebración pendiente que
    // build() consumirá UNA sola vez (sin replay en rebuilds posteriores).
    final nPend = items.where((i) => !i.checked).length;
    final hayComprados = items.any((i) => i.checked);
    _celebrationGate.registerFetch(
      currentPending: nPend,
      hasPurchased: hayComprados,
    );

    return items;
  }

  void _reload() {
    // Nunca usar arrow con un Future: calculamos antes y luego setState.
    final f = _fetch();
    setState(() {
      _itemsFuture = f;
    });
  }

  /// Obtiene el home_id del usuario autenticado leyendo su perfil.
  Future<String> _homeId() async {
    final user = _client.auth.currentUser;
    if (user == null) throw 'No hay usuario autenticado';
    final profile = await _client
        .from('profiles')
        .select('home_id')
        .eq('id', user.id)
        .single();
    final homeId = profile['home_id'] as String?;
    if (homeId == null) throw 'El usuario no esta asignado a ningun hogar.';
    return homeId;
  }

  Future<void> _toggleChecked(ShoppingListItem item, bool value) async {
    if (item.id == null) return;
    try {
      await _client
          .from('shopping_list_items')
          .update({'checked': value})
          .eq('id', item.id!);
      // Al marcar como comprado, el producto pasa SOLO a la despensa (dedup por
      // nombre). Al desmarcar no lo quitamos del inventario (ya está en casa).
      if (value) {
        await _addToPantry(item);
      }
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Mete un artículo comprado en el inventario (despensa). Deduplica por
  /// nombre normalizado: si ya existe (en cualquier ubicación de comida), suma
  /// la cantidad; si no, crea uno nuevo en Despensa con caducidad estimada.
  /// Best-effort: si algo falla, no rompe el marcado como comprado.
  Future<void> _addToPantry(ShoppingListItem item) async {
    try {
      final homeId = await _homeId();
      final nKey = CategoryIcons.normalize(item.name);
      final isHome = item.itemType == 'hogar';

      final existing = await _client
          .from('inventory_items')
          .select('id, name, quantity, item_type')
          .eq('home_id', homeId);

      // Dedup por nombre DENTRO del mismo tipo (no fusionar comida con hogar).
      String? foundId;
      double foundQty = 0;
      for (final row in (existing as List)) {
        final m = row as Map<String, dynamic>;
        final rowIsHome = (m['item_type'] ?? 'comida').toString() == 'hogar';
        if (rowIsHome != isHome) continue;
        if (CategoryIcons.normalize((m['name'] ?? '').toString()) == nKey) {
          foundId = m['id'] as String?;
          foundQty = (m['quantity'] as num?)?.toDouble() ?? 0;
          break;
        }
      }

      final addQty = item.quantity ?? 1;
      if (foundId != null) {
        await _client
            .from('inventory_items')
            .update({'quantity': foundQty + addQty})
            .eq('id', foundId);
      } else {
        // Ubicación: hogar -> 'Hogar'; comida -> la elegida (item.category) o,
        // si no hay, la deducida por el alimento. Caducidad solo para comida.
        final String location;
        if (isHome) {
          location = item.category ?? 'Hogar';
        } else {
          location = item.category ?? ShelfLife.suggestLocation(item.name);
        }
        final estimated = isHome
            ? null
            : ShelfLife.estimateDate(item.name, location);
        final inv = InventoryItem(
          id: '',
          homeId: homeId,
          name: item.name,
          category: location,
          itemType: item.itemType,
          quantity: addQty,
          unit: item.unit ?? 'unidades',
          kind: 'ingredient',
          expirationDate: estimated,
          imageUrl: item.imageUrl,
        );
        await _client.from('inventory_items').insert(inv.toMap());
      }
    } catch (e) {
      debugPrint('ShoppingList._addToPantry error: $e');
    }
  }

  Future<void> _deleteItem(ShoppingListItem item) async {
    if (item.id == null) return;
    try {
      await _client.from('shopping_list_items').delete().eq('id', item.id!);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo eliminar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Menú de acciones de un artículo (pulsación larga): cambiar foto o borrar.
  Future<void> _openItemActions(ShoppingListItem item) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.ink,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.woodDark,
              ),
              title: const Text('Elegir foto de la galería'),
              onTap: () => Navigator.of(ctx).pop('gallery'),
            ),
            ListTile(
              leading: const Icon(
                Icons.auto_awesome,
                color: AppColors.woodDark,
              ),
              title: const Text('Buscar otra foto automática'),
              onTap: () => Navigator.of(ctx).pop('auto'),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
              ),
              title: const Text('Quitar de la lista'),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'gallery':
        await _pickPhoto(item);
        break;
      case 'auto':
        await _regenPhoto(item);
        break;
      case 'delete':
        await _deleteItem(item);
        break;
    }
  }

  /// Sube una foto de la galería al bucket y la fija como foto del artículo.
  /// El bucket recipe-images se reutiliza (ya tiene políticas públicas).
  Future<void> _pickPhoto(ShoppingListItem item) async {
    if (item.id == null) return;
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        imageQuality: 82,
      );
      if (file == null) return;
      final homeId = await _homeId();
      final bytes = await file.readAsBytes();
      final ext = file.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      final path = '$homeId/shop_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _client.storage
          .from('recipe-images')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
              upsert: false,
            ),
          );
      final url = _client.storage.from('recipe-images').getPublicUrl(path);
      await _client
          .from('shopping_list_items')
          .update({'image_url': url})
          .eq('id', item.id!);
      // Memorizamos la foto para ese alimento en la caché del hogar, de modo
      // que la próxima vez (y en la despensa) se reutilice.
      await FoodPhotoService(
        _client,
      ).rememberPhoto(homeId: homeId, name: item.name, url: url);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo subir la foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Vuelve a buscar una foto automática para el artículo.
  Future<void> _regenPhoto(ShoppingListItem item) async {
    if (item.id == null) return;
    try {
      final homeId = await _homeId();
      final url = await FoodPhotoService(_client).resolvePhotoUrl(
        homeId: homeId,
        name: item.name,
        mode: item.itemType == 'comida' ? 'ingredient' : 'dish',
      );
      if (url == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No encontré una foto. Puedes poner una tuya.'),
          ),
        );
        return;
      }
      await _client
          .from('shopping_list_items')
          .update({'image_url': url})
          .eq('id', item.id!);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cambiar la foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Botón de elección de tipo (comida/hogar) para el diálogo de alta.
  Widget _typeChoice(
    String value,
    String label,
    IconData icon,
    String current,
    ValueChanged<String> onTap,
  ) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.wood : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.woodDark : AppColors.wood,
            width: 1.3,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.ink),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog de alta manual: nombre + cantidad/unidad + tipo (comida/hogar).
  Future<void> _openAddItem() async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    var itemType = 'comida';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialog) => AlertDialog(
            backgroundColor: AppColors.cream,
            title: const Text('Añadir a la lista'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tipo: comida u hogar/limpieza. Decide a qué parte del
                // inventario irá al comprarlo.
                Row(
                  children: [
                    Expanded(
                      child: _typeChoice(
                        'comida',
                        'Comida',
                        Icons.restaurant,
                        itemType,
                        (v) => setDialog(() => itemType = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _typeChoice(
                        'hogar',
                        'Hogar/Limpieza',
                        Icons.cleaning_services,
                        itemType,
                        (v) => setDialog(() => itemType = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ej. Tomates / Detergente',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Cantidad (opcional)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: unitCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Unidad (opcional)',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Añadir'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) {
      nameCtrl.dispose();
      qtyCtrl.dispose();
      unitCtrl.dispose();
      return;
    }

    final name = nameCtrl.text.trim();
    final qty = double.tryParse(qtyCtrl.text.trim().replaceAll(',', '.'));
    final unit = unitCtrl.text.trim();
    nameCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();

    if (name.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre no puede estar vacío.')),
      );
      return;
    }

    try {
      final homeId = await _homeId();
      // Foto real del artículo. Para comida en modo "ingrediente crudo"; para
      // hogar como producto tal cual. Best-effort y cacheado por hogar.
      String? imageUrl;
      try {
        imageUrl = await FoodPhotoService(_client).resolvePhotoUrl(
          homeId: homeId,
          name: name,
          mode: itemType == 'comida' ? 'ingredient' : 'dish',
        );
      } catch (_) {
        imageUrl = null;
      }
      final item = ShoppingListItem(
        homeId: homeId,
        name: name,
        quantity: qty,
        unit: unit.isEmpty ? null : unit,
        source: 'manual',
        itemType: itemType,
        imageUrl: imageUrl,
      );
      await _client.from('shopping_list_items').insert(item.toInsertMap());
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo anadir: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Lunes de esta semana (igual que meal_plan_screen.dart).
  DateTime get _weekStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  /// Clave de agregacion: nombre + unidad normalizados (trim + minusculas).
  String _aggKey(String name, String? unit) {
    final n = name.trim().toLowerCase();
    final u = (unit ?? '').trim().toLowerCase();
    return '$n|$u';
  }

  /// Genera la lista desde el plan semanal. Suma los ingredientes de las
  /// recetas planificadas de la semana, descuenta lo que ya hay en inventario
  /// cuando el match es fiable y crea los que faltan con source='auto'.
  Future<void> _generarDesdePlan() async {
    setState(() => _generating = true);
    try {
      final homeId = await _homeId();

      // Plan de esta semana (desde el lunes).
      final start = _weekStart;
      final end = start.add(const Duration(days: 7));
      final planRes = await _client
          .from('meal_plan_entries')
          .select()
          .eq('home_id', homeId)
          .gte('plan_date', start.toIso8601String().split('T').first)
          .lt('plan_date', end.toIso8601String().split('T').first);

      // Recetas de las comidas NO saltadas con recipe_id no nulo.
      final recipeIds = <String>{};
      for (final row in (planRes as List)) {
        final map = row as Map<String, dynamic>;
        final skipped = (map['skipped'] as bool?) ?? false;
        final recipeId = map['recipe_id'] as String?;
        if (!skipped && recipeId != null) recipeIds.add(recipeId);
      }

      if (recipeIds.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay plan esta semana todavia.')),
        );
        return;
      }

      // Ingredientes de esas recetas.
      final ingRes = await _client
          .from('recipe_ingredients')
          .select()
          .inFilter('recipe_id', recipeIds.toList());
      final ingredients = (ingRes as List)
          .map((m) => Ingredient.fromMap(m as Map<String, dynamic>))
          .toList();

      // Agregar por nombre + unidad normalizados. Si alguna cantidad es null
      // mantenemos el item sin cantidad (no inventamos cifras).
      final agg = <String, _AggItem>{};
      for (final ing in ingredients) {
        final name = ing.name.trim();
        if (name.isEmpty) continue;
        final key = _aggKey(name, ing.unit);
        final existing = agg[key];
        if (existing == null) {
          agg[key] = _AggItem(
            name: name,
            unit: ing.unit,
            quantity: ing.quantity,
          );
        } else {
          if (existing.quantity == null || ing.quantity == null) {
            // Si alguna no tiene cantidad, no podemos sumar de forma fiable.
            existing.quantity = null;
          } else {
            existing.quantity = existing.quantity! + ing.quantity!;
          }
        }
      }

      // Inventario del hogar, indexado por nombre normalizado. Nos quedamos con
      // una entrada por nombre (si hay varias, basta con detectar que existe).
      // Incluimos is_staple para tratar los basicos "siempre en casa" como
      // siempre disponibles.
      final invRes = await _client
          .from('inventory_items')
          .select('name, quantity, unit, is_staple')
          .eq('home_id', homeId);
      final inventory = <String, _InvEntry>{};
      // Conjunto de nombres normalizados marcados como "siempre en casa".
      // Criterio de match: nombre normalizado (minusculas + sin acentos) con la
      // MISMA normalizacion de CategoryIcons.normalize, para que, por ejemplo,
      // "Pimienta" en inventario excluya "pimienta" del plan.
      final staples = <String>{};
      for (final row in (invRes as List)) {
        final map = row as Map<String, dynamic>;
        final name = (map['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        final nKey = CategoryIcons.normalize(name);
        final qty = (map['quantity'] as num?)?.toDouble();
        final unit = (map['unit'] as String?)?.trim().toLowerCase();
        final isStaple = (map['is_staple'] as bool?) ?? false;
        if (isStaple) staples.add(nKey);
        // Si ya habia una entrada para ese nombre, la dejamos como esta (basta
        // con una para decidir si descontamos).
        inventory.putIfAbsent(nKey, () => _InvEntry(quantity: qty, unit: unit));
      }

      // Descontar lo que ya tenemos SOLO cuando el match es fiable. Ante
      // cualquier duda (unidad distinta o cantidad no comparable) NO
      // descontamos y mantenemos el ingrediente: es mejor comprar de mas que
      // quedarnos cortos.
      final faltan = <ShoppingListItem>[];
      for (final item in agg.values) {
        final nKey = CategoryIcons.normalize(item.name);

        // Basicos "siempre en casa": si el ingrediente coincide por nombre
        // normalizado con un item is_staple=true, lo tratamos como siempre
        // disponible y NO lo anadimos a la lista, por poca cantidad que pida la
        // receta (sal, pimienta, aceite...).
        if (staples.contains(nKey)) continue;

        final inv = inventory[nKey];

        if (inv != null &&
            item.quantity != null &&
            inv.quantity != null &&
            (item.unit ?? '').trim().toLowerCase() == (inv.unit ?? '')) {
          // Match fiable con unidades comparables: restamos.
          final restante = item.quantity! - inv.quantity!;
          if (restante <= 0) {
            // Ya tenemos suficiente, no hace falta comprarlo.
            continue;
          }
          faltan.add(
            ShoppingListItem(
              homeId: homeId,
              name: item.name,
              quantity: restante,
              unit: item.unit,
              source: 'auto',
            ),
          );
        } else {
          // No es fiable descontar: lo anadimos tal cual.
          faltan.add(
            ShoppingListItem(
              homeId: homeId,
              name: item.name,
              quantity: item.quantity,
              unit: item.unit,
              source: 'auto',
            ),
          );
        }
      }

      // La lista de la compra usa ilustración cozy por categoría (no fotos
      // reales), así que no resolvemos fotos aquí: ahorra cuota de Unsplash y
      // evita las fotos genéricas/aleatorias de básicos abstractos.

      // Regeneracion sin duplicar: borramos solo los items 'auto' pendientes.
      // No tocamos los manuales ni los ya marcados como comprados.
      await _client
          .from('shopping_list_items')
          .delete()
          .eq('home_id', homeId)
          .eq('source', 'auto')
          .eq('checked', false);

      if (faltan.isNotEmpty) {
        await _client
            .from('shopping_list_items')
            .insert(faltan.map((i) => i.toInsertMap()).toList());
      }

      _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            faltan.isEmpty
                ? 'Ya tienes todo lo del plan en el inventario.'
                : 'Anadidos ${faltan.length} items desde el plan.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text('Lista de la compra')),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'fab-compra-generar',
            onPressed: _generating ? null : _generarDesdePlan,
            backgroundColor: AppColors.wood,
            foregroundColor: AppColors.ink,
            icon: _generating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: const Text(
              'Generar del plan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'fab-compra-add',
            onPressed: _openAddItem,
            backgroundColor: AppColors.wood,
            foregroundColor: AppColors.ink,
            icon: const Icon(Icons.add),
            label: const Text(
              'Anadir',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<ShoppingListItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return _emptyState();
          }

          final pendientes = items.where((i) => !i.checked).toList();
          final comprados = items.where((i) => i.checked).toList();

          // Compra terminada: hay items y todos están marcados. Mostramos a
          // Miau celebrando (rebote + confeti al vaciar).
          final compraTerminada = pendientes.isEmpty && comprados.isNotEmpty;

          // La detección de la transición a 0 ya se hizo al resolver el fetch
          // (gate puro). Aquí solo CONSUMIMOS la celebración pendiente: devuelve
          // true una sola vez tras la transición y se apaga, de modo que un
          // rebuild posterior (p. ej. borrar un comprado estando en 0
          // pendientes) ya NO reproduce el rebote ni el confeti.
          final celebrar = _celebrationGate.consume();

          final slivers = <Widget>[
            if (compraTerminada)
              SliverToBoxAdapter(child: _CompraCelebracion(celebrar: celebrar)),
            if (pendientes.isNotEmpty)
              SliverToBoxAdapter(child: _costEstimateCard(pendientes)),
            ..._buildPendientesSlivers(pendientes),
            if (comprados.isNotEmpty)
              SliverToBoxAdapter(child: _cartCard(comprados)),
          ];

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
                sliver: SliverMainAxisGroup(slivers: slivers),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Tarjeta con el COSTE ESTIMADO de la compra pendiente, usando los precios
  /// aprendidos de los tickets. Solo aparece si conocemos el precio de alguna
  /// cosa; si no, no molesta.
  Widget _costEstimateCard(List<ShoppingListItem> pendientes) {
    final est = PriceMemory.estimateCost([
      for (final i in pendientes) (name: i.name, quantity: i.quantity),
    ], _prices);
    if (est.priced == 0) return const SizedBox.shrink();

    final total = est.total.toStringAsFixed(2).replaceAll('.', ',');
    final aprox = est.priced < est.totalItems; // faltan precios de algunos
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(radius: 18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.sageBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.euro_rounded, color: AppColors.sage),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aprox ? 'Coste estimado (aprox.)' : 'Coste estimado',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  '$total €',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  aprox
                      ? 'Con precios de ${est.priced} de ${est.totalItems} '
                            'productos. Escanea tickets para afinarlo.'
                      : 'Según tus últimas compras.',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Agrupa los pendientes por "pasillo" (= categoria via
  /// CategoryIcons.categoryFor) y emite, por cada grupo no vacio, una CABECERA
  /// DE PASILLO (SliverToBoxAdapter con _categoryHeader) seguida del contenido
  /// del grupo. El orden de los pasillos sigue el del enum FoodCategory
  /// (verduras, frutas, carne... y "Otros" al final), que ya va de alimentos
  /// frescos a genericos. Conserva el colapsado por categoria (_catCollapsed) y
  /// el chevron/AnimatedCrossFade.
  List<Widget> _buildPendientesSlivers(List<ShoppingListItem> pendientes) {
    final grupos = <FoodCategory, List<ShoppingListItem>>{};
    for (final item in pendientes) {
      final cat = CategoryIcons.categoryFor(item.name);
      grupos.putIfAbsent(cat, () => []).add(item);
    }

    final slivers = <Widget>[];
    for (final cat in FoodCategory.values) {
      final items = grupos[cat];
      if (items == null || items.isEmpty) continue;
      // Cada pasillo es UNA tarjeta cozy COLAPSABLE, con el MISMO lenguaje
      // visual que las secciones del inventario rediseñado: cabecera-toggle con
      // icono en pastilla del tono de la categoría + etiqueta + contador +
      // chevron animado, y debajo las filas separadas por divisores suaves.
      // Arranca EXPANDIDA (lo que falta por comprar apremia); la usuaria puede
      // plegarla y se recuerda en _catCollapsed.
      final expanded = !(_catCollapsed[cat.name] ?? false);
      slivers.add(
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: AppTheme.cardDecoration(radius: AppRadius.md),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _categoryHeader(cat, items.length, expanded),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 220),
                  sizeCurve: Curves.easeInOut,
                  crossFadeState: expanded
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                    child: Column(
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, color: AppColors.cream),
                          _buildRow(items[i]),
                        ],
                      ],
                    ),
                  ),
                  secondChild: const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return slivers;
  }

  /// Cabecera-toggle de sección coherente con la del inventario: icono dentro
  /// de una pastilla con el TONO cozy de la categoría, etiqueta, contador en
  /// pastilla y chevron animado. Pliega/despliega la categoría al tocarla.
  Widget _categoryHeader(FoodCategory category, int count, bool expanded) {
    final style = CategoryIcons.styleForCategory(category);
    return InkWell(
      onTap: () {
        setState(() {
          _catCollapsed[category.name] = expanded;
        });
      },
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: style.background,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(style.icon, color: style.foreground, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      category.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: style.background,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: style.foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 220),
              child: const Icon(
                Icons.expand_more,
                color: AppColors.woodDark,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Panel colapsable "YA EN EL CARRO". Reutiliza el patrón de secciones
  /// colapsables del inventario (cabecera-toggle con chevron animado +
  /// AnimatedCrossFade), pero arranca COLAPSADO porque lo comprado ya no
  /// apremia. Conserva el gesto de desmarcar (toggle checked) y el de deslizar
  /// para borrar, ambos dentro de las filas (_buildRow).
  Widget _cartCard(List<ShoppingListItem> comprados) {
    final expanded = _cartExpanded;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: AppTheme.cardDecoration(radius: 18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _cartExpanded = !_cartExpanded;
              });
            },
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.sageBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.sage,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'YA EN EL CARRO · ${comprados.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.4,
                        color: AppColors.ink.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(
                      Icons.expand_more,
                      color: AppColors.woodDark,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeInOut,
            crossFadeState: expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Column(
                children: [
                  for (var i = 0; i < comprados.length; i++) ...[
                    if (i > 0) const Divider(height: 1, color: AppColors.cream),
                    _buildRow(comprados[i]),
                  ],
                ],
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  /// Fila de la lista estilo "app de compra": compacta, con checkbox a la
  /// izquierda, un distintivo de categoría pequeño y limpio, y gesto de
  /// deslizar para borrar. Lo comprado se tacha y atenúa.
  Widget _buildRow(ShoppingListItem item) {
    final done = item.checked;
    return Dismissible(
      key: ValueKey(item.id ?? item.name + item.hashCode.toString()),
      direction: DismissDirection.endToStart,
      // Fondo que comunica "hecho/comprado" (check sobre sage), NO "borrar".
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.sageBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.check_circle_rounded, color: AppColors.sage),
      ),
      // Deslizar un item PENDIENTE lo MARCA COMO COMPRADO/HECHO (lo tacha,
      // baja la opacidad y lo mete en la despensa via _toggleChecked), NO lo
      // borra. confirmDismiss ejecuta el toggle y devuelve false para no
      // desmontar la fila: _reload reconstruye la lista y el item pasa a "YA
      // EN EL CARRO". El borrado del item sigue accesible por _openItemActions.
      confirmDismiss: (_) async {
        if (!done) {
          await _toggleChecked(item, true);
        }
        return false;
      },
      child: InkWell(
        onTap: () => _toggleChecked(item, !done),
        onLongPress: () => _openItemActions(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              // Checkbox redondo tipo lista de tareas.
              Icon(
                done
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                color: done ? AppColors.woodDark : Colors.grey[400],
                size: 24,
              ),
              const SizedBox(width: 12),
              // Foto real del artículo (si la hay) o ilustración por categoría.
              Opacity(
                opacity: done ? 0.5 : 1,
                child: FoodImage(
                  name: item.name,
                  itemType: item.itemType,
                  imageUrl: item.imageUrl,
                  size: 38,
                  radius: 10,
                ),
              ),
              const SizedBox(width: 12),
              // Nombre LIMPIO (sin marca ni unidad redundante) + origen.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shoppingCleanName(item.name),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        height: 1.15,
                        decoration: done ? TextDecoration.lineThrough : null,
                        color: done ? Colors.grey : AppColors.ink,
                      ),
                    ),
                    if (item.source == 'auto')
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Del plan de la semana',
                          style: TextStyle(
                            fontSize: 11,
                            color: done ? Colors.grey[400] : Colors.grey[500],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Pastilla de cantidad a la derecha (separada del nombre).
              if (shoppingQtyLabel(item.quantity, item.unit).isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: done ? Colors.grey[200] : AppColors.cream,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: done ? Colors.grey[300]! : AppColors.wood,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    shoppingQtyLabel(item.quantity, item.unit),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: done ? Colors.grey : AppColors.woodDark,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiauCharacter(mood: MiauMood.curious, size: 120),
            const SizedBox(height: 16),
            const Text(
              'Tu lista esta vacia',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Anade cosas o generala desde el plan de la semana.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Celebración cuando no quedan items por comprar. Muestra la tarjeta de
/// "Compra completada" con Miau celebrando y, cuando [celebrar] es `true` (solo
/// en la TRANSICIÓN a 0 pendientes), un REBOTE ELÁSTICO de Miau MÁS un CONFETI
/// POR CÓDIGO (CustomPainter, sin paquete ni assets).
///
/// Respeta "reducir movimiento": con [AppMotion.reduceMotionOf] en `true`
/// muestra solo el estado final estático (Miau + tarjeta) sin rebote ni
/// confeti. El confeti se autodestruye al terminar el burst.
class _CompraCelebracion extends StatefulWidget {
  /// `true` únicamente en la transición a 0 pendientes: dispara rebote+confeti.
  /// `false` para mostrar la tarjeta ya asentada (p. ej. al volver al tab).
  final bool celebrar;
  const _CompraCelebracion({required this.celebrar});

  @override
  State<_CompraCelebracion> createState() => _CompraCelebracionState();
}

class _CompraCelebracionState extends State<_CompraCelebracion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  // Muestra el confeti mientras dura su burst; se apaga al completarse.
  bool _confetiActivo = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
      value: widget.celebrar ? 0 : 1,
    );
    // Rebote elástico de entrada de Miau.
    _scale = Tween<double>(
      begin: 0.6,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.celebrar && !AppMotion.reduceMotionOf(context)) {
      _confetiActivo = true;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.reduceMotionOf(context);
    final animar = widget.celebrar && !reduceMotion;

    final miau = animar
        ? ScaleTransition(
            scale: _scale,
            child: const MiauCharacter(mood: MiauMood.celebrating, size: 72),
          )
        : const MiauCharacter(mood: MiauMood.celebrating, size: 72);

    final tarjeta = Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(radius: AppRadius.md),
      child: Row(
        children: [
          miau,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Compra completada',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ya tienes todo lo de la lista. Miau esta orgulloso.',
                  style: TextStyle(color: AppColors.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // El confeti se dibuja ENCIMA de la tarjeta pero sin ocupar hueco ni
    // bloquear toques (IgnorePointer dentro de ConfettiBurst). Solo cuando
    // procede y no hay reduce-motion.
    if (!_confetiActivo || reduceMotion) return tarjeta;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        tarjeta,
        Positioned.fill(
          child: ConfettiBurst(
            onCompleted: () {
              if (mounted) setState(() => _confetiActivo = false);
            },
          ),
        ),
      ],
    );
  }
}

/// Acumulador temporal para agregar ingredientes por nombre + unidad.
class _AggItem {
  final String name;
  final String? unit;
  double? quantity;
  _AggItem({required this.name, this.unit, this.quantity});
}

/// Entrada de inventario reducida que usamos para decidir si descontar.
class _InvEntry {
  final double? quantity;
  final String? unit;
  _InvEntry({this.quantity, this.unit});
}
