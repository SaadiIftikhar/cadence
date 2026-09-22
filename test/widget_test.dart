import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:step_reminder/data/database.dart';
import 'package:step_reminder/data/providers.dart';
import 'package:step_reminder/screens/run_step_screen.dart';
import 'package:step_reminder/theme/app_theme.dart';
import 'package:step_reminder/util/icon_catalog.dart';
import 'package:step_reminder/widgets/anchored_menu.dart';
import 'package:step_reminder/widgets/cookie_timer.dart';
import 'package:step_reminder/widgets/form_fields.dart';
import 'package:step_reminder/widgets/pill_tile.dart';
import 'package:step_reminder/widgets/icon_hint.dart';
import 'package:step_reminder/widgets/segmented_border.dart';

void main() {
  group('formatDuration', () {
    test('drops the hour segment under an hour', () {
      expect(formatDuration(const Duration(minutes: 5)), '05:00');
      expect(formatDuration(const Duration(seconds: 9)), '00:09');
    });

    test('includes hours once past one', () {
      expect(formatDuration(const Duration(hours: 1, minutes: 2)), '1:02:00');
    });

    test('clamps negatives to zero', () {
      expect(formatDuration(const Duration(seconds: -5)), '00:00');
    });
  });

  group('IconCatalog', () {
    test('every suggested icon exists in the symbol set', () {
      expect(IconCatalog.suggested, isNotEmpty);
      for (final name in IconCatalog.suggested) {
        expect(IconCatalog.exists(name), isTrue, reason: '$name is missing');
      }
    });

    test('search ranks prefix matches ahead of substring matches', () {
      final results = IconCatalog.search('alarm');
      expect(results.first.startsWith('alarm'), isTrue);
    });

    test('empty search falls back to the suggested list', () {
      expect(IconCatalog.search('   '), IconCatalog.suggested);
    });

    test('searches Tabler as well as Material Symbols', () {
      final results = IconCatalog.search('hourglass');
      expect(results.any((n) => !n.startsWith(IconCatalog.tablerPrefix)), isTrue,
          reason: 'no Material Symbols match');
      expect(results.any((n) => n.startsWith(IconCatalog.tablerPrefix)), isTrue,
          reason: 'no Tabler match');
    });

    test('a Tabler name resolves to the Tabler font', () {
      final icon = IconCatalog.resolve('${IconCatalog.tablerPrefix}stopwatch');
      expect(icon.fontPackage, 'tabler_icons_plus');
      expect(IconCatalog.exists('${IconCatalog.tablerPrefix}stopwatch'), isTrue);
    });

    test('an unknown Tabler name falls back rather than throwing', () {
      final icon = IconCatalog.resolve('${IconCatalog.tablerPrefix}not_an_icon');
      expect(icon.fontPackage, 'material_symbols_icons');
      expect(
          IconCatalog.exists('${IconCatalog.tablerPrefix}not_an_icon'), isFalse);
    });

    test('bare names still mean Material Symbols', () {
      // Keys stored before Tabler existed must keep resolving unchanged.
      expect(IconCatalog.resolve('alarm').fontPackage, 'material_symbols_icons');
    });
  });

  group('describeDays', () {
    test('names the common presets', () {
      expect(describeDays(0), 'Once');
      expect(describeDays(0x7F), 'Every day');
      expect(describeDays(0x1F), 'Weekdays');
      expect(describeDays(0x60), 'Weekend');
    });

    test('lists arbitrary selections in weekday order', () {
      // Monday, Wednesday, Friday.
      expect(describeDays(1 | 1 << 2 | 1 << 4), 'Mon, Wed, Fri');
      expect(describeDays(1 << 6), 'Sun');
    });
  });

  group('SegmentedProgressBorder', () {
    Future<void> pumpPill(WidgetTester tester, int done, int total) {
      return tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Center(
              child: PillTile(
                label: 'Morning routine',
                progress: (done: done, total: total),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('paints partial progress without error', (tester) async {
      await pumpPill(tester, 2, 4);
      expect(tester.takeException(), isNull);
      expect(find.byType(SegmentedProgressBorder), findsOneWidget);
    });

    testWidgets('survives the degenerate counts', (tester) async {
      for (final (done, total) in [(0, 0), (0, 1), (1, 1), (0, 40), (5, 3)]) {
        await pumpPill(tester, done, total);
        expect(tester.takeException(), isNull,
            reason: 'done=$done total=$total threw');
      }
    });

    testWidgets('a single step gets no segmented border', (tester) async {
      await pumpPill(tester, 0, 1);
      expect(find.byType(SegmentedProgressBorder), findsNothing);
    });

    testWidgets('cached geometry still follows a changed size or count',
        (tester) async {
      // The arcs are cached per size, shape and count, so a stale entry would
      // show up as the wrong layout after any of those change.
      Future<void> pumpAt(double width, int total) => tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(),
              home: Scaffold(
                body: Center(
                  child: SegmentedProgressBorder(
                    done: 1,
                    total: total,
                    shape: AppShapes.pill,
                    child: SizedBox(width: width, height: 72),
                  ),
                ),
              ),
            ),
          );

      for (final (width, total) in [
        (300.0, 4),
        (300.0, 7),
        (220.0, 4),
        (300.0, 4),
      ]) {
        await pumpAt(width, total);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'width=$width total=$total threw');
      }
    });

    testWidgets('traces a rounded card, not just a pill', (tester) async {
      // The image-card case: a tall rounded rectangle rather than a stadium.
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Center(
              child: SegmentedProgressBorder(
                done: 1,
                total: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const SizedBox(width: 300, height: 220),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('PillTile icon tap', () {
    Future<(int Function(), int Function())> pump(WidgetTester tester) async {
      var body = 0;
      var icon = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Center(
              child: PillTile(
                label: 'Stretch',
                iconKey: 'alarm',
                onTap: () => body++,
                onIconTap: () => icon++,
              ),
            ),
          ),
        ),
      );
      return (() => body, () => icon);
    }

    testWidgets('the icon runs onIconTap and leaves onTap alone',
        (tester) async {
      final (body, icon) = await pump(tester);

      await tester.tap(find.byIcon(IconCatalog.resolve('alarm')));
      await tester.pumpAndSettle();

      expect(icon(), 1);
      expect(body(), 0);
    });

    testWidgets('the rest of the row still runs onTap', (tester) async {
      final (body, icon) = await pump(tester);

      await tester.tap(find.text('Stretch'));
      await tester.pumpAndSettle();

      expect(body(), 1);
      expect(icon(), 0);
    });
  });

  group('IconHint', () {
    testWidgets('names the gesture and dismisses on Got it', (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(body: IconHint(onDismiss: () => dismissed++)),
        ),
      );

      expect(find.text('Tap the icon to change it'), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(dismissed, 1);
    });
  });

  group('Run step screen', () {
    Future<void> pumpTimed(WidgetTester tester, {int? timerSeconds}) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildAppTheme(),
            home: RunStepScreen(
              step: ReminderStep(
                id: 1,
                reminderId: 1,
                title: 'Stretch',
                iconKey: 'alarm',
                timerSeconds: timerSeconds,
                position: 0,
                completed: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('a timed step keeps its name in the pill at the top',
        (tester) async {
      await pumpTimed(tester, timerSeconds: 300);

      expect(find.byType(PillTile), findsOneWidget);
      expect(find.byType(CookieTimer), findsOneWidget);
    });

    testWidgets('a step with no timer shows its icon and name in the middle',
        (tester) async {
      await pumpTimed(tester);

      // The pill would sit where nothing else needs the room, so it goes.
      expect(find.byType(PillTile), findsNothing);
      expect(find.byType(CookieTimer), findsNothing);
      expect(find.text('Stretch'), findsOneWidget);
      expect(find.byIcon(IconCatalog.resolve('alarm')), findsOneWidget);
    });

    Future<void> pumpStep(WidgetTester tester, {required bool completed}) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildAppTheme(),
            home: RunStepScreen(
              step: ReminderStep(
                id: 1,
                reminderId: 1,
                title: 'Stretch',
                iconKey: null,
                timerSeconds: 300,
                position: 0,
                completed: completed,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    OutlinedButton resetButton(WidgetTester tester) =>
        tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Reset'),
        );

    Icon tickIcon(WidgetTester tester) =>
        tester.widget<Icon>(find.byIcon(Symbols.done_all));

    testWidgets('Reset and Done are the same width', (tester) async {
      await pumpStep(tester, completed: false);

      final reset =
          tester.getSize(find.widgetWithText(OutlinedButton, 'Reset'));
      final done = tester.getSize(find.widgetWithText(OutlinedButton, 'Done'));
      expect(reset.width, done.width);
    });

    testWidgets('an unfinished step cannot be reset and has a plain tick',
        (tester) async {
      await pumpStep(tester, completed: false);

      expect(resetButton(tester).onPressed, isNull);
      expect(tickIcon(tester).color, isNull);
    });

    testWidgets('reopening a finished step shows it finished', (tester) async {
      await pumpStep(tester, completed: true);

      expect(resetButton(tester).onPressed, isNotNull);
      expect(tickIcon(tester).color, AppColors.success);
    });
  });

  group('showAnchoredMenu', () {
    Future<GlobalKey> pumpHost(
      WidgetTester tester,
      void Function(String?) onResult,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  key: key,
                  onPressed: () async {
                    onResult(
                      await showAnchoredMenu<String>(
                        context: context,
                        anchorKey: key,
                        actions: const [
                          MenuAction(
                              icon: Icons.edit, label: 'Edit', value: 'edit'),
                          MenuAction(
                              icon: Icons.delete,
                              label: 'Delete',
                              value: 'delete'),
                        ],
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      return key;
    }

    testWidgets('a tap outside dismisses and returns null', (tester) async {
      String? result = 'untouched';
      await pumpHost(tester, (r) => result = r);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Far corner, clear of both pills.
      await tester.tapAt(const Offset(12, 12));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsNothing);
      expect(result, isNull);
    });

    testWidgets('choosing a pill returns its value', (tester) async {
      String? result = 'untouched';
      await pumpHost(tester, (r) => result = r);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(result, 'delete');
    });
  });

  group('orderedForHome', () {
    Reminder at(int id, int hour, int minute) => Reminder(
          id: id,
          title: 'reminder $id',
          iconKey: 'alarm',
          hour: hour,
          minute: minute,
          daysMask: 0,
          notificationsEnabled: true,
          alarmEnabled: false,
          multiStep: false,
          enabled: true,
          createdAt: DateTime(2026),
        );

    Iterable<int> idsOf(List<Reminder> list, Map<int, StepProgress> progress) =>
        orderedForHome(list, progress).map((r) => r.id);

    test('sorts by time of day', () {
      final list = [at(1, 9, 0), at(2, 7, 30), at(3, 8, 15)];
      expect(idsOf(list, const {}), [2, 3, 1]);
    });

    test('a minute still separates two reminders in the same hour', () {
      final list = [at(1, 8, 45), at(2, 8, 5)];
      expect(idsOf(list, const {}), [2, 1]);
    });

    test('finished ones drop below everything unfinished', () {
      final list = [at(1, 7, 0), at(2, 8, 0), at(3, 9, 0)];
      const progress = {
        1: StepProgress(total: 2, done: 2), // finished, earliest time
        2: StepProgress(total: 2, done: 1),
        3: StepProgress(total: 1, done: 0),
      };
      expect(idsOf(list, progress), [2, 3, 1]);
    });

    test('finished ones keep time order among themselves', () {
      final list = [at(1, 9, 0), at(2, 7, 0)];
      const progress = {
        1: StepProgress(total: 1, done: 1),
        2: StepProgress(total: 1, done: 1),
      };
      expect(idsOf(list, progress), [2, 1]);
    });

    test('an identical time falls back to id so the order never wobbles', () {
      final list = [at(3, 8, 0), at(1, 8, 0), at(2, 8, 0)];
      expect(idsOf(list, const {}), [1, 2, 3]);
    });

    test('a reminder with no steps counts as unfinished', () {
      final list = [at(1, 9, 0), at(2, 7, 0)];
      const progress = {
        2: StepProgress(total: 0, done: 0),
      };
      expect(idsOf(list, progress), [2, 1]);
    });
  });

  group('StepProgress', () {
    test('only counts as a routine past one step', () {
      expect(const StepProgress(total: 1, done: 0).isRoutine, isFalse);
      expect(const StepProgress(total: 2, done: 0).isRoutine, isTrue);
    });

    test('an empty reminder is never all done', () {
      expect(const StepProgress(total: 0, done: 0).allDone, isFalse);
      expect(const StepProgress(total: 3, done: 3).allDone, isTrue);
      expect(const StepProgress(total: 3, done: 2).allDone, isFalse);
    });
  });

  group('showDayPickerDialog', () {
    Future<void> openWith(WidgetTester tester, int mask, void Function(int?) sink) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async =>
                    sink(await showDayPickerDialog(context, mask)),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('a preset selects its whole set of days', (tester) async {
      int? result;
      await openWith(tester, 0, (r) => result = r);

      await tester.tap(find.text('Weekdays'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(result, 0x1F);
    });

    testWidgets('every preset round-trips through the summary',
        (tester) async {
      for (final (label, mask) in [
        ('Every day', 0x7F),
        ('Weekdays', 0x1F),
        ('Weekend', 0x60),
      ]) {
        int? result;
        await openWith(tester, 0, (r) => result = r);

        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        // The summary names the same preset the button does.
        expect(find.text(label), findsNWidgets(2), reason: 'for $label');

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(result, mask, reason: 'for $label');
      }
    });

    testWidgets('cancel keeps the original selection', (tester) async {
      int? result = -1;
      await openWith(tester, 0x1F, (r) => result = r);

      await tester.tap(find.text('Every day'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });

  group('DaySelector', () {
    testWidgets('toggles the bit for the tapped day', (tester) async {
      var mask = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => DaySelector(
                mask: mask,
                onChanged: (m) => setState(() => mask = m),
              ),
            ),
          ),
        ),
      );

      // Index 2 is Wednesday, so bit 2 should flip on then back off.
      await tester.tap(find.text('W'));
      await tester.pump();
      expect(mask, 1 << 2);

      await tester.tap(find.text('W'));
      await tester.pump();
      expect(mask, 0);
    });
  });
}
