import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n/l10n.dart';
import 'theme/app_theme.dart';
import 'utils/friendly_error.dart';

/// Una fila de la ficha de la casa (tabla home_info).
class HomeInfoItem {
  const HomeInfoItem({
    this.id,
    required this.homeId,
    required this.kind,
    required this.title,
    this.detail,
    this.phone,
    this.validUntil,
  });

  final String? id;
  final String homeId;

  /// wifi, contact, appliance o note.
  final String kind;
  final String title;
  final String? detail;
  final String? phone;

  /// Fin de la garantía (electrodomésticos).
  final DateTime? validUntil;

  static const kinds = ['wifi', 'contact', 'appliance', 'note'];

  factory HomeInfoItem.fromMap(Map<String, dynamic> m) => HomeInfoItem(
    id: m['id'] as String?,
    homeId: m['home_id'] as String,
    kind: m['kind'] as String? ?? 'note',
    title: m['title'] as String? ?? '',
    detail: m['detail'] as String?,
    phone: m['phone'] as String?,
    validUntil: m['valid_until'] == null
        ? null
        : DateTime.tryParse(m['valid_until'] as String),
  );

  Map<String, dynamic> toMap() => {
    'home_id': homeId,
    'kind': kind,
    'title': title.trim(),
    'detail': _blank(detail),
    'phone': _blank(phone),
    'valid_until': validUntil?.toIso8601String().split('T').first,
  };

  static String? _blank(String? s) =>
      s == null || s.trim().isEmpty ? null : s.trim();
}

/// Estado de una garantía: null sin fecha, 'expired', 'soon' (60 días o
/// menos) u 'ok'.
String? warrantyState(DateTime? until, DateTime today) {
  if (until == null) return null;
  final d = DateTime(until.year, until.month, until.day);
  final t = DateTime(today.year, today.month, today.day);
  if (d.isBefore(t)) return 'expired';
  if (d.difference(t).inDays <= 60) return 'soon';
  return 'ok';
}

/// Texto para pasar el wifi a una visita.
String wifiShareText(HomeInfoItem w, String networkLabel, String keyLabel) => [
  '$networkLabel: ${w.title}',
  if ((w.detail ?? '').isNotEmpty) '$keyLabel: ${w.detail}',
].join('\n');

/// Ficha de la casa: wifi, contactos útiles, electrodomésticos con garantía
/// y notas. Compartida con todo el hogar.
class HomeInfoScreen extends StatefulWidget {
  const HomeInfoScreen({super.key, required this.homeId});

  final String homeId;

  @override
  State<HomeInfoScreen> createState() => _HomeInfoScreenState();
}

