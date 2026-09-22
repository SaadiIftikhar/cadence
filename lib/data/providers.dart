import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../services/notification_service.dart';
import 'backup_service.dart';
import 'database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final remindersProvider = StreamProvider<List<Reminder>>(
  (ref) => ref.watch(databaseProvider).watchReminders(),
);

final stepsProvider = StreamProvider.family<List<ReminderStep>, int>(
  (ref, reminderId) => ref.watch(databaseProvider).watchSteps(reminderId),
);

final stepProgressProvider = StreamProvider<Map<int, StepProgress>>(
  (ref) => ref.watch(databaseProvider).watchStepProgress(),
);

final repositoryProvider = Provider<ReminderRepository>(
  (ref) => ReminderRepository(ref.watch(databaseProvider)),
);

final backupServiceProvider = FutureProvider<BackupService>((ref) async {
  return BackupService(
    ref.watch(databaseProvider),
    imageDirectory: await getApplicationDocumentsDirectory(),
  );
});

/// The step after [currentId] that still needs doing, or null if nothing
/// later in the list does.
///
/// Only looks forward, in list order, never back and never wrapping to the
/// start: "next" means the next one, not any incomplete step picked from
/// anywhere in the routine. That is what lets Done double as the only way to
/// move through a routine — there is no separate forward control whose
/// meaning could disagree with what back does.
ReminderStep? nextIncompleteStep(List<ReminderStep> steps, int currentId) {
  final index = steps.indexWhere((s) => s.id == currentId);
  if (index == -1) return null;
  for (var i = index + 1; i < steps.length; i++) {
    if (!steps[i].completed) return steps[i];
  }
  return null;
}

/// Moves a step within a routine, taking the indices a [ReorderableListView]'s
/// `onReorderItem` reports — `newIndex` is already the index the item should
/// end up at, the shift from removing it at `oldIndex` already accounted for
/// by the caller.
///
/// Position numbers are not stored here: saving rewrites them from this
/// order, which is what keeps them contiguous.
List<StepDraft> reorderSteps(
  List<StepDraft> steps,
  int oldIndex,
  int newIndex,
) {
  if (oldIndex < 0 || oldIndex >= steps.length) return steps;

  final target = newIndex.clamp(0, steps.length - 1);
  if (target == oldIndex) return steps;

  final next = [...steps];
  next.insert(target, next.removeAt(oldIndex));
  return next;
}

/// Home order: still to do first, earliest time of day first within that, and
/// anything finished pushed to the bottom keeping the same time order.
List<Reminder> orderedForHome(
  List<Reminder> reminders,
  Map<int, StepProgress> progress,
) {
  int minuteOfDay(Reminder r) => r.hour * 60 + r.minute;
  int finished(Reminder r) => (progress[r.id]?.allDone ?? false) ? 1 : 0;

  return [...reminders]..sort((a, b) {
      final byDone = finished(a) - finished(b);
      if (byDone != 0) return byDone;

      final byTime = minuteOfDay(a).compareTo(minuteOfDay(b));
      if (byTime != 0) return byTime;

      // Dart's sort is not stable, so break remaining ties deterministically.
      return a.id.compareTo(b.id);
    });
}

/// Whether a one-off reminder's day has already been and gone.
///
/// An empty [Reminder.daysMask] means "today only" — the day it was made and
/// no other. Once [now] has rolled past that date there is nothing left for it
/// to do. A repeating reminder never lapses, however old it is.
bool hasLapsed(Reminder reminder, DateTime now) {
  if (reminder.daysMask != 0) return false;
  final made = reminder.createdAt;
  return DateTime(made.year, made.month, made.day)
      .isBefore(DateTime(now.year, now.month, now.day));
}

/// The same rule over a whole list: what the home screen still has reason to
/// show, and what is still worth arming a notification for.
List<Reminder> withoutLapsedOneOffs(List<Reminder> all, DateTime now) =>
    all.where((r) => !hasLapsed(r, now)).toList();

