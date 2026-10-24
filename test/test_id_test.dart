import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:step_reminder/testing/test_id.dart';
import 'package:step_reminder/testing/test_ids.dart';

/// The end-to-end suite finds widgets by these ids, read from the Android
/// accessibility tree. These tests pin down that each id lands on the node a
/// test needs: the one carrying the label, state and tap action.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: child))));

  SemanticsData dataFor(WidgetTester tester, String id) =>
      tester.getSemantics(find.bySemanticsIdentifier(id)).getSemanticsData();

  testWidgets('a tagged button carries its own label, state and tap',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      TestId('go', child: FilledButton(onPressed: () {}, child: const Text('Go'))),
    );

    final data = dataFor(tester, 'go');
    expect(data.label, 'Go');
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.flagsCollection.isEnabled, Tristate.isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    handle.dispose();
  });

  testWidgets('a disabled tagged button reports itself disabled',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      const TestId('go', child: FilledButton(onPressed: null, child: Text('Go'))),
    );

    expect(dataFor(tester, 'go').flagsCollection.isEnabled, Tristate.isFalse);
    handle.dispose();
  });

  testWidgets('a tagged tile merges its texts into one label', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      TestId(
        TestIds.reminderCard,
        child: InkWell(
          onTap: () {},
          child: const Column(children: [Text('Stretch'), Text('8:00 AM')]),
        ),
      ),
    );

    final data = dataFor(tester, TestIds.reminderCard);
    expect(data.label, 'Stretch\n8:00 AM');
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    handle.dispose();
  });

  testWidgets('a tagged switch row reports whether it is on', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      TestId(
        TestIds.editorAlarm,
        child: Row(children: [
          const Text('Alarm'),
          Switch(value: true, onChanged: (_) {}),
        ]),
      ),
    );

    final data = dataFor(tester, TestIds.editorAlarm);
    expect(data.label, 'Alarm');
    expect(data.flagsCollection.isToggled, Tristate.isTrue);
    handle.dispose();
  });

  testWidgets('a tagged text field stays a text field, icon button apart',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      TestId(
        TestIds.editorTitleField,
        merge: false,
        child: TextField(
          decoration: InputDecoration(
            labelText: 'Step title',
            prefixIcon: TestId(
              TestIds.editorIcon,
              child: IconButton(onPressed: () {}, icon: const Icon(Icons.star)),
            ),
          ),
        ),
      ),
    );

    expect(dataFor(tester, TestIds.editorTitleField).flagsCollection.isTextField,
        isTrue);
    expect(dataFor(tester, TestIds.editorIcon).hasAction(SemanticsAction.tap),
        isTrue);
    handle.dispose();
  });

  testWidgets('merge: false keeps a tagged inner button reachable on its own',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      TestId(
        TestIds.editorStepRow,
        merge: false,
        child: InkWell(
          onTap: () {},
          child: Row(children: [
            TestId(
              TestIds.editorStepIcon,
              child: IconButton(onPressed: () {}, icon: const Icon(Icons.star)),
            ),
            const Text('Make bed'),
          ]),
        ),
      ),
    );

    expect(dataFor(tester, TestIds.editorStepRow).label, contains('Make bed'));
    expect(
      dataFor(tester, TestIds.editorStepIcon).hasAction(SemanticsAction.tap),
      isTrue,
    );
    handle.dispose();
  });
}
