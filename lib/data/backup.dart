import 'dart:convert';

/// Raised when a file is not a backup this app can read.
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

class StepBackup {
  const StepBackup({required this.title, this.iconKey, this.timerSeconds});

  final String title;
  final String? iconKey;
  final int? timerSeconds;
}

class ReminderBackup {
  const ReminderBackup({
    required this.title,
    required this.iconKey,
    required this.hour,
    required this.minute,
    required this.daysMask,
    required this.notificationsEnabled,
    required this.alarmEnabled,
    required this.multiStep,
    required this.enabled,
    required this.steps,
    this.imageBase64,
  });

  final String title;
  final String iconKey;
  final int hour;
  final int minute;
  final int daysMask;
  final bool notificationsEnabled;
  final bool alarmEnabled;
  final bool multiStep;
  final bool enabled;

  /// The picture itself travels inside the file, so a backup is one
  /// self-contained thing to move between phones.
  final String? imageBase64;

  final List<StepBackup> steps;
}

/// Reads and writes the backup file.
///
/// What a reminder *is* gets written; how far through it you are does not.
/// Completion describes today, so carrying it to another phone, or back to
/// this one weeks later, would be restoring a moment rather than a reminder.
class Backup {
  const Backup._();

  static const formatVersion = 1;
  static const _appTag = 'step_reminder';

  static String encode(List<ReminderBackup> reminders) {
    final doc = {
      'app': _appTag,
      'format': formatVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'reminders': [
        for (final r in reminders)
          {
            'title': r.title,
            'iconKey': r.iconKey,
            'hour': r.hour,
            'minute': r.minute,
            'daysMask': r.daysMask,
            'notifications': r.notificationsEnabled,
            'alarm': r.alarmEnabled,
            'multiStep': r.multiStep,
            'enabled': r.enabled,
            if (r.imageBase64 != null) 'image': r.imageBase64,
            'steps': [
              for (final s in r.steps)
                {
                  'title': s.title,
                  if (s.iconKey != null) 'iconKey': s.iconKey,
                  if (s.timerSeconds != null) 'timerSeconds': s.timerSeconds,
                },
            ],
          },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(doc);
  }

  static List<ReminderBackup> decode(String source) {
    final Object? parsed;
    try {
      parsed = jsonDecode(source);
    } on FormatException {
      throw const BackupFormatException('That file is not a backup.');
    }

    if (parsed is! Map<String, dynamic>) {
      throw const BackupFormatException('That file is not a backup.');
    }
    if (parsed['app'] != _appTag) {
      throw const BackupFormatException(
        'That backup was made by a different app.',
      );
    }

    final format = parsed['format'];
    if (format is! int) {
      throw const BackupFormatException('That file is not a backup.');
    }
    if (format > formatVersion) {
      throw const BackupFormatException(
        'That backup was made by a newer version of this app.',
      );
    }

    final raw = parsed['reminders'];
    if (raw is! List) {
      throw const BackupFormatException('That backup has no reminders in it.');
    }

    return [for (final entry in raw) _reminder(entry)];
  }

  static ReminderBackup _reminder(Object? entry) {
    if (entry is! Map<String, dynamic>) {
      throw const BackupFormatException('That backup is damaged.');
    }

    final steps = entry['steps'];
    if (steps is! List) {
      throw const BackupFormatException('A reminder in that backup has no steps.');
    }

    return ReminderBackup(
      title: _string(entry['title'], ''),
      iconKey: _string(entry['iconKey'], 'alarm'),
      hour: _int(entry['hour'], 8, max: 23),
      minute: _int(entry['minute'], 0, max: 59),
      daysMask: _int(entry['daysMask'], 0, max: 0x7F),
      notificationsEnabled: _bool(entry['notifications'], false),
      alarmEnabled: _bool(entry['alarm'], false),
      multiStep: _bool(entry['multiStep'], false),
      enabled: _bool(entry['enabled'], true),
      imageBase64: entry['image'] is String ? entry['image'] as String : null,
      steps: [for (final s in steps) _step(s)],
    );
  }

  static StepBackup _step(Object? entry) {
    if (entry is! Map<String, dynamic>) {
      throw const BackupFormatException('That backup is damaged.');
    }
    final timer = entry['timerSeconds'];
    return StepBackup(
      title: _string(entry['title'], ''),
      iconKey: entry['iconKey'] is String ? entry['iconKey'] as String : null,
      timerSeconds: timer is int && timer > 0 ? timer : null,
    );
  }

  // A backup that is merely odd should still import; only one that cannot be
  // understood at all is rejected.
  static String _string(Object? value, String fallback) =>
      value is String ? value : fallback;

  static bool _bool(Object? value, bool fallback) =>
      value is bool ? value : fallback;

  static int _int(Object? value, int fallback, {required int max}) {
    if (value is! int || value < 0 || value > max) return fallback;
    return value;
  }
}
