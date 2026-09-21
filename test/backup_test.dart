import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:step_reminder/data/backup.dart';
import 'package:step_reminder/data/backup_service.dart';
import 'package:step_reminder/data/database.dart';

void main() {
  group('Backup format', () {
    ReminderBackup sample({List<StepBackup>? steps, String? image}) =>
        ReminderBackup(
          title: 'Morning routine',
          iconKey: 'wb_sunny',
          hour: 7,
          minute: 15,
          daysMask: 0x1F,
          notificationsEnabled: true,
          alarmEnabled: true,
          multiStep: true,
          enabled: false,
          imageBase64: image,
          steps: steps ??
              const [
                StepBackup(title: 'Water', iconKey: 'water_drop'),
                StepBackup(title: 'Stretch', timerSeconds: 300),
              ],
        );

    test('every setting survives a round trip', () {
      final out = Backup.decode(Backup.encode([sample()]));
      expect(out, hasLength(1));

      final r = out.single;
      expect(r.title, 'Morning routine');
      expect(r.iconKey, 'wb_sunny');
      expect(r.hour, 7);
      expect(r.minute, 15);
      expect(r.daysMask, 0x1F);
      expect(r.notificationsEnabled, isTrue);
      expect(r.alarmEnabled, isTrue);
      expect(r.multiStep, isTrue);
      expect(r.enabled, isFalse);

      expect(r.steps.map((s) => s.title), ['Water', 'Stretch']);
      expect(r.steps[0].iconKey, 'water_drop');
      expect(r.steps[0].timerSeconds, isNull);
      expect(r.steps[1].timerSeconds, 300);
    });

    test('step order is preserved', () {
      final many = [
        for (var i = 0; i < 6; i++) StepBackup(title: 'step $i'),
      ];
      final out = Backup.decode(Backup.encode([sample(steps: many)]));
      expect(out.single.steps.map((s) => s.title),
          ['step 0', 'step 1', 'step 2', 'step 3', 'step 4', 'step 5']);
    });

    test('a picture travels inside the file', () {
      final image = base64Encode(List.filled(64, 7));
      final out = Backup.decode(Backup.encode([sample(image: image)]));
      expect(out.single.imageBase64, image);
    });

    test('the file never mentions completion', () {
      final json = Backup.encode([sample()]);
      expect(json.contains('completed'), isFalse);
      expect(json.contains('"done"'), isFalse);
    });

    test('rubbish is rejected rather than half-imported', () {
      expect(() => Backup.decode('not json'),
          throwsA(isA<BackupFormatException>()));
      expect(() => Backup.decode('[]'), throwsA(isA<BackupFormatException>()));
      expect(() => Backup.decode('{"app":"something_else","format":1}'),
          throwsA(isA<BackupFormatException>()));
      expect(
        () => Backup.decode('{"app":"step_reminder","format":1}'),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('a newer format is refused, not guessed at', () {
      final json = jsonEncode({
        'app': 'step_reminder',
        'format': Backup.formatVersion + 1,
        'reminders': <dynamic>[],
      });
      expect(() => Backup.decode(json), throwsA(isA<BackupFormatException>()));
    });

    test('an out-of-range time falls back instead of throwing', () {
      final json = jsonEncode({
        'app': 'step_reminder',
        'format': 1,
        'reminders': [
          {'title': 'Odd', 'hour': 99, 'minute': -3, 'steps': <dynamic>[]},
        ],
      });
      final r = Backup.decode(json).single;
      expect(r.hour, 8);
      expect(r.minute, 0);
    });
  });

  group('BackupService', () {
    late Directory dir;
    late File file;
    late AppDatabase db;
    late BackupService service;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('step_reminder_backup');
      file = File('${dir.path}/app.sqlite');
      db = AppDatabase.forTesting(NativeDatabase(file));
      service = BackupService(db, imageDirectory: dir);
    });

    tearDown(() async {
      await db.close();
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    Future<int> addRoutine({
      String title = 'Morning routine',
      bool alarm = false,
      String? imagePath,
    }) async {
      final id = await db.upsertReminder(
        RemindersCompanion.insert(
          title: Value(title),
          iconKey: const Value('wb_sunny'),
          hour: const Value(7),
          minute: const Value(15),
          daysMask: const Value(0x1F),
          notificationsEnabled: const Value(true),
          alarmEnabled: Value(alarm),
          multiStep: const Value(true),
          imagePath: Value(imagePath),
        ),
      );
      await db.replaceSteps(id, [
        ReminderStepsCompanion.insert(
          reminderId: id,
          title: const Value('Water'),
        ),
        ReminderStepsCompanion.insert(
          reminderId: id,
          title: const Value('Stretch'),
          timerSeconds: const Value(300),
        ),
      ]);
      return id;
    }

    test('an export carries the settings but not the progress', () async {
      final id = await addRoutine(alarm: true);
      final steps = await db.stepsFor(id);
      await db.setStepCompleted(steps.first.id, true);

      final json = await service.export();
      final decoded = Backup.decode(json).single;

      expect(decoded.title, 'Morning routine');
      expect(decoded.alarmEnabled, isTrue);
      expect(decoded.daysMask, 0x1F);
      expect(decoded.steps[1].timerSeconds, 300);
      expect(json.contains('completed'), isFalse);
    });

    test('importing into an empty app restores everything', () async {
      await addRoutine(alarm: true);
      final json = await service.export();

      await db.deleteAllReminders();
      expect(await db.allReminders(), isEmpty);

      final count = await service.import(json, mode: ImportMode.add);
      expect(count, 1);

      final restored = (await db.allReminders()).single;
      expect(restored.title, 'Morning routine');
      expect(restored.iconKey, 'wb_sunny');
      expect(restored.hour, 7);
      expect(restored.minute, 15);
      expect(restored.daysMask, 0x1F);
      expect(restored.notificationsEnabled, isTrue);
      expect(restored.alarmEnabled, isTrue);
      expect(restored.multiStep, isTrue);

      final steps = await db.stepsFor(restored.id);
      expect(steps.map((s) => s.title), ['Water', 'Stretch']);
      expect(steps[1].timerSeconds, 300);
      expect(steps.map((s) => s.position), [0, 1]);
    });

    test('imported steps always arrive unticked', () async {
      final id = await addRoutine();
      for (final s in await db.stepsFor(id)) {
        await db.setStepCompleted(s.id, true);
      }
      final json = await service.export();

      await service.import(json, mode: ImportMode.replace);

      final restored = (await db.allReminders()).single;
      final steps = await db.stepsFor(restored.id);
      expect(steps.any((s) => s.completed), isFalse);
    });

    test('adding keeps what is already there', () async {
      await addRoutine(title: 'Mine');
      final json = await service.export();

      await service.import(json, mode: ImportMode.add);

      final all = await db.allReminders();
      expect(all, hasLength(2));
      expect(all.every((r) => r.title == 'Mine'), isTrue);
      // The copy is a separate reminder with its own steps, not a shared one.
      expect(all.first.id, isNot(all.last.id));
      expect(await db.stepsFor(all.first.id), hasLength(2));
      expect(await db.stepsFor(all.last.id), hasLength(2));
    });

    test('replacing leaves only what was in the file', () async {
      await addRoutine(title: 'From the file');
      final json = await service.export();

      await db.deleteAllReminders();
      await addRoutine(title: 'Made later');
      await addRoutine(title: 'Also made later');

      await service.import(json, mode: ImportMode.replace);

      final all = await db.allReminders();
      expect(all, hasLength(1));
      expect(all.single.title, 'From the file');
    });

    test('replacing leaves no orphaned steps behind', () async {
      await addRoutine(title: 'Doomed');
      final json = await service.export();
      await service.import(json, mode: ImportMode.replace);

      final all = await db.allReminders();
      final live = await db.stepsFor(all.single.id);
      final everything = await db.select(db.reminderSteps).get();
      expect(everything, hasLength(live.length));
    });

    test('a picture is exported and written back on import', () async {
      final source = File('${dir.path}/picture.jpg');
      await source.writeAsBytes(List.filled(128, 3));
      await addRoutine(imagePath: source.path);

      final json = await service.export();
      expect(Backup.decode(json).single.imageBase64, isNotNull);

      await service.import(json, mode: ImportMode.replace);

      final restored = (await db.allReminders()).single;
      expect(restored.imagePath, isNotNull);
      final written = File(restored.imagePath!);
      expect(written.existsSync(), isTrue);
      expect(await written.readAsBytes(), List.filled(128, 3));
    });

    test('a reminder with no picture stays that way', () async {
      await addRoutine();
      final json = await service.export();
      await service.import(json, mode: ImportMode.replace);

      expect((await db.allReminders()).single.imagePath, isNull);
    });

    test('a bad file changes nothing', () async {
      await addRoutine(title: 'Untouched');

      await expectLater(
        service.import('not a backup', mode: ImportMode.replace),
        throwsA(isA<BackupFormatException>()),
      );

      final all = await db.allReminders();
      expect(all, hasLength(1));
      expect(all.single.title, 'Untouched');
    });
  });
}
