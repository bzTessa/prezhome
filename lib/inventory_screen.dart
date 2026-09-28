import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/inventory_provider.dart';
import 'models/inventory_item.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E6), // Fondo amarillo pastel cálido[cite: 3]
      appBar: AppBar(
        title: const Text(
          'Despensa y Nevera',
          style: TextStyle(color: Color(0xFF2C2C2C), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2C2C2C)),
      ),
      body: inventoryAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Aquí se integrará visualmente Presidente Miau en estados vacíos[cite: 3, 4]
                  Image.asset('assets/images/presidente_prezhome.jpg', height: 120),
                  const SizedBox(height: 16),
                  const Text(
                    '¡Todo está vacío por aquí, Miau!',
                    style: TextStyle(color: Color(0xFF2C2C2C), fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
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
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C)),
                  ),
                  subtitle: Text('${item.quantity} ${item.unit} • ${item.location}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      ref.read(inventoryProvider.notifier).removeItem(item.id);
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF2C2C2C))),
        error: (err, stack) => Center(child: Text('Error al cargar inventario: $err')),
      ),
    );
  }
}