import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n.dart';
import '../main_shell.dart';
import '../models/dashboard_prefs.dart';
import '../models/usage_mode.dart';
import '../theme/app_theme.dart';
import '../utils/friendly_error.dart';

/// "Cómo usas PrezHome": tres modos (esencial, cocina, completo) que
/// encienden o apagan módulos de golpe. Lee y guarda profiles.dashboard_prefs
/// y avisa al shell para que las pestañas cambien al momento.
class UsageModePicker extends StatefulWidget {
  const UsageModePicker({super.key, this.onChanged});

  /// Tras guardar (p. ej. para refrescar la pantalla que lo contiene).
  final VoidCallback? onChanged;

  @override
  State<UsageModePicker> createState() => _UsageModePickerState();
}

class _UsageModePickerState extends State<UsageModePicker> {
  final _client = Supabase.instance.client;
  DashboardPrefs? _prefs;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final row = await _client
          .from('profiles')
          .select('dashboard_prefs')
          .eq('id', uid)
          .maybeSingle();
      final raw = row?['dashboard_prefs'];
      if (!mounted) return;
      setState(
        () => _prefs = raw is Map
            ? DashboardPrefs.fromJson(Map<String, dynamic>.from(raw))
            : DashboardPrefs.defaults(),
      );
    } catch (_) {
      if (mounted) setState(() => _prefs = DashboardPrefs.defaults());
    }
  }

  Future<void> _pick(UsageMode mode) async {
    final uid = _client.auth.currentUser?.id;
    final prefs = _prefs;
    if (uid == null || prefs == null || _saving) return;
    HapticFeedback.selectionClick();
    final next = mode.applyTo(prefs);
    setState(() {
      _prefs = next;
      _saving = true;
    });
    try {
      await _client
          .from('profiles')
          .update({'dashboard_prefs': next.toJson()})
          .eq('id', uid);
      MainShell.reloadModules();
      widget.onChanged?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _prefs = prefs);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, context.l.couldNotUpdate)),
          backgroundColor: AppColors.expired,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = _prefs;
    final current = prefs == null ? null : UsageMode.of(prefs);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l.modeTitle, style: AppTextStyles.title),
        const SizedBox(height: 4),
        Text(
          current == UsageMode.custom
              ? context.l.modeCustomHint
              : context.l.modeHint,
          style: AppTextStyles.bodyMuted,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final m in UsageMode.choices) ...[
          _ModeOption(
            mode: m,
            selected: current == m,
            enabled: prefs != null && !_saving,
            onTap: () => _pick(m),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.mode,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final UsageMode mode;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String title, String sub) = switch (mode) {
      UsageMode.essential => (
        Icons.shopping_basket_outlined,
        context.l.modeEssential,
        context.l.modeEssentialSub,
      ),
      UsageMode.kitchen => (
        Icons.soup_kitchen_outlined,
        context.l.modeKitchen,
        context.l.modeKitchenSub,
      ),
      _ => (
        Icons.home_rounded,
        context.l.modeComplete,
        context.l.modeCompleteSub,
      ),
    };
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.goldBg : AppColors.cream,
        borderRadius: AppRadius.lgRadius,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppRadius.lgRadius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: AppRadius.lgRadius,
              border: Border.all(
                color: selected ? AppColors.gold : AppColors.line,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.gold : AppColors.iconTile,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: selected ? AppColors.ink : AppColors.inkMuted,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.bodyStrong),
                      Text(sub, style: AppTextStyles.bodyMuted),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, color: AppColors.woodDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
