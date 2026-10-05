import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../data/database.dart';
import '../data/providers.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../util/icon_catalog.dart';
import '../widgets/anchored_menu.dart';
import '../widgets/empty_state.dart';
import '../widgets/form_fields.dart';
import '../widgets/pill_tile.dart';
import '../widgets/segmented_border.dart';
import 'calendar_screen.dart';
import 'edit_reminder_screen.dart';
import 'run_reminder_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _fabKey = GlobalKey();

  void _onDestination(int i) => setState(() => _index = i);

  /// Offers the two things you can create, anchored just above the add button.
  Future<void> _showAddMenu() async {
    final routine = await showAnchoredMenu<bool>(
      context: context,
      anchorKey: _fabKey,
      actions: [
        MenuAction(
          icon: Symbols.format_list_numbered,
          label: AppLocalizations.of(context).addRoutine,
          value: true,
        ),
        MenuAction(
          icon: Symbols.check_circle,
          label: AppLocalizations.of(context).addStepMenuItem,
          value: false,
        ),
      ],
    );

    if (routine == null || !mounted) return;
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditReminderScreen(isRoutine: routine),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back off a tab goes home first and only leaves the app from there,
      // so the way out is never one stray tap away from wherever you are.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() => _index = 0);
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _index,
            children: const [
              ReminderListView(),
              CalendarScreen(),
              SettingsScreen(),
            ],
          ),
        ),
        floatingActionButton: _index == 0
            ? FloatingActionButton(
                key: _fabKey,
                onPressed: _showAddMenu,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Symbols.add,
                    size: 30, semanticLabel: AppLocalizations.of(context).addReminderButton),
              )
            : null,
        bottomNavigationBar:
            _BottomBar(index: _index, onSelected: _onDestination),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(32),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            _NavItem(
              icon: Symbols.home,
              label: AppLocalizations.of(context).navHome,
              selected: index == 0,
              onTap: () => onSelected(0),
            ),
            _NavItem(
              icon: Symbols.calendar_month,
              label: AppLocalizations.of(context).navCalendar,
              selected: index == 1,
              onTap: () => onSelected(1),
            ),
            _NavItem(
              icon: Symbols.settings,
              label: AppLocalizations.of(context).navSettings,
              selected: index == 2,
              onTap: () => onSelected(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 26,
                color: selected ? AppColors.onPrimary : AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReminderListView extends ConsumerWidget {
  const ReminderListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersProvider);
    final progress =
        ref.watch(stepProgressProvider).value ?? const <int, StepProgress>{};

    return reminders.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => EmptyState(
        icon: Symbols.error,
        title: AppLocalizations.of(context).loadErrorTitle,
        message: AppLocalizations.of(context).loadErrorMessage,
      ),
      data: (all) {
        // Filtered before the emptiness check, or a list holding nothing but
        // yesterday's one-offs would render as a blank screen instead of
        // saying there is nothing there.
        final items =
            orderedForHome(withoutLapsedOneOffs(all, DateTime.now()), progress);
        if (items.isEmpty) {
          return EmptyState(
            icon: Symbols.alarm_add,
            title: AppLocalizations.of(context).emptyHomeTitle,
            message: AppLocalizations.of(context).emptyHomeMessage,
          );
        }
        return ListView.separated(
          // Bottom padding clears the floating add button.
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, i) => _ReminderEntry(
            // Keyed by reminder rather than position, so finishing one and
            // watching it drop down the list moves the row it belongs to
            // instead of reshuffling state between neighbours.
            key: ValueKey(items[i].id),
            reminder: items[i],
            progress: progress[items[i].id] ??
                const StepProgress(total: 0, done: 0),
          ),
        );
      },
    );
  }
}

class _ReminderEntry extends ConsumerStatefulWidget {
  const _ReminderEntry({
    super.key,
    required this.reminder,
    required this.progress,
  });

  final Reminder reminder;
  final StepProgress progress;

  @override
  ConsumerState<_ReminderEntry> createState() => _ReminderEntryState();
}

class _ReminderEntryState extends ConsumerState<_ReminderEntry> {
  final _anchor = GlobalKey();

