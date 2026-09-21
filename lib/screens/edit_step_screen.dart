import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../data/providers.dart';
import '../util/icon_catalog.dart';
import '../widgets/timer_picker.dart';
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
          TimerPicker(
            seconds: _seconds,
            onChanged: (v) => setState(() => _seconds = v),
          ),
        ],
      ),
    );
  }
}
