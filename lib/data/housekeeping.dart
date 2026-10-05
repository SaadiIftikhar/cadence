import 'dart:io';

import 'package:path/path.dart' as p;

import 'database.dart';

/// Files this app writes for reminder pictures, and nothing else.
///
/// The match is deliberately strict. The database lives alongside these, so a
/// sweep that deleted anything it merely failed to recognise would be one bug
/// away from deleting somebody's reminders.
final _imageName = RegExp(r'^reminder_\d+\.jpg$');

/// Deletes pictures no reminder refers to any more.
///
/// Nothing removed one before: deleting a reminder, replacing its picture, or
/// turning Add image off all left the file behind. Sweeping by what the
/// database actually points at clears those, including ones orphaned by
/// earlier versions, and does not need every future caller to remember.
///
/// Returns how many were removed.
Future<int> deleteOrphanedImages(AppDatabase db, Directory imageDirectory) async {
  if (!imageDirectory.existsSync()) return 0;

  // Compared by file name, not by whole path: the stored path and the one a
  // directory listing reports can describe the same file and still differ as
  // strings. Names are unique — each picture is stamped with the millisecond
  // it was taken — so the name is enough to tell them apart.
  final kept = {
    for (final reminder in await db.allReminders())
      if (reminder.imagePath != null) p.basename(reminder.imagePath!),
  };

  var removed = 0;
  for (final entity in imageDirectory.listSync()) {
    if (entity is! File) continue;
    final name = p.basename(entity.path);
    if (!_imageName.hasMatch(name)) continue;
    if (kept.contains(name)) continue;

    try {
      entity.deleteSync();
      removed++;
    } catch (_) {
      // A file held open elsewhere is not worth failing startup over; the
      // next sweep will get it.
    }
  }
  return removed;
}
