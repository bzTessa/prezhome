import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_inventory_item_screen.dart';
import 'models/inventory_item.dart';
import 'theme/app_theme.dart';
import 'widgets/food_image.dart';
import 'widgets/miau_character.dart';

/// Una sección del inventario agrupada por ubicación (Nevera, Congelador,
/// Despensa o Hogar y limpieza). Agrupa los items y lleva su presentación
/// (icono + título) para pintar la cabecera.
class _InventorySection {
  final String title;
  final IconData icon;
  final bool isFood;
  final List<InventoryItem> items;

  const _InventorySection({
    required this.title,
    required this.icon,
    required this.isFood,
    required this.items,
  });
}

class InventoryScreen extends StatefulWidget {
  final bool embedded;
  const InventoryScreen({super.key, this.embedded = false});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  late Future<List<InventoryItem>> _itemsFuture;

  // Filtro por sección: 'todo' | 'Nevera' | 'Congelador' | 'Despensa' |
  // 'Especias' | 'Hogar'. Se aplica en cliente sobre la lista ya cargada.
  String _sectionFilter = 'todo';

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
            backgroundColor: AppColors.expired,
          ),
        );
      }
    }
  }

  /// Alterna el flag "siempre en casa" (is_staple) de un item para que la
  /// usuaria pueda gestionar sus basicos de un vistazo desde el inventario.
  Future<void> _toggleStaple(InventoryItem item, bool value) async {
    try {
      await supabase
          .from('inventory_items')
          .update({'is_staple': value})
          .eq('id', item.id);
      _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? '${item.name} ya no aparecerá en la compra.'
                : '${item.name} volverá a aparecer en la compra.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar: $e'),
          backgroundColor: AppColors.expired,
        ),
      );
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
      backgroundColor: AppColors.cream,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text(
                'Despensa y Nevera',
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: AppColors.cream,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.ink),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-inventory',
        onPressed: _openAddItem,
        backgroundColor: AppColors.wood,
        foregroundColor: AppColors.ink,
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
                children: const [
                  MiauCharacter(mood: MiauMood.curious, size: 120),
                  SizedBox(height: 16),
                  Text(
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

          // Filtrado en cliente por sección (ubicación / tipo).
          final filtered = _sectionFilter == 'todo'
              ? items
              : items.where(_matchesSectionFilter).toList();

          return Column(
            children: [
              _sectionFilterBar(),
              Expanded(child: _buildSections(filtered)),
            ],
          );
        },
      ),
    );
  }

  /// ¿El item encaja con el filtro de sección seleccionado?
  bool _matchesSectionFilter(InventoryItem i) {
    switch (_sectionFilter) {
      case 'Hogar':
        return i.itemType != 'comida';
      case 'Nevera':
        return i.itemType == 'comida' && i.category == 'Nevera';
      case 'Congelador':
        return i.itemType == 'comida' && i.category == 'Congelador';
      case 'Especias':
        return i.itemType == 'comida' && i.category == 'Especias';
      case 'Despensa':
        return i.itemType == 'comida' &&
            i.category != 'Nevera' &&
            i.category != 'Congelador' &&
            i.category != 'Especias';
      default:
        return true;
    }
  }

  /// Barra de filtros por sección: scroll horizontal de chips (Todo, Nevera,
  /// Congelador, Despensa, Condimentos, Hogar). Da más divisiones que el viejo
  /// Todo/Comida/Hogar sin tocar la base de datos.
  Widget _sectionFilterBar() {
    const filters = <(String, String, IconData)>[
      ('todo', 'Todo', Icons.apps_rounded),
      ('Nevera', 'Nevera', Icons.kitchen),
      ('Congelador', 'Congelador', Icons.ac_unit),
      ('Despensa', 'Despensa', Icons.inventory_2),
      ('Especias', 'Condimentos', Icons.grass),
      ('Hogar', 'Hogar y limpieza', Icons.cleaning_services),
    ];
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (value, label, icon) = filters[i];
          final selected = _sectionFilter == value;
          return GestureDetector(
            onTap: () => setState(() => _sectionFilter = value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.woodDark : AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppColors.woodDark : AppColors.wood,
                  width: 1.4,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? Colors.white : AppColors.woodDark,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Agrupa la lista por ubicación en secciones de orden fijo:
  /// Nevera, Congelador, Despensa y, al final, Hogar y limpieza.
  List<_InventorySection> _groupIntoSections(List<InventoryItem> items) {
    // Las comidas se agrupan por su ubicación (category). El resto (hogar) va
    // a una sección propia porque no tiene caducidad.
    final nevera = <InventoryItem>[];
    final congelador = <InventoryItem>[];
    final despensa = <InventoryItem>[];
    final especias = <InventoryItem>[];
    final hogar = <InventoryItem>[];

    for (final item in items) {
      if (item.itemType != 'comida') {
        hogar.add(item);
        continue;
      }
      switch (item.category) {
        case 'Nevera':
          nevera.add(item);
          break;
        case 'Congelador':
          congelador.add(item);
          break;
        case 'Despensa':
          despensa.add(item);
          break;
        case 'Especias':
          especias.add(item);
          break;
        default:
          // Cualquier otra ubicación de comida se trata como despensa.
          despensa.add(item);
      }
    }

    // Dentro de cada sección de comida ordenamos por caducidad más próxima;
    // los que no tienen fecha quedan al final (orden estable para el resto).
    void sortByExpiry(List<InventoryItem> list) {
      list.sort((a, b) {
        final da = a.daysUntilExpiry;
        final db = b.daysUntilExpiry;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
    }

    sortByExpiry(nevera);
    sortByExpiry(congelador);
    sortByExpiry(despensa);
    // Las especias no se ordenan por caducidad (no suele aplicar); las dejamos
    // en su orden natural de llegada.

    final sections = <_InventorySection>[
      _InventorySection(
        title: 'Nevera',
        icon: Icons.kitchen,
        isFood: true,
        items: nevera,
      ),
      _InventorySection(
        title: 'Congelador',
        icon: Icons.ac_unit,
        isFood: true,
        items: congelador,
      ),
      _InventorySection(
        title: 'Despensa',
        icon: Icons.inventory_2,
        isFood: true,
        items: despensa,
      ),
      // Especias y condimentos: básicos que no caducan rápido ni van a la
      // compra. Sin semáforo de caducidad (isFood: false) para no mostrar
      // chips de "sin fecha" en algo que no lo necesita.
      _InventorySection(
        title: 'Especias y condimentos',
        icon: Icons.grass,
        isFood: false,
        items: especias,
      ),
      _InventorySection(
        title: 'Hogar y limpieza',
        icon: Icons.cleaning_services,
        isFood: false,
        items: hogar,
      ),
    ];

    // Solo mostramos secciones con contenido.
    return sections.where((s) => s.items.isNotEmpty).toList();
  }

  Widget _buildSections(List<InventoryItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No hay productos en esta categoría.',
            style: TextStyle(color: AppColors.ink, fontSize: 15),
          ),
        ),
      );
    }

    final sections = _groupIntoSections(items);

    // Construimos una lista plana de widgets: cabecera + tarjetas por sección.
    final children = <Widget>[];
    for (final section in sections) {
      children.add(_sectionHeader(section));
      for (final item in section.items) {
        children.add(_itemCard(item));
      }
      children.add(const SizedBox(height: 8));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: children,
    );
  }

  Widget _sectionHeader(_InventorySection section) {
    // Resumen de la sección estilo "app de nevera": título + total y, para las
    // secciones de comida, una fila de números grandes por estado
    // (Frescos / Pronto / Caducados) con los colores de estado de AppColors.
    final int frescos;
    final int pronto;
    final int caducados;
    if (section.isFood) {
      frescos = section.items
          .where((i) => i.expiryStatus == ExpiryStatus.fresco)
          .length;
      pronto = section.items
          .where((i) => i.expiryStatus == ExpiryStatus.pronto)
          .length;
      caducados = section.items
          .where((i) => i.expiryStatus == ExpiryStatus.caducado)
          .length;
    } else {
      frescos = 0;
      pronto = 0;
      caducados = 0;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.wood,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(section.icon, color: AppColors.ink, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${section.title} · ${section.items.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          if (section.isFood) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _statSummary('Frescos', frescos, AppColors.fresh),
                const SizedBox(width: 8),
                _statSummary('Pronto', pronto, AppColors.soon),
                const SizedBox(width: 8),
                _statSummary('Caducados', caducados, AppColors.expired),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Tarjeta-resumen con un NÚMERO grande y su etiqueta de estado, con el color
  /// cálido correspondiente (fresco/pronto/caducado). Pensada para que la
  /// usuaria vea de un vistazo cómo está cada ubicación.
  Widget _statSummary(String label, int count, Color color) {
    final active = count > 0;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.45) : AppColors.wood,
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: active ? color : AppColors.woodDark,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: active ? color : AppColors.woodDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemCard(InventoryItem item) {
    // Las especias son 'comida' pero no mostramos chip de caducidad (no suele
    // aplicar y ensucia la tarjeta con "Sin fecha").
    final isFood = item.itemType == 'comida' && item.category != 'Especias';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration(radius: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onLongPress: () => _openItemActions(item),
        leading: FoodImage(
          name: item.name,
          itemType: item.itemType,
          imageUrl: item.imageUrl,
          size: 56,
          radius: 14,
          // Muestra la FOTO real del alimento si la hay (buscada en modo
          // "ingrediente crudo" para que acierte: pollo crudo, no un plato);
          // si no hay foto, cae a la ilustración cozy por categoría. Las
          // especias usan siempre ilustración (sus fotos salen genéricas).
          forceIllustration: item.category == 'Especias',
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
            ),
            if (item.isStaple)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.woodDark),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.remove_shopping_cart,
                      size: 12,
                      color: AppColors.woodDark,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'No se compra',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.woodDark,
                      ),
                    ),
                  ],
                ),
              ),
            if (item.itemType == 'hogar')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: AppColors.wood,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.itemTypeLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${item.quantity} ${item.unit} • ${item.category}'
              '${item.kind != 'ingredient' ? ' • ${item.kindLabel}' : ''}'
              '${item.servings != null ? ' • ${item.servings!.toStringAsFixed(0)} rac.' : ''}',
            ),
            if (isFood) ...[const SizedBox(height: 6), _ExpiryChip(item: item)],
          ],
        ),
        // Las acciones (no comprar / eliminar) van por pulsación larga, para no
        // ensuciar la fila con iconos. Un punto de "más" lo insinúa.
        trailing: Icon(Icons.more_vert, size: 20, color: Colors.grey[400]),
      ),
    );
  }

  /// Menú de acciones de un producto (pulsación larga): marcar/quitar "no
  /// comprar" y eliminar.
  Future<void> _openItemActions(InventoryItem item) async {
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
                Icons.edit_outlined,
                color: AppColors.woodDark,
              ),
              title: const Text('Editar'),
              onTap: () => Navigator.of(ctx).pop('edit'),
            ),
            if (item.itemType == 'comida')
              ListTile(
                leading: Icon(
                  item.isStaple
                      ? Icons.add_shopping_cart
                      : Icons.remove_shopping_cart,
                  color: AppColors.woodDark,
                ),
                title: Text(
                  item.isStaple
                      ? 'Volver a añadir a la compra'
                      : 'No añadir a la compra',
                ),
                subtitle: item.isStaple
                    ? null
                    : const Text('Para básicos que siempre tienes'),
                onTap: () => Navigator.of(ctx).pop('staple'),
              ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.expired,
              ),
              title: const Text('Eliminar'),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'edit') {
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => AddInventoryItemScreen(item: item)),
      );
      if (changed == true) _reload();
    } else if (action == 'staple') {
      await _toggleStaple(item, !item.isStaple);
    } else if (action == 'delete') {
      await _deleteItem(item);
    }
  }
}

