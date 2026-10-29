import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/inventory_item.dart';
import 'services/food_photo_service.dart';
import 'services/home_supermarkets.dart';
import 'services/product_search_service.dart';
import 'services/inventory_prefill.dart';
import 'services/shelf_life.dart';
import 'theme/app_theme.dart';
import 'utils/quick_items.dart';
import 'widgets/food_category_icon.dart';
import 'widgets/food_image.dart';
import 'widgets/product_photo_menu.dart';
import 'widgets/product_search_sheet.dart';
import 'utils/friendly_error.dart';

class AddInventoryItemScreen extends StatefulWidget {
  /// Si se pasa un item, la pantalla funciona en modo EDICIÓN (precarga sus
  /// campos y hace UPDATE en vez de INSERT).
  final InventoryItem? item;

  /// Valores precargables para un ALTA NUEVA (p. ej. al escanear un código de
  /// barras). Solo se aplican cuando [item] es null; en edición se ignoran.
  final InventoryPrefill? prefill;

  const AddInventoryItemScreen({super.key, this.item, this.prefill});

  bool get isEditing => item != null;

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

  // Producto del súper elegido en el buscador: su foto se usa tal cual
  // mientras no se cambie el nombre.
  SupermarketProduct? _product;

  // Foto elegida a mano en esta pantalla (gana a cualquier otra).
  String? _photoUrl;

  // ¿La usuaria ha fijado la fecha a mano? Si es así, no la pisamos con la
  // estimación automática. Al escribir el nombre o cambiar de ubicación, si la
  // fecha sigue siendo automática, la recalculamos.
  bool _expirationManual = false;

  static const List<String> _foodCategories = [
    'Despensa',
    'Nevera',
    'Congelador',
    'Especias',
    'Bebidas',
  ];
  static const List<String> _homeCategories = ['Limpieza', 'Hogar'];

  // La categoría guardada sale siempre, aunque no sea de la lista (si no, el
  // desplegable no puede mostrarla).
  List<String> get _categories {
    final base = _itemType == 'hogar' ? _homeCategories : _foodCategories;
    final saved = widget.item?.category;
    return saved != null &&
            !base.contains(saved) &&
            _itemType == widget.item!.itemType
        ? [...base, saved]
        : base;
  }

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
    final it = widget.item;
    if (it != null) {
      // Modo edición: precargamos los campos del item existente.
      _nameController.text = it.name;
      _quantityController.text = it.quantity % 1 == 0
          ? it.quantity.toStringAsFixed(0)
          : it.quantity.toString();
      _itemType = it.itemType;
      _selectedCategory = it.category;
      // Una unidad que no está en la lista se conserva tal cual.
      if (it.unit.trim().isNotEmpty && !_units.contains(it.unit)) {
        _units.add(it.unit);
      }
      _selectedUnit = _units.contains(it.unit) ? it.unit : 'unidades';
      _kind = it.kind;
      _frozenOn = it.frozenOn;
      _expirationDate = it.expirationDate;
      _bestBefore = it.bestBefore;
      _isStaple = it.isStaple;
      // No pisamos la fecha ya guardada con la estimación automática.
      _expirationManual = true;
      if (it.servings != null) {
        _servingsController.text = it.servings! % 1 == 0
            ? it.servings!.toStringAsFixed(0)
            : it.servings!.toString();
      }
    } else {
      // Modo ALTA NUEVA: si llega una precarga (p. ej. de un escaneo), la
      // aplicamos ANTES de enganchar el listener para que la primera
      // estimación de fecha salga ya del nombre/ubicación precargados. Dejamos
      // _expirationManual = false para que la estimación automática se dispare.
      final pre = widget.prefill;
      if (pre != null) {
        if (pre.name != null) _nameController.text = pre.name!;
        final q = pre.quantity;
        if (q != null) {
          _quantityController.text = q % 1 == 0
              ? q.toStringAsFixed(0)
              : q.toString();
        }
        if (pre.unit != null && _units.contains(pre.unit)) {
          _selectedUnit = pre.unit!;
        }
        // La categoría del formulario es la ubicación en comida; usamos la
        // sugerida solo si es un valor válido de la lista actual.
        final cat = pre.location ?? pre.category;
        if (_foodCategories.contains(cat)) _selectedCategory = cat;
      }
    }
    _nameController.addListener(_recalcEstimatedExpiry);
    // Si hubo precarga con nombre, calculamos la fecha estimada inicial sin
    // setState (estamos aún en initState): el listener solo reacciona a cambios
    // de texto posteriores, no al valor inicial del controlador.
    if (widget.item == null &&
        widget.prefill?.name != null &&
        _itemType == 'comida' &&
        _nameController.text.trim().isNotEmpty) {
      final estimated = ShelfLife.estimateDate(
        _nameController.text.trim(),
        _selectedCategory,
      );
      if (_selectedCategory == 'Congelador') {
        _frozenOn ??= DateTime.now();
        _bestBefore = estimated;
      } else {
        _expirationDate = estimated;
      }
    }
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

