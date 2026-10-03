import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/inventory_item.dart';
import 'services/shelf_life.dart';
import 'theme/app_theme.dart';

/// Escanea un ticket con la cámara/galería, lo procesa con IA y muestra una
/// pantalla de revisión editable antes de guardar. Aprende las correcciones.
class ScanTicketScreen extends StatefulWidget {
  const ScanTicketScreen({super.key});

  @override
  State<ScanTicketScreen> createState() => _ScanTicketScreenState();
}

class _ScanTicketScreenState extends State<ScanTicketScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  final _picker = ImagePicker();

  bool _processing = false;
  bool _saving = false;

  // Datos extraídos (editables)
  final _merchantController = TextEditingController();
  DateTime _purchasedAt = DateTime.now();
  List<_ItemRow> _items = [];
  bool _hasResult = false;
  bool _addToPantry = true;

  @override
  void dispose() {
    _merchantController.dispose();
    for (final it in _items) {
      it.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndScan(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (file == null) return;

      setState(() => _processing = true);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mime = file.mimeType ?? 'image/jpeg';

      final res = await _client.functions.invoke(
        'scan-ticket',
        body: {'image_base64': base64Image, 'mime_type': mime},
      );

      final data = res.data;
      if (data is Map && data['ticket'] is Map) {
        _applyResult(Map<String, dynamic>.from(data['ticket'] as Map));
      } else {
        final msg = (data is Map && data['error'] != null)
            ? data['error'].toString()
            : 'No se pudo leer el ticket';
        throw msg;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al escanear: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _applyResult(Map<String, dynamic> t) {
    String s(dynamic v) => v == null ? '' : v.toString();
    for (final it in _items) {
      it.dispose();
    }
    final items = <_ItemRow>[];
    final rawItems = t['items'];
    if (rawItems is List) {
      for (final raw in rawItems) {
        final m = raw is Map ? raw : {};
        items.add(
          _ItemRow(
            rawName: s(m['raw_name']),
            name: s(m['name']),
            category: s(m['category']),
            quantity: s(m['quantity']),
            totalPrice: s(m['total_price']),
          ),
        );
      }
    }
    setState(() {
      _merchantController.text = s(t['merchant']);
      final dateStr = s(t['purchased_at']);
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) _purchasedAt = parsed;
      _items = items;
      _hasResult = true;
    });
  }

  double _num(String v) => double.tryParse(v.trim().replaceAll(',', '.')) ?? 0;

  double get _total =>
      _items.fold(0.0, (a, it) => a + _num(it.totalPrice.text));

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw 'No autenticado';
      final profile = await _client
          .from('profiles')
          .select('home_id')
          .eq('id', user.id)
          .single();
      final homeId = profile['home_id'];
      if (homeId == null) throw 'No perteneces a ningún hogar.';

      // 1. Crear el ticket
      final ticket = await _client
          .from('tickets')
          .insert({
            'home_id': homeId,
            'storage_path': '', // (futuro: subir la imagen al bucket)
            'merchant': _merchantController.text.trim(),
            'total_amount': _total,
            'purchased_at': _purchasedAt.toIso8601String().split('T').first,
          })
          .select('id')
          .single();
      final ticketId = ticket['id'] as String;

      // 2. Insertar los items
      final rows = <Map<String, dynamic>>[];
      var pos = 0;
      for (final it in _items) {
        final name = it.name.text.trim();
        if (name.isEmpty) continue;
        rows.add({
          'ticket_id': ticketId,
          'home_id': homeId,
          'raw_name': it.rawName,
          'name': name,
          'category': it.category.text.trim().isEmpty
              ? null
              : it.category.text.trim(),
          'quantity': _num(it.quantity.text),
          'total_price': _num(it.totalPrice.text),
          'position': pos++,
        });
      }
      if (rows.isNotEmpty) {
        await _client.from('ticket_items').insert(rows);
      }

      // 3. Aprender correcciones: si el nombre corregido difiere del original,
      //    guardamos/actualizamos el alias para el futuro.
      //    Deduplicamos por raw_name (un ticket puede repetir el mismo texto),
      //    porque el upsert no admite dos filas con la misma clave a la vez.
      final aliasByRaw = <String, Map<String, dynamic>>{};
      for (final it in _items) {
        final raw = it.rawName.trim();
        final name = it.name.text.trim();
        if (raw.isNotEmpty && name.isNotEmpty && raw != name) {
          aliasByRaw[raw] = {
            'home_id': homeId,
            'raw_name': raw,
            'correct_name': name,
            'category': it.category.text.trim().isEmpty
                ? null
                : it.category.text.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          };
        }
      }
      if (aliasByRaw.isNotEmpty) {
        await _client
            .from('product_aliases')
            .upsert(aliasByRaw.values.toList(), onConflict: 'home_id,raw_name');
      }

      // 4. Añadir los productos a la despensa (inventario), si procede.
      //    Es un paso secundario: si falla, el ticket queda guardado igual.
      if (_addToPantry) {
        try {
          await _addItemsToPantry(homeId);
        } catch (e) {
          debugPrint('No se pudo actualizar la despensa: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'El ticket se guardó, pero no se pudo actualizar la '
                  'despensa: $e',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

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
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Mete los productos del ticket en el inventario (comida, en Despensa).
  /// Deduplica contra el inventario existente y dentro del propio ticket:
  /// si el producto ya existe por NOMBRE NORMALIZADO en CUALQUIER ubicación
  /// (Despensa, Nevera o Congelador), suma la cantidad sobre esa fila en vez
  /// de crear un duplicado. Solo si no existe en ninguna ubicación se inserta
  /// uno nuevo en Despensa (comida por defecto).
  ///
  /// La categoría que la IA asignó por línea del ticket NO se usa para la
  /// ubicación del inventario: todos los productos del ticket entran como
  /// 'comida' en 'Despensa'. Es una simplificación deliberada (lo pedido en el
  /// diseño y lo que anuncia el subtítulo del switch); mapear Nevera/Congelador
  /// desde la IA es opcional y queda fuera de alcance. El cruce se hace solo
  /// por nombre, así que un producto ya ubicado en Nevera/Congelador igualmente
  /// recibe la suma y no se duplica.
  Future<void> _addItemsToPantry(dynamic homeId) async {
    const category = 'Despensa';

    // Inventario actual del hogar (RLS ya filtra; el eq es explícito y barato).
    final existing = await _client
        .from('inventory_items')
        .select('id, name, item_type, quantity, created_at')
        .eq('home_id', homeId);

    // Índice por NOMBRE normalizado -> {id, quantity}, ignorando la ubicación.
    // Solo cruzamos contra filas de comida (item_type != 'hogar') para no
    // fusionar un alimento del ticket con un producto de limpieza que
    // casualmente se llame igual. Si hubiera varias filas con el mismo nombre,
    // elegimos de forma determinista la más antigua (menor created_at; a
    // igualdad, menor id) para que el resultado sea estable.
    final existingByName = <String, Map<String, dynamic>>{};
    for (final row in (existing as List)) {
      final map = Map<String, dynamic>.from(row as Map);
      final itemType = (map['item_type'] ?? 'comida').toString();
      if (itemType == 'hogar') continue;
      final name = (map['name'] ?? '').toString();
      final key = name.trim().toLowerCase();
      if (key.isEmpty) continue;
      final id = (map['id'] ?? '').toString();
      final createdAt = (map['created_at'] ?? '').toString();
      final candidate = {
        'id': map['id'],
        'quantity': (map['quantity'] as num?)?.toDouble() ?? 0,
        'created_at': createdAt,
        '_id': id,
      };
      final prev = existingByName[key];
      if (prev == null) {
        existingByName[key] = candidate;
      } else {
        final prevCreated = (prev['created_at'] as String);
        final prevId = (prev['_id'] as String);
        final isOlder =
            createdAt.compareTo(prevCreated) < 0 ||
            (createdAt == prevCreated && id.compareTo(prevId) < 0);
        if (isOlder) existingByName[key] = candidate;
      }
    }

    // Acumulamos las cantidades del ticket por nombre normalizado para no
    // duplicar dentro del propio lote (un ticket puede repetir el producto).
    final ticketByName = <String, Map<String, dynamic>>{};
    for (final it in _items) {
      final name = it.name.text.trim();
      if (name.isEmpty) continue;
      final qtyRaw = _num(it.quantity.text);
      final qty = qtyRaw > 0 ? qtyRaw : 1.0;
      final key = name.trim().toLowerCase();
      final acc = ticketByName[key];
      if (acc == null) {
        ticketByName[key] = {'name': name, 'quantity': qty};
      } else {
        acc['quantity'] = (acc['quantity'] as double) + qty;
      }
    }

    for (final entry in ticketByName.entries) {
      final name = entry.value['name'] as String;
      final qty = entry.value['quantity'] as double;
      final found = existingByName[entry.key];
      if (found != null) {
        final newQty = (found['quantity'] as double) + qty;
        await _client
            .from('inventory_items')
            .update({'quantity': newQty})
            .eq('id', found['id']);
      } else {
        // Caducidad orientativa automática según el producto (entra en
        // Despensa). La usuaria puede ajustarla luego desde el inventario.
        final estimated = ShelfLife.estimateDate(name, category);
        final item = InventoryItem(
          id: '',
          homeId: homeId,
          name: name,
          category: category,
          itemType: 'comida',
          quantity: qty,
          unit: 'unidades',
          kind: 'ingredient',
          expirationDate: estimated,
        );
        await _client.from('inventory_items').insert(item.toMap());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Escanear ticket')),
      body: _processing
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Leyendo el ticket con IA…'),
                ],
              ),
            )
          : _hasResult
          ? _buildReview()
          : _buildStart(),
    );
  }

  Widget _buildStart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 72,
              color: AppColors.wood,
            ),
            const SizedBox(height: 16),
            const Text(
              'Escanea el ticket de la compra',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'La IA extraerá los productos y precios. Después podrás revisarlo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _pickAndScan(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Hacer foto'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _pickAndScan(ImageSource.gallery),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                minimumSize: const Size.fromHeight(50),
                side: const BorderSide(color: AppColors.wood, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Elegir de la galería'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReview() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Revisa y corrige lo que haga falta',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tus correcciones se recordarán para la próxima vez.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _merchantController,
                      decoration: _dec('Tienda'),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _purchasedAt,
                          firstDate: DateTime(now.year - 3),
                          lastDate: now,
                        );
                        if (picked != null) {
                          setState(() => _purchasedAt = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: InputDecorator(
                        decoration: _dec('Fecha'),
                        child: Text(
                          '${_purchasedAt.day.toString().padLeft(2, '0')}/'
                          '${_purchasedAt.month.toString().padLeft(2, '0')}/'
                          '${_purchasedAt.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Añadir a la despensa'),
                      subtitle: const Text(
                        'Mete los productos en el inventario (comida, en '
                        'Despensa)',
                      ),
                      value: _addToPantry,
                      activeThumbColor: AppColors.wood,
                      onChanged: (val) {
                        setState(() {
                          _addToPantry = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'PRODUCTOS (${_items.length})',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setState(() => _items.add(_ItemRow())),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Añadir'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._items.asMap().entries.map((e) => _itemCard(e.key, e.value)),
            ],
          ),
        ),
        _bottomBar(),
      ],
    );
  }

  Widget _itemCard(int index, _ItemRow it) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardDecoration(radius: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: it.name,
                  decoration: _dec('Producto'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.redAccent),
                onPressed: () => setState(() {
                  _items.removeAt(index);
                  it.dispose();
                }),
              ),
            ],
          ),
          if (it.rawName.isNotEmpty && it.rawName != it.name.text)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 2, left: 4),
                child: Text(
                  'Ticket: "${it.rawName}"',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: it.category,
                  decoration: _dec('Categoría'),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: it.quantity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _dec('Cant.'),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: it.totalPrice,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _dec('€'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total', style: TextStyle(color: Colors.grey[600])),
                Text(
                  '${_total.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('Guardar ticket'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    isDense: true,
    filled: true,
    fillColor: AppColors.cream,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
}

class _ItemRow {
  final String rawName;
  final TextEditingController name;
  final TextEditingController category;
  final TextEditingController quantity;
  final TextEditingController totalPrice;

  _ItemRow({
    this.rawName = '',
    String name = '',
    String category = '',
    String quantity = '1',
    String totalPrice = '',
  }) : name = TextEditingController(text: name),
       category = TextEditingController(text: category),
       quantity = TextEditingController(text: quantity),
       totalPrice = TextEditingController(text: totalPrice);

  void dispose() {
    name.dispose();
    category.dispose();
    quantity.dispose();
    totalPrice.dispose();
  }
}
