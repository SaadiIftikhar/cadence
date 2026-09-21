import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get iconKey => text().withDefault(const Constant('alarm'))();
  IntColumn get hour => integer().withDefault(const Constant(8))();
  IntColumn get minute => integer().withDefault(const Constant(0))();

  /// Bit 0 = Monday … bit 6 = Sunday. Zero means "no repeat".
  IntColumn get daysMask => integer().withDefault(const Constant(0))();

  BoolColumn get notificationsEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get alarmEnabled => boolean().withDefault(const Constant(false))();
  BoolColumn get multiStep => boolean().withDefault(const Constant(false))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Named `ReminderSteps` rather than `Steps` so the generated row class is
/// `ReminderStep` and does not collide with Flutter's `Step` stepper widget.
class ReminderSteps extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get reminderId =>
      integer().references(Reminders, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get iconKey => text().nullable()();

  /// Null means the step has no timer.
  IntColumn get timerSeconds => integer().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();
}

@DriftDatabase(tables: [Reminders, ReminderSteps])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'step_reminder'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Stream<List<Reminder>> watchReminders() =>
      (select(reminders)..orderBy([(r) => OrderingTerm(expression: r.hour), (r) => OrderingTerm(expression: r.minute)]))
          .watch();

  Future<Reminder?> findReminder(int id) =>
      (select(reminders)..where((r) => r.id.equals(id))).getSingleOrNull();

  Stream<List<ReminderStep>> watchSteps(int reminderId) => (select(reminderSteps)
        ..where((s) => s.reminderId.equals(reminderId))
        ..orderBy([(s) => OrderingTerm(expression: s.position)]))
      .watch();

  Future<List<ReminderStep>> stepsFor(int reminderId) => (select(reminderSteps)
        ..where((s) => s.reminderId.equals(reminderId))
        ..orderBy([(s) => OrderingTerm(expression: s.position)]))
      .get();

  Future<int> upsertReminder(RemindersCompanion entry) async {
    if (entry.id.present) {
      await (update(reminders)..where((r) => r.id.equals(entry.id.value)))
          .write(entry);
      return entry.id.value;
    }
    return into(reminders).insert(entry);
  }

  Future<void> deleteReminder(int id) =>
      (delete(reminders)..where((r) => r.id.equals(id))).go();

  Future<int> upsertStep(ReminderStepsCompanion entry) async {
    if (entry.id.present) {
      await (update(reminderSteps)..where((s) => s.id.equals(entry.id.value)))
          .write(entry);
      return entry.id.value;
    }
    return into(reminderSteps).insert(entry);
  }

  Future<void> deleteStep(int id) =>
      (delete(reminderSteps)..where((s) => s.id.equals(id))).go();

  Future<void> replaceSteps(
      int reminderId, List<ReminderStepsCompanion> entries) async {
    await transaction(() async {
      await (delete(reminderSteps)
            ..where((s) => s.reminderId.equals(reminderId)))
          .go();
      for (var i = 0; i < entries.length; i++) {
        await into(reminderSteps).insert(
          entries[i].copyWith(
            reminderId: Value(reminderId),
            position: Value(i),
          ),
        );
      }
    });
  }
}
