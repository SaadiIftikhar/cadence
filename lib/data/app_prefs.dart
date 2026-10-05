import 'package:shared_preferences/shared_preferences.dart';

/// The handful of one-off flags the app remembers about the person using it,
/// as opposed to the reminders themselves, which live in the database.
class AppPrefs {
  const AppPrefs._();

  static const _seenOnboarding = 'seen_onboarding';
  static const _seenIconHint = 'seen_icon_hint';
  static const _seenTimeHint = 'seen_time_hint';
  static const _runningTimer = 'running_timer';

  static Future<bool> seenOnboarding() async =>
      (await SharedPreferences.getInstance()).getBool(_seenOnboarding) ?? false;

  static Future<void> markOnboardingSeen() async =>
      (await SharedPreferences.getInstance()).setBool(_seenOnboarding, true);

  /// Whether the hint explaining that an icon is also a button has been shown.
  ///
  /// One flag for the whole app rather than one per screen: having learned
  /// that a title's icon can be tapped, the same person does not need telling
  /// again on the next screen that does it.
  static Future<bool> seenIconHint() async =>
      (await SharedPreferences.getInstance()).getBool(_seenIconHint) ?? false;

  static Future<void> markIconHintSeen() async =>
      (await SharedPreferences.getInstance()).setBool(_seenIconHint, true);

  /// Whether the hint explaining that time decides the home order has run.
  static Future<bool> seenTimeHint() async =>
      (await SharedPreferences.getInstance()).getBool(_seenTimeHint) ?? false;

  static Future<void> markTimeHintSeen() async =>
      (await SharedPreferences.getInstance()).setBool(_seenTimeHint, true);

  /// The step countdown currently running, and the moment it ends.
  ///
  /// Held here rather than in memory because the screen's ticker dies with the
  /// process: this is what lets a timer started before the phone was locked
  /// still show the right number when the app comes back. One at a time —
  /// starting a timer on another step replaces this one.
  static Future<({int stepId, DateTime endsAt})?> runningTimer() async {
    final raw = (await SharedPreferences.getInstance()).getString(_runningTimer);
    if (raw == null) return null;

    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final stepId = int.tryParse(parts[0]);
    final millis = int.tryParse(parts[1]);
    if (stepId == null || millis == null) return null;

    return (
      stepId: stepId,
      endsAt: DateTime.fromMillisecondsSinceEpoch(millis),
    );
  }

  static Future<void> setRunningTimer(int stepId, DateTime endsAt) async =>
      (await SharedPreferences.getInstance()).setString(
        _runningTimer,
        '$stepId:${endsAt.millisecondsSinceEpoch}',
      );

  static Future<void> clearRunningTimer() async =>
      (await SharedPreferences.getInstance()).remove(_runningTimer);
}
