import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:step_reminder/screens/icon_picker_screen.dart';
import 'package:step_reminder/theme/app_theme.dart';
import 'package:step_reminder/util/icon_catalog.dart';

void main() {
  Future<String?> pump(WidgetTester tester) async {
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  picked = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) => const IconPickerScreen(),
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
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return picked;
  }

  testWidgets('opens on the suggested icons', (tester) async {
    await pump(tester);
    expect(find.byIcon(IconCatalog.resolve(IconCatalog.suggested.first)),
        findsOneWidget);
  });

  testWidgets('searching is debounced, then narrows the grid', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'hourglass');

    // Nothing has changed yet: the search waits for a pause in typing.
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byIcon(IconCatalog.resolve('hourglass')), findsNothing);

    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byIcon(IconCatalog.resolve('hourglass')), findsOneWidget);
  });

  testWidgets('fast typing only searches for the final text', (tester) async {
    await pump(tester);

    for (final text in ['h', 'ho', 'hou', 'hour', 'hourglass']) {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump(const Duration(milliseconds: 40));
    }
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byIcon(IconCatalog.resolve('hourglass')), findsOneWidget);
  });

  testWidgets('clearing returns to the suggested icons at once',
      (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'hourglass');
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byIcon(Symbols.close));
    await tester.pumpAndSettle();

    expect(find.byIcon(IconCatalog.resolve(IconCatalog.suggested.first)),
        findsOneWidget);
  });

  testWidgets('a search that matches nothing says so', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'zzzzzzzznotanicon');
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('No icons match that search.'), findsOneWidget);
  });
}
