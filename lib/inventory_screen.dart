import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_inventory_item_screen.dart';
import 'models/inventory_item.dart';

class InventoryScreen extends StatefulWidget {
  final bool embedded;
  const InventoryScreen({super.key, this.embedded = false});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  late Future<List<InventoryItem>> _itemsFuture;

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
    setState(() => _itemsFuture = _fetchItems());
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/presidente_prezhome.jpg',
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '¡Todo está vacío por aquí, Miau!',
                    style: TextStyle(
                      color: Color(0xFF1E1E1E),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
                  title: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  subtitle: Text(
                    '${item.quantity} ${item.unit} • ${item.category}'
                    '${item.kind != 'ingredient' ? ' • ${item.kindLabel}' : ''}'
                    '${item.servings != null ? ' • ${item.servings!.toStringAsFixed(0)} rac.' : ''}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => _deleteItem(item),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
