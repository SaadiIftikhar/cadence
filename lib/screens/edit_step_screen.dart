import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../data/providers.dart';
import '../theme/app_theme.dart';
import '../util/icon_catalog.dart';
import '../widgets/cookie_timer.dart';
import 'icon_picker_screen.dart';

class StepEditResult {
  const StepEditResult.save(StepDraft this.draft) : deleted = false;
  const StepEditResult.delete()
      : draft = null,
        deleted = true;

  final StepDraft? draft;
  final bool deleted;
}

class EditStepScreen extends StatefulWidget {
  const EditStepScreen({super.key, this.draft, this.allowDelete = true});

  final StepDraft? draft;
  final bool allowDelete;

  @override
  State<EditStepScreen> createState() => _EditStepScreenState();
}

class _EditStepScreenState extends State<EditStepScreen> {
  late final TextEditingController _title =
      TextEditingController(text: widget.draft?.title ?? '');
  late String? _iconKey = widget.draft?.iconKey;
  late int _seconds = widget.draft?.timerSeconds ?? 0;
  late bool _timerExpanded = _seconds > 0;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => IconPickerScreen(selected: _iconKey)),
    );
    if (picked != null) setState(() => _iconKey = picked);
  }

  void _save() {
    final draft = widget.draft ?? StepDraft();
    draft
      ..title = _title.text.trim()
      ..iconKey = _iconKey
      ..timerSeconds = _seconds > 0 ? _seconds : null;
    Navigator.pop(context, StepEditResult.save(draft));
  }

  void _setUnit({int? hours, int? minutes, int? secs}) {
    final h = hours ?? _seconds ~/ 3600;
    final m = minutes ?? (_seconds % 3600) ~/ 60;
    final s = secs ?? _seconds % 60;
    setState(() => _seconds = h * 3600 + m * 60 + s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.allowDelete)
            IconButton(
              icon: const Icon(Symbols.delete),
              tooltip: 'Delete step',
              onPressed: () =>
                  Navigator.pop(context, const StepEditResult.delete()),
            ),
          IconButton(
            icon: const Icon(Symbols.save),
            tooltip: 'Save step',
            onPressed: _save,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          TextField(
            controller: _title,
            style: const TextStyle(fontSize: 19),
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Step Title',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 20, right: 14),
                child: Icon(IconCatalog.resolve(_iconKey), size: 28),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: OutlinedButton.icon(
              onPressed: _pickIcon,
              icon: const Icon(Symbols.add, size: 24),
              label: Text(_iconKey == null ? 'Add Step Icon' : 'Change Step Icon'),
            ),
          ),
          const SizedBox(height: 26),
          const Divider(),
          const SizedBox(height: 26),
          _TimerSection(
            seconds: _seconds,
            expanded: _timerExpanded,
            onToggle: () => setState(() => _timerExpanded = !_timerExpanded),
            onHours: (v) => _setUnit(hours: v),
            onMinutes: (v) => _setUnit(minutes: v),
            onSeconds: (v) => _setUnit(secs: v),
            onClear: () => setState(() => _seconds = 0),
          ),
        ],
      ),
    );
  }
}

class _TimerSection extends StatelessWidget {
  const _TimerSection({
    required this.seconds,
    required this.expanded,
    required this.onToggle,
    required this.onHours,
    required this.onMinutes,
    required this.onSeconds,
    required this.onClear,
  });

  final int seconds;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<int> onHours;
  final ValueChanged<int> onMinutes;
  final ValueChanged<int> onSeconds;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          shape: const StadiumBorder(side: BorderSide(color: AppColors.outline)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  const Icon(Symbols.timer, size: 28),
                  const SizedBox(width: 18),
                  const Expanded(
                    child: Text('Step Timer', style: TextStyle(fontSize: 20)),
                  ),
                  if (seconds > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text(
                        formatDuration(Duration(seconds: seconds)),
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Symbols.arrow_drop_down, size: 30),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          crossFadeState:
              expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.only(top: 22),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _UnitPicker(
                        label: 'Hours',
                        value: seconds ~/ 3600,
                        max: 23,
                        onChanged: onHours,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _UnitPicker(
                        label: 'Minutes',
                        value: (seconds % 3600) ~/ 60,
                        max: 59,
                        onChanged: onMinutes,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _UnitPicker(
                        label: 'Seconds',
                        value: seconds % 60,
                        max: 59,
                        onChanged: onSeconds,
                      ),
                    ),
                  ],
                ),
                if (seconds > 0)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onClear,
                      icon: const Icon(Symbols.close, size: 20),
                      label: const Text('No timer'),
                    ),
                  ),
              ],
            ),
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _UnitPicker extends StatelessWidget {
  const _UnitPicker({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(18),
          style: const TextStyle(fontSize: 20, color: AppColors.onSurface),
          items: [
            for (var i = 0; i <= max; i++)
              DropdownMenuItem(
                value: i,
                child: Text(i.toString().padLeft(2, '0')),
              ),
          ],
          onChanged: (v) => onChanged(v ?? 0),
        ),
      ),
    );
  }
}
