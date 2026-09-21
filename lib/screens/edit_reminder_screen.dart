import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
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
import '../widgets/timer_picker.dart';
import 'edit_step_screen.dart';
import 'icon_picker_screen.dart';

/// Creates or edits either a routine (a named checklist of steps) or a single
/// step (one action, which needs no separate name — its own title is what the
/// home list shows).
class EditReminderScreen extends ConsumerStatefulWidget {
  const EditReminderScreen({
    super.key,
    this.reminderId,
    this.isRoutine = false,
  });

  final int? reminderId;

  /// Only consulted when creating; an existing reminder knows which it is.
  final bool isRoutine;

  @override
  ConsumerState<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends ConsumerState<EditReminderScreen> {
  final _title = TextEditingController();

  late bool _routine = widget.isRoutine;
  String _iconKey = IconCatalog.defaultReminder;
  TimeOfDay? _time;
  int _daysMask = 0;
  bool _notifications = true;
  bool _alarm = false;
  bool _addImage = false;
  String? _imagePath;

  /// Routine mode only.
  List<StepDraft> _steps = [];

  /// Single-step mode only. Held as a draft so its id and completion survive.
  StepDraft _single = StepDraft();
  int _stepSeconds = 0;

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
    super.dispose();
  }

  Future<void> _load() async {
    final id = widget.reminderId;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    final reminder = await ref.read(databaseProvider).findReminder(id);
    final steps = await ref.read(repositoryProvider).draftsFor(id);
    if (!mounted) return;
    if (reminder == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() {
      _routine = reminder.multiStep;
      _time = TimeOfDay(hour: reminder.hour, minute: reminder.minute);
      _daysMask = reminder.daysMask;
      _notifications = reminder.notificationsEnabled;
      _alarm = reminder.alarmEnabled;
      _imagePath = reminder.imagePath;
      _addImage = reminder.imagePath != null;

      if (_routine) {
        _title.text = reminder.title;
        _iconKey = reminder.iconKey;
        _steps = steps;
      } else {
        _single = steps.isNotEmpty ? steps.first : StepDraft();
        _title.text = _single.title;
        _iconKey = _single.iconKey ?? reminder.iconKey;
        _stepSeconds = _single.timerSeconds ?? 0;
      }
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

  Future<void> _pickIcon() async {
    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => IconPickerScreen(selected: _iconKey)),
    );
    if (picked != null) setState(() => _iconKey = picked);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    // Cropped to the card's exact ratio so nothing the user framed gets
    // silently cut off by the home list.
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(
        ratioX: kCardImageRatioX,
        ratioY: kCardImageRatioY,
      ),
      maxWidth: 1600,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop image',
          toolbarColor: AppColors.background,
          toolbarWidgetColor: AppColors.onSurface,
          backgroundColor: AppColors.background,
          activeControlsWidgetColor: AppColors.primary,
          cropFrameColor: AppColors.primary,
          cropGridColor: AppColors.outlineDim,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop image',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );
    if (cropped == null) return;

    // Copied into app storage so the reminder survives the gallery item moving.
    final dir = await getApplicationDocumentsDirectory();
    final dest = p.join(
      dir.path,
      'reminder_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await File(cropped.path).copy(dest);
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

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      _toast(_routine ? 'Give the routine a name.' : 'Give the step a title.');
      return;
    }
    if (_routine && _steps.isEmpty) {
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

    final List<StepDraft> steps;
    if (_routine) {
      steps = _steps;
    } else {
      _single
        ..title = title
        ..iconKey = _iconKey
        ..timerSeconds = _stepSeconds > 0 ? _stepSeconds : null;
      steps = [_single];
    }

    await ref.read(repositoryProvider).save(
          id: widget.reminderId,
          // A single step has no separate name, so the reminder mirrors it and
          // the home list keeps reading one field either way.
          title: title,
          iconKey: _iconKey,
          hour: _time!.hour,
          minute: _time!.minute,
          daysMask: _daysMask,
          notificationsEnabled: _notifications,
          alarmEnabled: _alarm,
          multiStep: _routine,
          imagePath: _addImage ? _imagePath : null,
          steps: steps,
        );

    if (mounted) Navigator.pop(context);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String get _screenTitle {
    if (_routine) return _isNew ? 'New routine' : 'Edit routine';
    return _isNew ? 'New step' : 'Edit step';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_screenTitle),
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
              labelText: _routine ? 'Routine name' : 'Step title',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 6),
                child: IconButton(
                  icon: Icon(IconCatalog.resolve(_iconKey), size: 28),
                  tooltip: 'Choose icon',
                  onPressed: _pickIcon,
                ),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),
          if (!_routine) ...[
            const SizedBox(height: 18),
            TimerPicker(
              seconds: _stepSeconds,
              onChanged: (v) => setState(() => _stepSeconds = v),
            ),
          ],
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
            _ImagePickerBox(path: _imagePath, onTap: _pickImage),
          ],
          if (_routine) ...[
            const SizedBox(height: 22),
            const Divider(),
            const SizedBox(height: 22),
            if (_steps.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'No steps yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15, color: AppColors.onSurfaceVariant),
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
            Center(
              child: OutlinedButton.icon(
                onPressed: _addStep,
                icon: const Icon(Symbols.add, size: 24),
                label: const Text('Add Step'),
              ),
            ),
          ],
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
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        // Same ratio as the home card, so this preview is a true preview.
        child: AspectRatio(
          aspectRatio: kCardImageAspect,
          child: hasImage
              ? Image.file(file, fit: BoxFit.cover)
              : const Center(
                  child: Icon(Symbols.image,
                      size: 52, color: AppColors.onSurfaceVariant),
                ),
        ),
      ),
    );
  }
}
