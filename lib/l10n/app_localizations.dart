import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Cadence'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Reminders with steps, icons and timers'**
  String get appTagline;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get actionReplace;

  /// No description provided for @actionReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get actionReset;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get actionStart;

  /// No description provided for @actionPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get actionPause;

  /// No description provided for @actionDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get actionDismiss;

  /// No description provided for @actionGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get actionGotIt;

  /// No description provided for @actionGrant.
  ///
  /// In en, this message translates to:
  /// **'Grant'**
  String get actionGrant;

  /// No description provided for @actionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkip;

  /// No description provided for @actionNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get actionNotNow;

  /// No description provided for @actionSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get actionSearch;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @addReminderButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addReminderButton;

  /// No description provided for @addRoutine.
  ///
  /// In en, this message translates to:
  /// **'Add a routine'**
  String get addRoutine;

  /// No description provided for @addStepMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Add a step'**
  String get addStepMenuItem;

  /// No description provided for @loadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load your reminders'**
  String get loadErrorTitle;

  /// No description provided for @loadErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Restarting the app usually clears this.'**
  String get loadErrorMessage;

  /// No description provided for @emptyHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet'**
  String get emptyHomeTitle;

  /// No description provided for @emptyHomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create one.'**
  String get emptyHomeMessage;

  /// No description provided for @untitledReminder.
  ///
  /// In en, this message translates to:
  /// **'Untitled reminder'**
  String get untitledReminder;

  /// No description provided for @untitledStep.
  ///
  /// In en, this message translates to:
  /// **'Untitled step'**
  String get untitledStep;

  /// No description provided for @deleteReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete reminder?'**
  String get deleteReminderTitle;

  /// No description provided for @deleteReminderMessage.
  ///
  /// In en, this message translates to:
  /// **'This reminder and its steps will be removed.'**
  String get deleteReminderMessage;

  /// No description provided for @deleteReminderNamedMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" and its steps will be removed.'**
  String deleteReminderNamedMessage(String title);

  /// No description provided for @turnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get turnOff;

  /// No description provided for @turnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get turnOn;

  /// No description provided for @calendarNothingTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled'**
  String get calendarNothingTitle;

  /// No description provided for @calendarNothingMessage.
  ///
  /// In en, this message translates to:
  /// **'No reminders repeat on this day.'**
  String get calendarNothingMessage;

  /// No description provided for @newRoutine.
  ///
  /// In en, this message translates to:
  /// **'New routine'**
  String get newRoutine;

  /// No description provided for @editRoutine.
  ///
  /// In en, this message translates to:
  /// **'Edit routine'**
  String get editRoutine;

  /// No description provided for @newStep.
  ///
  /// In en, this message translates to:
  /// **'New step'**
  String get newStep;

  /// No description provided for @editStep.
  ///
  /// In en, this message translates to:
  /// **'Edit step'**
  String get editStep;

  /// No description provided for @routineName.
  ///
  /// In en, this message translates to:
  /// **'Routine name'**
  String get routineName;

  /// No description provided for @stepTitle.
  ///
  /// In en, this message translates to:
  /// **'Step title'**
  String get stepTitle;

  /// No description provided for @fieldTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get fieldTime;

  /// No description provided for @setTime.
  ///
  /// In en, this message translates to:
  /// **'Set time'**
  String get setTime;

  /// No description provided for @fieldRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get fieldRepeat;

  /// No description provided for @switchNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get switchNotifications;

  /// No description provided for @switchAlarm.
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get switchAlarm;

  /// No description provided for @switchAddImage.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get switchAddImage;

  /// No description provided for @cropImage.
  ///
  /// In en, this message translates to:
  /// **'Crop image'**
  String get cropImage;

  /// No description provided for @noStepsYet.
  ///
  /// In en, this message translates to:
  /// **'No steps yet.'**
  String get noStepsYet;

  /// No description provided for @reorderHint.
  ///
  /// In en, this message translates to:
  /// **'Press and hold a step to reorder'**
  String get reorderHint;

  /// No description provided for @addStep.
  ///
  /// In en, this message translates to:
  /// **'Add step'**
  String get addStep;

  /// No description provided for @saveStep.
  ///
  /// In en, this message translates to:
  /// **'Save step'**
  String get saveStep;

  /// No description provided for @deleteStep.
  ///
  /// In en, this message translates to:
  /// **'Delete step'**
  String get deleteStep;

  /// No description provided for @changeStepIcon.
  ///
  /// In en, this message translates to:
  /// **'Change step icon'**
  String get changeStepIcon;

  /// No description provided for @chooseIcon.
  ///
  /// In en, this message translates to:
  /// **'Choose icon'**
  String get chooseIcon;

  /// No description provided for @iconHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the icon to change it'**
  String get iconHint;

  /// No description provided for @timeHint.
  ///
  /// In en, this message translates to:
  /// **'Where a card sits on the home screen depends on its time'**
  String get timeHint;

  /// No description provided for @notificationsBlockedToast.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked — enable them in system settings.'**
  String get notificationsBlockedToast;

  /// No description provided for @exactAlarmsOffToast.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms are off; reminders may fire late.'**
  String get exactAlarmsOffToast;

  /// No description provided for @stillBlockedToast.
  ///
  /// In en, this message translates to:
  /// **'Still blocked — you can change it in system settings.'**
  String get stillBlockedToast;

  /// No description provided for @stepTimer.
  ///
  /// In en, this message translates to:
  /// **'Step timer'**
  String get stepTimer;

  /// No description provided for @timerNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get timerNone;

  /// No description provided for @noTimer.
  ///
  /// In en, this message translates to:
  /// **'No timer'**
  String get noTimer;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutes;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'Seconds'**
  String get seconds;

  /// No description provided for @backToFullTime.
  ///
  /// In en, this message translates to:
  /// **'Back to full time'**
  String get backToFullTime;

  /// No description provided for @timerFinished.
  ///
  /// In en, this message translates to:
  /// **'Timer finished'**
  String get timerFinished;

  /// No description provided for @repeatOn.
  ///
  /// In en, this message translates to:
  /// **'Repeat on'**
  String get repeatOn;

  /// No description provided for @repeatTodayOnly.
  ///
  /// In en, this message translates to:
  /// **'Today only'**
  String get repeatTodayOnly;

  /// No description provided for @repeatEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get repeatEveryDay;

  /// No description provided for @repeatWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get repeatWeekdays;

  /// No description provided for @repeatWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend'**
  String get repeatWeekend;

  /// No description provided for @dayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get daySun;

  /// No description provided for @markRoutineDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark the whole routine as done?'**
  String get markRoutineDoneTitle;

  /// No description provided for @markRoutineDoneMessage.
  ///
  /// In en, this message translates to:
  /// **'Every step will be ticked off, including any you have not run. To leave without changing anything, go back instead.'**
  String get markRoutineDoneMessage;

  /// No description provided for @markDone.
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get markDone;

  /// No description provided for @resetRoutineTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset this routine?'**
  String get resetRoutineTitle;

  /// No description provided for @resetRoutineMessage.
  ///
  /// In en, this message translates to:
  /// **'Every step will go back to not done, including ones you already finished. This cannot be undone.'**
  String get resetRoutineMessage;

  /// No description provided for @stepsLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load these steps'**
  String get stepsLoadErrorTitle;

  /// No description provided for @nothingToRunTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to run'**
  String get nothingToRunTitle;

  /// No description provided for @nothingToRunMessage.
  ///
  /// In en, this message translates to:
  /// **'This reminder has no steps yet.'**
  String get nothingToRunMessage;

  /// No description provided for @stepFallback.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get stepFallback;

  /// No description provided for @reminderFallback.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminderFallback;

  /// No description provided for @progressDone.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String progressDone(int done, int total);

  /// No description provided for @stepNumber.
  ///
  /// In en, this message translates to:
  /// **'Step {number}'**
  String stepNumber(int number);

  /// No description provided for @iconSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No icons match that search.'**
  String get iconSearchEmpty;

  /// No description provided for @onboardOneStepTitle.
  ///
  /// In en, this message translates to:
  /// **'One step, or a whole routine'**
  String get onboardOneStepTitle;

  /// No description provided for @onboardOneStepBody.
  ///
  /// In en, this message translates to:
  /// **'Save a single thing to do, or build a routine of steps and work through them one at a time. Give any of them their own icon and a countdown.'**
  String get onboardOneStepBody;

  /// No description provided for @onboardPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Everything stays on your phone'**
  String get onboardPrivacyTitle;

  /// No description provided for @onboardPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'No account, no sync, no servers. This app has no internet access at all, so what you write here has nowhere else to go.'**
  String get onboardPrivacyBody;

  /// No description provided for @onboardRemindTitle.
  ///
  /// In en, this message translates to:
  /// **'So it can actually remind you'**
  String get onboardRemindTitle;

  /// No description provided for @onboardRemindBody.
  ///
  /// In en, this message translates to:
  /// **'Reminders arrive as notifications at the time you pick, or as a full-screen alarm when something really matters.'**
  String get onboardRemindBody;

  /// No description provided for @allowNotifications.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get allowNotifications;

  /// No description provided for @onboardPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {count}'**
  String onboardPageOf(int page, int count);

  /// No description provided for @sectionPermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get sectionPermissions;

  /// No description provided for @permissionsRow.
  ///
  /// In en, this message translates to:
  /// **'Notifications and alarms'**
  String get permissionsRow;

  /// No description provided for @permissionsChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get permissionsChecking;

  /// No description provided for @permissionsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Notifications and exact alarms allowed'**
  String get permissionsAllowed;

  /// No description provided for @permissionsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked'**
  String get permissionsBlocked;

  /// No description provided for @permissionsExactBlocked.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms blocked — reminders may fire late'**
  String get permissionsExactBlocked;

  /// No description provided for @sectionBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get sectionBackup;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportTitle;

  /// No description provided for @exportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save your reminders to a file'**
  String get exportSubtitle;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importTitle;

  /// No description provided for @importSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bring reminders in from a backup file'**
  String get importSubtitle;

  /// No description provided for @saveBackupDialog.
  ///
  /// In en, this message translates to:
  /// **'Save backup'**
  String get saveBackupDialog;

  /// No description provided for @chooseBackupDialog.
  ///
  /// In en, this message translates to:
  /// **'Choose a backup'**
  String get chooseBackupDialog;

  /// No description provided for @backupSaved.
  ///
  /// In en, this message translates to:
  /// **'Backup saved.'**
  String get backupSaved;

  /// No description provided for @backupSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the backup.'**
  String get backupSaveFailed;

  /// No description provided for @backupReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read that file.'**
  String get backupReadFailed;

  /// No description provided for @importDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get importDialogTitle;

  /// No description provided for @importedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Imported 1 reminder} other{Imported {count} reminders}}'**
  String importedCount(int count);

  /// No description provided for @importDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You already have 1 reminder. Keep it and add the backup alongside, or replace everything with what is in the file?} other{You already have {count} reminders. Keep them and add the backup alongside, or replace everything with what is in the file?}}'**
  String importDialogMessage(int count);

  /// No description provided for @backupNotABackup.
  ///
  /// In en, this message translates to:
  /// **'That file is not a backup.'**
  String get backupNotABackup;

  /// No description provided for @backupWrongApp.
  ///
  /// In en, this message translates to:
  /// **'That backup was made by a different app.'**
  String get backupWrongApp;

  /// No description provided for @backupNewerVersion.
  ///
  /// In en, this message translates to:
  /// **'That backup was made by a newer version of this app.'**
  String get backupNewerVersion;

  /// No description provided for @backupNoReminders.
  ///
  /// In en, this message translates to:
  /// **'That backup has no reminders in it.'**
  String get backupNoReminders;

  /// No description provided for @backupDamaged.
  ///
  /// In en, this message translates to:
  /// **'That backup is damaged.'**
  String get backupDamaged;

  /// No description provided for @backupStepless.
  ///
  /// In en, this message translates to:
  /// **'A reminder in that backup has no steps.'**
  String get backupStepless;

  /// No description provided for @backupZipUnreadable.
  ///
  /// In en, this message translates to:
  /// **'That zip could not be opened.'**
  String get backupZipUnreadable;

  /// No description provided for @backupZipNotABackup.
  ///
  /// In en, this message translates to:
  /// **'That zip is not a backup.'**
  String get backupZipNotABackup;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
