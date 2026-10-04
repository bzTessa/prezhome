import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_inventory_item_screen.dart';
import 'models/inventory_item.dart';
import 'theme/app_theme.dart';
import 'utils/shopping_display.dart';
import 'widgets/food_image.dart';
import 'widgets/miau_character.dart';

/// Una sección del inventario agrupada por ubicación (Nevera, Congelador,
/// Despensa, Bebidas, Especias o Hogar y limpieza). Agrupa los items y lleva su
/// presentación (icono + título) para pintar la cabecera.
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

  /// Clave estable para recordar el estado expandido/colapsado entre rebuilds.
  String get key => title;

  int get frescos =>
      items.where((i) => i.expiryStatus == ExpiryStatus.fresco).length;
  int get pronto =>
      items.where((i) => i.expiryStatus == ExpiryStatus.pronto).length;
  int get caducados =>
      items.where((i) => i.expiryStatus == ExpiryStatus.caducado).length;

  /// Secciones "tranquilas" que arrancan colapsadas aunque no tengan urgencias:
  /// condimentos y hogar no suelen caducar y abultan el scroll.
  bool get isCalmByDefault =>
      title == 'Especias y condimentos' || title == 'Hogar y limpieza';

  /// Apertura inteligente (NN/g: no esconder lo urgente). Una sección arranca
  /// EXPANDIDA si contiene algún item que caduca pronto o ya caducado; en caso
  /// contrario, y siempre para las secciones tranquilas, arranca COLAPSADA.
  bool get defaultExpanded {
    if (isCalmByDefault) return false;
    if (!isFood) return false;
    return pronto > 0 || caducados > 0;
  }
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
  // 'Bebidas' | 'Especias' | 'Hogar'. Se aplica en cliente sobre la lista ya
  // cargada.
  String _sectionFilter = 'todo';

  // Overrides manuales de expandido/colapsado por sección (clave = título). Lo
  // que la usuaria toca manda sobre la apertura inteligente por defecto.
  final Map<String, bool> _expandedOverrides = {};

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
      case 'Bebidas':
        return i.itemType == 'comida' && i.category == 'Bebidas';
      case 'Despensa':
        return i.itemType == 'comida' &&
            i.category != 'Nevera' &&
            i.category != 'Congelador' &&
            i.category != 'Especias' &&
            i.category != 'Bebidas';
      default:
        return true;
    }
  }

  /// Barra de filtros por sección: scroll horizontal de chips (Todo, Nevera,
  /// Congelador, Despensa, Bebidas, Condimentos, Hogar). Da más divisiones que
  /// el viejo Todo/Comida/Hogar sin tocar la base de datos.
  Widget _sectionFilterBar() {
    const filters = <(String, String, IconData)>[
      ('todo', 'Todo', Icons.apps_rounded),
      ('Nevera', 'Nevera', Icons.kitchen),
      ('Congelador', 'Congelador', Icons.ac_unit),
      ('Despensa', 'Despensa', Icons.inventory_2),
      ('Bebidas', 'Bebidas', Icons.local_drink),
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
            // Al tocar un filtro concreto limpiamos los overrides manuales para
            // que la sección enfocada aplique su apertura inteligente de nuevo
            // (y la sección filtrada se muestre expandida).
            onTap: () {
              setState(() {
                _sectionFilter = value;
                _expandedOverrides.clear();
              });
            },
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
  /// Nevera, Congelador, Despensa, Bebidas, Especias y, al final, Hogar y
  /// limpieza.
  List<_InventorySection> _groupIntoSections(List<InventoryItem> items) {
    // Las comidas se agrupan por su ubicación (category). El resto (hogar) va
    // a una sección propia porque no tiene caducidad.
    final nevera = <InventoryItem>[];
    final congelador = <InventoryItem>[];
    final despensa = <InventoryItem>[];
    final especias = <InventoryItem>[];
    final bebidas = <InventoryItem>[];
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
        case 'Bebidas':
          bebidas.add(item);
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
    sortByExpiry(bebidas);
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
      // Bebidas: agua, refrescos, zumos, leche, vino... Con semáforo de
      // caducidad porque algunas (leche, zumo) sí caducan.
      _InventorySection(
        title: 'Bebidas',
        icon: Icons.local_drink,
        isFood: true,
        items: bebidas,
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

    // Resumen superior tipo dashboard + una tarjeta colapsable por sección.
    final children = <Widget>[
      _DashboardSummary(sections: sections),
      const SizedBox(height: 16),
    ];
    for (final section in sections) {
      children.add(_sectionCard(section));
      children.add(const SizedBox(height: 14));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: children,
    );
  }

  /// ¿Está la sección expandida? Si el usuario la tocó manualmente respetamos
  /// su decisión; si no, aplicamos la apertura inteligente por defecto. Cuando
  /// hay un filtro de sección activo (distinto de 'todo'), la sección mostrada
  /// se fuerza a expandida para que no quede escondida.
  bool _isExpanded(_InventorySection section) {
    final override = _expandedOverrides[section.key];
    if (override != null) return override;
    if (_sectionFilter != 'todo') return true;
    return section.defaultExpanded;
  }

  void _toggleSection(_InventorySection section) {
    final current = _isExpanded(section);
    setState(() {
      _expandedOverrides[section.key] = !current;
    });
  }

  /// Una sección = UNA tarjeta cozy colapsable: cabecera-toggle (icono + título
  /// + contador + resumen compacto de estado + chevron) y, debajo, las filas de
  /// producto separadas por divisores suaves. Reduce el ruido visual frente a
  /// una tarjeta con sombra por producto.
  Widget _sectionCard(_InventorySection section) {
    final expanded = _isExpanded(section);
    return Container(
      decoration: AppTheme.cardDecoration(radius: 18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(section, expanded),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeInOut,
            crossFadeState: expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _sectionBody(section),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _sectionBody(_InventorySection section) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Column(
        children: [
          for (var i = 0; i < section.items.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: AppColors.cream.withValues(alpha: 1)),
            _itemRow(section.items[i], section),
          ],
        ],
      ),
    );
  }

  /// Cabecera-toggle de la sección: actúa como botón para plegar/desplegar.
  Widget _sectionHeader(_InventorySection section, bool expanded) {
    return InkWell(
      onTap: () => _toggleSection(section),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${section.title} · ${section.items.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                  ),
                  // Resumen compacto de estado para ver de un vistazo si una
                  // sección colapsada esconde urgencias.
                  if (section.isFood &&
                      (section.pronto > 0 || section.caducados > 0)) ...[
                    const SizedBox(height: 4),
                    _miniStatusRow(section),
                  ],
                ],
              ),
            ),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 220),
              child: Icon(
                Icons.expand_more,
                color: AppColors.woodDark,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fila compacta de estado (pronto / caducados) para la cabecera de sección.
  Widget _miniStatusRow(_InventorySection section) {
    final chips = <Widget>[];
    if (section.caducados > 0) {
      chips.add(
        _miniStatusChip(
          '${section.caducados} caducados',
          AppColors.expiredBg,
          AppColors.expired,
        ),
      );
    }
    if (section.pronto > 0) {
      chips.add(
        _miniStatusChip(
          '${section.pronto} caducan pronto',
          AppColors.soonBg,
          AppColors.soon,
        ),
      );
    }
    return Wrap(spacing: 6, runSpacing: 4, children: chips);
  }

  Widget _miniStatusChip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  /// Fila de producto limpia y táctil dentro de la tarjeta de sección. Sin
  /// triple redundancia de ubicación: no repetimos la ubicación en el subtítulo
  /// (la da la sección) ni la pastilla 'Hogar/Limpieza'. Conservamos la pastilla
  /// 'No se compra' (is_staple), la cantidad legible y el chip de caducidad.
  Widget _itemRow(InventoryItem item, _InventorySection section) {
    // Las especias son 'comida' pero no mostramos chip de caducidad (no suele
    // aplicar y ensucia la fila con "Sin fecha").
    final isFood = item.itemType == 'comida' && item.category != 'Especias';
    final qty = inventoryQtyLabel(item.quantity, item.unit);
    final subtitleParts = <String>[
      if (qty.isNotEmpty) qty,
      if (item.kind != 'ingredient') item.kindLabel,
      if (item.servings != null) '${item.servings!.toStringAsFixed(0)} rac.',
    ];

    return InkWell(
      onTap: () => _openItemActions(item),
      onLongPress: () => _openItemActions(item),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            FoodImage(
              name: item.name,
              itemType: item.itemType,
              imageUrl: item.imageUrl,
              size: 52,
              radius: 14,
              // Muestra la FOTO real del alimento si la hay; si no, cae a la
              // ilustración cozy por categoría. Las especias usan siempre
              // ilustración (sus fotos salen genéricas).
              forceIllustration: item.category == 'Especias',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shoppingCleanName(item.name),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      if (item.isStaple) _stapleBadge(),
                    ],
                  ),
                  if (subtitleParts.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitleParts.join(' • '),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.ink.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                  if (isFood) ...[
                    const SizedBox(height: 6),
                    _ExpiryChip(item: item),
                  ],
                ],
              ),
            ),
            // Las acciones (editar / no comprar / eliminar) van por pulsación;
            // un punto de "más" lo insinúa.
            Icon(Icons.more_vert, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  /// Pastilla "No se compra" (is_staple). Esta información NO la da la sección,
  /// por eso se conserva en la fila.
  Widget _stapleBadge() {
    return Container(
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
          Icon(Icons.remove_shopping_cart, size: 12, color: AppColors.woodDark),
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
    );
  }

  /// Menú de acciones de un producto (pulsación larga o toque): marcar/quitar
  /// "no comprar", editar y eliminar.
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

/// Resumen superior tipo dashboard de TODA la despensa (ya filtrada): totales
/// de Frescos / Caducan pronto / Caducados en números grandes con los colores
/// de estado de AppColors, más un Miau cozy con un mensaje que cambia según la
/// urgencia. Pensado para que "entre por los ojos" y sirva de vistazo rápido.
class _DashboardSummary extends StatelessWidget {
  final List<_InventorySection> sections;
  const _DashboardSummary({required this.sections});

  @override
  Widget build(BuildContext context) {
    var frescos = 0;
    var pronto = 0;
    var caducados = 0;
    for (final s in sections) {
      if (!s.isFood) continue;
      frescos += s.frescos;
      pronto += s.pronto;
      caducados += s.caducados;
    }

    // Miau reacciona a lo que de verdad importa: alarma suave si hay caducados,
    // aviso si algo caduca pronto, y tranquilidad si todo está en orden.
    final MiauMood mood;
    final String message;
    if (caducados > 0) {
      mood = MiauMood.neutral;
      message = caducados == 1
          ? '¡Miau! Hay 1 producto caducado, échale un ojo.'
          : '¡Miau! Hay $caducados productos caducados, échales un ojo.';
    } else if (pronto > 0) {
      mood = MiauMood.curious;
      message = pronto == 1
          ? 'Ojo: 1 producto caduca pronto. ¡A cocinarlo!'
          : 'Ojo: $pronto productos caducan pronto. ¡A cocinarlos!';
    } else {
      mood = MiauMood.celebrating;
      message = 'Todo bajo control en tu despensa, ¡bien hecho!';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(radius: 18),
      child: Column(
        children: [
          Row(
            children: [
              MiauCharacter(mood: mood, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _DashboardStat(
                label: 'Frescos',
                count: frescos,
                color: AppColors.fresh,
                background: AppColors.freshBg,
                icon: Icons.check_circle,
              ),
              const SizedBox(width: 8),
              _DashboardStat(
                label: 'Caducan pronto',
                count: pronto,
                color: AppColors.soon,
                background: AppColors.soonBg,
                icon: Icons.schedule,
              ),
              const SizedBox(width: 8),
              _DashboardStat(
                label: 'Caducados',
                count: caducados,
                color: AppColors.expired,
                background: AppColors.expiredBg,
                icon: Icons.warning_amber_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tarjeta-resumen del dashboard: un NÚMERO grande y su etiqueta de estado con
/// el color cálido correspondiente (fresco/pronto/caducado).
class _DashboardStat extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color background;
  final IconData icon;

  const _DashboardStat({
    required this.label,
    required this.count,
    required this.color,
    required this.background,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: active ? background : AppColors.cream,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.45) : AppColors.wood,
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: active ? color : AppColors.woodDark),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: active ? color : AppColors.woodDark,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
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
