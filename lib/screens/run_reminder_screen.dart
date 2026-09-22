import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../data/database.dart';
import '../data/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/cookie_timer.dart';
import '../widgets/empty_state.dart';
import '../widgets/pill_tile.dart';
import 'run_step_screen.dart';

/// Entry point for running a reminder. A single-step reminder goes straight to
/// the step screen; a multi-step one shows the checklist from the mockup.
///
/// Progress lives in the database, so leaving and re-entering keeps whatever
/// was already ticked off. Only Reset clears it.
/// A step's tick, or its countdown if it has one and is not done yet.
///
/// The tick scales in rather than appearing, which is the only acknowledgement
/// the list gives that a step was just finished.
class _StepTrailing extends StatelessWidget {
  const _StepTrailing({required this.step});

  final ReminderStep step;

  @override
  Widget build(BuildContext context) {
    final timer = step.timerSeconds;

    final Widget child;
    if (step.completed) {
      child = const Icon(
        Symbols.check_circle,
        key: ValueKey('done'),
        size: 24,
        color: AppColors.success,
      );
    } else if (timer != null && timer > 0) {
      child = Text(
        formatDuration(Duration(seconds: timer)),
        key: const ValueKey('timer'),
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      );
    } else {
      child = const SizedBox.shrink(key: ValueKey('none'));
    }

    return AnimatedSwitcher(
      duration: AppMotion.fast,
      switchInCurve: AppMotion.curve,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: child,
    );
  }
}

class RunReminderScreen extends ConsumerWidget {
  const RunReminderScreen({super.key, required this.reminderId});

  final int reminderId;

  Future<bool> _confirmDone(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark the whole routine as done?'),
        content: const Text(
          'Every step will be ticked off, including any you have not run. '
          'To leave without changing anything, go back instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mark done'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _runStep(BuildContext context, ReminderStep step) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RunStepScreen(step: step)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(stepsProvider(reminderId));

    return steps.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Symbols.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const EmptyState(
          icon: Symbols.error,
          title: 'Could not load these steps',
          message: 'Restarting the app usually clears this.',
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Symbols.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: const EmptyState(
              icon: Symbols.checklist,
              title: 'Nothing to run',
              message: 'This reminder has no steps yet.',
            ),
          );
        }

        if (items.length == 1) return RunStepScreen(step: items.first);

        final doneCount = items.where((s) => s.completed).length;
        final allDone = doneCount == items.length;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Symbols.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('$doneCount of ${items.length} done'),
          ),
          body: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final step = items[i];
              return PillTile(
                label: step.title.trim().isEmpty
                    ? 'Step ${i + 1}'
                    : step.title.trim(),
                iconKey: step.iconKey,
                dimmed: step.completed,
                onTap: () => _runStep(context, step),
                trailing: _StepTrailing(step: step),
              );
            },
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: doneCount == 0
                          ? null
                          : () => ref
                              .read(repositoryProvider)
                              .setAllCompleted(reminderId, false),
                      icon: const Icon(Symbols.refresh, size: 24),
                      label: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      // Confirmed, because Done here ticks off steps the user
                      // may not have run, and the wording is what teaches that
                      // going back is the way to leave progress alone.
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final confirmed = await _confirmDone(context);
                        if (!confirmed) return;
                        await ref
                            .read(repositoryProvider)
                            .setAllCompleted(reminderId, true);
                        navigator.pop();
                      },
                      icon: Icon(
                        Symbols.done_all,
                        size: 24,
                        color: allDone ? AppColors.success : null,
                      ),
                      label: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
