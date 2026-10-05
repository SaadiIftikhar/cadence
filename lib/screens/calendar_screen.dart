import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:table_calendar/table_calendar.dart';

import '../data/database.dart';
import '../data/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/pill_tile.dart';
import 'run_reminder_screen.dart';

/// Not in the mockups — designed to match them. Shows which reminders land on
/// a given day, driven by each reminder's weekday mask.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final reminders = ref.watch(remindersProvider);

    return reminders.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const EmptyState(
        icon: Symbols.error,
        title: 'Could not load your reminders',
        message: 'Restarting the app usually clears this.',
      ),
      data: (all) {
        final forDay = remindersOnDay(all, _selected);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            TableCalendar<Reminder>(
              firstDay: DateTime.utc(2020),
              lastDay: DateTime.utc(2100),
              focusedDay: _focused,
              selectedDayPredicate: (d) => isSameDay(d, _selected),
              eventLoader: (d) => remindersOnDay(all, d),
              startingDayOfWeek: StartingDayOfWeek.monday,
              // A month grid is four, five or six rows deep depending on how
              // the dates fall. Holding it at six keeps the date and the day's
              // reminders in one place instead of sliding up and down the
              // screen as you page through the months.
              sixWeekMonthsEnforced: true,
              onDaySelected: (selected, focused) => setState(() {
                _selected = selected;
                _focused = focused;
              }),
              onPageChanged: (focused) => _focused = focused,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle:
                    TextStyle(fontSize: 20, color: AppColors.onSurface),
                leftChevronIcon:
                    Icon(Symbols.chevron_left, color: AppColors.onSurface),
                rightChevronIcon:
                    Icon(Symbols.chevron_right, color: AppColors.onSurface),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: AppColors.onSurfaceVariant),
                weekendStyle: TextStyle(color: AppColors.onSurfaceVariant),
              ),
              // Taller rows than the default 52, so the selected day's circle
              // and the dot beneath it each have room of their own.
              rowHeight: 58,
              calendarStyle: const CalendarStyle(
                defaultTextStyle: TextStyle(color: AppColors.onSurface),
                weekendTextStyle: TextStyle(color: AppColors.onSurface),
                outsideTextStyle: TextStyle(color: AppColors.outlineDim),
                todayDecoration: BoxDecoration(
                  color: AppColors.surfaceFilled,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(color: AppColors.onSurface),
                selectedDecoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: TextStyle(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
                markerDecoration: BoxDecoration(
                  color: AppColors.accentPink,
                  shape: BoxShape.circle,
                ),
                // One dot answers the only question the grid is being asked:
                // is there anything on this day. How many there are is what
                // the list below is for, and a row of dots per day turned the
                // month into noise.
                markersMaxCount: 1,
                markerSize: 6,
                // Pinned to the bottom of the cell rather than auto-anchored,
                // which placed it over the selected day's circle.
                markersAutoAligned: false,
                markersOffset: PositionedOffset(bottom: 2),
                // Vertical margin shrinks the day circle, leaving the dot its
                // own band underneath.
                cellMargin: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              DateFormat('EEEE, d MMMM').format(_selected),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, color: AppColors.onSurface),
            ),
            const SizedBox(height: 14),
            if (forDay.isEmpty)
              const EmptyState(
                icon: Symbols.event_busy,
                title: 'Nothing scheduled',
                message: 'No reminders repeat on this day.',
              )
            else
              for (final r in forDay)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PillTile(
                    label: r.title.trim().isEmpty
                        ? 'Untitled reminder'
                        : r.title.trim(),
                    iconKey: r.iconKey,
                    trailing: Text(
                      _formatTime(r),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RunReminderScreen(reminderId: r.id),
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }

  String _formatTime(Reminder r) {
    final dt = DateTime(2000, 1, 1, r.hour, r.minute);
    return DateFormat('h:mm a').format(dt);
  }
}
