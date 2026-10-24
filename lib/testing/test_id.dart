import 'package:flutter/widgets.dart';

/// Gives [child] a stable id for UI automation.
///
/// The id is carried by [Semantics.identifier], which Android exposes as the
/// accessibility node's `resource-id` and iOS as `accessibilityIdentifier`.
/// Nothing reads it aloud and nothing draws it, so it costs users nothing.
/// What it buys is a handle for end-to-end tests that survives copy changes
/// and translation, which text labels do not.
///
/// By default the id and everything beneath it become one node, so a tagged
/// button reports its own label, enabled state and tap action under the id.
/// Pass `merge: false` when [child] holds a second tap target of its own that
/// must stay separately reachable, such as a row with a tappable icon in it.
class TestId extends StatelessWidget {
  const TestId(this.id, {super.key, required this.child, this.merge = true});

  final String id;
  final Widget child;
  final bool merge;

  @override
  Widget build(BuildContext context) {
    final tagged = Semantics(identifier: id, child: child);
    return merge ? MergeSemantics(child: tagged) : tagged;
  }
}
