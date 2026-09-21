import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../data/database.dart';
import '../data/providers.dart';
import '../theme/app_theme.dart';
import '../util/icon_catalog.dart';
import '../widgets/form_fields.dart';
import '../widgets/pill_tile.dart';
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
    final box = _fabKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final origin = box.localToGlobal(Offset.zero);

    final routine = await showGeneralDialog<bool>(
      context: context,
      barrierLabel: 'Add',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (ctx, _, _) {
        final screen = MediaQuery.of(ctx).size;
        return Stack(
          children: [
            Positioned(
              right: screen.width - origin.dx - box.size.width,
              bottom: screen.height - origin.dy + 14,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _AddOption(
                    icon: Symbols.format_list_numbered,
                    label: 'Add a routine',
                    onTap: () => Navigator.pop(ctx, true),
                  ),
                  const SizedBox(height: 12),
                  _AddOption(
                    icon: Symbols.check_circle,
                    label: 'Add a step',
                    onTap: () => Navigator.pop(ctx, false),
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
    return Scaffold(
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
              tooltip: 'Add',
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Symbols.add, size: 30),
            )
          : null,
      bottomNavigationBar: _BottomBar(index: _index, onSelected: _onDestination),
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
              label: 'Home',
              selected: index == 0,
              onTap: () => onSelected(0),
            ),
            _NavItem(
              icon: Symbols.calendar_month,
              label: 'Calendar',
              selected: index == 1,
              onTap: () => onSelected(1),
            ),
            _NavItem(
              icon: Symbols.settings,
              label: 'Settings',
              selected: index == 2,
              onTap: () => onSelected(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddOption extends StatelessWidget {
  const _AddOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: AppShapes.pill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: AppColors.onPrimary),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
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
    final counts = ref.watch(stepCountsProvider).value ?? const <int, int>{};

    return reminders.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('Could not load reminders.\n$e',
              textAlign: TextAlign.center),
        ),
      ),
      data: (items) {
        if (items.isEmpty) return const _EmptyState();
        return ListView.separated(
          // Bottom padding clears the floating add button.
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, i) => _ReminderEntry(
            reminder: items[i],
            stepCount: counts[items[i].id] ?? 0,
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.alarm_add,
                size: 64, color: AppColors.onSurfaceVariant.withValues(alpha: 0.7)),
            const SizedBox(height: 20),
            const Text(
              'No reminders yet',
              style: TextStyle(fontSize: 22, color: AppColors.onSurface),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap + to create one.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderEntry extends ConsumerStatefulWidget {
  const _ReminderEntry({required this.reminder, required this.stepCount});

  final Reminder reminder;
  final int stepCount;

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
        title: const Text('Delete reminder?'),
        content: Text(
          widget.reminder.title.trim().isEmpty
              ? 'This reminder and its steps will be removed.'
              : '"${widget.reminder.title}" and its steps will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(repositoryProvider).delete(widget.reminder.id);
    }
  }

  Future<void> _showActions() async {
    final box = _anchor.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final origin = box.localToGlobal(Offset.zero);

    final action = await showGeneralDialog<String>(
      context: context,
      barrierLabel: 'Actions',
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (ctx, _, _) {
        final screen = MediaQuery.of(ctx).size;
        return Stack(
          children: [
            Positioned(
              // Hangs off the item's top-right corner, as in the mockup.
              right: (screen.width - origin.dx - box.size.width) + 4,
              top: origin.dy - 26,
              child: Material(
                color: AppColors.primary,
                shape: AppShapes.card,
                clipBehavior: Clip.antiAlias,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionButton(
                      icon: Symbols.edit,
                      tooltip: 'Edit',
                      onTap: () => Navigator.pop(ctx, 'edit'),
                    ),
                    _ActionButton(
                      icon: Symbols.delete,
                      tooltip: 'Delete',
                      onTap: () => Navigator.pop(ctx, 'delete'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (action == 'edit') _edit();
    if (action == 'delete') await _confirmDelete();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reminder;
    final title = r.title.trim().isEmpty ? 'Untitled reminder' : r.title.trim();
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay(hour: r.hour, minute: r.minute));
    final subtitle = '$time · ${describeDays(r.daysMask)}';
    final multiStep = widget.stepCount > 1;

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
              trailing:
                  multiStep ? _StepCountBadge(count: widget.stepCount) : null,
            )
          : _ImageCard(
              reminder: r,
              title: title,
              subtitle: subtitle,
              stepCount: widget.stepCount,
              onTap: _open,
              onLongPress: _showActions,
            ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Icon(icon, size: 26, color: AppColors.onPrimary),
        ),
      ),
    );
  }
}

/// Marks a reminder that runs as a checklist rather than a single action.
class _StepCountBadge extends StatelessWidget {
  const _StepCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
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
            '$count',
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
    required this.stepCount,
    required this.onTap,
    required this.onLongPress,
  });

  final Reminder reminder;
  final String title;
  final String subtitle;
  final int stepCount;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final file = File(reminder.imagePath!);

    return Material(
      color: AppColors.surfaceFilled,
      shape: AppShapes.card,
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
                  aspectRatio: 16 / 9,
                  child: file.existsSync()
                      ? Image.file(file, fit: BoxFit.cover)
                      : Container(
                          color: AppColors.primary,
                          child: const Icon(Symbols.image,
                              size: 40, color: AppColors.onPrimary),
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
                  if (stepCount > 1) ...[
                    const SizedBox(width: 12),
                    _StepCountBadge(count: stepCount),
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
  }
}