/// Chip (pastilla) de estado de caducidad con color e icono cálidos y texto en
/// español sensible al día: 'Caducado', 'Caduca hoy', 'Caduca mañana',
/// 'Caduca en N días', o una fecha para los que están lejos; 'Sin fecha' si no
/// tiene caducidad conocida.
class _ExpiryChip extends StatelessWidget {
  final InventoryItem item;
  const _ExpiryChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final status = item.expiryStatus;
    final Color bg;
    final Color fg;
    final IconData icon;

    switch (status) {
      case ExpiryStatus.fresco:
        bg = AppColors.freshBg;
        fg = AppColors.fresh;
        icon = Icons.check_circle;
        break;
      case ExpiryStatus.pronto:
        bg = AppColors.soonBg;
        fg = AppColors.soon;
        icon = Icons.schedule;
        break;
      case ExpiryStatus.caducado:
        bg = AppColors.expiredBg;
        fg = AppColors.expired;
        icon = Icons.warning_amber_rounded;
        break;
      case ExpiryStatus.sinFecha:
        bg = AppColors.cream;
        fg = AppColors.woodDark;
        icon = Icons.help_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            _label(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  String _label() {
    final status = item.expiryStatus;
    if (status == ExpiryStatus.sinFecha) return 'Sin fecha';

    final days = item.daysUntilExpiry;
    if (days == null) return 'Sin fecha';

    if (days < 0) return 'Caducado';
    if (days == 0) return 'Caduca hoy';
    if (days == 1) return 'Caduca mañana';
    if (status == ExpiryStatus.pronto) return 'Caduca en $days días';

    // Fresco y lejano: mostramos una fecha completa dd/mm/yyyy para que no
    // sea ambigua al cruzar el cambio de año.
    final expiry = item.effectiveExpiry!;
    return 'Caduca ${expiry.day.toString().padLeft(2, '0')}/'
        '${expiry.month.toString().padLeft(2, '0')}/'
        '${expiry.year}';
  }
}
