import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:step_reminder/data/database.dart';
import 'package:step_reminder/data/providers.dart';
import 'package:step_reminder/screens/run_reminder_screen.dart';
import 'package:step_reminder/screens/run_step_screen.dart';
import 'package:step_reminder/theme/app_theme.dart';

/// Exercises the routine run screen against a real database, so Done's
/// auto-advance and Reset's confirmation are proven against the actual widget
/// tree rather than against the pure functions alone.
///
/// Two things about this combination need explaining, both found by tracing
/// a genuine hang rather than guessed at:
///
/// This screen holds a live drift watch() stream open for as long as it is
/// mounted, by design, so pumpAndSettle() — which waits for the widget tree
/// to have nothing left scheduled — never returns against it. Every wait
/// here is a bounded run of pump() calls instead.
///
/// Disposing that widget makes drift schedule a zero-duration Timer
/// (StreamQueryStore.markAsClosed, cancelling the watch) rather than
/// finishing the cancellation inline. Under testWidgets' fake clock a timer
/// only fires on a pump with a positive duration, and AppDatabase.close()
/// waits for that cancellation — so closing the database right after
/// disposing the tree deadlocks waiting on a timer only a pump can fire, and
/// nothing pumps while close() is itself being awaited. finish() below pumps
/// a few times after disposal specifically to drain that before closing.
void main() {
  late Directory dir;
  late AppDatabase db;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('step_reminder_nav');
    db = AppDatabase.forTesting(NativeDatabase(File('${dir.path}/app.sqlite')));
  });

  tearDown(() {
    // finish() below is what actually closes db; if a test throws before
    // reaching it, the connection may still hold the file. The OS reclaims
    // it once this process exits, which is an acceptable trade-off for
    // teardown that must never itself be the reason a suite hangs.
    if (dir.existsSync()) {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  Future<int> addRoutine(List<String> stepTitles) async {
    final id = await db.upsertReminder(
      RemindersCompanion.insert(
        title: const Value('Morning routine'),
        iconKey: const Value('wb_sunny'),
        hour: const Value(7),
        minute: const Value(0),
        daysMask: const Value(0x7F),
        multiStep: const Value(true),
      ),
    );
    await db.replaceSteps(id, [
      for (final title in stepTitles)
        ReminderStepsCompanion.insert(reminderId: id, title: Value(title)),
    ]);
    return id;
  }

  /// Pumps enough frames for a stream emission or a finite animation
  /// (AppMotion's longest is 450ms) to land, without waiting for the
  /// screen's live query subscription to go quiet, which it never does.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pump(WidgetTester tester, int reminderId) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: RunReminderScreen(reminderId: reminderId),
        ),
      ),
    );
    await settle(tester);
  }

  /// Tears down the widget tree and only then closes the database — see the
  /// file comment above for why both the order and the extra pumps matter.
  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    await db.close();
  }

  testWidgets(
      'finishing a step in a routine moves straight to the next one left to do',
      (tester) async {
    final id = await addRoutine(['Water', 'Stretch', 'Coffee']);
    await pump(tester, id);

    await tester.tap(find.text('Water'));
    await settle(tester);
    expect(find.text('Water'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await settle(tester);

    // Landed on Stretch, not back at the routine list and not stuck on Water.
    expect(find.text('Stretch'), findsOneWidget);
    expect(find.text('Water'), findsNothing);

    await finish(tester);
  });

  testWidgets('the next step rises into place from below', (tester) async {
    final id = await addRoutine(['Water', 'Stretch']);
    await pump(tester, id);

    await tester.tap(find.text('Water'));
    await settle(tester);
    await tester.tap(find.text('Done'));

    // Scoped to the step screen: the routine list underneath names both
    // steps too, so a bare text finder could measure the wrong widget.
    final heading = find.descendant(
      of: find.byType(RunStepScreen),
      matching: find.text('Stretch'),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final entering = tester.getTopLeft(heading).dy;

    await settle(tester);
    final landed = tester.getTopLeft(heading).dy;

    // Well beyond the few pixels a scale or fade would shift it by.
    expect(entering - landed, greaterThan(50));

    await finish(tester);
  });

  testWidgets('finishing the last remaining step returns to the routine list',
      (tester) async {
    final id = await addRoutine(['Water', 'Stretch']);
    final steps = await db.stepsFor(id);
    await db.setStepCompleted(steps[0].id, true);
    await pump(tester, id);

    await tester.tap(find.text('Stretch'));
    await settle(tester);
    await tester.tap(find.text('Done'));
    await settle(tester);

    // Back on the checklist, with both steps now shown as done.
    expect(find.text('2 of 2 done'), findsOneWidget);

    await finish(tester);
  });

  testWidgets('going back from an auto-advanced step skips the finished one',
      (tester) async {
    final id = await addRoutine(['Water', 'Stretch', 'Coffee']);
    await pump(tester, id);

    await tester.tap(find.text('Water'));
    await settle(tester);
    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(find.text('Stretch'), findsOneWidget);

    // The auto-advance replaced the route, so back from Stretch goes to the
    // list directly, not back to the now-finished Water screen. Only Water
    // was ever marked done here — landing on Stretch is not finishing it.
    await tester.tap(find.byIcon(Symbols.arrow_back));
    await settle(tester);

    expect(find.text('1 of 3 done'), findsOneWidget);

    await finish(tester);
  });

  testWidgets('Reset asks first, and Cancel leaves progress untouched',
      (tester) async {
    final id = await addRoutine(['Water', 'Stretch']);
    final steps = await db.stepsFor(id);
    await db.setStepCompleted(steps[0].id, true);
    await pump(tester, id);

    expect(find.text('1 of 2 done'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await settle(tester);

    expect(find.text('Reset this routine?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);

    // The dialog is gone and nothing was cleared.
    expect(find.text('Reset this routine?'), findsNothing);
    expect(find.text('1 of 2 done'), findsOneWidget);

    await finish(tester);
  });

  testWidgets('confirming Reset clears every step', (tester) async {
    final id = await addRoutine(['Water', 'Stretch']);
    final steps = await db.stepsFor(id);
    await db.setStepCompleted(steps[0].id, true);
    await db.setStepCompleted(steps[1].id, true);
    await pump(tester, id);

    expect(find.text('2 of 2 done'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await settle(tester);
    // The confirming action shares its label with the button that opened the
    // dialog, so the dialog's own copy is targeted specifically.
    await tester.tap(find.widgetWithText(TextButton, 'Reset'));
    await settle(tester);

    expect(find.text('0 of 2 done'), findsOneWidget);

    await finish(tester);
  });

  testWidgets('Done goes quiet once every step is ticked off', (tester) async {
    final id = await addRoutine(['Water', 'Stretch']);
    final steps = await db.stepsFor(id);
    await db.setStepCompleted(steps[0].id, true);
    await pump(tester, id);

    OutlinedButton doneButton() => tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Done'),
        );

    // Still something left to do, so Done still has a job.
    expect(doneButton().onPressed, isNotNull);

    await db.setStepCompleted(steps[1].id, true);
    await settle(tester);

    expect(find.text('2 of 2 done'), findsOneWidget);
    expect(doneButton().onPressed, isNull);

    await finish(tester);
  });

  testWidgets('Reset is disabled when nothing has been done yet',
      (tester) async {
    final id = await addRoutine(['Water', 'Stretch']);
    await pump(tester, id);

    final resetButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Reset'),
    );
    expect(resetButton.onPressed, isNull);

    await finish(tester);
  });
}
