import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/app_prefs.dart';
import 'data/providers.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/run_reminder_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await NotificationService.instance.init();

  final seenOnboarding = await AppPrefs.seenOnboarding();

  runApp(
    ProviderScope(child: StepReminderApp(seenOnboarding: seenOnboarding)),
  );
}

class StepReminderApp extends ConsumerStatefulWidget {
  const StepReminderApp({super.key, required this.seenOnboarding});

  final bool seenOnboarding;

  @override
  ConsumerState<StepReminderApp> createState() => _StepReminderAppState();
}

class _StepReminderAppState extends ConsumerState<StepReminderApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late bool _seenOnboarding = widget.seenOnboarding;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Android drops scheduled alarms on reboot and reinstall, so re-arm them.
      await ref.read(repositoryProvider).rescheduleAll();
    });

    NotificationService.instance.launchReminderId
        .addListener(_openLaunchedReminder);
    _openLaunchedReminder();
  }

  Future<void> _finishOnboarding({required bool allowNotifications}) async {
    // Swapping what `home` builds, rather than pushing, leaves no route to go
    // back to: once the user is home, back cannot return to the introduction.
    setState(() => _seenOnboarding = true);
    await AppPrefs.markOnboardingSeen();

    if (allowNotifications) {
      await NotificationService.instance.requestNotificationsIfUndecided();
    }
  }

  @override
  void dispose() {
    NotificationService.instance.launchReminderId
        .removeListener(_openLaunchedReminder);
    super.dispose();
  }

  void _openLaunchedReminder() {
    final id = NotificationService.instance.launchReminderId.value;
    if (id == null) return;
    NotificationService.instance.launchReminderId.value = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => RunReminderScreen(reminderId: id)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Step Reminder',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: buildAppTheme(),
      home: _seenOnboarding
          ? const HomeShell()
          : OnboardingScreen(onFinished: _finishOnboarding),
    );
  }
}
