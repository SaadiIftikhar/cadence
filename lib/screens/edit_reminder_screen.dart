import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/app_prefs.dart';
import '../data/providers.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../util/duration_format.dart';
import '../util/icon_catalog.dart';
import '../widgets/form_fields.dart';
import '../widgets/hint_callout.dart';
import '../widgets/pill_tile.dart';
import '../widgets/tappable_icon.dart';
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
  bool _notifications = false;
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

  /// Set when a save was attempted with the field empty; reddens its outline
  /// until it is filled in.
  bool _titleInvalid = false;
  bool _timeInvalid = false;

  /// Same idea for a routine's step list: there is no single field to redden,
  /// so Add step's own border carries it instead.
  bool _stepsInvalid = false;

  /// Each shown once ever, the first time someone reaches an editor.
  bool _showIconHint = false;
  bool _showTimeHint = false;

  bool get _isNew => widget.reminderId == null;

  @override
  void initState() {
    super.initState();
    _load();
    AppPrefs.seenIconHint().then((seen) {
      if (!seen && mounted) setState(() => _showIconHint = true);
    });
    AppPrefs.seenTimeHint().then((seen) {
      if (!seen && mounted) setState(() => _showTimeHint = true);
    });
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
    _dismissTimeHint();
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _time = picked;
        _timeInvalid = false;
      });
    }
  }

  Future<void> _pickDays() async {
    final picked = await showDayPickerDialog(context, _daysMask);
    if (picked != null) setState(() => _daysMask = picked);
  }

  void _dismissIconHint() {
    if (!_showIconHint) return;
    setState(() => _showIconHint = false);
    AppPrefs.markIconHintSeen();
  }

  void _dismissTimeHint() {
    if (!_showTimeHint) return;
    setState(() => _showTimeHint = false);
    AppPrefs.markTimeHintSeen();
  }

  Future<void> _pickIcon() async {
    // Tapping the icon is the thing the hint was there to teach.
    _dismissIconHint();
    // Dropped before leaving, or Flutter hands focus back to the name field on
    // the way in and the keyboard reappears over the picker's results.
    FocusManager.instance.primaryFocus?.unfocus();

    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => IconPickerScreen(selected: _iconKey)),
    );
    if (picked != null) setState(() => _iconKey = picked);
  }

  /// Retargets an already-added step's icon without opening its whole editor.
  Future<void> _pickStepIcon(int index) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => IconPickerScreen(selected: _steps[index].iconKey),
      ),
    );
    if (picked == null) return;
    setState(() {
      final next = [..._steps];
      next[index].iconKey = picked;
      _steps = next;
    });
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
    setState(() {
      _steps = [..._steps, result!.draft!];
      _stepsInvalid = false;
    });
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
    FocusManager.instance.primaryFocus?.unfocus();
    final title = _title.text.trim();
    final missingTitle = title.isEmpty;
    final missingTime = _time == null;
    final missingSteps = _routine && _steps.isEmpty;

    // All three are marked at once, so a save never fixes one problem only
    // to find out about the next one on the next attempt.
    if (missingTitle || missingTime || missingSteps) {
      setState(() {
        _titleInvalid = missingTitle;
        _timeInvalid = missingTime;
        _stepsInvalid = missingSteps;
      });
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
                : const Icon(Symbols.save, semanticLabel: 'Save'),
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
            onChanged: (v) {
              if (_titleInvalid && v.trim().isNotEmpty) {
                setState(() => _titleInvalid = false);
              }
            },
            decoration: InputDecoration(
              labelText: _routine ? 'Routine name' : 'Step title',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              enabledBorder: _titleInvalid ? AppShapes.invalidFieldBorder : null,
              focusedBorder: _titleInvalid ? AppShapes.invalidFieldBorder : null,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: TappableIcon(iconKey: _iconKey, onTap: _pickIcon),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),
          if (_showIconHint)
            HintCallout(
              message: 'Tap the icon to change it',
              onDismiss: _dismissIconHint,
            ),
          const SizedBox(height: 18),
          ValuePill(
            icon: Symbols.schedule,
            label: 'Time',
            value: _time == null
                ? 'Set time'
                : MaterialLocalizations.of(context).formatTimeOfDay(_time!),
            placeholder: _time == null,
            invalid: _timeInvalid,
            onTap: _pickTime,
          ),
          if (_showTimeHint)
            HintCallout(
              message: 'Time is the only thing that changes a reminder\'s '
                  'place on the home screen',
              onDismiss: _dismissTimeHint,
              arrowInset: 34,
            ),
          const SizedBox(height: 12),
          ValuePill(
            icon: Symbols.repeat,
            label: 'Repeat',
            value: describeDays(_daysMask),
            placeholder: _daysMask == 0,
            onTap: _pickDays,
          ),
          if (!_routine) ...[
            const SizedBox(height: 12),
            TimerPicker(
              seconds: _stepSeconds,
              onChanged: (v) => setState(() => _stepSeconds = v),
            ),
          ],
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
            label: 'Add image',
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
            else ...[
              if (_steps.length > 1)
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'Press and hold a step to reorder',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.onSurfaceVariant),
                  ),
                ),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _steps.length,
                onReorderItem: (oldIndex, newIndex) => setState(
                  () => _steps = reorderSteps(_steps, oldIndex, newIndex),
                ),
                itemBuilder: (context, i) => Padding(
                  // Keyed by identity, not index, so a dragged step keeps its
                  // own row rather than swapping content with a neighbour.
                  key: ObjectKey(_steps[i]),
                  padding: EdgeInsets.only(bottom: i == _steps.length - 1 ? 0 : 12),
                  child: PillTile(
                    label: _steps[i].title.isEmpty
                        ? 'Untitled step'
                        : _steps[i].title,
                    iconKey: _steps[i].iconKey,
                    onTap: () => _editStep(i),
                    onIconTap: () => _pickStepIcon(i),
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
                ),
              ),
            ],
            const SizedBox(height: 20),
            Center(
              child: OutlinedButton.icon(
                onPressed: _addStep,
                style: _stepsInvalid
                    ? OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppColors.error, width: 3),
                      )
                    : null,
                icon: const Icon(Symbols.add, size: 24),
                label: const Text('Add step'),
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
