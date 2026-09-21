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

  /// Survives leaving and re-entering a routine. Only an explicit Reset
  /// clears it.
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Reminders, ReminderSteps])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'step_reminder'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(reminderSteps, reminderSteps.completed);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> setStepCompleted(int stepId, bool completed) =>
      (update(reminderSteps)..where((s) => s.id.equals(stepId)))
          .write(ReminderStepsCompanion(completed: Value(completed)));

  Future<void> clearCompletion(int reminderId) =>
      (update(reminderSteps)..where((s) => s.reminderId.equals(reminderId)))
          .write(const ReminderStepsCompanion(completed: Value(false)));

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

  /// Step count per reminder id, so the home list can tell a single-step
  /// reminder from a multi-step one without loading every step.
  Stream<Map<int, int>> watchStepCounts() {
    final total = reminderSteps.id.count();
    final query = selectOnly(reminderSteps)
      ..addColumns([reminderSteps.reminderId, total])
      ..groupBy([reminderSteps.reminderId]);

    return query.watch().map(
          (rows) => {
            for (final row in rows)
              row.read(reminderSteps.reminderId)!: row.read(total)!,
          },
        );
  }

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

  /// Inserts one single-step and one multi-step example the first time the app
  /// runs, so the home list has something to show. Deleting them is permanent —
  /// they are only seeded into an empty database.
  Future<void> seedSamplesIfEmpty() async {
    final existing = await select(reminders).get();
    if (existing.isNotEmpty) return;

    await transaction(() async {
      final vitamins = await into(reminders).insert(
        RemindersCompanion.insert(
          title: const Value('Take vitamins'),
          iconKey: const Value('medication'),
          hour: const Value(8),
          minute: const Value(30),
          daysMask: const Value(0x1F), // weekdays
        ),
      );
      await into(reminderSteps).insert(
        ReminderStepsCompanion.insert(
          reminderId: vitamins,
          title: const Value('Vitamin D with breakfast'),
          iconKey: const Value('medication'),
        ),
      );

      final routine = await into(reminders).insert(
        RemindersCompanion.insert(
          title: const Value('Morning routine'),
          iconKey: const Value('wb_sunny'),
          hour: const Value(7),
          minute: const Value(0),
          daysMask: const Value(0x7F), // every day
          multiStep: const Value(true),
        ),
      );
      const steps = [
        ('Drink a glass of water', 'water_drop', null),
        ('Stretch', 'self_improvement', 300),
        ('Shower', 'shower', 600),
        ('Make coffee', 'local_cafe', 180),
      ];
      for (var i = 0; i < steps.length; i++) {
        final (title, icon, seconds) = steps[i];
        await into(reminderSteps).insert(
          ReminderStepsCompanion.insert(
            reminderId: routine,
            title: Value(title),
            iconKey: Value(icon),
            timerSeconds: Value(seconds),
            position: Value(i),
          ),
        );
      }
    });
  }

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
