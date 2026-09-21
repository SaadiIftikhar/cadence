import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import 'backup.dart';
import 'database.dart';

/// How an import should treat what is already on the phone.
enum ImportMode {
  /// Keep everything and add the file's reminders alongside it.
  add,

  /// Clear the phone first, so it ends up matching the file exactly.
  replace,
}

/// Moves reminders in and out of a backup file.
class BackupService {
  BackupService(this._db, {required this.imageDirectory});

  final AppDatabase _db;

  /// Where imported pictures are written. Injected so a test can use a
  /// temporary folder instead of app storage.
  final Directory imageDirectory;

  Future<String> export() async {
    final reminders = await _db.allReminders();
    final items = <ReminderBackup>[];

    for (final r in reminders) {
      final steps = await _db.stepsFor(r.id);

      String? image;
      final path = r.imagePath;
      if (path != null) {
        final file = File(path);
        if (file.existsSync()) image = base64Encode(await file.readAsBytes());
      }

      items.add(
        ReminderBackup(
          title: r.title,
          iconKey: r.iconKey,
          hour: r.hour,
          minute: r.minute,
          daysMask: r.daysMask,
          notificationsEnabled: r.notificationsEnabled,
          alarmEnabled: r.alarmEnabled,
          multiStep: r.multiStep,
          enabled: r.enabled,
          imageBase64: image,
          steps: [
            // Completion is left behind here: a backup describes the
            // reminder, not how far through today's run you happen to be.
            for (final s in steps)
              StepBackup(
                title: s.title,
                iconKey: s.iconKey,
                timerSeconds: s.timerSeconds,
              ),
          ],
        ),
      );
    }

    return Backup.encode(items);
  }

  /// Returns how many reminders were brought in.
  /// Throws [BackupFormatException] if the file cannot be read.
  Future<int> import(String source, {required ImportMode mode}) async {
    final items = Backup.decode(source);

    if (mode == ImportMode.replace) {
      await _db.deleteAllReminders();
    }

    for (final item in items) {
      String? imagePath;
      final encoded = item.imageBase64;
      if (encoded != null) {
        try {
          final bytes = base64Decode(encoded);
          final file = File(
            p.join(
              imageDirectory.path,
              'imported_${DateTime.now().microsecondsSinceEpoch}_'
                  '${items.indexOf(item)}.jpg',
            ),
          );
          await file.writeAsBytes(bytes);
          imagePath = file.path;
        } on FormatException {
          // A damaged picture should not cost the user the reminder.
          imagePath = null;
        }
      }

      final id = await _db.upsertReminder(
        RemindersCompanion.insert(
          title: Value(item.title),
          iconKey: Value(item.iconKey),
          hour: Value(item.hour),
          minute: Value(item.minute),
          daysMask: Value(item.daysMask),
          notificationsEnabled: Value(item.notificationsEnabled),
          alarmEnabled: Value(item.alarmEnabled),
          multiStep: Value(item.multiStep),
          enabled: Value(item.enabled),
          imagePath: Value(imagePath),
        ),
      );

      await _db.replaceSteps(id, [
        for (final s in item.steps)
          ReminderStepsCompanion.insert(
            reminderId: id,
            title: Value(s.title),
            iconKey: Value(s.iconKey),
            timerSeconds: Value(s.timerSeconds),
            // Imported reminders start unticked, whatever the source phone
            // had been doing.
            completed: const Value(false),
          ),
      ]);
    }

    return items.length;
  }
}
