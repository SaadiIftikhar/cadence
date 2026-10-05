import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../data/backup.dart';
import '../data/backup_service.dart';
import '../data/providers.dart';
import '../l10n/app_localizations.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// Not in the mockups — designed to match them. Surfaces the two Android
/// permissions that decide whether reminders actually fire on time.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  PermissionStatus? _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Granting exact alarms happens in system settings, so the answer only
    // arrives once the user comes back.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final status = await NotificationService.instance.currentStatus();
    if (mounted) setState(() => _status = status);
  }

  Future<void> _request() async {
    setState(() => _busy = true);
    final status = await NotificationService.instance.requestPermissions();
    if (!mounted) return;
    setState(() {
      _status = status;
      _busy = false;
    });
    if (!status.allGranted) {
      _toast(AppLocalizations.of(context).stillBlockedToast);
      return;
    }
    // Anything scheduled while the permission was missing was scheduled
    // inexactly, so re-arm it now rather than waiting for the next launch.
    await ref.read(repositoryProvider).rescheduleAll();
  }

  Future<void> _export() async {
    // Read up front: the save dialog opens several awaits later, by which
    // point reaching back for the context is no longer sound.
    final dialogTitle = AppLocalizations.of(context).saveBackupDialog;
    setState(() => _busy = true);
    try {
      final service = await ref.read(backupServiceProvider.future);
      final zip = await service.export();
      final stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final saved = await FilePicker.saveFile(
        fileName: 'cadence-$stamp.zip',
        bytes: zip,
        mimeType: 'application/zip',
        dialogTitle: dialogTitle,
      );
      if (!mounted) return;
      if (saved != null) _toast(AppLocalizations.of(context).backupSaved);
    } catch (_) {
      if (mounted) _toast(AppLocalizations.of(context).backupSaveFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final picked = await FilePicker.pickFiles(
      dialogTitle: AppLocalizations.of(context).chooseBackupDialog,
      type: FileType.custom,
      // A bare manifest works too, for anyone who unzipped one.
      allowedExtensions: const ['zip', 'json'],
    );
    if (picked.isEmpty || !mounted) return;

    final existing = ref.read(remindersProvider).value ?? const [];
    final mode = existing.isEmpty
        ? ImportMode.add
        : await _askImportMode(existing.length);
    if (mode == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final bytes = await picked.first.xFile.readAsBytes();
      final service = await ref.read(backupServiceProvider.future);
      final count = await service.import(bytes, mode: mode);
      await ref.read(repositoryProvider).rescheduleAll();
      if (!mounted) return;
      _toast(AppLocalizations.of(context).importedCount(count));
    } on BackupFormatException catch (e) {
      if (mounted) _toast(_backupProblemText(AppLocalizations.of(context), e));
    } catch (_) {
      if (mounted) _toast(AppLocalizations.of(context).backupReadFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<ImportMode?> _askImportMode(int existing) => showDialog<ImportMode>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(ctx).importDialogTitle),
          content: Text(AppLocalizations.of(ctx).importDialogMessage(existing)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(ctx).actionCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ImportMode.add),
              child: Text(AppLocalizations.of(ctx).actionAdd),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ImportMode.replace),
              child: Text(
                AppLocalizations.of(ctx).actionReplace,
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        ),
      );

  /// Puts the reading failure into the user's language. The exception itself
  /// only names the problem, having no way to reach the strings.
  String _backupProblemText(AppLocalizations l10n, BackupFormatException e) =>
      switch (e.problem) {
        BackupProblem.notABackup => l10n.backupNotABackup,
        BackupProblem.wrongApp => l10n.backupWrongApp,
        BackupProblem.newerVersion => l10n.backupNewerVersion,
        BackupProblem.noReminders => l10n.backupNoReminders,
        BackupProblem.damaged => l10n.backupDamaged,
        BackupProblem.stepless => l10n.backupStepless,
        BackupProblem.zipUnreadable => l10n.backupZipUnreadable,
        BackupProblem.zipNotABackup => l10n.backupZipNotABackup,
      };

  String _permissionSubtitle(AppLocalizations l10n) {
    final status = _status;
    if (status == null) return l10n.permissionsChecking;
    if (status.allGranted) return l10n.permissionsAllowed;
    if (!status.notifications) return l10n.permissionsBlocked;
    return l10n.permissionsExactBlocked;
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        // No screen heading: the bottom bar already names this tab, and Home
        // and Calendar do not carry one either.
        _SectionLabel(l10n.sectionPermissions),
        _SettingRow(
          icon: Symbols.notifications,
          title: l10n.permissionsRow,
          subtitle: _permissionSubtitle(l10n),
          trailing: _status == null
              ? null
              : _status!.allGranted
                  // Nothing left to ask for, so the button becomes a receipt.
                  ? const Icon(Symbols.check_circle,
                      size: 26, color: AppColors.success)
                  : TextButton(
                      onPressed: _busy ? null : _request,
                      child: Text(l10n.actionGrant),
                    ),
        ),
        const SizedBox(height: 26),
        _SectionLabel(l10n.sectionBackup),
        _SettingRow(
          icon: Symbols.download,
          title: l10n.exportTitle,
          subtitle: l10n.exportSubtitle,
          trailing: TextButton(
            onPressed: _busy ? null : _export,
            child: Text(l10n.exportTitle),
          ),
        ),
        _SettingRow(
          icon: Symbols.upload,
          title: l10n.importTitle,
          subtitle: l10n.importSubtitle,
          trailing: TextButton(
            onPressed: _busy ? null : _import,
            child: Text(l10n.importTitle),
          ),
        ),
        const SizedBox(height: 26),
        _SectionLabel(l10n.sectionAbout),
        _SettingRow(
          icon: Symbols.info,
          title: l10n.appName,
          subtitle: l10n.appTagline,
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
