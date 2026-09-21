import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../data/providers.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// Not in the mockups — designed to match them. Surfaces the two Android
/// permissions that decide whether reminders actually fire on time.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _exactAlarms;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final exact = await NotificationService.instance.canScheduleExact();
    if (mounted) setState(() => _exactAlarms = exact);
  }

  Future<void> _request() async {
    setState(() => _busy = true);
    final status = await NotificationService.instance.requestPermissions();
    if (!mounted) return;
    setState(() {
      _exactAlarms = status.exactAlarms;
      _busy = false;
    });
    _toast(status.allGranted
        ? 'Permissions granted.'
        : 'Some permissions are still blocked.');
  }

  Future<void> _rescheduleAll() async {
    setState(() => _busy = true);
    await ref.read(repositoryProvider).rescheduleAll();
    if (!mounted) return;
    setState(() => _busy = false);
    _toast('All reminders rescheduled.');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(remindersProvider).value?.length ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        const Text(
          'Settings',
          style: TextStyle(fontSize: 28, color: AppColors.onSurface),
        ),
        const SizedBox(height: 24),
        const _SectionLabel('Permissions'),
        _SettingRow(
          icon: Symbols.notifications,
          title: 'Notifications & alarms',
          subtitle: switch (_exactAlarms) {
            null => 'Checking…',
            true => 'Exact alarms allowed',
            false => 'Exact alarms blocked — reminders may fire late',
          },
          trailing: TextButton(
            onPressed: _busy ? null : _request,
            child: const Text('Grant'),
          ),
        ),
        const SizedBox(height: 26),
        const _SectionLabel('Maintenance'),
        _SettingRow(
          icon: Symbols.refresh,
          title: 'Reschedule all reminders',
          subtitle: '$count reminder${count == 1 ? '' : 's'} stored',
          trailing: TextButton(
            onPressed: _busy ? null : _rescheduleAll,
            child: const Text('Run'),
          ),
        ),
        const SizedBox(height: 26),
        const _SectionLabel('About'),
        const _SettingRow(
          icon: Symbols.info,
          title: 'Step Reminder',
          subtitle: 'Reminders with steps, icons and timers',
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(icon, size: 26, color: AppColors.onSurface),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 17, color: AppColors.onSurface)),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
