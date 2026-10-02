import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/inventory_item.dart';
import 'theme/app_theme.dart';

class AddInventoryItemScreen extends StatefulWidget {
  const AddInventoryItemScreen({super.key});

  @override
  State<AddInventoryItemScreen> createState() => _AddInventoryItemScreenState();
}

class _AddInventoryItemScreenState extends State<AddInventoryItemScreen> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _servingsController = TextEditingController();
  String _itemType = 'comida';
  String _selectedCategory = 'Despensa';
  String _selectedUnit = 'unidades';
  String _kind = 'ingredient';
  DateTime? _frozenOn;
  bool _isStaple = false;
  bool _isLoading = false;

  static const List<String> _foodCategories = [
    'Despensa',
    'Nevera',
    'Congelador',
  ];
  static const List<String> _homeCategories = ['Limpieza', 'Hogar'];

  List<String> get _categories =>
      _itemType == 'hogar' ? _homeCategories : _foodCategories;

  final List<String> _units = [
    'unidades',
    'kg',
    'g',
    'litros',
    'ml',
    'botes',
    'bolsas',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw 'No hay usuario autenticado';

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('home_id')
          .eq('id', user.id)
          .single();

      final homeId = profile['home_id'];
      if (homeId == null) {
        throw 'El usuario no está asignado a ningún hogar.';
      }

      final qty = double.tryParse(
        _quantityController.text.trim().replaceAll(',', '.'),
      );
      if (qty == null) throw 'Introduce una cantidad válida.';

      final isFood = _itemType == 'comida';
      final item = InventoryItem(
        id: '',
        homeId: homeId,
        name: _nameController.text.trim(),
        category: _selectedCategory,
        itemType: _itemType,
        quantity: qty,
        unit: _selectedUnit,
        kind: isFood ? _kind : 'ingredient',
        servings: (isFood && _kind != 'ingredient')
            ? double.tryParse(
                _servingsController.text.trim().replaceAll(',', '.'),
              )
            : null,
        frozenOn: (isFood && _selectedCategory == 'Congelador')
            ? _frozenOn
            : null,
        // Solo tiene sentido marcar basicos de comida como "siempre en casa".
        isStaple: isFood && _isStaple,
      );

      await Supabase.instance.client
          .from('inventory_items')
          .insert(item.toMap());

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isFood = _itemType == 'comida';
    final isFrozen = isFood && _selectedCategory == 'Congelador';
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Añadir al inventario')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            // Tipo de producto (comida u hogar/limpieza)
            const Text(
              'Tipo de producto',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: InventoryItem.itemTypeLabels.entries.map((e) {
                final selected = _itemType == e.key;
                return ChoiceChip(
                  label: Text(e.value),
                  selected: selected,
                  selectedColor: AppColors.wood,
                  backgroundColor: Colors.white,
                  onSelected: (_) {
                    setState(() {
                      _itemType = e.key;
                      // Al cambiar de tipo, fijamos una categoría válida.
                      if (!_categories.contains(_selectedCategory)) {
                        _selectedCategory = _categories.first;
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Nivel del item (solo aplica a comida).
            if (isFood) ...[
              const Text(
                '¿Qué es?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: InventoryItem.kindLabels.entries.map((e) {
                  final selected = _kind == e.key;
                  return ChoiceChip(
                    label: Text(e.value),
                    selected: selected,
                    selectedColor: AppColors.wood,
                    backgroundColor: Colors.white,
                    onSelected: (_) => setState(() => _kind = e.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: 4),
              Text(
                _kind == 'ingredient'
                    ? 'Materia prima (ej. pollo troceado, cebolla picada).'
                    : _kind == 'prep'
                    ? 'Base preparada (ej. sofrito, sopa en daditos).'
                    : 'Plato listo para comer (ej. lentejas cocinadas).',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 20),
            ],

            TextField(controller: _nameController, decoration: _dec('Nombre')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: _dec(isFood ? 'Ubicación' : 'Categoría'),
              items: _categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _dec('Cantidad'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedUnit,
                    decoration: _dec('Unidad'),
                    items: _units
                        .map(
                          (unit) =>
                              DropdownMenuItem(value: unit, child: Text(unit)),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedUnit = val!),
                  ),
                ),
              ],
            ),

            // Raciones (solo para platos/preparados de comida)
            if (isFood && _kind != 'ingredient') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _servingsController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _dec('Raciones que representa (opcional)'),
              ),
            ],

            // Fecha de congelación (solo si está en el congelador)
            if (isFrozen) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _frozenOn ?? now,
                    firstDate: DateTime(now.year - 1),
                    lastDate: now,
                    helpText: 'Fecha de congelación',
                  );
                  if (picked != null) setState(() => _frozenOn = picked);
                },
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: _dec('Congelado el (opcional)'),
                  child: Text(
                    _frozenOn == null
                        ? 'Sin fecha'
                        : '${_frozenOn!.day.toString().padLeft(2, '0')}/'
                              '${_frozenOn!.month.toString().padLeft(2, '0')}/'
                              '${_frozenOn!.year}',
                  ),
                ),
              ),
            ],

            // "Siempre en casa": basicos/especias que no queremos que acaben
            // en la lista de la compra (sal, pimienta, aceite...). Solo para
            // productos de comida.
            if (isFood) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  value: _isStaple,
                  activeThumbColor: AppColors.woodDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Siempre en casa',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Básico o especia que das por supuesto. No se añadirá a '
                    'la lista de la compra aunque una receta lo pida.',
                  ),
                  onChanged: (v) => setState(() => _isStaple = v),
                ),
              ),
            ],

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveItem,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Guardar en el inventario'),
            ),
          ],
        ),
      ),
    );
  }
}