  /// Rellena el formulario con una sugerencia rápida de condimento sin que la
  /// usuaria tenga que escribir: pone el nombre, una cantidad por defecto de 1
  /// y la unidad del chip. Al cambiar el nombre, el listener recalcula la
  /// caducidad estimada (que para 'Especias' no pone fecha).
  void _applyQuickItem(QuickItem quick) {
    setState(() {
      _nameController.text = quick.name;
      if (_quantityController.text.trim().isEmpty) {
        _quantityController.text = '1';
      }
      if (_units.contains(quick.unit)) {
        _selectedUnit = quick.unit;
      }
    });
  }

  Future<void> _saveItem() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw 'No hay usuario autenticado';

      // Resolvemos el home_id de la fila. En edición ya lo trae el item; en
      // alta nueva lo leemos del perfil (best-effort: si no hay red usamos el
      // del item editado o lo dejamos vacío para que el repositorio lo rellene
      // al enviar). Así el alta funciona también de forma optimista sin red.
      String? homeId = widget.item?.homeId;
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('home_id')
            .eq('id', user.id)
            .single();
        homeId = (profile['home_id'] as String?) ?? homeId;
      } catch (_) {
        // Sin conexión: conservamos el homeId que tuviéramos (puede ser null en
        // un alta nueva; el SupabaseRemoteSender lo resolverá al drenar).
      }

      final qty = double.tryParse(
        _quantityController.text.trim().replaceAll(',', '.'),
      );
      if (qty == null) throw 'Introduce una cantidad válida.';

      final isFood = _itemType == 'comida';
      final name = _nameController.text.trim();

      // Foto real del alimento buscada en modo "ingrediente CRUDO" (para que
      // acierte: p. ej. pollo crudo, no un plato cocinado). Best-effort: si no
      // hay clave/match, image_url queda null y se muestra la ilustración cozy.
      // Las especias no buscan foto (salen genéricas; mejor su ilustración).
      // En EDICIÓN solo re-buscamos si cambió el nombre; si no, conservamos la
      // foto que ya tenía (no gastamos cuota ni perdemos foto).
      final editing = widget.item;
      String? imageUrl = editing?.imageUrl;
      final nameChanged = editing == null || editing.name.trim() != name;
      final picked = _product;
      if (_photoUrl != null) {
        imageUrl = _photoUrl;
      } else if (picked != null &&
          picked.imageUrl != null &&
          picked.displayName == name) {
        imageUrl = picked.imageUrl;
        if (homeId != null) {
          await FoodPhotoService(Supabase.instance.client)
              .rememberPhoto(homeId: homeId, name: name, url: imageUrl!);
        }
      } else if (isFood &&
          name.isNotEmpty &&
          _selectedCategory != 'Especias' &&
          nameChanged &&
          homeId != null) {
        try {
          imageUrl = await FoodPhotoService(Supabase.instance.client)
              .resolvePhotoUrl(homeId: homeId, name: name, mode: 'ingredient');
        } catch (_) {
          imageUrl = editing?.imageUrl;
        }
      }

      final item = InventoryItem(
        id: editing?.id ?? '',
        homeId: homeId ?? '',
        name: name,
        category: _selectedCategory,
        itemType: _itemType,
        quantity: qty,
        unit: _selectedUnit,
        kind: isFood ? _kind : 'ingredient',
        // Que editar un plato congelado no lo desenlace de su receta.
        recipeId: editing?.recipeId,
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
        // Solo tiene sentido marcar basicos de comida como "no comprar".
        isStaple: isFood && _isStaple,
        imageUrl: imageUrl,
      );

      // OFFLINE-FIRST: ya NO escribimos aquí en Supabase. Devolvemos el item
      // construido a InventoryScreen, que aplica la op (insert/update) de forma
      // OPTIMISTA a la caché, la encola y la drena a Supabase en segundo plano.
      // Así el alta/edición funciona igual sin conexión.
      if (mounted) Navigator.of(context).pop(item);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e, 'Error al guardar')),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _dec(String label) => InputDecoration(labelText: label);

  /// Cambia la foto del producto (cámara, galería, súper, generada o dibujo).
  Future<void> _changePhoto() async {
    final item = widget.item!;
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
            const SizedBox(height: 8),
            ...productPhotoTiles(
              ctx,
              name: item.name,
              imageUrl: _photoUrl ?? item.imageUrl,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    final keys = await HomeSupermarkets(Supabase.instance.client).load();
    final homeId = item.homeId.isNotEmpty ? item.homeId : keys.homeId;
    if (homeId == null || !mounted) return;
    final url = await pickProductPhoto(
      context,
      action,
      homeId: homeId,
      name: item.name,
      imageUrl: _photoUrl ?? item.imageUrl,
      supermarketKey: keys.keys.isEmpty ? null : keys.keys.first,
    );
    if (url != null && mounted) setState(() => _photoUrl = url);
  }

  bool get isEditingItem => widget.item != null;

  /// Abre el buscador de productos del súper principal y rellena el
  /// formulario con el elegido (nombre, foto y formato de venta).
  Future<void> _searchProduct() async {
    final keys = await HomeSupermarkets(Supabase.instance.client).load();
    if (!mounted) return;
    final p = await showProductSearchSheet(
      context,
      initialQuery: _nameController.text.trim(),
      supermarketKey: keys.keys.isEmpty ? null : keys.keys.first,
    );
    if (p == null || !mounted) return;
    final cat = CategoryIcons.categoryFor(p.name);
    final isHome = CategoryIcons.isHousehold(cat);
    final pkg = parsePackageQuantity(p.quantity);
    setState(() {
      _product = p;
      _nameController.text = p.displayName;
      _itemType = isHome ? 'hogar' : 'comida';
      if (!_categories.contains(_selectedCategory)) {
        _selectedCategory = _categories.first;
      }
      if (pkg != null && _units.contains(pkg.unit)) {
        final q = pkg.quantity;
        _quantityController.text = q == q.roundToDouble()
            ? q.toInt().toString()
            : q.toString();
        _selectedUnit = pkg.unit;
      }
    });
  }

  Widget _pickedProductCard(SupermarketProduct p) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          FoodImage(
            name: p.name,
            imageUrl: p.imageUrl,
            size: 56,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Producto del súper',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkMuted,
                  ),
                ),
                Text(
                  [?p.brand, ?p.quantity].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Quitar producto',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => setState(() => _product = null),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFood = _itemType == 'comida';
    final isFrozen = isFood && _selectedCategory == 'Congelador';
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Editar producto' : 'Añadir al inventario',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            // DESTINO del Hero: al EDITAR un item con id mostramos un preview
            // de su imagen envuelto en Hero(tag: 'inv-<id>') con el MISMO tag
            // que la tarjeta del grid, para que la transición case. En alta
            // nueva (sin item/id) no hay Hero.
            if (widget.item != null && widget.item!.id.isNotEmpty) ...[
              Center(
                child: GestureDetector(
                  onTap: _changePhoto,
                  child: Hero(
                    tag: 'inv-${widget.item!.id}',
                    child: FoodImage(
                      name: widget.item!.name,
                      itemType: widget.item!.itemType,
                      imageUrl: _photoUrl ?? widget.item!.imageUrl,
                      size: 120,
                      radius: AppRadius.md,
                      forceIllustration:
                          _photoUrl == null &&
                          widget.item!.category == 'Especias',
                    ),
                  ),
                ),
              ),
              Center(
                child: TextButton.icon(
                  onPressed: _changePhoto,
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text('Cambiar foto'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.woodDark,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
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
                  backgroundColor: AppColors.card,
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
                    backgroundColor: AppColors.card,
                    onSelected: (_) => setState(() => _kind = e.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: 4),
              Text(
                _kind == 'ingredient'
                    ? 'Ingrediente para cocinar'
                    : _kind == 'prep'
                    ? 'Base ya preparada'
                    : 'Plato listo para comer',
                style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
            ],

            TextField(
              controller: _nameController,
              decoration: _dec('Nombre').copyWith(
                suffixIcon: IconButton(
                  tooltip: 'Buscar en el súper',
                  icon: Icon(
                    Icons.storefront_rounded,
                    color: AppColors.woodDark,
                  ),
                  onPressed: _searchProduct,
                ),
              ),
            ),
            if (_product != null &&
                _product!.displayName == _nameController.text.trim())
              _pickedProductCard(_product!)
            else
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _searchProduct,
                  icon: const Icon(Icons.storefront_rounded, size: 18),
                  label: const Text('Buscar el producto del súper con foto'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.woodDark,
                  ),
                ),
              ),

            // Sugerencias rápidas de condimentos: al elegir la ubicación
            // 'Especias', mostramos chips de los de siempre (sal, pimienta,
            // comino...) que rellenan el formulario con UN toque, sin escribir.
            if (isFood && _selectedCategory == 'Especias') ...[
              const SizedBox(height: 16),
              const Text(
                'Añade los de siempre con un toque',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kQuickCondiments.map((quick) {
                  final style = CategoryIcons.styleForCategory(
                    FoodCategory.especias,
                  );
                  return ActionChip(
                    backgroundColor: style.background,
                    avatar: Icon(style.icon, size: 18, color: style.foreground),
                    label: Text(quick.name),
                    labelStyle: TextStyle(color: style.foreground),
                    onPressed: () => _applyQuickItem(quick),
                  );
                }).toList(),
              ),
            ],

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
                style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
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
                  decoration:
                      _dec(
                        _expirationManual ? 'Caduca el' : 'Caduca el (aprox.)',
                      ).copyWith(
                        suffixIcon: _expirationDate == null
                            ? null
                            : IconButton(
                                tooltip: 'Sin fecha',
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () => setState(() {
                                  _expirationDate = null;
                                  _expirationManual = true;
                                }),
                              ),
                      ),
                  child: Text(
                    _expirationDate == null
                        ? 'Sin fecha'
                        : '${_expirationDate!.day.toString().padLeft(2, '0')}/'
                              '${_expirationDate!.month.toString().padLeft(2, '0')}/'
                              '${_expirationDate!.year}',
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
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  value: _isStaple,
                  activeThumbColor: AppColors.woodDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'No añadir a la compra',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Básicos que siempre tienes'),
                  onChanged: (v) => setState(() => _isStaple = v),
                ),
              ),
            ],

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveItem,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      widget.isEditing
                          ? 'Guardar cambios'
                          : 'Guardar en el inventario',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
