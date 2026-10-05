import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:step_reminder/data/database.dart';
import 'package:step_reminder/data/housekeeping.dart';
import 'package:step_reminder/data/providers.dart';

void main() {
  late Directory dir;
  late AppDatabase db;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('step_reminder_sweep');
    db = AppDatabase.forTesting(NativeDatabase(File('${dir.path}/app.sqlite')));
  });

  tearDown(() async {
    await db.close();
    if (dir.existsSync()) {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  File writeImage(String name) {
    final file = File('${dir.path}/$name')..writeAsBytesSync([1, 2, 3]);
    return file;
  }

  Future<int> addReminder({
    required int daysMask,
    String? imagePath,
    DateTime? createdAt,
    String title = 'Reminder',
  }) =>
      db.upsertReminder(
        RemindersCompanion.insert(
          title: Value(title),
          hour: const Value(8),
          minute: const Value(0),
          daysMask: Value(daysMask),
          imagePath: Value(imagePath),
          createdAt:
              createdAt == null ? const Value.absent() : Value(createdAt),
        ),
      );

  group('deleteOrphanedImages', () {
    test('a picture no reminder points at is removed', () async {
      final orphan = writeImage('reminder_111.jpg');

      expect(await deleteOrphanedImages(db, dir), 1);
      expect(orphan.existsSync(), isFalse);
    });

    test('a picture still in use is left alone', () async {
      final kept = writeImage('reminder_222.jpg');
      await addReminder(daysMask: 0x7F, imagePath: kept.path);

      expect(await deleteOrphanedImages(db, dir), 0);
      expect(kept.existsSync(), isTrue);
    });

    test('it keeps its hands off anything it did not write', () async {
      // The database sits in the same directory. A sweep that deleted what it
      // merely did not recognise would take the reminders with it.
      final database = File('${dir.path}/app.sqlite');
      final stray = File('${dir.path}/notes.txt')..writeAsStringSync('hello');
      final nearMiss = writeImage('reminder_abc.jpg');
      final alsoNearMiss = writeImage('reminder_333.png');

      await deleteOrphanedImages(db, dir);

      expect(database.existsSync(), isTrue);
      expect(stray.existsSync(), isTrue);
      expect(nearMiss.existsSync(), isTrue);
      expect(alsoNearMiss.existsSync(), isTrue);
    });

    test('only the unreferenced ones go, out of a mixed directory', () async {
      final kept = writeImage('reminder_1.jpg');
      final gone = writeImage('reminder_2.jpg');
      final alsoGone = writeImage('reminder_3.jpg');
      await addReminder(daysMask: 0x7F, imagePath: kept.path);

      expect(await deleteOrphanedImages(db, dir), 2);
      expect(kept.existsSync(), isTrue);
      expect(gone.existsSync(), isFalse);
      expect(alsoGone.existsSync(), isFalse);
    });

    test('a missing directory is not an error', () async {
      final absent = Directory('${dir.path}/nowhere');
      expect(await deleteOrphanedImages(db, absent), 0);
    });
  });

  group('removeLapsedOneOffs', () {
    late ReminderRepository repo;

    setUp(() => repo = ReminderRepository(db));

    final now = DateTime(2026, 9, 22, 10, 0);

    test('yesterday\'s one-off is deleted, steps and all', () async {
      final id = await addReminder(
        daysMask: 0,
        createdAt: DateTime(2026, 9, 21),
        title: 'Bin night',
      );
      await db.replaceSteps(id, [
        ReminderStepsCompanion.insert(
          reminderId: id,
          title: const Value('Take it out'),
        ),
      ]);

      expect(await repo.removeLapsedOneOffs(now), 1);
      expect(await db.allReminders(), isEmpty);
      // The cascade took the steps with it rather than stranding them.
      expect(await db.select(db.reminderSteps).get(), isEmpty);
    });

    test('today\'s one-off is left alone', () async {
      await addReminder(daysMask: 0, createdAt: DateTime(2026, 9, 22, 7));

      expect(await repo.removeLapsedOneOffs(now), 0);
      expect(await db.allReminders(), hasLength(1));
    });

    test('a repeating reminder is never touched, however old', () async {
      await addReminder(daysMask: 0x7F, createdAt: DateTime(2024, 1, 1));

      expect(await repo.removeLapsedOneOffs(now), 0);
      expect(await db.allReminders(), hasLength(1));
    });

    test('its picture is swept straight afterwards', () async {
      final image = writeImage('reminder_999.jpg');
      await addReminder(
        daysMask: 0,
        createdAt: DateTime(2026, 9, 20),
        imagePath: image.path,
      );

      await repo.removeLapsedOneOffs(now);
      expect(await deleteOrphanedImages(db, dir), 1);
      expect(image.existsSync(), isFalse);
    });
  });
}
