import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/providers.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../util/icon_catalog.dart';
import '../widgets/cookie_timer.dart';
import '../widgets/form_fields.dart';
import '../widgets/pill_tile.dart';
import 'edit_step_screen.dart';
import 'icon_picker_screen.dart';

class EditReminderScreen extends ConsumerStatefulWidget {
  const EditReminderScreen({super.key, this.reminderId});

  final int? reminderId;

  @override
  ConsumerState<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends ConsumerState<EditReminderScreen> {
  final _title = TextEditingController();
  final _quickStep = TextEditingController();

  String _iconKey = IconCatalog.defaultReminder;
  TimeOfDay? _time;
  int _daysMask = 0;
  bool _notifications = true;
  bool _alarm = false;
  bool _multiStep = false;
  bool _addImage = false;
  String? _imagePath;
  List<StepDraft> _steps = [];

  bool _loading = true;
  bool _saving = false;

  bool get _isNew => widget.reminderId == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _quickStep.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = widget.reminderId;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    final db = ref.read(databaseProvider);
    final reminder = await db.findReminder(id);
    final steps = await ref.read(repositoryProvider).draftsFor(id);
    if (!mounted || reminder == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() {
      _title.text = reminder.title;
      _iconKey = reminder.iconKey;
      _time = TimeOfDay(hour: reminder.hour, minute: reminder.minute);
      _daysMask = reminder.daysMask;
      _notifications = reminder.notificationsEnabled;
      _alarm = reminder.alarmEnabled;
      _multiStep = reminder.multiStep;
      _imagePath = reminder.imagePath;
      _addImage = reminder.imagePath != null;
      _steps = steps;
      _loading = false;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickDays() async {
    final picked = await showDayPickerDialog(context, _daysMask);
    if (picked != null) setState(() => _daysMask = picked);
  }

  Future<void> _pickReminderIcon() async {
    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => IconPickerScreen(selected: _iconKey)),
    );
    if (picked != null) setState(() => _iconKey = picked);
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 1600);
    if (file == null) return;

    // Copied into app storage so the reminder survives the gallery item moving.
    final dir = await getApplicationDocumentsDirectory();
    final dest = p.join(
      dir.path,
      'reminder_${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}',
    );
    await File(file.path).copy(dest);
    if (!mounted) return;
    setState(() => _imagePath = dest);
  }

  Future<void> _addStep() async {
    final result = await Navigator.of(context).push<StepEditResult>(
      MaterialPageRoute(
        builder: (_) => const EditStepScreen(allowDelete: false),
      ),
    );
    if (result?.draft == null) return;
    setState(() => _steps = [..._steps, result!.draft!]);
  }

  Future<void> _editStep(int index) async {
    final result = await Navigator.of(context).push<StepEditResult>(
      MaterialPageRoute(builder: (_) => EditStepScreen(draft: _steps[index])),
    );
    if (result == null) return;
    setState(() {
      final next = [..._steps];
      if (result.deleted) {
        next.removeAt(index);
      } else {
        next[index] = result.draft!;
      }
      _steps = next;
    });
  }

  void _quickAddStep(String value) {
    final name = value.trim();
    if (name.isEmpty) return;
    setState(() {
      _steps = [..._steps, StepDraft(title: name)];
      _quickStep.clear();
    });
  }

