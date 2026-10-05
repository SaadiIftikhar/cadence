import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
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
///
/// A backup is a zip holding one manifest and the pictures it refers to.
/// Pictures stay real files rather than text inside the manifest, which keeps
/// the archive close to the size of the images themselves.
class BackupService {
  BackupService(this._db, {required this.imageDirectory});

  final AppDatabase _db;

  /// Where imported pictures are written. Injected so a test can use a
  /// temporary folder instead of app storage.
  final Directory imageDirectory;

  static const manifestName = 'backup.json';
  static const imageFolder = 'images';

  Future<Uint8List> export() async {
    final reminders = await _db.allReminders();
    final items = <ReminderBackup>[];
    final archive = Archive();

    for (var i = 0; i < reminders.length; i++) {
      final r = reminders[i];
      final steps = await _db.stepsFor(r.id);

      String? imageName;
      final path = r.imagePath;
      if (path != null) {
        final file = File(path);
        if (file.existsSync()) {
          final bytes = await file.readAsBytes();
          final extension = p.extension(path);
          imageName = 'reminder_$i${extension.isEmpty ? '.jpg' : extension}';
          archive.addFile(
            ArchiveFile('$imageFolder/$imageName', bytes.length, bytes),
          );
        }
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
          imageName: imageName,
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

    final manifest = utf8.encode(Backup.encode(items));
    archive.addFile(ArchiveFile(manifestName, manifest.length, manifest));

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  /// Returns how many reminders were brought in. Accepts a backup zip, or a
  /// bare manifest for anyone who unzipped one.
  ///
  /// Throws [BackupFormatException] if the file cannot be read, having
  /// changed nothing.
  Future<int> import(Uint8List bytes, {required ImportMode mode}) async {
    final (source, images) = _unpack(bytes);

    // Parsed before anything is deleted, so a bad file cannot cost the user
    // what they already had.
    final items = Backup.decode(source);

    if (mode == ImportMode.replace) {
      await _db.deleteAllReminders();
    }

    final stamp = DateTime.now().microsecondsSinceEpoch;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];

      String? imagePath;
      final name = item.imageName;
      final data = name == null ? null : images[name];
      if (data != null) {
        final file = File(
          p.join(imageDirectory.path, 'imported_${stamp}_${i}_$name'),
        );
        await file.writeAsBytes(data);
        imagePath = file.path;
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

  (String manifest, Map<String, Uint8List> images) _unpack(Uint8List bytes) {
    if (!_looksLikeZip(bytes)) {
      try {
        return (utf8.decode(bytes), const {});
      } on FormatException {
        throw const BackupFormatException(
          BackupProblem.notABackup, 'That file is not a backup.');
      }
    }

    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const BackupFormatException(
          BackupProblem.zipUnreadable, 'That zip could not be opened.');
    }

    String? manifest;
    final images = <String, Uint8List>{};
    for (final entry in archive) {
      if (!entry.isFile) continue;

      if (entry.name == manifestName) {
        manifest = utf8.decode(entry.content, allowMalformed: true);
      } else if (entry.name.startsWith('$imageFolder/')) {
        images[entry.name.substring(imageFolder.length + 1)] = entry.content;
      }
    }

    if (manifest == null) {
      throw const BackupFormatException(
          BackupProblem.zipNotABackup, 'That zip is not a backup.');
    }
    return (manifest, images);
  }

  static bool _looksLikeZip(Uint8List bytes) =>
      bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B;
}
