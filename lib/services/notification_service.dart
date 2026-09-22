import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/database.dart';

/// Alarm payloads are tagged, so a tap can be told apart from an ordinary
/// reminder's without going back to the database to ask.
const _alarmPrefix = 'alarm:';

/// What a notification carries: which reminder it is for, and whether it
/// arrived as an alarm that has to be dismissed rather than merely opened.
class NotificationTarget {
  const NotificationTarget(this.reminderId, {required this.isAlarm});

  final int reminderId;
  final bool isAlarm;
}

String payloadFor(Reminder reminder) =>
    reminder.alarmEnabled ? '$_alarmPrefix${reminder.id}' : '${reminder.id}';

/// The other half of [payloadFor]. Null for anything unreadable, including
/// the untagged payloads written by older versions, which is why a bare
/// number still parses as an ordinary reminder.
NotificationTarget? parseNotificationPayload(String? payload) {
  if (payload == null) return null;
  final isAlarm = payload.startsWith(_alarmPrefix);
  final id = int.tryParse(
    isAlarm ? payload.substring(_alarmPrefix.length) : payload,
  );
  return id == null ? null : NotificationTarget(id, isAlarm: isAlarm);
}

/// Schedules the two flavours of reminder the designs call for.
///
/// A notification chimes once and waits. An alarm rings the phone's own alarm
/// tone at alarm volume and keeps ringing until it is dealt with, and asks to
/// take over the screen if the phone is locked.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _reminderChannel = 'reminders';

  /// Bumped when the channel's fixed settings had to change; see [init].
  static const _alarmChannel = 'alarms_v2';
  static const _retiredAlarmChannel = 'alarms';

  /// The phone's own alarm tone, so an alarm sounds like the alarms the user
  /// already knows rather than like a message arriving.
  static const _systemAlarmSound = 'content://settings/system/alarm_alert';

  /// `Notification.FLAG_INSISTENT`: repeat the sound until the notification is
  /// dealt with. Without it an alarm rings once and gives up, which is the one
  /// thing an alarm must not do.
  static final _insistent = Int32List.fromList(<int>[4]);

  /// Notification ids are derived from the reminder id so they can be cancelled
  /// without keeping a side table. Seven weekday slots plus one one-shot slot.
  static const _slotsPerReminder = 8;

  /// Set when a notification launched the app, so the UI can jump straight to
  /// the reminder that fired.
  final ValueNotifier<int?> launchReminderId = ValueNotifier(null);

  /// Set instead of [launchReminderId] when the notification was an alarm, so
  /// the app opens the alarm screen and the ringing has to be dealt with
  /// rather than stopping the moment the phone is unlocked.
  final ValueNotifier<int?> ringingAlarmId = ValueNotifier(null);

  static const _lockScreen = MethodChannel('step_reminder/alarm');

  bool _ready = false;

  /// Null anywhere there is no Android plugin registered to answer — another
  /// platform, or a test. Every caller already has to cope with that, so the
  /// lookup failing outright is not worth telling them apart from it.
  AndroidFlutterLocalNotificationsPlugin? get _android {
    try {
      return _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
    } catch (_) {
      return null;
    }
  }

  void _routePayload(String? rawPayload) {
    final target = parseNotificationPayload(rawPayload);
    if (target == null) return;
    if (target.isAlarm) {
      ringingAlarmId.value = target.reminderId;
    } else {
      launchReminderId.value = target.reminderId;
    }
  }

  /// Lets the alarm screen show over the keyguard and wake the screen, for as
  /// long as it is up. Silently does nothing where the channel is not
  /// implemented, which includes tests.
  Future<void> takeOverLockScreen() async {
    try {
      await _lockScreen.invokeMethod<void>('show');
    } catch (_) {}
  }

  Future<void> releaseLockScreen() async {
    try {
      await _lockScreen.invokeMethod<void>('release');
    } catch (_) {}
  }

  /// Stops a ringing alarm. Cancelling the notification is what silences it,
  /// since the sound repeats for as long as it is posted — so a repeating
  /// alarm is armed again straight afterwards, while a one-off is not: its
  /// day is done.
  Future<void> dismissAlarm(Reminder reminder) async {
    await cancelReminder(reminder.id);
    if (reminder.daysMask != 0) await scheduleReminder(reminder);
  }

  Future<void> init() async {
    if (_ready) return;

    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Falls back to UTC; scheduling still works, just without DST handling.
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) =>
          _routePayload(response.payload),
    );

    final android = _android;

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _reminderChannel,
        'Reminders',
        description: 'Scheduled reminder notifications',
        importance: Importance.high,
      ),
    );
    // The first alarm channel was created without a sound of its own, so it
    // played the short default notification chime and an alarm was
    // indistinguishable from a reminder. A channel's settings are fixed once
    // Android has seen it, so correcting that needs a new id; the old one is
    // dropped so it stops cluttering the app's notification settings.
    await android?.deleteNotificationChannel(channelId: _retiredAlarmChannel);
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _alarmChannel,
        'Alarms',
        description: 'Full-screen alarms that ring until dismissed',
        importance: Importance.max,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        sound: UriAndroidNotificationSound(_systemAlarmSound),
        enableVibration: true,
        enableLights: true,
      ),
    );

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      _routePayload(launch?.notificationResponse?.payload);
    }

    _ready = true;
  }

  Future<PermissionStatus> requestPermissions() async {
    final android = _android;
    if (android == null) return const PermissionStatus(true, true);

    final notifications = await android.requestNotificationsPermission() ?? false;
    var exact = await android.canScheduleExactNotifications() ?? false;
    if (!exact) {
      exact = await android.requestExactAlarmsPermission() ?? false;
    }
    await android.requestFullScreenIntentPermission();

    return PermissionStatus(notifications, exact);
  }

  /// What is granted right now, without prompting for anything.
  Future<PermissionStatus> currentStatus() async {
    final android = _android;
    if (android == null) return const PermissionStatus(true, true);

    return PermissionStatus(
      await android.areNotificationsEnabled() ?? true,
      await android.canScheduleExactNotifications() ?? true,
    );
  }

  /// Asks for the notification permission on first launch, the way most apps
  /// do. Deliberately leaves exact alarms alone: that request opens a system
  /// settings page, which would be hostile to throw at someone unprompted.
  Future<void> requestNotificationsIfUndecided() async {
    final android = _android;
    if (android == null) return;

    if (await android.areNotificationsEnabled() ?? false) return;
    await android.requestNotificationsPermission();
  }

  Future<bool> canScheduleExact() async {
    final android = _android;
    return await android?.canScheduleExactNotifications() ?? true;
  }

  NotificationDetails _details(Reminder reminder) {
    final isAlarm = reminder.alarmEnabled;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        isAlarm ? _alarmChannel : _reminderChannel,
        isAlarm ? 'Alarms' : 'Reminders',
        importance: isAlarm ? Importance.max : Importance.high,
        priority: isAlarm ? Priority.max : Priority.high,
        category: isAlarm
            ? AndroidNotificationCategory.alarm
            : AndroidNotificationCategory.reminder,
        fullScreenIntent: isAlarm,
        audioAttributesUsage: isAlarm
            ? AudioAttributesUsage.alarm
            : AudioAttributesUsage.notification,
        sound: isAlarm
            ? const UriAndroidNotificationSound(_systemAlarmSound)
            : null,
        additionalFlags: isAlarm ? _insistent : null,
        playSound: true,
        enableVibration: true,
        // A reminder is done with once tapped. An alarm is not: tapping it
        // opens the alarm screen while it carries on ringing, and only
        // Dismiss there stops it — otherwise unlocking the phone to look at
        // the notification would be enough to silence an alarm. It stays
        // swipeable either way, so there is always a way out of the noise.
        autoCancel: !isAlarm,
        visibility: NotificationVisibility.public,
      ),
    );
  }

  Future<void> cancelReminder(int reminderId) async {
    final base = reminderId * _slotsPerReminder;
    for (var slot = 0; slot < _slotsPerReminder; slot++) {
      await _plugin.cancel(id: base + slot);
    }
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    await cancelReminder(reminder.id);

    if (!reminder.enabled) return;
    if (!reminder.notificationsEnabled && !reminder.alarmEnabled) return;

    final title = reminder.title.trim().isEmpty ? 'Reminder' : reminder.title.trim();
    final body = reminder.alarmEnabled ? 'Alarm • tap to start' : 'Tap to start';
    final details = _details(reminder);
    final mode = await canScheduleExact()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    final base = reminder.id * _slotsPerReminder;
    final payload = payloadFor(reminder);

    if (reminder.daysMask == 0) {
      await _plugin.zonedSchedule(
        id: base + 7,
        title: title,
        body: body,
        scheduledDate: _nextOneShot(reminder.hour, reminder.minute),
        notificationDetails: details,
        androidScheduleMode: mode,
        payload: payload,
      );
      return;
    }

    for (var bit = 0; bit < 7; bit++) {
      if (reminder.daysMask & (1 << bit) == 0) continue;
      await _plugin.zonedSchedule(
        id: base + bit,
        title: title,
        body: body,
        scheduledDate: _nextWeekday(bit + 1, reminder.hour, reminder.minute),
        notificationDetails: details,
        androidScheduleMode: mode,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: payload,
      );
    }
  }

  Future<void> rescheduleAll(List<Reminder> reminders) async {
    for (final reminder in reminders) {
      await scheduleReminder(reminder);
    }
  }

  tz.TZDateTime _nextOneShot(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    return next;
  }

  /// [weekday] follows [DateTime.weekday]: Monday is 1, Sunday is 7.
  tz.TZDateTime _nextWeekday(int weekday, int hour, int minute) {
    var next = _nextOneShot(hour, minute);
    while (next.weekday != weekday) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }
}

class PermissionStatus {
  const PermissionStatus(this.notifications, this.exactAlarms);
  final bool notifications;
  final bool exactAlarms;

  bool get allGranted => notifications && exactAlarms;
}