  Future<void> _save() async {
    if (_steps.isEmpty && _quickStep.text.trim().isNotEmpty) {
      _quickAddStep(_quickStep.text);
    }
    if (_steps.isEmpty) {
      _toast('Add at least one step.');
      return;
    }
    if (_time == null) {
      _toast('Pick a time first.');
      return;
    }

    setState(() => _saving = true);

    if (_notifications || _alarm) {
      final status = await NotificationService.instance.requestPermissions();
      if (mounted && !status.notifications) {
        _toast('Notifications are blocked — enable them in system settings.');
      } else if (mounted && !status.exactAlarms) {
        _toast('Exact alarms are off; reminders may fire late.');
      }
    }

    await ref.read(repositoryProvider).save(
          id: widget.reminderId,
          title: _title.text.trim(),
          iconKey: _iconKey,
          hour: _time!.hour,
          minute: _time!.minute,
          daysMask: _daysMask,
          notificationsEnabled: _notifications,
          alarmEnabled: _alarm,
          multiStep: _multiStep,
          imagePath: _addImage ? _imagePath : null,
          steps: _multiStep ? _steps : _steps.take(1).toList(),
        );

    if (mounted) Navigator.pop(context);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final canAddMore = _multiStep || _steps.isEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_isNew ? 'New reminder' : 'Edit reminder'),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Symbols.save),
            tooltip: 'Save',
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
        children: [
          TextField(
            controller: _title,
            style: const TextStyle(fontSize: 19),
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Reminder name',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 6),
                child: IconButton(
                  icon: Icon(IconCatalog.resolve(_iconKey), size: 28),
                  tooltip: 'Choose icon',
                  onPressed: _pickReminderIcon,
                ),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),
          const SizedBox(height: 14),
          LabeledSwitch(
            label: 'Multiple Steps',
            value: _multiStep,
            onChanged: (v) => setState(() => _multiStep = v),
          ),
          const SizedBox(height: 18),
          ValuePill(
            icon: Symbols.schedule,
            label: 'Time',
            value: _time == null
                ? 'Set time'
                : MaterialLocalizations.of(context).formatTimeOfDay(_time!),
            placeholder: _time == null,
            onTap: _pickTime,
          ),
          const SizedBox(height: 12),
          ValuePill(
            icon: Symbols.repeat,
            label: 'Repeat',
            value: describeDays(_daysMask),
            placeholder: _daysMask == 0,
            onTap: _pickDays,
          ),
          const SizedBox(height: 18),
          LabeledSwitch(
            label: 'Notifications',
            value: _notifications,
            onChanged: (v) => setState(() => _notifications = v),
          ),
          LabeledSwitch(
            label: 'Alarm',
            value: _alarm,
            onChanged: (v) => setState(() => _alarm = v),
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 18),
          LabeledSwitch(
            label: 'Add Image',
            value: _addImage,
            onChanged: (v) => setState(() => _addImage = v),
          ),
          if (_addImage) ...[
            const SizedBox(height: 18),
            Center(child: _ImagePickerBox(path: _imagePath, onTap: _pickImage)),
          ],
          const SizedBox(height: 22),
          const Divider(),
          const SizedBox(height: 22),
          if (_steps.isEmpty)
            TextField(
              controller: _quickStep,
              style: const TextStyle(fontSize: 19),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: _quickAddStep,
              decoration: const InputDecoration(
                hintText: 'Step name',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(left: 22, right: 16),
                  child: Icon(Symbols.check_circle, size: 28),
                ),
                prefixIconConstraints:
                    BoxConstraints(minWidth: 0, minHeight: 0),
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < _steps.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  PillTile(
                    label: _steps[i].title.isEmpty
                        ? 'Untitled step'
                        : _steps[i].title,
                    iconKey: _steps[i].iconKey,
                    onTap: () => _editStep(i),
                    trailing: _steps[i].hasTimer
                        ? Text(
                            formatDuration(
                                Duration(seconds: _steps[i].timerSeconds!)),
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                ],
              ],
            ),
          const SizedBox(height: 20),
          if (canAddMore)
            Center(
              child: OutlinedButton.icon(
                onPressed: _addStep,
                icon: const Icon(Symbols.add, size: 24),
                label: const Text('Add Step'),
              ),
            )
          else
            const Center(
              child: Text(
                'Turn on Multiple Steps to add more.',
                style:
                    TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImagePickerBox extends StatelessWidget {
  const _ImagePickerBox({required this.path, required this.onTap});

  final String? path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final file = path == null ? null : File(path!);
    final hasImage = file != null && file.existsSync();

    return Material(
      color: AppColors.surfaceFilled,
      borderRadius: BorderRadius.circular(32),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 220,
          height: 220,
          child: hasImage
              ? Image.file(file, fit: BoxFit.cover)
              : const Icon(Symbols.image, size: 52, color: AppColors.onSurface),
        ),
      ),
    );
  }
}