class _HomeInfoScreenState extends State<HomeInfoScreen> {
  final _client = Supabase.instance.client;
  List<HomeInfoItem> _items = const [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await _client
          .from('home_info')
          .select()
          .eq('home_id', widget.homeId)
          .order('created_at');
      if (!mounted) return;
      setState(() {
        _items = [
          for (final r in rows as List)
            HomeInfoItem.fromMap(r as Map<String, dynamic>),
        ];
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e;
        });
      }
    }
  }

  void _fail(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(friendlyError(e, context.l.couldNotSave)),
        backgroundColor: AppColors.expired,
      ),
    );
  }

  Future<void> _edit({HomeInfoItem? item, String? kind, String? title}) async {
    final r = await showModalBottomSheet<HomeInfoItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditSheet(
        homeId: widget.homeId,
        item: item,
        kind: item?.kind ?? kind ?? 'note',
        title: title,
      ),
    );
    if (r == null) return;
    try {
      if (item?.id == null) {
        await _client.from('home_info').insert(r.toMap());
      } else {
        await _client.from('home_info').update(r.toMap()).eq('id', item!.id!);
      }
      HapticFeedback.lightImpact();
      await _load();
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _delete(HomeInfoItem item) async {
    final l = context.l;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _items = [..._items]..remove(item));
    try {
      await _client.from('home_info').delete().eq('id', item.id!);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l.hiDeleted),
          action: SnackBarAction(
            label: l.undo,
            onPressed: () async {
              try {
                await _client.from('home_info').insert(item.toMap());
              } catch (_) {}
              await _load();
            },
          ),
        ),
      );
    } catch (e) {
      _fail(e);
      await _load();
    }
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l.hiCopied)));
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    var ok = false;
    try {
      ok = await launchUrl(uri);
    } catch (_) {}
    if (!ok) await _copy(phone);
  }

  void _actions(HomeInfoItem item) {
    final l = context.l;
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if ((item.detail ?? '').isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: Text(item.kind == 'wifi' ? l.hiCopyKey : l.hiCopy),
                onTap: () {
                  Navigator.pop(ctx);
                  _copy(item.detail!);
                },
              ),
            if (item.kind == 'wifi')
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: Text(l.hiShareWifi),
                onTap: () {
                  Navigator.pop(ctx);
                  SharePlus.instance.share(
                    ShareParams(
                      text: wifiShareText(item, l.hiWifiNetwork, l.hiWifiKey),
                    ),
                  );
                },
              ),
            if ((item.phone ?? '').isNotEmpty)
              ListTile(
                leading: const Icon(Icons.call_outlined),
                title: Text(l.hiCall),
                onTap: () {
                  Navigator.pop(ctx);
                  _call(item.phone!);
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l.hiEdit),
              onTap: () {
                Navigator.pop(ctx);
                _edit(item: item);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.expired),
              title: Text(
                l.hiDelete,
                style: TextStyle(color: AppColors.expired),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _delete(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _kindTitle(String kind) => switch (kind) {
    'wifi' => context.l.hiWifi,
    'contact' => context.l.hiContacts,
    'appliance' => context.l.hiAppliances,
    _ => context.l.hiNotes,
  };

  IconData _kindIcon(String kind) => switch (kind) {
    'wifi' => Icons.wifi_rounded,
    'contact' => Icons.contact_phone_outlined,
    'appliance' => Icons.kitchen_outlined,
    _ => Icons.sticky_note_2_outlined,
  };

  List<String> _suggestions(String kind) => switch (kind) {
    'wifi' => [context.l.hiSugWifi],
    'contact' => [
      context.l.hiSugLandlord,
      context.l.hiSugPlumber,
      context.l.hiSugInsurance,
      context.l.hiSugBuilding,
    ],
    'appliance' => [
      context.l.hiSugWasher,
      context.l.hiSugFridge,
      context.l.hiSugBoiler,
    ],
    _ => [context.l.hiSugBins],
  };

  Widget _section(String kind) {
    final items = [
      for (final i in _items)
        if (i.kind == kind) i,
    ];
    final have = {for (final i in items) i.title.toLowerCase()};
    // Con algo ya apuntado en la sección, solo se sugiere lo que falta y
    // sin repetir el wifi.
    final sugg = [
      for (final s in _suggestions(kind))
        if (!have.contains(s.toLowerCase()) &&
            !(kind == 'wifi' && items.isNotEmpty))
          s,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 0, 4),
            child: Row(
              children: [
                Icon(_kindIcon(kind), size: 18, color: AppColors.inkMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _kindTitle(kind).toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.l.hiAdd,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => _edit(kind: kind),
                ),
              ],
            ),
          ),
          if (items.isNotEmpty)
            DecoratedBox(
              decoration: AppTheme.surfaceDecoration(radius: 18),
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 16),
                    _row(items[i]),
                  ],
                ],
              ),
            ),
          if (sugg.isNotEmpty) ...[
            if (items.isNotEmpty) const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in sugg)
                  ActionChip(
                    avatar: const Icon(Icons.add_rounded, size: 18),
                    label: Text(s),
                    onPressed: () => _edit(kind: kind, title: s),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(HomeInfoItem item) {
    final l = context.l;
    final locale = Localizations.localeOf(context).toString();
    final w = warrantyState(item.validUntil, DateTime.now());
    final lines = <Widget>[
      if ((item.detail ?? '').isNotEmpty)
        Text(
          item.kind == 'wifi' ? '${l.hiWifiKey}: ${item.detail}' : item.detail!,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelMuted,
        ),
      if ((item.phone ?? '').isNotEmpty)
        Text(item.phone!, style: AppTextStyles.labelMuted),
      if (w != null)
        Text(
          w == 'expired'
              ? l.hiWarrantyExpired(
                  DateFormat.yMMMd(locale).format(item.validUntil!),
                )
              : l.hiWarrantyUntil(
                  DateFormat.yMMMd(locale).format(item.validUntil!),
                ),
          style: AppTextStyles.labelMuted.copyWith(
            color: w == 'ok' ? null : AppColors.expired,
            fontWeight: w == 'ok' ? null : FontWeight.w700,
          ),
        ),
    ];
    return ListTile(
      title: Text(item.title, style: AppTextStyles.titleSmall),
      subtitle: lines.isEmpty
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines,
            ),
      trailing: (item.phone ?? '').isNotEmpty
          ? IconButton(
              tooltip: l.hiCall,
              icon: Icon(Icons.call_outlined, color: AppColors.sage),
              onPressed: () => _call(item.phone!),
            )
          : (item.detail ?? '').isNotEmpty
          ? IconButton(
              tooltip: l.hiCopy,
              icon: const Icon(Icons.copy_rounded, size: 20),
              onPressed: () => _copy(item.detail!),
            )
          : null,
      onTap: () => _actions(item),
      onLongPress: () => _actions(item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(context.l.hiTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(friendlyError(_error)))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                    child: Text(
                      context.l.hiIntro,
                      style: AppTextStyles.bodyMuted,
                    ),
                  ),
                  for (final k in HomeInfoItem.kinds) _section(k),
                ],
              ),
            ),
    );
  }
}

