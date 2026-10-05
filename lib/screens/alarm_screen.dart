import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../data/database.dart';
import '../data/providers.dart';
import '../l10n/app_localizations.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../util/icon_catalog.dart';
import 'run_reminder_screen.dart';

/// What a ringing alarm looks like: the whole screen, over the keyguard, with
/// nothing to do but deal with it.
///
/// The notification carries on sounding for as long as it is posted, so this
/// screen — not unlocking the phone — is what stops it. That is the difference
/// between an alarm and a notification that happens to be loud.
class AlarmScreen extends ConsumerStatefulWidget {
  const AlarmScreen({super.key, required this.reminderId});

  final int reminderId;

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen> {
  Reminder? _reminder;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    NotificationService.instance.takeOverLockScreen();
    _load();
  }

  @override
  void dispose() {
    // Whichever way this screen goes away, the app stops being allowed past
    // the lock screen with it.
    NotificationService.instance.releaseLockScreen();
    super.dispose();
  }

  Future<void> _load() async {
    final reminder =
        await ref.read(databaseProvider).findReminder(widget.reminderId);
    if (!mounted) return;
    setState(() {
      _reminder = reminder;
      _loading = false;
    });
  }

  Future<void> _silence() async {
    final reminder = _reminder;
    if (reminder != null) {
      await NotificationService.instance.dismissAlarm(reminder);
    }
  }

  Future<void> _dismiss() async {
    await _silence();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _start() async {
    await _silence();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RunReminderScreen(reminderId: widget.reminderId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reminder = _reminder;
    final title = reminder == null || reminder.title.trim().isEmpty
        ? AppLocalizations.of(context).reminderFallback
        : reminder.title.trim();
    final time = reminder == null
        ? ''
        : MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay(hour: reminder.hour, minute: reminder.minute),
          );

    return Scaffold(
      // No app bar, and nothing to navigate to: an alarm is not somewhere you
      // browsed to, so there is nowhere to go back to from it.
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            time,
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w300,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 36),
                          Icon(
                            IconCatalog.resolve(reminder?.iconKey),
                            size: 120,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 32),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 30,
                              height: 1.2,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _start,
                      icon: const Icon(Symbols.play_arrow, size: 26),
                      label: Text(AppLocalizations.of(context).actionStart),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _dismiss,
                      icon: const Icon(Symbols.alarm_off, size: 24),
                      label: Text(AppLocalizations.of(context).actionDismiss),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
