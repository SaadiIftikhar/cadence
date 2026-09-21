import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:step_reminder/data/database.dart';
import 'package:step_reminder/screens/run_step_screen.dart';
import 'package:step_reminder/theme/app_theme.dart';
import 'package:step_reminder/util/icon_catalog.dart';
import 'package:step_reminder/widgets/anchored_menu.dart';
import 'package:step_reminder/widgets/cookie_timer.dart';
import 'package:step_reminder/widgets/form_fields.dart';
import 'package:step_reminder/widgets/pill_tile.dart';
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
  });

  group('describeDays', () {
    test('names the common presets', () {
      expect(describeDays(0), 'Once');
      expect(describeDays(0x7F), 'Every day');
      expect(describeDays(0x1F), 'Weekdays');
      expect(describeDays(0x60), 'Weekends');
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

    testWidgets('cuts a rounded card at its corners for any count',
        (tester) async {
      // Fewer steps than sides, one per side, and more steps than sides all
      // take different branches of the corner-aligned layout.
      for (final count in [2, 3, 4, 5, 8, 9, 20]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              body: Center(
                child: SegmentedProgressBorder(
                  done: count ~/ 2,
                  total: count,
                  shape: AppShapes.card,
                  child: const SizedBox(width: 340, height: 300),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: '$count steps threw');
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

  group('Run step screen', () {
    testWidgets('Reset and Done are the same width', (tester) async {
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
                completed: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final reset =
          tester.getSize(find.widgetWithText(OutlinedButton, 'Reset'));
      final done = tester.getSize(find.widgetWithText(OutlinedButton, 'Done'));
      expect(reset.width, done.width);
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
