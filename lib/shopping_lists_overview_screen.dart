import 'package:flutter/material.dart';

import 'models/shopping_category.dart';
import 'models/shopping_list.dart';
import 'theme/app_theme.dart';

/// Vista general de las LISTAS de la compra del hogar (migración 0045).
///
/// Muestra la "Lista principal" (implícita, list_id null) y las listas creadas
/// por el hogar (p. ej. una por súper). Permite:
///   - Elegir una lista como ACTIVA: al tocarla, se cierra devolviendo su id
///     ('' = Lista principal) para que la pantalla de la compra la use.
///   - Crear una lista nueva con nombre (y color opcional).
///
/// Es una pantalla "tonta": no habla con Supabase directamente, sino que delega
/// la creación en el callback [ShoppingListsOverviewScreen] recibe desde la
/// pantalla de la compra, para no duplicar la lógica de red/RLS. Devuelve por
/// Navigator.pop el id de la lista elegida (o null si se sale sin elegir).
class ShoppingListsOverviewScreen extends StatefulWidget {
  final List<ShoppingList> lists;
  final String? activeListId;

  const ShoppingListsOverviewScreen({
    super.key,
    required this.lists,
    required this.activeListId,
  });

  @override
  State<ShoppingListsOverviewScreen> createState() =>
      _ShoppingListsOverviewScreenState();
}

class _ShoppingListsOverviewScreenState
    extends State<ShoppingListsOverviewScreen> {
  late List<ShoppingList> _lists = List.of(widget.lists);

  Future<void> _promptCreate() async {
    final name = await _promptName(context, title: 'Nueva lista');
    if (name == null || name.trim().isEmpty) return;
    // La creación real la hace la pantalla de la compra al volver (recarga).
    // Aquí devolvemos un marcador especial para que la cree y la seleccione.
    if (!mounted) return;
    Navigator.of(context).pop('new:${name.trim()}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Mis listas')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-listas-nueva',
        backgroundColor: AppColors.wood,
        foregroundColor: AppColors.ink,
        onPressed: _promptCreate,
        icon: const Icon(Icons.add),
        label: const Text(
          'Nueva lista',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _listTile(
            id: null,
            name: 'Lista principal',
            selected: widget.activeListId == null,
          ),
          for (final l in _lists)
            _listTile(
              id: l.id,
              name: l.name,
              selected: widget.activeListId == l.id,
            ),
        ],
      ),
    );
  }

  Widget _listTile({
    required String? id,
    required String name,
    required bool selected,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration(radius: AppRadius.md),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: selected ? AppColors.sageBg : AppColors.peachBg,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            selected ? Icons.check_circle : Icons.shopping_basket,
            color: selected ? AppColors.sage : AppColors.peach,
          ),
        ),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        trailing: selected
            ? const Text(
                'Activa',
                style: TextStyle(
                  color: AppColors.sage,
                  fontWeight: FontWeight.w700,
                ),
              )
            : const Icon(Icons.chevron_right, color: AppColors.woodDark),
        // Devuelve '' para la principal (list_id null) o el id de la lista.
        onTap: () => Navigator.of(context).pop(id ?? ''),
      ),
    );
  }
}

/// Pantalla de gestión de CATEGORÍAS (secciones) de la compra: crear, renombrar
/// (toque sobre la fila) y REORDENAR (ReorderableListView). No habla con
/// Supabase: delega en callbacks de la pantalla de la compra.
class ShoppingCategoriesScreen extends StatefulWidget {
  final List<ShoppingCategory> categories;
  final Future<void> Function(String name) onCreate;
  final Future<void> Function(ShoppingCategory category, String name) onRename;
  final Future<void> Function(List<ShoppingCategory> ordered) onReorder;

  const ShoppingCategoriesScreen({
    super.key,
    required this.categories,
    required this.onCreate,
    required this.onRename,
    required this.onReorder,
  });

  @override
  State<ShoppingCategoriesScreen> createState() =>
      _ShoppingCategoriesScreenState();
}

class _ShoppingCategoriesScreenState extends State<ShoppingCategoriesScreen> {
  late List<ShoppingCategory> _cats = List.of(widget.categories);

  Future<void> _promptCreate() async {
    final name = await _promptName(context, title: 'Nueva categoría');
    if (name == null || name.trim().isEmpty) return;
    await widget.onCreate(name.trim());
    if (!mounted) return;
    setState(() {
      _cats = [
        ..._cats,
        ShoppingCategory(homeId: '', name: name.trim(), position: _cats.length),
      ];
    });
  }

  Future<void> _promptRename(ShoppingCategory category) async {
    final name = await _promptName(
      context,
      title: 'Renombrar categoría',
      initial: category.name,
    );
    if (name == null || name.trim().isEmpty) return;
    await widget.onRename(category, name.trim());
    if (!mounted) return;
    setState(() {
      _cats = [
        for (final c in _cats)
          if (c.id == category.id) c.copyWith(name: name.trim()) else c,
      ];
    });
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      var insertAt = newIndex;
      if (insertAt > oldIndex) insertAt -= 1;
      final moved = _cats.removeAt(oldIndex);
      _cats.insert(insertAt, moved);
    });
    await widget.onReorder(_cats);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Categorías')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-categorias-nueva',
        backgroundColor: AppColors.wood,
        foregroundColor: AppColors.ink,
        onPressed: _promptCreate,
        icon: const Icon(Icons.add),
        label: const Text(
          'Añadir categoría',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _cats.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Aún no hay categorías. Añade la primera con el botón de '
                  'abajo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkMuted),
                ),
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: _cats.length,
              onReorder: _onReorder,
              itemBuilder: (context, index) {
                final c = _cats[index];
                return Container(
                  key: ValueKey(c.id ?? 'cat-$index-${c.name}'),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: AppTheme.cardDecoration(radius: AppRadius.md),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    leading: const Icon(
                      Icons.folder_outlined,
                      color: AppColors.woodDark,
                    ),
                    title: Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Renombrar',
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: AppColors.woodDark,
                          ),
                          onPressed: () => _promptRename(c),
                        ),
                        ReorderableDragStartListener(
                          index: index,
                          child: const Icon(
                            Icons.drag_handle,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _promptRename(c),
                  ),
                );
              },
            ),
    );
  }
}

/// Diálogo simple para pedir un nombre (crear/renombrar lista o categoría).
/// Devuelve el texto o null si se cancela.
Future<String?> _promptName(
  BuildContext context, {
  required String title,
  String initial = '',
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.cream,
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(labelText: 'Nombre'),
        onSubmitted: (v) => Navigator.of(ctx).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(controller.text),
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}
