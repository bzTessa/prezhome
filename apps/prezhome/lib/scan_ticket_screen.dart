import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/money.dart';

import 'models/shopping_list_item.dart';
import 'services/count_prefs.dart';
import 'services/offline_provider.dart';
import 'services/price_memory.dart';
import 'services/shopping_checkout.dart';
import 'theme/app_theme.dart';
import 'utils/friendly_error.dart';
import 'utils/shopping_display.dart';
import 'utils/ticket_date.dart';
import 'utils/ticket_reconcile.dart';
import 'widgets/food_category_icon.dart';
import 'widgets/miau_character.dart';
import 'l10n/l10n.dart';

/// Escanea un ticket con la cámara/galería, lo procesa con IA y muestra una
/// pantalla de revisión editable antes de guardar. Aprende las correcciones.
/// Con [ticketId] edita un ticket ya guardado (fecha, tienda, productos).
class ScanTicketScreen extends StatefulWidget {
  const ScanTicketScreen({super.key, this.ticketId, this.shoppingListId});

  final String? ticketId;

  /// Lista de la compra desde la que se abre el escáner (null = principal).
  final String? shoppingListId;

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
  bool _pantryToggledByUser = false;
  TicketReconcileResult? _reconcile;
  Future<void>? _reconcileFuture;
  bool _autoSkippedPantry = false;

  @override
  void initState() {
    super.initState();
    if (widget.ticketId != null) _loadTicket(widget.ticketId!);
  }

