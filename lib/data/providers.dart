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
  Future<void> rescheduleAll() async {
    final all = await _db.watchReminders().first;
    await NotificationService.instance.rescheduleAll(all);
  }
}
