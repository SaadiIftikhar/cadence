import 'package:shared_preferences/shared_preferences.dart';

/// The handful of one-off flags the app remembers about the person using it,
/// as opposed to the reminders themselves, which live in the database.
class AppPrefs {
  const AppPrefs._();

  static const _seenOnboarding = 'seen_onboarding';
  static const _seenIconHint = 'seen_icon_hint';

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
}