  void _open() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RunReminderScreen(reminderId: widget.reminder.id),
      ),
    );
  }

  void _edit() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditReminderScreen(reminderId: widget.reminder.id),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteReminderTitle),
        content: Text(
          widget.reminder.title.trim().isEmpty
              ? AppLocalizations.of(context).deleteReminderMessage
              : AppLocalizations.of(context).deleteReminderNamedMessage(widget.reminder.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context).actionDelete,
                style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(repositoryProvider).delete(widget.reminder.id);
    }
  }

  Future<void> _showActions() async {
    final reminder = widget.reminder;
    final action = await showAnchoredMenu<String>(
      context: context,
      anchorKey: _anchor,
      preferAbove: false,
      actions: [
        MenuAction(icon: Symbols.edit, label: AppLocalizations.of(context).actionEdit, value: 'edit'),
        reminder.enabled
            ? MenuAction(
                icon: Symbols.notifications_off,
                label: AppLocalizations.of(context).turnOff,
                value: 'toggle',
              )
            : MenuAction(
                icon: Symbols.notifications_active,
                label: AppLocalizations.of(context).turnOn,
                value: 'toggle',
              ),
        MenuAction(icon: Symbols.delete, label: AppLocalizations.of(context).actionDelete, value: 'delete'),
      ],
    );

    if (!mounted) return;
    if (action == 'edit') _edit();
    if (action == 'toggle') {
      await ref
          .read(repositoryProvider)
          .setEnabled(reminder, !reminder.enabled);
    }
    if (action == 'delete') await _confirmDelete();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reminder;
    final title = r.title.trim().isEmpty ? AppLocalizations.of(context).untitledReminder : r.title.trim();
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay(hour: r.hour, minute: r.minute));
    final subtitle = '$time · ${describeDays(AppLocalizations.of(context), r.daysMask)}';
    final p = widget.progress;

    return KeyedSubtree(
      key: _anchor,
      child: r.imagePath == null
          ? PillTile(
              label: title,
              subtitle: subtitle,
              iconKey: r.iconKey,
              dimmed: !r.enabled,
              onTap: _open,
              onLongPress: _showActions,
              progress:
                  p.isRoutine ? (done: p.done, total: p.total) : null,
              // A single step has no segments, so the whole outline carries
              // the completed state instead.
              outlineColor:
                  !p.isRoutine && p.allDone ? AppColors.success : null,
              trailing: p.isRoutine ? _ProgressBadge(progress: p) : null,
            )
          : _ImageCard(
              reminder: r,
              title: title,
              subtitle: subtitle,
              progress: p,
              onTap: _open,
              onLongPress: _showActions,
            ),
    );
  }
}

/// Marks a reminder that runs as a checklist, and carries the same progress the
/// segmented border shows — so the count never depends on reading colour.
class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({required this.progress});

  final StepProgress progress;

  @override
  Widget build(BuildContext context) {
    if (progress.allDone) {
      return const Icon(Symbols.check_circle,
          size: 24, color: AppColors.success);
    }

    final label = progress.done > 0
        ? '${progress.done}/${progress.total}'
        : '${progress.total}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Symbols.format_list_numbered,
              size: 16, color: AppColors.onPrimary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({
    required this.reminder,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.onTap,
    required this.onLongPress,
  });

  final Reminder reminder;
  final String title;
  final String subtitle;
  final StepProgress progress;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final file = File(reminder.imagePath!);

    // One shape drives both the card and its progress border, so the arcs
    // always trace the corner the card actually has.
    final shape = AppShapes.card;

    // Same treatment as PillTile: transparent with an outline, or bare when
    // the segmented painter draws the outline instead.
    final card = Material(
      color: Colors.transparent,
      shape: progress.isRoutine
          ? shape
          : shape.copyWith(
              side: BorderSide(
                color: progress.allDone
                    ? AppColors.success
                    : AppColors.outline,
                width: progress.allDone
                    ? SegmentedProgressBorder.strokeWidth
                    : 1,
              ),
            ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: AspectRatio(
                  aspectRatio: kCardImageAspect,
                  child: file.existsSync()
                      ? Image.file(file, fit: BoxFit.cover)
                      : Container(
                          color: AppColors.surfaceFilled,
                          child: const Icon(Symbols.image,
                              size: 40, color: AppColors.onSurfaceVariant),
                        ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(IconCatalog.resolve(reminder.iconKey),
                      size: 26, color: AppColors.onSurface),
                  const SizedBox(width: 14),
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  if (progress.isRoutine) ...[
                    const SizedBox(width: 12),
                    _ProgressBadge(progress: progress),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (!progress.isRoutine) return card;
    return SegmentedProgressBorder(
      done: progress.done,
      total: progress.total,
      shape: shape,
      child: card,
    );
  }
}
