import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:table_calendar/table_calendar.dart';

import '../data/database.dart';
import '../data/providers.dart';
import '../theme/app_theme.dart';
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

  static List<Reminder> _onDay(List<Reminder> all, DateTime day) {
    final bit = 1 << (day.weekday - 1);
    return all.where((r) => r.enabled && r.daysMask & bit != 0).toList();
  }

  @override
  Widget build(BuildContext context) {
    final reminders = ref.watch(remindersProvider);

    return reminders.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load reminders.\n$e')),
      data: (all) {
        final forDay = _onDay(all, _selected);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            TableCalendar<Reminder>(
              firstDay: DateTime.utc(2020),
              lastDay: DateTime.utc(2100),
              focusedDay: _focused,
              selectedDayPredicate: (d) => isSameDay(d, _selected),
              eventLoader: (d) => _onDay(all, d),
              startingDayOfWeek: StartingDayOfWeek.monday,
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
                markersMaxCount: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              DateFormat('EEEE, d MMMM').format(_selected),
              style: const TextStyle(fontSize: 20, color: AppColors.onSurface),
            ),
            const SizedBox(height: 14),
            if (forDay.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Text(
                  'Nothing scheduled for this day.',
                  style: TextStyle(color: AppColors.onSurfaceVariant),
                ),
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
