import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'l10n/l10n.dart';
import 'main_shell.dart';
import 'recipe_detail_screen.dart';
import 'services/global_search.dart';
import 'theme/app_theme.dart';
import 'utils/debouncer.dart';
import 'utils/quick_capture.dart' show CaptureTarget;
import 'widgets/quick_capture_sheet.dart';
import 'widgets/recipe_image.dart';

/// Buscador general: un solo campo que mira la lista, En casa, recetas y
/// tareas. Tocar un resultado lleva a donde vive; si no está en la lista, se
/// puede añadir desde aquí.
class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key, this.data});

  /// Datos ya cargados (tests). Si es null, se cargan al abrir.
  final SearchData? data;

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _ctrl = TextEditingController();
  final _debounce = Debouncer(delay: const Duration(milliseconds: 120));
  SearchData _data = const SearchData();
  bool _loading = true;
  String _query = '';
  final Set<String> _added = {};

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _data = widget.data!;
      _loading = false;
    } else {
      loadSearchData(Supabase.instance.client).then((d) {
        if (mounted) {
          setState(() {
            _data = d;
            _loading = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _debounce.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) =>
      _debounce.run(() => mounted ? setState(() => _query = v.trim()) : null);

  void _open(SearchHit h) {
    final shell = MainShell.current;
    switch (h.kind) {
      case SearchKind.recipe:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(recipe: h.recipe!),
          ),
        );
        return;
      case SearchKind.shopping:
        Navigator.of(context).pop();
        shell?.openShopping();
      case SearchKind.pantry:
        Navigator.of(context).pop();
        shell?.openPantry();
      case SearchKind.task:
        Navigator.of(context).pop();
        shell?.openTab(TabId.tareas);
    }
  }

  Future<void> _addToList(String name) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await client
          .from('profiles')
          .select('home_id')
          .eq('id', user.id)
          .maybeSingle();
      final homeId = profile?['home_id'] as String?;
      if (homeId == null) return;
      await saveCapture(
        client,
        target: CaptureTarget.shopping,
        items: [name],
        homeId: homeId,
        userId: user.id,
      );
      if (!mounted) return;
      setState(() => _added.add(name.toLowerCase()));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l.gsAdded(name))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l.gsAddFailed),
          backgroundColor: AppColors.expired,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = searchEverything(_data, _query);
    final inList = (results[SearchKind.shopping] ?? const []).any(
      (h) => h.title.toLowerCase() == _query.toLowerCase(),
    );
    final canAdd =
        _query.isNotEmpty && !inList && !_added.contains(_query.toLowerCase());
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: (v) => setState(() => _query = v.trim()),
            decoration: InputDecoration(
              hintText: context.l.gsHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _ctrl.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: context.l.gsClear,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _ctrl.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
        ),
      ),
      body: _query.isEmpty
          ? _hint(context.l.gsTip, Icons.manage_search_rounded)
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.xxxl,
              ),
              children: [
                if (results.isEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    context.l.gsNothing(_query),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMuted,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                for (final kind in SearchKind.values)
                  if (results[kind] case final hits?) ...[
                    _sectionTitle(kind, hits.length),
                    DecoratedBox(
                      decoration: AppTheme.surfaceDecoration(radius: 18),
                      child: Column(
                        children: [
                          for (var i = 0; i < hits.length; i++) ...[
                            if (i > 0)
                              Divider(height: 1, indent: 64, endIndent: 16),
                            _hitTile(hits[i]),
                          ],
                        ],
                      ),
                    ),
                  ],
                if (canAdd) ...[
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    onPressed: () => _addToList(_query),
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: Text(context.l.gsAddToList(_query)),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _hint(String text, IconData icon) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.inkMuted),
          const SizedBox(height: AppSpacing.md),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
        ],
      ),
    ),
  );

  Widget _sectionTitle(SearchKind kind, int n) => Padding(
    padding: const EdgeInsets.fromLTRB(4, AppSpacing.lg, 4, AppSpacing.sm),
    child: Text(
      context.l.gsSection(kind.name).toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: AppColors.inkMuted,
      ),
    ),
  );

  Widget _hitTile(SearchHit h) {
    final (IconData icon, Color bg, Color fg) = switch (h.kind) {
      SearchKind.shopping => (
        Icons.shopping_cart_outlined,
        AppColors.sageBg,
        AppColors.sage,
      ),
      SearchKind.pantry => (
        Icons.kitchen_outlined,
        AppColors.frostBg,
        AppColors.frost,
      ),
      SearchKind.recipe => (
        Icons.restaurant_rounded,
        AppColors.peachBg,
        AppColors.peach,
      ),
      SearchKind.task => (
        Icons.check_circle_outline_rounded,
        AppColors.terracottaBg,
        AppColors.terracottaText,
      ),
    };
    final detail = [
      if (h.detail != null && h.detail!.isNotEmpty) h.detail!,
      if (h.done) context.l.gsBought,
    ].join(' · ');
    return ListTile(
      minTileHeight: 56,
      onTap: () => _open(h),
      leading: h.recipe != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: RecipeImage(
                recipe: h.recipe!,
                width: 40,
                height: 40,
                radius: 0,
                cacheWidth: 120,
              ),
            )
          : Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: fg),
            ),
      title: Text(
        h.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.title.copyWith(
          decoration: h.done ? TextDecoration.lineThrough : null,
          color: h.done ? AppColors.inkMuted : null,
        ),
      ),
      subtitle: detail.isEmpty
          ? null
          : Text(detail, style: AppTextStyles.labelMuted),
      trailing: Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
    );
  }
}