class _EditSheet extends StatefulWidget {
  const _EditSheet({
    required this.homeId,
    required this.kind,
    this.item,
    this.title,
  });

  final String homeId;
  final String kind;
  final HomeInfoItem? item;
  final String? title;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final _title = TextEditingController(
    text: widget.item?.title ?? widget.title ?? '',
  );
  late final _detail = TextEditingController(text: widget.item?.detail ?? '');
  late final _phone = TextEditingController(text: widget.item?.phone ?? '');
  late DateTime? _until = widget.item?.validUntil;

  @override
  void dispose() {
    _title.dispose();
    _detail.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _until ?? DateTime(now.year + 2, now.month, now.day),
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 15),
    );
    if (d != null) setState(() => _until = d);
  }

  void _save() {
    if (_title.text.trim().isEmpty) return;
    Navigator.of(context).pop(
      HomeInfoItem(
        id: widget.item?.id,
        homeId: widget.homeId,
        kind: widget.kind,
        title: _title.text,
        detail: _detail.text,
        phone: widget.kind == 'contact' ? _phone.text : null,
        validUntil: widget.kind == 'appliance' ? _until : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final locale = Localizations.localeOf(context).toString();
    final wifi = widget.kind == 'wifi';
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.item == null ? l.hiAdd : l.hiEdit,
            style: AppTextStyles.headline,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            autofocus: widget.title == null && widget.item == null,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: switch (widget.kind) {
                'wifi' => l.hiWifiNetwork,
                'contact' => l.hiFieldWho,
                'appliance' => l.hiFieldAppliance,
                _ => l.hiFieldTitle,
              },
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _detail,
            autofocus: widget.title != null,
            maxLines: wifi ? 1 : 4,
            minLines: 1,
            decoration: InputDecoration(
              labelText: switch (widget.kind) {
                'wifi' => l.hiWifiKey,
                'appliance' => l.hiFieldModel,
                _ => l.hiFieldNote,
              },
            ),
          ),
          if (widget.kind == 'contact') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l.hiFieldPhone),
            ),
          ],
          if (widget.kind == 'appliance') ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                _until == null
                    ? l.hiFieldWarranty
                    : l.hiWarrantyUntil(
                        DateFormat.yMMMd(locale).format(_until!),
                      ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(onPressed: _save, child: Text(l.hiSave)),
        ],
      ),
    );
  }
}
