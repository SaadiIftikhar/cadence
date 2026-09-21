import 'dart:io';

// `isNull`/`isNotNull` exist in both drift and the matcher library.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:step_reminder/data/database.dart';

/// Proves that what the app writes actually lands on disk, by closing the
/// database between every write and read rather than trusting one open
/// connection's cache.
void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('step_reminder_persistence');
    file = File('${dir.path}/app.sqlite');
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  AppDatabase reopen() => AppDatabase.forTesting(NativeDatabase(file));

  /// Runs [work] against a freshly opened database and closes it afterwards,
  /// so the next call has to read from the file.
  Future<T> withDb<T>(Future<T> Function(AppDatabase db) work) async {
    final db = reopen();
    try {
      return await work(db);
    } finally {
      await db.close();
    }
  }

  Future<int> createRoutine() => withDb((db) async {
        final id = await db.upsertReminder(
          RemindersCompanion.insert(
            title: const Value('Morning routine'),
            iconKey: const Value('wb_sunny'),
            hour: const Value(7),
            minute: const Value(15),
            daysMask: const Value(0x1F),
            multiStep: const Value(true),
            notificationsEnabled: const Value(true),
          ),
        );
        await db.replaceSteps(id, [
          ReminderStepsCompanion.insert(
            reminderId: id,
            title: const Value('Drink water'),
          ),
          ReminderStepsCompanion.insert(
            reminderId: id,
            title: const Value('Stretch'),
            timerSeconds: const Value(300),
          ),
          ReminderStepsCompanion.insert(
            reminderId: id,
            title: const Value('Coffee'),
          ),
        ]);
        return id;
      });

  test('a reminder and its steps survive a restart', () async {
    final id = await createRoutine();

    await withDb((db) async {
      final reminder = await db.findReminder(id);
      expect(reminder, isNotNull);
      expect(reminder!.title, 'Morning routine');
      expect(reminder.iconKey, 'wb_sunny');
      expect(reminder.hour, 7);
      expect(reminder.minute, 15);
      expect(reminder.daysMask, 0x1F);
      expect(reminder.multiStep, isTrue);

      final steps = await db.stepsFor(id);
      expect(steps.map((s) => s.title), ['Drink water', 'Stretch', 'Coffee']);
      expect(steps[1].timerSeconds, 300);
      // Order is what the routine screen walks, so it has to be stable.
      expect(steps.map((s) => s.position), [0, 1, 2]);
    });
  });

  test('marking one step done survives a restart', () async {
    final id = await createRoutine();

    final secondStepId = await withDb((db) async {
      final steps = await db.stepsFor(id);
      await db.setStepCompleted(steps[1].id, true);
      return steps[1].id;
    });

    await withDb((db) async {
      final steps = await db.stepsFor(id);
      expect(steps.firstWhere((s) => s.id == secondStepId).completed, isTrue);
      expect(steps.where((s) => s.completed).length, 1);
    });
  });

  test('finishing a whole routine survives a restart', () async {
    final id = await createRoutine();
    await withDb((db) => db.setAllCompleted(id, true));

    await withDb((db) async {
      final steps = await db.stepsFor(id);
      expect(steps.every((s) => s.completed), isTrue);
    });
  });

  test('resetting clears completion on disk, not just on screen', () async {
    final id = await createRoutine();
    await withDb((db) => db.setAllCompleted(id, true));
    await withDb((db) => db.setAllCompleted(id, false));

    await withDb((db) async {
      final steps = await db.stepsFor(id);
      expect(steps.any((s) => s.completed), isFalse);
    });
  });

  test('editing a reminder keeps how far through it you were', () async {
    final id = await createRoutine();
    await withDb((db) async {
      final steps = await db.stepsFor(id);
      await db.setStepCompleted(steps.first.id, true);
    });

    // The edit screen rewrites every step row, carrying completion across.
    await withDb((db) async {
      final drafts = await db.stepsFor(id);
      await db.upsertReminder(
        RemindersCompanion(id: Value(id), title: const Value('Renamed')),
      );
      await db.replaceSteps(
        id,
        [
          for (final s in drafts)
            ReminderStepsCompanion.insert(
              reminderId: id,
              title: Value(s.title),
              iconKey: Value(s.iconKey),
              timerSeconds: Value(s.timerSeconds),
              completed: Value(s.completed),
            ),
        ],
      );
    });

    await withDb((db) async {
      expect((await db.findReminder(id))!.title, 'Renamed');
      final steps = await db.stepsFor(id);
      expect(steps.first.completed, isTrue);
      expect(steps.where((s) => s.completed).length, 1);
    });
  });

  test('progress counts read back correctly after a restart', () async {
    final id = await createRoutine();
    await withDb((db) async {
      final steps = await db.stepsFor(id);
      await db.setStepCompleted(steps[0].id, true);
      await db.setStepCompleted(steps[2].id, true);
    });

    await withDb((db) async {
      final progress = await db.watchStepProgress().first;
      expect(progress[id]!.total, 3);
      expect(progress[id]!.done, 2);
      expect(progress[id]!.allDone, isFalse);
      expect(progress[id]!.isRoutine, isTrue);
    });
  });

  test('deleting a reminder takes its steps with it', () async {
    final id = await createRoutine();
    await withDb((db) => db.deleteReminder(id));

    await withDb((db) async {
      expect(await db.findReminder(id), isNull);
      expect(await db.stepsFor(id), isEmpty);
    });
  });

  test('turning a reminder off survives a restart', () async {
    final id = await createRoutine();
    await withDb(
      (db) => db.upsertReminder(
        RemindersCompanion(id: Value(id), enabled: const Value(false)),
      ),
    );

    await withDb((db) async {
      expect((await db.findReminder(id))!.enabled, isFalse);
      // Turning it off must not disturb anything else about it.
      expect((await db.findReminder(id))!.title, 'Morning routine');
    });
  });
}
