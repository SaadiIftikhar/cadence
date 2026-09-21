import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:step_reminder/theme/app_theme.dart';
import 'package:step_reminder/util/icon_catalog.dart';
import 'package:step_reminder/widgets/cookie_timer.dart';
import 'package:step_reminder/widgets/form_fields.dart';

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
