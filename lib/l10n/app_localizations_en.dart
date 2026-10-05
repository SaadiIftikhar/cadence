// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Cadence';

  @override
  String get appTagline => 'Reminders with steps, icons and timers';

  @override
  String get navHome => 'Home';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navSettings => 'Settings';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionSave => 'Save';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionReplace => 'Replace';

  @override
  String get actionReset => 'Reset';

  @override
  String get actionDone => 'Done';

  @override
  String get actionStart => 'Start';

  @override
  String get actionPause => 'Pause';

  @override
  String get actionDismiss => 'Dismiss';

  @override
  String get actionGotIt => 'Got it';

  @override
  String get actionGrant => 'Grant';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionNotNow => 'Not now';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionContinue => 'Continue';

  @override
  String get addReminderButton => 'Add';

  @override
  String get addRoutine => 'Add a routine';

  @override
  String get addStepMenuItem => 'Add a step';

  @override
  String get loadErrorTitle => 'Could not load your reminders';

  @override
  String get loadErrorMessage => 'Restarting the app usually clears this.';

  @override
  String get emptyHomeTitle => 'No reminders yet';

  @override
  String get emptyHomeMessage => 'Tap + to create one.';

  @override
  String get untitledReminder => 'Untitled reminder';

  @override
  String get untitledStep => 'Untitled step';

  @override
  String get deleteReminderTitle => 'Delete reminder?';

  @override
  String get deleteReminderMessage =>
      'This reminder and its steps will be removed.';

  @override
  String deleteReminderNamedMessage(String title) {
    return '\"$title\" and its steps will be removed.';
  }

  @override
  String get turnOff => 'Turn off';

  @override
  String get turnOn => 'Turn on';

  @override
  String get calendarNothingTitle => 'Nothing scheduled';

  @override
  String get calendarNothingMessage => 'No reminders repeat on this day.';

  @override
  String get newRoutine => 'New routine';

  @override
  String get editRoutine => 'Edit routine';

  @override
  String get newStep => 'New step';

  @override
  String get editStep => 'Edit step';

  @override
  String get routineName => 'Routine name';

  @override
  String get stepTitle => 'Step title';

  @override
  String get fieldTime => 'Time';

  @override
  String get setTime => 'Set time';

  @override
  String get fieldRepeat => 'Repeat';

  @override
  String get switchNotifications => 'Notifications';

  @override
  String get switchAlarm => 'Alarm';

  @override
  String get switchAddImage => 'Add image';

  @override
  String get cropImage => 'Crop image';

  @override
  String get noStepsYet => 'No steps yet.';

  @override
  String get reorderHint => 'Press and hold a step to reorder';

  @override
  String get addStep => 'Add step';

  @override
  String get saveStep => 'Save step';

  @override
  String get deleteStep => 'Delete step';

  @override
  String get changeStepIcon => 'Change step icon';

  @override
  String get chooseIcon => 'Choose icon';

  @override
  String get iconHint => 'Tap the icon to change it';

  @override
  String get timeHint =>
      'Where a card sits on the home screen depends on its time';

  @override
  String get notificationsBlockedToast =>
      'Notifications are blocked — enable them in system settings.';

  @override
  String get exactAlarmsOffToast =>
      'Exact alarms are off; reminders may fire late.';

  @override
  String get stillBlockedToast =>
      'Still blocked — you can change it in system settings.';

  @override
  String get stepTimer => 'Step timer';

  @override
  String get timerNone => 'None';

  @override
  String get noTimer => 'No timer';

  @override
  String get hours => 'Hours';

  @override
  String get minutes => 'Minutes';

  @override
  String get seconds => 'Seconds';

  @override
  String get backToFullTime => 'Back to full time';

  @override
  String get timerFinished => 'Timer finished';

  @override
  String get repeatOn => 'Repeat on';

  @override
  String get repeatTodayOnly => 'Today only';

  @override
  String get repeatEveryDay => 'Every day';

  @override
  String get repeatWeekdays => 'Weekdays';

  @override
  String get repeatWeekend => 'Weekend';

  @override
  String get dayMon => 'Mon';

  @override
  String get dayTue => 'Tue';

  @override
  String get dayWed => 'Wed';

  @override
  String get dayThu => 'Thu';

  @override
  String get dayFri => 'Fri';

  @override
  String get daySat => 'Sat';

  @override
  String get daySun => 'Sun';

  @override
  String get markRoutineDoneTitle => 'Mark the whole routine as done?';

  @override
  String get markRoutineDoneMessage =>
      'Every step will be ticked off, including any you have not run. To leave without changing anything, go back instead.';

  @override
  String get markDone => 'Mark done';

  @override
  String get resetRoutineTitle => 'Reset this routine?';

  @override
  String get resetRoutineMessage =>
      'Every step will go back to not done, including ones you already finished. This cannot be undone.';

  @override
  String get stepsLoadErrorTitle => 'Could not load these steps';

  @override
  String get nothingToRunTitle => 'Nothing to run';

  @override
  String get nothingToRunMessage => 'This reminder has no steps yet.';

  @override
  String get stepFallback => 'Step';

  @override
  String get reminderFallback => 'Reminder';

  @override
  String progressDone(int done, int total) {
    return '$done of $total done';
  }

  @override
  String stepNumber(int number) {
    return 'Step $number';
  }

  @override
  String get iconSearchEmpty => 'No icons match that search.';

  @override
  String get onboardOneStepTitle => 'One step, or a whole routine';

  @override
  String get onboardOneStepBody =>
      'Save a single thing to do, or build a routine of steps and work through them one at a time. Give any of them their own icon and a countdown.';

  @override
  String get onboardPrivacyTitle => 'Everything stays on your phone';

  @override
  String get onboardPrivacyBody =>
      'No account, no sync, no servers. This app has no internet access at all, so what you write here has nowhere else to go.';

  @override
  String get onboardRemindTitle => 'So it can actually remind you';

  @override
  String get onboardRemindBody =>
      'Reminders arrive as notifications at the time you pick, or as a full-screen alarm when something really matters.';

  @override
  String get allowNotifications => 'Allow notifications';

  @override
  String onboardPageOf(int page, int count) {
    return 'Page $page of $count';
  }

  @override
  String get sectionPermissions => 'Permissions';

  @override
  String get permissionsRow => 'Notifications and alarms';

  @override
  String get permissionsChecking => 'Checking…';

  @override
  String get permissionsAllowed => 'Notifications and exact alarms allowed';

  @override
  String get permissionsBlocked => 'Notifications are blocked';

  @override
  String get permissionsExactBlocked =>
      'Exact alarms blocked — reminders may fire late';

  @override
  String get sectionBackup => 'Backup';

  @override
  String get sectionAbout => 'About';

  @override
  String get exportTitle => 'Export';

  @override
  String get exportSubtitle => 'Save your reminders to a file';

  @override
  String get importTitle => 'Import';

  @override
  String get importSubtitle => 'Bring reminders in from a backup file';

  @override
  String get saveBackupDialog => 'Save backup';

  @override
  String get chooseBackupDialog => 'Choose a backup';

  @override
  String get backupSaved => 'Backup saved.';

  @override
  String get backupSaveFailed => 'Could not save the backup.';

  @override
  String get backupReadFailed => 'Could not read that file.';

  @override
  String get importDialogTitle => 'Import backup';

  @override
  String importedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count reminders',
      one: 'Imported 1 reminder',
    );
    return '$_temp0';
  }

  @override
  String importDialogMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'You already have $count reminders. Keep them and add the backup alongside, or replace everything with what is in the file?',
      one: 'You already have 1 reminder. Keep it and add the backup alongside, or replace everything with what is in the file?',
    );
    return '$_temp0';
  }

  @override
  String get backupNotABackup => 'That file is not a backup.';

  @override
  String get backupWrongApp => 'That backup was made by a different app.';

  @override
  String get backupNewerVersion =>
      'That backup was made by a newer version of this app.';

  @override
  String get backupNoReminders => 'That backup has no reminders in it.';

  @override
  String get backupDamaged => 'That backup is damaged.';

  @override
  String get backupStepless => 'A reminder in that backup has no steps.';

  @override
  String get backupZipUnreadable => 'That zip could not be opened.';

  @override
  String get backupZipNotABackup => 'That zip is not a backup.';
}
