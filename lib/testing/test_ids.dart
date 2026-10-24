/// Every automation id in the app, in one place.
///
/// These are a contract with the end-to-end suite
/// (github.com/SaadiIftikhar/appium-automation), which keeps a copy of
/// this list. Renaming one breaks the tests that use it, so add new ids freely
/// but change existing ones together with that suite.
///
/// Ids name what a widget is, not what it says. Repeated widgets, such as a
/// card per reminder, share one id and are told apart by their label.
abstract final class TestIds {
  // Onboarding
  static const onboardingSkip = 'onboarding-skip';
  static const onboardingTitle = 'onboarding-title';

  /// Continue on the first pages, Allow notifications on the last.
  static const onboardingPrimary = 'onboarding-primary';
  static const onboardingNotNow = 'onboarding-not-now';
  static String onboardingDot(int page) => 'onboarding-dot-$page';

  // Home shell
  static const homeAddButton = 'home-add-button';
  static const homeEmpty = 'home-empty';
  static const reminderCard = 'reminder-card';
  static const navHome = 'nav-home';
  static const navCalendar = 'nav-calendar';
  static const navSettings = 'nav-settings';

  // Anchored menus
  static const menuAddRoutine = 'menu-add-routine';
  static const menuAddStep = 'menu-add-step';
  static const menuEdit = 'menu-edit';
  static const menuToggle = 'menu-toggle';
  static const menuDelete = 'menu-delete';

  // Confirmation dialogs (delete, mark done, reset)
  static const dialogCancel = 'dialog-cancel';
  static const dialogConfirm = 'dialog-confirm';

  // Reminder editor
  static const editorSave = 'editor-save';
  static const editorTitleField = 'editor-title-field';
  static const editorIcon = 'editor-icon';
  static const editorTime = 'editor-time';
  static const editorRepeat = 'editor-repeat';
  static const editorNotifications = 'editor-notifications';
  static const editorAlarm = 'editor-alarm';
  static const editorAddImage = 'editor-add-image';
  static const editorAddStep = 'editor-add-step';
  static const editorNoSteps = 'editor-no-steps';
  static const editorStepRow = 'editor-step-row';
  static const editorStepIcon = 'editor-step-icon';
  static const hintDismiss = 'hint-dismiss';

  // Step timer picker
  static const timerToggle = 'timer-toggle';
  static const timerHours = 'timer-hours';
  static const timerMinutes = 'timer-minutes';
  static const timerSeconds = 'timer-seconds';
  static const timerClear = 'timer-clear';

  // Repeat dialog
  static const repeatSummary = 'repeat-summary';
  static const repeatOk = 'repeat-ok';
  static const repeatCancel = 'repeat-cancel';

  /// Monday is 0, matching the app's weekday bitmask.
  static String repeatDay(int index) =>
      'repeat-day-${const ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'][index]}';
  static String repeatPreset(int mask) => switch (mask) {
        0x7F => 'repeat-preset-every-day',
        0x1F => 'repeat-preset-weekdays',
        0x60 => 'repeat-preset-weekend',
        _ => 'repeat-preset-$mask',
      };

  // Step editor
  static const stepEditorSave = 'step-editor-save';
  static const stepEditorDelete = 'step-editor-delete';
  static const stepEditorTitleField = 'step-editor-title-field';

  // Icon picker
  static const iconSearchField = 'icon-search-field';
  static const iconSearchClear = 'icon-search-clear';
  static const iconCell = 'icon-cell';
  static const iconEmpty = 'icon-empty';

  // Routine checklist
  static const routineProgress = 'routine-progress';
  static const routineStepRow = 'routine-step-row';
  static const routineReset = 'routine-reset';
  static const routineDone = 'routine-done';

  // Running a step
  static const stepTitle = 'step-title';
  static const stepDone = 'step-done';
  static const stepReset = 'step-reset';
  static const timerStartPause = 'timer-start-pause';
  static const timerRestart = 'timer-restart';
  static const timerRemaining = 'timer-remaining';

  // Calendar
  static const calendarEmpty = 'calendar-empty';
  static const calendarReminder = 'calendar-reminder';
  static const calendarSelectedDay = 'calendar-selected-day';

  // Settings
  static const settingsPermissions = 'settings-permissions';
  static const settingsExport = 'settings-export';
  static const settingsImport = 'settings-import';
  static const settingsAbout = 'settings-about';
}