  /// Carga un ticket guardado en la pantalla de revisión.
  Future<void> _loadTicket(String id) async {
    setState(() => _processing = true);
    try {
      final t = await _client
          .from('tickets')
          .select(
            'merchant, purchased_at, created_at, '
            'ticket_items(raw_name, name, category, quantity, total_price, position)',
          )
          .eq('id', id)
          .single();
      final items = [...(t['ticket_items'] as List? ?? const [])]
        ..sort(
          (a, b) => ((a['position'] as num?) ?? 0).compareTo(
            (b['position'] as num?) ?? 0,
          ),
        );
      String s(dynamic v) => v == null ? '' : v.toString();
      String n(dynamic v) {
        final d = (v as num?)?.toDouble();
        if (d == null) return '';
        return d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toString();
      }

      if (!mounted) return;
      setState(() {
        _merchantController.text = s(t['merchant']);
        _purchasedAt = ticketDate(t) ?? DateTime.now();
        _items = [
          for (final m in items)
            _ItemRow(
              rawName: s(m['raw_name']),
              name: s(m['name']),
              category: s(m['category']),
              quantity: n(m['quantity']),
              totalPrice: n(m['total_price']),
            ),
        ];
        _hasResult = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e, context.l.stkOpenError))),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  /// Guarda los cambios de un ticket ya guardado: datos del ticket y sus
  /// productos (se reemplazan). No toca la despensa ni la lista.
  Future<void> _saveEdit(String id) async {
    setState(() => _saving = true);
    try {
      final t = await _client
          .from('tickets')
          .update({
            'merchant': _merchantController.text.trim(),
            'total_amount': _total,
            'purchased_at': _purchasedAt.toIso8601String().split('T').first,
          })
          .eq('id', id)
          .select('home_id')
          .single();
      // Primero los nuevos y luego se quitan los viejos: si algo falla a
      // medias no se pierden los productos.
      final old = await _client
          .from('ticket_items')
          .select('id')
          .eq('ticket_id', id);
      final rows = _itemRows(id, t['home_id']);
      if (rows.isNotEmpty) await _client.from('ticket_items').insert(rows);
      final oldIds = [for (final r in old) r['id']];
      if (oldIds.isNotEmpty) {
        await _client.from('ticket_items').delete().inFilter('id', oldIds);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e, context.l.nutSaveError)),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<Map<String, dynamic>> _itemRows(String ticketId, dynamic homeId) {
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
        'category': it.category.label,
        'quantity': _num(it.quantity.text),
        'total_price': _num(it.totalPrice.text),
        'position': pos++,
      });
    }
    return rows;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    for (final it in _items) {
      it.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndScan(ImageSource source) async {
    final l = context.l;
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
            : l.stkReadError;
        throw msg;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e, context.l.stkScanError)),
            backgroundColor: AppColors.expired,
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
      if (parsed != null) _purchasedAt = plausibleTicketDate(parsed);
      _items = items;
      _hasResult = true;
      _reconcile = null;
      _autoSkippedPantry = false;
      _addToPantry = true;
      _pantryToggledByUser = false;
    });
    _reconcileFuture = _reconcileLoadedItems();
    unawaited(_reconcileFuture);
  }

  Future<void> _reconcileLoadedItems() async {
    try {
      final shoppingRows = await OfflineProvider.instance.shopping.readCached();
      final listItems = [
        for (final r in shoppingRows) ShoppingListItem.fromMap(r),
      ];
      final recent = await RecentCheckoutStore().load();
      final result = reconcileTicket(
        ticketNames: [for (final it in _items) it.name.text.trim()],
        listItems: listItems,
        recentCheckouts: recent,
        now: DateTime.now(),
      );
      if (!mounted) return;
      setState(() {
        _reconcile = result;
        if (result.likelyAlreadySavedToPantry && !_pantryToggledByUser) {
          _addToPantry = false;
          _autoSkippedPantry = true;
        }
      });
    } catch (_) {
      // Sin caché local sigue el comportamiento estándar.
    }
  }

  double _num(String v) => double.tryParse(v.trim().replaceAll(',', '.')) ?? 0;

  double get _total =>
      _items.fold(0.0, (a, it) => a + _num(it.totalPrice.text));

  Future<void> _save() async {
    final l = context.l;
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
      if (homeId == null) throw l.planNoHome;

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
      final rows = _itemRows(ticketId, homeId);
      if (rows.isNotEmpty) {
        await _client.from('ticket_items').insert(rows);
      }

      // 2b. Aprender PRECIOS de los productos (memoria de precios por hogar),
      //     para estimar costes de la compra y de las comidas. Best-effort.
      final priceLines = <({String name, double quantity, double totalPrice})>[
        for (final it in _items)
          if (it.name.text.trim().isNotEmpty && _num(it.totalPrice.text) > 0)
            (
              name: it.name.text.trim(),
              quantity: _num(it.quantity.text),
              totalPrice: _num(it.totalPrice.text),
            ),
      ];
      if (priceLines.isNotEmpty) {
        await PriceMemory(_client).learnFromTicket(homeId, priceLines);
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
            'category': it.category.label,
            'updated_at': DateTime.now().toIso8601String(),
          };
        }
      }
      if (aliasByRaw.isNotEmpty) {
        await _client
            .from('product_aliases')
            .upsert(aliasByRaw.values.toList(), onConflict: 'home_id,raw_name');
      }

      // 4. Esperamos la conciliación por si se guardó muy rápido y añadimos los
      //    productos a la despensa si procede.
      try {
        await _reconcileFuture;
      } catch (_) {}
      if (_addToPantry) {
        try {
          await _addItemsToPantry(homeId);
        } catch (e) {
          debugPrint('No se pudo actualizar la despensa: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(friendlyError(e, context.l.stkPantryError)),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      // 5. Quitar de la lista y del carrito lo que trae el ticket. Secundario.
      var crossed = 0;
      try {
        crossed = await ShoppingCheckout(client: _client).clearCoveredByTicket([
          for (final it in _items)
            if (it.name.text.trim().isNotEmpty) it.name.text.trim(),
        ], listId: widget.shoppingListId);
      } catch (e) {
        debugPrint('No se pudo tachar de la lista: $e');
      }

      if (!mounted) return;
      if (crossed > 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l.stkCrossed(crossed))));
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e, context.l.nutSaveError)),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Mete los productos del ticket en "En casa" vía [ShoppingCheckout],
  /// conservando los gramos/envases de lo que estuviera en la lista o guardado
  /// en [CountPrefs] y evitando duplicar en la caché offline.
  Future<void> _addItemsToPantry(dynamic homeId) async {
    final hid = homeId.toString();
    if ((await OfflineProvider.instance.inventory.readCached()).isEmpty) {
      try {
        await OfflineProvider.instance.inventory.refreshFromRemote();
      } catch (_) {}
    }
    try {
      await CountPrefs(_client).load(hid);
    } catch (_) {}
    final checkout = ShoppingCheckout(client: _client);
    final toAdd = <ShoppingListItem>[];
    final addedNames = <String>[];
    for (var i = 0; i < _items.length; i++) {
      // Si este producto concreto ya se había guardado desde la lista hace
      // poco, lo saltamos salvo que la persona encendiera el switch a mano.
      if (!_pantryToggledByUser &&
          (_reconcile?.alreadyInPantryIndices.contains(i) ?? false)) {
        continue;
      }
      final it = _items[i];
      final name = it.name.text.trim();
      if (name.isEmpty) continue;
      final qtyRaw = _num(it.quantity.text);
      final qty = qtyRaw > 0 ? qtyRaw : 1.0;
      final candidate = _reconcile?.matchedListItems[i];
      final matched =
          candidate != null &&
              ticketCovers(name, shoppingCleanName(candidate.name))
          ? candidate
          : null;
      var unit = 'unidades';
      var finalQty = qty;
      double? packSize;
      String? imageUrl;
      var itemType =
          it.category == FoodCategory.limpieza ||
              it.category == FoodCategory.hogar
          ? 'hogar'
          : 'comida';
      if (matched != null) {
        imageUrl = matched.imageUrl;
        itemType = matched.itemType;
        if (matched.packSize != null && matched.packSize! > 0) {
          unit = matched.unit ?? 'unidades';
          packSize = matched.packSize;
          finalQty = qty * matched.packSize!;
        } else if (qty == 1 && matched.quantity != null) {
          unit = matched.unit ?? 'unidades';
          finalQty = matched.quantity!;
        } else if (matched.unit != null && !isMeasureUnit(matched.unit)) {
          unit = matched.unit!;
        }
      }
      toAdd.add(
        ShoppingListItem(
          homeId: hid,
          name: name,
          quantity: finalQty,
          unit: unit,
          itemType: itemType,
          category: it.category.label,
          imageUrl: imageUrl,
          packSize: packSize,
        ),
      );
      addedNames.add(name);
    }
    for (final item in toAdd) {
      await checkout.addToPantry(item, homeId: hid);
    }
    if (addedNames.isNotEmpty) {
      await RecentCheckoutStore().record(addedNames);
    }
    unawaited(OfflineProvider.instance.inventory.tryDrain(force: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          widget.ticketId == null ? context.l.ecoScan : context.l.stkEdit,
        ),
      ),
      body: _processing
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(context.l.stkReading),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: AppTheme.surfaceDecoration(radius: AppRadius.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: MiauCharacter(
                  mood: MiauMood.shopping,
                  size: 112,
                  interactive: true,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.l.stkStartTitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.headline,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l.stkStartSub,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: AppSpacing.xxl),
              FilledButton.icon(
                onPressed: () => _pickAndScan(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(context.l.takePhoto),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.terracotta,
                  foregroundColor: AppColors.onTerracotta,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () => _pickAndScan(ImageSource.gallery),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  backgroundColor: AppColors.card,
                  minimumSize: const Size.fromHeight(50),
                  side: BorderSide(color: AppColors.cardEdge),
                ),
                icon: Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.terracottaText,
                ),
                label: Text(context.l.rdGallery),
              ),
            ],
          ),
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
                    Text(
                      context.l.stkReview,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l.stkRemember,
                      style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _merchantController,
                      decoration: _dec(context.l.stkStore),
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
                        decoration: _dec(context.l.date),
                        child: Text(DateFormat.yMd().format(_purchasedAt)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (widget.ticketId == null && _autoSkippedPantry) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.goldBg,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: AppElevation.border,
                        ),
                        child: Row(
                          children: [
                            const MiauCharacter(
                              mood: MiauMood.curious,
                              size: 40,
                              float: false,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                context.l.stkAlreadyInPantryNotice,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (widget.ticketId == null)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.l.stkAddPantry),
                        subtitle: Text(context.l.stkAddPantrySub),
                        value: _addToPantry,
                        activeThumbColor: AppColors.wood,
                        onChanged: (val) {
                          setState(() {
                            _pantryToggledByUser = true;
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
                    context.l.stkProducts(_items.length),
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setState(() => _items.add(_ItemRow())),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(context.l.add),
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
                  decoration: _dec(context.l.product),
                ),
              ),
              IconButton(
                tooltip: context.l.remove,
                icon: Icon(Icons.close, color: AppColors.expired),
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
                  context.l.stkRaw(it.rawName),
                  style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<FoodCategory>(
                  initialValue: it.category,
                  isExpanded: true,
                  decoration: _dec(context.l.category),
                  items: [
                    for (final c in FoodCategory.values)
                      DropdownMenuItem(
                        value: c,
                        child: Text(
                          '${c.emoji} ${context.l.foodCategory(c.name)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (c) => it.category = c ?? it.category,
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
                  decoration: _dec(context.l.stkQty),
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
                  decoration: _dec(currencySymbol()),
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
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l.total,
                  style: TextStyle(color: AppColors.inkMuted),
                ),
                Text(
                  money(_total),
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
                onPressed: _saving
                    ? null
                    : widget.ticketId == null
                    ? _save
                    : () => _saveEdit(widget.ticketId!),
                child: _saving
                    ? const CircularProgressIndicator()
                    : Text(context.l.stkSave),
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

/// La del ticket si es una de las nuestras; si no ("otros"…), la que
/// sugiere el nombre del producto o, si tampoco, lo que ponía el ticket
/// ([raw], a veces en catalán: "XOCOLATA").
FoodCategory guessTicketCategory(
  String fromTicket,
  String name, [
  String? raw,
]) {
  // Los tickets guardan el nombre ("Lácteos"); la IA da la clave ("lacteos").
  final key = CategoryIcons.normalize(fromTicket);
  for (final c in FoodCategory.values) {
    if (c == FoodCategory.otros) continue;
    if (c.name == key || CategoryIcons.normalize(c.label) == key) return c;
  }
  final byName = CategoryIcons.categoryFor(name);
  if (byName != FoodCategory.otros || raw == null) return byName;
  return CategoryIcons.categoryFor(raw);
}

class _ItemRow {
  final String rawName;
  final TextEditingController name;
  FoodCategory category;
  final TextEditingController quantity;
  final TextEditingController totalPrice;

  _ItemRow({
    this.rawName = '',
    String name = '',
    String category = '',
    String quantity = '1',
    String totalPrice = '',
  }) : name = TextEditingController(text: name),
       category = guessTicketCategory(category, name, rawName),
       quantity = TextEditingController(text: quantity),
       totalPrice = TextEditingController(text: totalPrice);

  void dispose() {
    name.dispose();
    quantity.dispose();
    totalPrice.dispose();
  }
}
