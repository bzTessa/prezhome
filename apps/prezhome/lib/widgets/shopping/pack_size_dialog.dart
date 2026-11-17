import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';
import '../../services/count_prefs.dart';
import '../../theme/app_theme.dart';

/// Pregunta lo que trae cada envase de [name] ("570 g"). Devuelve null si se
/// cancela. El diálogo es dueño de su controlador: se libera al cerrarse.
Future<PackMeasure?> askPackSize(
  BuildContext context, {
  required String name,
  PackMeasure? current,
}) => showDialog<PackMeasure>(
  context: context,
  builder: (_) => _PackSizeDialog(name: name, current: current),
);

class _PackSizeDialog extends StatefulWidget {
  const _PackSizeDialog({required this.name, this.current});

  final String name;
  final PackMeasure? current;

  @override
  State<_PackSizeDialog> createState() => _PackSizeDialogState();
}

class _PackSizeDialogState extends State<_PackSizeDialog> {
  late final TextEditingController _size;
  late String _unit;

  @override
  void initState() {
    super.initState();
    final c = widget.current;
    _size = TextEditingController(
      text: c == null
          ? ''
          : c.size == c.size.roundToDouble()
          ? c.size.toInt().toString()
          : c.size.toString(),
    );
    _unit = c?.unit ?? 'g';
  }

  @override
  void dispose() {
    _size.dispose();
    super.dispose();
  }

  double? get _value => double.tryParse(_size.text.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final valid = (_value ?? 0) > 0;
    return AlertDialog(
      backgroundColor: AppColors.cream,
      title: Text(context.l.shopPackSizeTitle(widget.name)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l.shopPackSizeHint,
            style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _size,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(hintText: '570'),
                ),
              ),
              const SizedBox(width: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'g', label: Text('g')),
                  ButtonSegment(value: 'ml', label: Text('ml')),
                ],
                selected: {_unit},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _unit = s.first),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l.cancel),
        ),
        FilledButton(
          onPressed: valid
              ? () => Navigator.of(
                  context,
                ).pop<PackMeasure>((size: _value!, unit: _unit))
              : null,
          child: Text(context.l.save),
        ),
      ],
    );
  }
}
