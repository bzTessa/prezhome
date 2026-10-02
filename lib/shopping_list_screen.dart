import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/ingredient.dart';
import 'models/shopping_list_item.dart';
import 'theme/app_theme.dart';
import 'widgets/food_category_icon.dart';
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
  late Future<List<ShoppingListItem>> _itemsFuture;
  bool _generating = false;

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

    return (res as List)
        .map((m) => ShoppingListItem.fromMap(m as Map<String, dynamic>))
        .toList();
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

  /// Dialog de alta manual: nombre obligatorio, cantidad y unidad opcionales.
  Future<void> _openAddItem() async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final unitCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cream,
          title: const Text('Anadir a la lista'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej. Tomates',
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
              child: const Text('Anadir'),
            ),
          ],
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
        const SnackBar(content: Text('El nombre no puede estar vacio.')),
      );
      return;
    }

    try {
      final homeId = await _homeId();
      final item = ShoppingListItem(
        homeId: homeId,
        name: name,
        quantity: qty,
        unit: unit.isEmpty ? null : unit,
        source: 'manual',
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
          // Miau celebrando con una animación de aparición sutil.
          final compraTerminada = pendientes.isEmpty && comprados.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
            children: [
              _CompraCelebracion(visible: compraTerminada),
              if (pendientes.isNotEmpty)
                ..._buildPendientesPorCategoria(pendientes),
              if (comprados.isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionTitle('Comprados'),
                ...comprados.map(_buildRow),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: AppColors.ink,
        ),
      ),
    );
  }

  /// Agrupa los pendientes por categoria (CategoryIcons.categoryFor) y los
  /// pinta con un encabezado de seccion legible por cada grupo no vacio. El
  /// orden de las secciones sigue el del enum FoodCategory (verduras, frutas,
  /// carne... y "Otros" al final), que ya va de alimentos frescos a genericos.
  List<Widget> _buildPendientesPorCategoria(List<ShoppingListItem> pendientes) {
    final grupos = <FoodCategory, List<ShoppingListItem>>{};
    for (final item in pendientes) {
      final cat = CategoryIcons.categoryFor(item.name);
      grupos.putIfAbsent(cat, () => []).add(item);
    }

    final widgets = <Widget>[];
    for (final cat in FoodCategory.values) {
      final items = grupos[cat];
      if (items == null || items.isEmpty) continue;
      widgets.add(_categoryHeader(cat, items.length));
      widgets.addAll(items.map(_buildRow));
      widgets.add(const SizedBox(height: 8));
    }
    return widgets;
  }

  /// Encabezado de seccion con el emoji de la categoria, su nombre legible y un
  /// contador de items. Mantiene la estetica Cozy (tonos madera sobre crema).
  Widget _categoryHeader(FoodCategory category, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Row(
        children: [
          Text(category.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            category.label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.wood,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(ShoppingListItem item) {
    final done = item.checked;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDecoration(radius: 16),
      child: CheckboxListTile(
        value: done,
        onChanged: (v) => _toggleChecked(item, v ?? false),
        activeColor: AppColors.woodDark,
        controlAffinity: ListTileControlAffinity.leading,
        title: Row(
          children: [
            CategoryIcons.badge(item.name, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.display,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: done ? TextDecoration.lineThrough : null,
                  color: done ? Colors.grey : AppColors.ink,
                ),
              ),
            ),
          ],
        ),
        subtitle: item.source == 'auto'
            ? Text(
                'Del plan de la semana',
                style: TextStyle(
                  fontSize: 12,
                  color: done ? Colors.grey : Colors.grey[600],
                ),
              )
            : null,
        secondary: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          tooltip: 'Borrar',
          onPressed: () => _deleteItem(item),
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

/// Tarjeta de celebración cuando no quedan items por comprar. Aparece con una
/// animación sutil (opacidad + escala) y muestra a Miau celebrando.
class _CompraCelebracion extends StatelessWidget {
  final bool visible;
  const _CompraCelebracion({required this.visible});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: visible ? 1 : 0,
        child: visible
            ? Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(),
                child: Row(
                  children: [
                    const MiauCharacter(mood: MiauMood.celebrating, size: 72),
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
              )
            : const SizedBox(width: double.infinity),
      ),
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
