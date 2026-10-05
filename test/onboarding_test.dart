import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:step_reminder/l10n/app_localizations.dart';
import 'package:step_reminder/screens/onboarding_screen.dart';
import 'package:step_reminder/theme/app_theme.dart';

void main() {
  late List<bool> finished;

  Future<void> pump(WidgetTester tester) async {
    finished = [];
    await tester.pumpWidget(
      MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAppTheme(),
        home: OnboardingScreen(
          onFinished: ({required bool allowNotifications}) =>
              finished.add(allowNotifications),
        ),
      ),
    );
  }

  testWidgets('opens on the first page', (tester) async {
    await pump(tester);
    expect(find.text('One step, or a whole routine'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('Continue walks through every page', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Everything stays on your phone'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('So it can actually remind you'), findsOneWidget);

    // The last page asks rather than continuing.
    expect(find.text('Continue'), findsNothing);
    expect(find.text('Allow notifications'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
    expect(finished, isEmpty);
  });

  testWidgets('swiping back to an earlier page works', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Everything stays on your phone'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('One step, or a whole routine'), findsOneWidget);
  });

  testWidgets('a dot jumps straight to its page', (tester) async {
    await pump(tester);

    await tester.tap(find.bySemanticsLabel('Page 3 of 3'));
    await tester.pumpAndSettle();
    expect(find.text('So it can actually remind you'), findsOneWidget);
  });

  testWidgets('Skip finishes without asking for notifications',
      (tester) async {
    await pump(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(finished, [false]);
  });

  testWidgets('Skip is inert on the last page rather than moving',
      (tester) async {
    await pump(tester);

    await tester.tap(find.bySemanticsLabel('Page 3 of 3'));
    await tester.pumpAndSettle();

    // Still present, so nothing shifts under the thumb, but disabled.
    final skip = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Skip'),
    );
    expect(skip.onPressed, isNull);
  });

  testWidgets('Allow notifications finishes asking for them', (tester) async {
    await pump(tester);

    await tester.tap(find.bySemanticsLabel('Page 3 of 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Allow notifications'));
    await tester.pumpAndSettle();

    expect(finished, [true]);
  });

  testWidgets('Not now finishes without asking', (tester) async {
    await pump(tester);

    await tester.tap(find.bySemanticsLabel('Page 3 of 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(finished, [false]);
  });
}
