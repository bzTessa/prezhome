import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'l10n/l10n.dart';
import 'services/count_prefs.dart';
import 'theme/app_theme.dart';
import 'utils/friendly_error.dart';
import 'utils/measure_format.dart';
import 'widgets/empty_state.dart';
import 'widgets/shopping/pack_size_dialog.dart';

/// Mi hogar > Envases habituales: lo que trae cada envase que se compra
/// siempre igual ("Garbanzos 570 g", "Leche 1 L"). Lo usan la lista de la
/// compra (cuenta envases enteros) y En casa (resta lo que gasta cada receta).
class PackSizesScreen extends StatefulWidget {
  const PackSizesScreen({super.key, required this.homeId});

  final String homeId;

  @override
  State<PackSizesScreen> createState() => _PackSizesScreenState();
}

class _PackSizesScreenState extends State<PackSizesScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  late Future<List<({String key, PackMeasure pack})>> _future = _load();

  Future<List<({String key, PackMeasure pack})>> _load() =>
      CountPrefs(_client).packs(widget.homeId);

  void _reload() => setState(() => _future = _load());

  static String _label(String key) =>
      key.isEmpty ? key : key[0].toUpperCase() + key.substring(1);

  Future<void> _edit(String name, PackMeasure? current) async {
    final pack = await askPackSize(context, name: name, current: current);
    if (pack == null || !mounted) return;
    try {
      await CountPrefs(_client).savePack(widget.homeId, name, pack);
    } catch (e) {
      _error(e);
      return;
    }
    _reload();
  }

  Future<void> _add() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NameDialog(),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    await _edit(name.trim(), CountPrefs.customPackOf(name));
  }

  Future<void> _remove(String key, PackMeasure pack) async {
    try {
      await CountPrefs(_client).removePack(widget.homeId, key);
    } catch (e) {
      _error(e);
      return;
    }
    _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.l.shopRemovedOne(_label(key))),
          action: SnackBarAction(
            label: context.l.undo,
            onPressed: () async {
              try {
                await CountPrefs(_client).savePack(widget.homeId, key, pack);
              } catch (_) {}
              if (mounted) _reload();
            },
          ),
        ),
      );
  }

  void _error(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(friendlyError(e, context.l.couldNotUpdate)),
        backgroundColor: AppColors.expired,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(context.l.hhPacks),
        actions: [
          IconButton(
            tooltip: context.l.packsAdd,
            icon: const Icon(Icons.add_rounded),
            onPressed: _add,
          ),
        ],
      ),
      body: FutureBuilder<List<({String key, PackMeasure pack})>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(friendlyError(snap.error, context.l.couldNotLoad)),
            );
          }
          final packs = snap.data ?? const [];
          if (packs.isEmpty) {
            return EmptyState(
              title: context.l.hhPacks,
              message: context.l.packsEmpty,
              actionLabel: context.l.packsAdd,
              onAction: _add,
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  context.l.hhPacksSub,
                  style: TextStyle(color: AppColors.inkMuted),
                ),
              ),
              Container(
                decoration: AppTheme.cardDecoration(),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    children: [
                      for (final (i, p) in packs.indexed) ...[
                        if (i > 0) Divider(height: 1, color: AppColors.line),
                        ListTile(
                          title: Text(
                            _label(p.key),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            formatQuantityUnit(p.pack.size, p.pack.unit),
                          ),
                          onTap: () => _edit(p.key, p.pack),
                          trailing: IconButton(
                            tooltip: context.l.remove,
                            icon: Icon(
                              Icons.delete_outline,
                              color: AppColors.inkMuted,
                            ),
                            onPressed: () => _remove(p.key, p.pack),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Pide el nombre del producto. Es dueño de su controlador (se libera al
/// cerrarse el diálogo, no justo después de showDialog).
class _NameDialog extends StatefulWidget {
  const _NameDialog();

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _ok() => Navigator.of(context).pop(_name.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cream,
      title: Text(context.l.packsAdd),
      content: TextField(
        controller: _name,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(hintText: context.l.packsNameHint),
        onSubmitted: (_) => _ok(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l.cancel),
        ),
        FilledButton(onPressed: _ok, child: Text(context.l.add)),
      ],
    );
  }
}