/// Reminders that repeat on [day]'s weekday.
///
/// A reminder with an empty [Reminder.daysMask] fires once at its next
/// occurrence rather than repeating, so it has no weekday of its own and
/// never matches here — a one-off belongs on the home list, not scattered
/// across a calendar day it may or may not still land on by the time that
/// day arrives.
List<Reminder> remindersOnDay(List<Reminder> all, DateTime day) {
  final bit = 1 << (day.weekday - 1);
  return all.where((r) => r.enabled && r.daysMask & bit != 0).toList();
}

/// An unsaved step. The edit screen builds these up before the reminder itself
/// has an id, so they cannot be drift rows yet.
class StepDraft {
  StepDraft({
    this.id,
    this.title = '',
    this.iconKey,
    this.timerSeconds,
    this.completed = false,
  });

  factory StepDraft.fromRow(ReminderStep row) => StepDraft(
        id: row.id,
        title: row.title,
        iconKey: row.iconKey,
        timerSeconds: row.timerSeconds,
        completed: row.completed,
      );

  int? id;
  String title;
  String? iconKey;
  int? timerSeconds;

  /// Carried through a save so that editing a reminder does not silently
  /// wipe how far through its routine you were.
  bool completed;

  bool get hasTimer => timerSeconds != null && timerSeconds! > 0;

  ReminderStepsCompanion toCompanion() => ReminderStepsCompanion(
        title: Value(title),
        iconKey: Value(iconKey),
        timerSeconds: Value(timerSeconds),
        completed: Value(completed),
      );
}

class ReminderRepository {
  ReminderRepository(this._db);

  final AppDatabase _db;

  Future<int> save({
    int? id,
    required String title,
    required String iconKey,
    required int hour,
    required int minute,
    required int daysMask,
    required bool notificationsEnabled,
    required bool alarmEnabled,
    required bool multiStep,
    String? imagePath,
    required List<StepDraft> steps,
  }) async {
    final reminderId = await _db.upsertReminder(
      RemindersCompanion(
        id: id == null ? const Value.absent() : Value(id),
        title: Value(title),
        iconKey: Value(iconKey),
        hour: Value(hour),
        minute: Value(minute),
        daysMask: Value(daysMask),
        notificationsEnabled: Value(notificationsEnabled),
        alarmEnabled: Value(alarmEnabled),
        multiStep: Value(multiStep),
        imagePath: Value(imagePath),
      ),
    );

    await _db.replaceSteps(
      reminderId,
      steps.map((s) => s.toCompanion()).toList(),
    );

    final saved = await _db.findReminder(reminderId);
    if (saved != null) {
      await NotificationService.instance.scheduleReminder(saved);
    }
    return reminderId;
  }

  Future<void> delete(int id) async {
    await NotificationService.instance.cancelReminder(id);
    await _db.deleteReminder(id);
  }

  Future<void> setEnabled(Reminder reminder, bool enabled) async {
    await _db.upsertReminder(
      RemindersCompanion(id: Value(reminder.id), enabled: Value(enabled)),
    );
    final saved = await _db.findReminder(reminder.id);
    if (saved != null) {
      await NotificationService.instance.scheduleReminder(saved);
    }
  }

  Future<void> markStep(int stepId, bool completed) =>
      _db.setStepCompleted(stepId, completed);

  Future<void> setAllCompleted(int reminderId, bool completed) =>
      _db.setAllCompleted(reminderId, completed);

  Future<List<StepDraft>> draftsFor(int reminderId) async {
    final rows = await _db.stepsFor(reminderId);
    return rows.map(StepDraft.fromRow).toList();
  }

  /// Re-arms every scheduled notification. Android drops alarms on reboot and
  /// on app reinstall, so this runs at startup.
  ///
  /// Yesterday's one-offs are left out: re-arming one would schedule it for
  /// the next time its clock time comes round, which is tomorrow — a reminder
  /// meant for a day that has passed ringing on a day it was never for.
  Future<void> rescheduleAll() async {
    final all = await _db.watchReminders().first;
    await NotificationService.instance
        .rescheduleAll(withoutLapsedOneOffs(all, DateTime.now()));
  }
}
