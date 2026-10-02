import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_inventory_item_screen.dart';
import 'models/inventory_item.dart';
import 'theme/app_theme.dart';
import 'widgets/food_category_icon.dart';
import 'widgets/miau_character.dart';

class InventoryScreen extends StatefulWidget {
  final bool embedded;
  const InventoryScreen({super.key, this.embedded = false});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  late Future<List<InventoryItem>> _itemsFuture;

  // Filtro por tipo: 'todo' | 'comida' | 'hogar'. Se aplica en cliente sobre la
  // lista ya cargada, sin recargar el Future.
  String _typeFilter = 'todo';

  @override
  void initState() {
    super.initState();
    _itemsFuture = _fetchItems();
  }

  Future<List<InventoryItem>> _fetchItems() async {
    // RLS filtra automáticamente por el home_id del usuario autenticado.
    final response = await supabase
        .from('inventory_items')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => InventoryItem.fromMap(item))
        .toList();
  }

  void _reload() {
    final future = _fetchItems();
    setState(() {
      _itemsFuture = future;
    });
  }

  Future<void> _deleteItem(InventoryItem item) async {
    try {
      await supabase.from('inventory_items').delete().eq('id', item.id);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openAddItem() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddInventoryItemScreen()),
    );
    if (added == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8E1),
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text(
                'Despensa y Nevera',
                style: TextStyle(
                  color: Color(0xFF1E1E1E),
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: const Color(0xFFFDF8E1),
              elevation: 0,
              iconTheme: const IconThemeData(color: Color(0xFF1E1E1E)),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-inventory',
        onPressed: _openAddItem,
        backgroundColor: const Color(0xFFE2C792),
        foregroundColor: const Color(0xFF1E1E1E),
        icon: const Icon(Icons.add),
        label: const Text(
          'Añadir',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<InventoryItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar inventario: ${snapshot.error}'),
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const MiauCharacter(mood: MiauMood.curious, size: 120),
                  const SizedBox(height: 16),
                  const Text(
                    '¡Todo está vacío por aquí, Miau!',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          // Filtrado en cliente sobre la lista ya cargada (sin recargar).
          final filtered = _typeFilter == 'todo'
              ? items
              : items.where((i) => i.itemType == _typeFilter).toList();

          return Column(
            children: [
              _typeFilterBar(),
              Expanded(child: _buildList(filtered)),
            ],
          );
        },
      ),
    );
  }

  Widget _typeFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'todo', label: Text('Todo')),
          ButtonSegment(value: 'comida', label: Text('Comida')),
          ButtonSegment(value: 'hogar', label: Text('Hogar')),
        ],
        selected: {_typeFilter},
        showSelectedIcon: false,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? const Color(0xFFE2C792)
                : Colors.white,
          ),
          foregroundColor: const WidgetStatePropertyAll(Color(0xFF1E1E1E)),
        ),
        onSelectionChanged: (selection) {
          setState(() {
            _typeFilter = selection.first;
          });
        },
      ),
    );
  }

  Widget _buildList(List<InventoryItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No hay productos en esta categoría.',
            style: TextStyle(color: Color(0xFF1E1E1E), fontSize: 15),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: CategoryIcons.badge(item.name, itemType: item.itemType),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                ),
                if (item.itemType == 'hogar')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2C792),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.itemTypeLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.quantity} ${item.unit} • ${item.category}'
                  '${item.kind != 'ingredient' ? ' • ${item.kindLabel}' : ''}'
                  '${item.servings != null ? ' • ${item.servings!.toStringAsFixed(0)} rac.' : ''}',
                ),
                if (item.daysUntilBestBefore != null)
                  Builder(
                    builder: (_) {
                      final d = item.daysUntilBestBefore!;
                      final soon = d <= 7;
                      final expired = d < 0;
                      return Text(
                        expired
                            ? 'Caducado'
                            : soon
                            ? 'Consumir en $d día${d == 1 ? '' : 's'}'
                            : 'Consumir antes: ${item.bestBefore!.day}/${item.bestBefore!.month}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: (soon || expired)
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: expired
                              ? Colors.red
                              : soon
                              ? const Color(0xFFB58A3C)
                              : Colors.grey[600],
                        ),
                      );
                    },
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _deleteItem(item),
            ),
          ),
        );
      },
    );
  }
}
