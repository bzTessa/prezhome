import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/inventory_item.dart';
import 'services/food_photo_service.dart';
import 'services/shelf_life.dart';
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
  DateTime? _expirationDate;
  DateTime? _bestBefore; // consumo preferente estimado (congelador)
  bool _isStaple = false;
  bool _isLoading = false;

  // ¿La usuaria ha fijado la fecha a mano? Si es así, no la pisamos con la
  // estimación automática. Al escribir el nombre o cambiar de ubicación, si la
  // fecha sigue siendo automática, la recalculamos.
  bool _expirationManual = false;

  static const List<String> _foodCategories = [
    'Despensa',
    'Nevera',
    'Congelador',
    'Especias',
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
  void initState() {
    super.initState();
    // Al escribir el nombre recalculamos la caducidad estimada (si la usuaria
    // no la ha fijado a mano). Con un pequeño debounce implícito: solo
    // recalculamos cuando cambia el texto.
    _nameController.addListener(_recalcEstimatedExpiry);
  }

  @override
  void dispose() {
    _nameController.removeListener(_recalcEstimatedExpiry);
    _nameController.dispose();
    _quantityController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  /// Recalcula una fecha de caducidad/consumo preferente ORIENTATIVA a partir
  /// del nombre del producto y la ubicación, salvo que la usuaria la haya
  /// fijado a mano (_expirationManual). Para nevera/despensa rellena
  /// _expirationDate; para congelador rellena _bestBefore (y _frozenOn=hoy si
  /// no hay). Para especias no pone fecha.
  void _recalcEstimatedExpiry() {
    if (_expirationManual) return;
    if (_itemType != 'comida') return;

    final name = _nameController.text.trim();
    final estimated = name.isEmpty
        ? null
        : ShelfLife.estimateDate(name, _selectedCategory);

    setState(() {
      if (_selectedCategory == 'Congelador') {
        _frozenOn ??= DateTime.now();
        _bestBefore = estimated;
      } else {
        _expirationDate = estimated;
      }
    });
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
      final name = _nameController.text.trim();

      // Combo visual: solo para COMIDA intentamos resolver una foto real por
      // nombre (Unsplash vía recipe-photo, con caché por hogar). Best-effort:
      // si no hay clave, falla o no hay match, devuelve null y el item se
      // guarda sin foto (la UI mostrará la ilustración cozy de la categoría).
      String? imageUrl;
      // Para especias/condimentos no buscamos foto real: salen genéricas y la
      // ilustración cozy (🧂) queda más limpia. Resto de comida sí.
      if (isFood && name.isNotEmpty && _selectedCategory != 'Especias') {
        try {
          imageUrl = await FoodPhotoService(
            Supabase.instance.client,
          ).resolvePhotoUrl(homeId: homeId, name: name);
        } catch (_) {
          // Nunca bloquea el guardado por la foto.
          imageUrl = null;
        }
      }

      final item = InventoryItem(
        id: '',
        homeId: homeId,
        name: name,
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
        // Consumo preferente estimado para el congelador (si lo hay). El modelo
        // usa best_before como caducidad efectiva en el congelador.
        bestBefore: (isFood && _selectedCategory == 'Congelador')
            ? _bestBefore
            : null,
        // La fecha de caducidad solo aplica a comida fuera del congelador
        // (Nevera/Despensa); el congelador usa la fecha de congelación.
        expirationDate: (isFood && _selectedCategory != 'Congelador')
            ? _expirationDate
            : null,
        // Solo tiene sentido marcar basicos de comida como "siempre en casa".
        isStaple: isFood && _isStaple,
        imageUrl: imageUrl,
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
              onChanged: (val) {
                setState(() {
                  _selectedCategory = val!;
                  // Las especias son básicos que no deben acabar en la lista
                  // de la compra: activamos "siempre en casa" por defecto al
                  // elegir esta ubicación (la usuaria puede desmarcarlo).
                  if (_selectedCategory == 'Especias') _isStaple = true;
                });
                // Al cambiar de ubicación, la caducidad típica cambia: la
                // reestimamos (si no está fijada a mano).
                _recalcEstimatedExpiry();
              },
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
                  if (picked != null) {
                    setState(() => _frozenOn = picked);
                    // Reestimar el consumo preferente desde la nueva fecha de
                    // congelación (si no está fijado a mano).
                    if (!_expirationManual) {
                      final name = _nameController.text.trim();
                      final days = name.isEmpty
                          ? ShelfLife.defaultFreezerDays
                          : (ShelfLife.estimateDays(name, 'Congelador') ??
                                ShelfLife.defaultFreezerDays);
                      setState(() {
                        _bestBefore = DateTime(
                          picked.year,
                          picked.month,
                          picked.day + days,
                        );
                      });
                    }
                  }
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
              const SizedBox(height: 4),
              Text(
                _bestBefore == null
                    ? 'Calcularemos cuánto aguanta en el congelador.'
                    : 'Mejor consumir antes del '
                          '${_bestBefore!.day.toString().padLeft(2, '0')}/'
                          '${_bestBefore!.month.toString().padLeft(2, '0')}/'
                          '${_bestBefore!.year} (aprox.).',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],

            // Fecha de caducidad (solo comida fuera del congelador)
            if (isFood && !isFrozen) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _expirationDate ?? now,
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 5),
                    helpText: 'Fecha de caducidad',
                  );
                  if (picked != null) {
                    setState(() {
                      _expirationDate = picked;
                      _expirationManual = true; // la usuaria la fijó a mano
                    });
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: _dec('Caduca el (estimado, editable)'),
                  child: Text(
                    _expirationDate == null
                        ? 'Sin fecha'
                        : '${_expirationDate!.day.toString().padLeft(2, '0')}/'
                              '${_expirationDate!.month.toString().padLeft(2, '0')}/'
                              '${_expirationDate!.year}',
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _expirationManual || _expirationDate == null
                    ? 'Te avisaremos en el Inicio cuando esté a punto de caducar.'
                    : 'Fecha aproximada calculada automáticamente. Puedes ajustarla.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
