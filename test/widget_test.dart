import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:step_reminder/data/database.dart';
import 'package:step_reminder/data/providers.dart';
import 'package:step_reminder/screens/calendar_screen.dart';
import 'package:step_reminder/screens/edit_reminder_screen.dart';
import 'package:step_reminder/screens/edit_step_screen.dart';
import 'package:step_reminder/screens/run_step_screen.dart';
import 'package:step_reminder/theme/app_theme.dart';
import 'package:step_reminder/util/duration_format.dart';
import 'package:step_reminder/util/icon_catalog.dart';
import 'package:step_reminder/widgets/anchored_menu.dart';
import 'package:step_reminder/widgets/form_fields.dart';
import 'package:step_reminder/widgets/hint_callout.dart';
import 'package:step_reminder/widgets/pill_tile.dart';
import 'package:step_reminder/widgets/segmented_border.dart';
import 'package:step_reminder/widgets/timer_pill.dart';

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
      expect(describeDays(0), 'Today only');
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

  group('HintCallout', () {
    testWidgets('shows its message and dismisses on Got it', (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: HintCallout(
              message: 'Tap the icon to change it',
              onDismiss: () => dismissed++,
            ),
          ),
        ),
      );

      expect(find.text('Tap the icon to change it'), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(dismissed, 1);
    });
  });

  group('TimerPill', () {
    Future<void> pumpPill(
      WidgetTester tester, {
      required Duration remaining,
      required Duration total,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Center(child: TimerPill(remaining: remaining, total: total)),
          ),
        ),
      );
    }

    testWidgets('shows the formatted time remaining', (tester) async {
      await pumpPill(
        tester,
        remaining: const Duration(minutes: 4, seconds: 5),
        total: const Duration(minutes: 5),
      );
      expect(find.text('04:05'), findsOneWidget);
    });

    testWidgets('a fresh timer, a half-run one and a finished one all paint',
        (tester) async {
      const total = Duration(minutes: 5);
      for (final remaining in [total, total ~/ 2, Duration.zero]) {
        await pumpPill(tester, remaining: remaining, total: total);
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull,
            reason: 'remaining=$remaining threw');
      }
    });

    testWidgets('a step with no timer at all does not divide by zero',
        (tester) async {
      await pumpPill(tester, remaining: Duration.zero, total: Duration.zero);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a ring put back to full sweeps there instead of snapping',
        (tester) async {
      const total = Duration(minutes: 2);
      await pumpPill(tester, remaining: const Duration(seconds: 10), total: total);
      await tester.pump(const Duration(seconds: 1));

      // What a reset does: the time jumps back to full, and the ring has to
      // travel to meet it rather than arrive there on the next frame.
      await pumpPill(tester, remaining: total, total: total);
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.binding.hasScheduledFrame, isTrue);
    });
  });

  group('timerRingFraction', () {
    const total = Duration(minutes: 5);

    test('a timer that has not started yet lights the whole ring', () {
      expect(timerRingFraction(total, total), 1.0);
    });

    test('a finished timer lights none of it', () {
      expect(timerRingFraction(Duration.zero, total), 0.0);
    });

    test('half the time left lights half the ring', () {
      expect(timerRingFraction(const Duration(minutes: 2, seconds: 30), total),
          0.5);
    });

    test('the ring drains rather than fills as time runs down', () {
      // The direction is the whole point: each later reading must light less
      // of the ring than the one before it.
      final readings = [
        for (final seconds in [300, 200, 100, 0])
          timerRingFraction(Duration(seconds: seconds), total),
      ];
      for (var i = 1; i < readings.length; i++) {
        expect(readings[i], lessThan(readings[i - 1]));
      }
    });

    test('a step with no timer lights nothing instead of dividing by zero', () {
      expect(timerRingFraction(Duration.zero, Duration.zero), 0.0);
    });

    test('more remaining than the total still stops at a full ring', () {
      expect(timerRingFraction(const Duration(minutes: 9), total), 1.0);
    });
  });

  group('Run step screen', () {
    Future<void> pumpTimed(
      WidgetTester tester, {
      int? timerSeconds,
      bool completed = false,
    }) async {
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
                completed: completed,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    bool controlIsLive(WidgetTester tester, IconData icon) {
      final ink = tester.widget<InkWell>(
        find.ancestor(of: find.byIcon(icon), matching: find.byType(InkWell)),
      );
      return ink.onTap != null;
    }

    testWidgets('both kinds of step lead with the icon and name',
        (tester) async {
      // Timed and untimed differ by the clock, not by the layout around it.
      for (final timer in [null, 300]) {
        await pumpTimed(tester, timerSeconds: timer);

        expect(find.byType(PillTile), findsNothing,
            reason: 'timer=$timer still shows the old pill');
        expect(find.text('Stretch'), findsOneWidget, reason: 'timer=$timer');
        expect(find.byIcon(IconCatalog.resolve('alarm')), findsOneWidget,
            reason: 'timer=$timer');
      }
    });

    testWidgets('only a timed step gets a clock', (tester) async {
      await pumpTimed(tester, timerSeconds: 300);
      expect(find.byType(TimerPill), findsOneWidget);

      await pumpTimed(tester);
      expect(find.byType(TimerPill), findsNothing);
    });

    testWidgets(
        'the heading is the same size whether or not the step has a timer',
        (tester) async {
      Size headingIconSize(WidgetTester t) =>
          t.getSize(find.byIcon(IconCatalog.resolve('alarm')));

      await pumpTimed(tester);
      final withoutTimer = headingIconSize(tester);

      await pumpTimed(tester, timerSeconds: 300);
      final withTimer = headingIconSize(tester);

      expect(withTimer, withoutTimer);
    });

    testWidgets('a step still to do keeps its timer controls live',
        (tester) async {
      await pumpTimed(tester, timerSeconds: 120);

      expect(controlIsLive(tester, Symbols.play_arrow), isTrue);
      expect(controlIsLive(tester, Symbols.restart_alt), isTrue);
      expect(tester.widget<TimerPill>(find.byType(TimerPill)).enabled, isTrue);
    });

    testWidgets('a step already done has its whole timer row switched off',
        (tester) async {
      await pumpTimed(tester, timerSeconds: 120, completed: true);

      expect(controlIsLive(tester, Symbols.play_arrow), isFalse);
      expect(controlIsLive(tester, Symbols.restart_alt), isFalse);
      expect(tester.widget<TimerPill>(find.byType(TimerPill)).enabled, isFalse);
    });

    testWidgets('a finished step will not start counting down', (tester) async {
      await pumpTimed(tester, timerSeconds: 120, completed: true);
      expect(find.text('02:00'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Start'), warnIfMissed: false);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('02:00'), findsOneWidget);
    });

    testWidgets('a timer runs down to zero and stops', (tester) async {
      await pumpTimed(tester, timerSeconds: 2);
      expect(find.text('00:02'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Start'));
      await tester.pump();

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:01'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:00'), findsOneWidget);

      // Finishing chimes; a device that cannot play it must not take the
      // screen down with it.
      expect(tester.takeException(), isNull);

      // The ticker has stopped, so nothing counts past zero.
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('00:00'), findsOneWidget);
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

  group('Edit reminder screen validation', () {
    setUp(() {
      // initState reads AppPrefs (backed by shared_preferences) to decide
      // whether to show the one-time icon/time hints; without a mock store
      // that read never resolves under flutter_test.
      SharedPreferences.setMockInitialValues({});
    });

    Future<void> pumpNewRoutine(WidgetTester tester) async {
      // The form is taller than the default 600px test surface, and a
      // ListView only builds what is within its viewport plus a small cache
      // extent — Add step sits past that, so without more room it is simply
      // never in the tree for find to see, whether reddened or not.
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const EditReminderScreen(isRoutine: true),
          ),
        ),
      );
      await tester.pump();
    }

    BorderSide? addStepBorder(WidgetTester tester) {
      final button = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Add step'),
      );
      return button.style?.side?.resolve(const <WidgetState>{});
    }

    testWidgets('a fresh routine does not start with Add step reddened',
        (tester) async {
      await pumpNewRoutine(tester);
      expect(tester.takeException(), isNull);
      expect(addStepBorder(tester), isNull);
    });

    testWidgets('saving an empty routine reddens Add step', (tester) async {
      await pumpNewRoutine(tester);

      await tester.tap(find.bySemanticsLabel('Save'));
      await tester.pump();

      expect(addStepBorder(tester)?.color, AppColors.error);
    });

    testWidgets('adding a step clears the red border', (tester) async {
      await pumpNewRoutine(tester);
      await tester.tap(find.bySemanticsLabel('Save'));
      await tester.pump();
      expect(addStepBorder(tester)?.color, AppColors.error);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Add step'));
      await tester.pumpAndSettle();
      // The step editor opens with an empty title; give it one and save.
      // Scoped to the pushed screen: the routine editor underneath has a
      // TextField of its own, still in the tree while this one is on top.
      await tester.enterText(
        find.descendant(
          of: find.byType(EditStepScreen),
          matching: find.byType(TextField),
        ),
        'Stretch',
      );
      await tester.tap(find.bySemanticsLabel('Save step'));
      await tester.pumpAndSettle();

      expect(addStepBorder(tester), isNull);
    });
  });

  group('Edit step screen validation', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Future<void> pumpEditStep(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const EditStepScreen(allowDelete: false),
        ),
      );
      await tester.pump();
    }

    InputBorder? titleBorder(WidgetTester tester) {
      final field = tester.widget<TextField>(find.byType(TextField));
      return field.decoration?.enabledBorder;
    }

    testWidgets('a fresh step does not start with its title reddened',
        (tester) async {
      await pumpEditStep(tester);
      expect(tester.takeException(), isNull);
      expect(titleBorder(tester), isNull);
    });

    testWidgets('saving with no title reddens it instead of saving',
        (tester) async {
      await pumpEditStep(tester);

      await tester.tap(find.bySemanticsLabel('Save step'));
      await tester.pump();

      final border = titleBorder(tester);
      expect(border, isA<OutlineInputBorder>());
      expect((border as OutlineInputBorder).borderSide.color, AppColors.error);
      // Nothing to pop back to here, so a successful save would have thrown;
      // reaching this line at all means it declined to pop.
      expect(tester.takeException(), isNull);
    });

    testWidgets('typing a title clears the red border', (tester) async {
      await pumpEditStep(tester);
      await tester.tap(find.bySemanticsLabel('Save step'));
      await tester.pump();
      expect(titleBorder(tester), isNotNull);

      await tester.enterText(find.byType(TextField), 'Stretch');
      await tester.pump();

      expect(titleBorder(tester), isNull);
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

  group('Calendar screen', () {
    testWidgets('the day below the grid stays put as the months change shape',
        (tester) async {
      // Tall enough that the whole screen is laid out at once, whatever the
      // month grid's height.
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            remindersProvider.overrideWith((ref) => Stream.value(<Reminder>[])),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const Scaffold(body: CalendarScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      double dayListTop() =>
          tester.getTopLeft(find.text('Nothing scheduled')).dy;

      final settled = dayListTop();

      // A year covers every shape a month grid takes — four rows through six.
      for (var month = 1; month <= 12; month++) {
        await tester.tap(find.byIcon(Symbols.chevron_right));
        await tester.pumpAndSettle();
        expect(dayListTop(), settled,
            reason: '$month month(s) on, the day below the grid had moved');
      }
    });
  });

  group('withoutLapsedOneOffs', () {
    Reminder made(int id, int daysMask, DateTime createdAt) => Reminder(
          id: id,
          title: 'reminder $id',
          iconKey: 'alarm',
          hour: 8,
          minute: 0,
          daysMask: daysMask,
          notificationsEnabled: true,
          alarmEnabled: false,
          multiStep: false,
          enabled: true,
          createdAt: createdAt,
        );

    final now = DateTime(2026, 9, 22, 10, 0);

    test('a today-only reminder made today is still there', () {
      final list = [made(1, 0, DateTime(2026, 9, 22, 7, 30))];
      expect(withoutLapsedOneOffs(list, now).single.id, 1);
    });

    test('a today-only reminder is gone once the day has rolled over', () {
      final list = [made(1, 0, DateTime(2026, 9, 21, 8, 0))];
      expect(withoutLapsedOneOffs(list, now), isEmpty);
    });

    test('a repeating reminder stays however old it is', () {
      final list = [made(1, 0x7F, DateTime(2024, 1, 1))];
      expect(withoutLapsedOneOffs(list, now).single.id, 1);
    });

    test('the date decides it, not how many hours have passed', () {
      // Made a minute before midnight and checked a minute after it: barely
      // any time has gone by, but the day it was for has.
      expect(
        withoutLapsedOneOffs(
          [made(1, 0, DateTime(2026, 9, 21, 23, 59))],
          DateTime(2026, 9, 22, 0, 1),
        ),
        isEmpty,
      );
      // Nearly a full day later, but still the same day it was made for.
      expect(
        withoutLapsedOneOffs(
          [made(1, 0, DateTime(2026, 9, 22, 0, 1))],
          DateTime(2026, 9, 22, 23, 59),
        ),
        isNotEmpty,
      );
    });

    test('only the lapsed ones are dropped out of a mixed list', () {
      final list = [
        made(1, 0, DateTime(2026, 9, 21)),
        made(2, 0, DateTime(2026, 9, 22)),
        made(3, 0x7F, DateTime(2024, 1, 1)),
      ];
      expect(withoutLapsedOneOffs(list, now).map((r) => r.id), [2, 3]);
    });
  });

  group('remindersOnDay', () {
    Reminder reminder(int id, int daysMask, {bool enabled = true}) =>
        Reminder(
          id: id,
          title: 'reminder $id',
          iconKey: 'alarm',
          hour: 8,
          minute: 0,
          daysMask: daysMask,
          notificationsEnabled: true,
          alarmEnabled: false,
          multiStep: false,
          enabled: enabled,
          createdAt: DateTime(2026),
        );

    // 2026-09-21 was a Monday, so this whole week's dates are known weekdays.
    final monday = DateTime(2026, 9, 21);
    final wednesday = DateTime(2026, 9, 23);
    final sunday = DateTime(2026, 9, 27);

    test('a today-only reminder never appears, on any day', () {
      final list = [reminder(1, 0)];
      for (final day in [monday, wednesday, sunday]) {
        expect(remindersOnDay(list, day), isEmpty,
            reason: '$day should not show a mask-0 reminder');
      }
    });

    test('a reminder appears only on the weekdays it repeats on', () {
      // Bit 0 is Monday, bit 2 is Wednesday.
      final list = [reminder(1, 1 | 1 << 2)];
      expect(remindersOnDay(list, monday).single.id, 1);
      expect(remindersOnDay(list, wednesday).single.id, 1);
      expect(remindersOnDay(list, sunday), isEmpty);
    });

    test('every day shows an every-day reminder', () {
      final list = [reminder(1, 0x7F)];
      for (final day in [monday, wednesday, sunday]) {
        expect(remindersOnDay(list, day).single.id, 1);
      }
    });

    test('a turned-off reminder is excluded even on its own day', () {
      final list = [reminder(1, 1, enabled: false)]; // Monday, but off
      expect(remindersOnDay(list, monday), isEmpty);
    });
  });

  group('reorderSteps', () {
    // newIndex here already carries the adjustment ReorderableListView's
    // onReorderItem performs before calling the app back, so these are the
    // exact arguments the widget hands the function.
    List<StepDraft> stepsNamed(List<String> titles) =>
        [for (final t in titles) StepDraft(title: t)];

    List<String> titlesOf(List<StepDraft> steps) =>
        [for (final s in steps) s.title];

    test('moving the first step after the third lands it there', () {
      final steps = stepsNamed(['A', 'B', 'C', 'D']);
      final result = reorderSteps(steps, 0, 2);
      expect(titlesOf(result), ['B', 'C', 'A', 'D']);
    });

    test('moving the last step to the front lands it there', () {
      final steps = stepsNamed(['A', 'B', 'C', 'D']);
      final result = reorderSteps(steps, 3, 0);
      expect(titlesOf(result), ['D', 'A', 'B', 'C']);
    });

    test('dropping a step back where it started changes nothing', () {
      final steps = stepsNamed(['A', 'B', 'C']);
      final result = reorderSteps(steps, 1, 1);
      expect(titlesOf(result), ['A', 'B', 'C']);
    });

    test('every step keeps its identity across a move, not just its title',
        () {
      final steps = stepsNamed(['A', 'B', 'C']);
      final b = steps[1];
      final result = reorderSteps(steps, 1, 0);
      expect(identical(result[0], b), isTrue);
    });

    test('an out-of-range oldIndex is ignored rather than throwing', () {
      final steps = stepsNamed(['A', 'B']);
      expect(reorderSteps(steps, -1, 0), same(steps));
      expect(reorderSteps(steps, 5, 0), same(steps));
    });

    test('positions come out contiguous and in the new order', () {
      // This is what save() rewrites from, so a gap here is a gap a user
      // could see reflected in step numbering.
      final steps = stepsNamed(['A', 'B', 'C', 'D', 'E']);
      final result = reorderSteps(steps, 4, 1);
      expect(titlesOf(result), ['A', 'E', 'B', 'C', 'D']);
      expect(result.length, steps.length);
      expect(result.toSet().length, result.length,
          reason: 'no step should be duplicated or dropped by a move');
    });
  });

  group('nextIncompleteStep', () {
    ReminderStep stepAt(int id, int position, {bool completed = false}) =>
        ReminderStep(
          id: id,
          reminderId: 1,
          title: 'step $id',
          iconKey: null,
          timerSeconds: null,
          position: position,
          completed: completed,
        );

    test('finds the next one that still needs doing', () {
      final steps = [
        stepAt(1, 0, completed: true),
        stepAt(2, 1),
        stepAt(3, 2),
      ];
      expect(nextIncompleteStep(steps, 1)?.id, 2);
    });

    test('skips over ones already done to find the one after that', () {
      final steps = [
        stepAt(1, 0),
        stepAt(2, 1, completed: true),
        stepAt(3, 2),
      ];
      expect(nextIncompleteStep(steps, 1)?.id, 3);
    });

    test('never looks backward, even when an earlier step is still open',
        () {
      final steps = [
        stepAt(1, 0), // still open
        stepAt(2, 1),
        stepAt(3, 2, completed: true),
      ];
      // Finishing 2 should not send the user back to 1.
      expect(nextIncompleteStep(steps, 2), isNull);
    });

    test('the last step has nothing after it', () {
      final steps = [stepAt(1, 0), stepAt(2, 1)];
      expect(nextIncompleteStep(steps, 2), isNull);
    });

    test('a step id not in the list finds nothing', () {
      final steps = [stepAt(1, 0), stepAt(2, 1)];
      expect(nextIncompleteStep(steps, 99), isNull);
    });

    test('a single-step list has nothing after it', () {
      expect(nextIncompleteStep([stepAt(1, 0)], 1), isNull);
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
