import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../data/database.dart';
import '../data/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/cookie_timer.dart';
import '../widgets/pill_tile.dart';
import 'run_step_screen.dart';

/// Entry point for running a reminder. A single-step reminder goes straight to
/// the step screen; a multi-step one shows the checklist from the mockup.
///
/// Progress lives in the database, so leaving and re-entering keeps whatever
/// was already ticked off. Only Reset clears it.
class RunReminderScreen extends ConsumerWidget {
  const RunReminderScreen({super.key, required this.reminderId});

  final int reminderId;

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
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Could not load steps.\n$e')),
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
            body: const Center(child: Text('This reminder has no steps.')),
          );
        }

        if (items.length == 1) return RunStepScreen(step: items.first);

        final doneCount = items.where((s) => s.completed).length;
        final currentIndex = items.indexWhere((s) => !s.completed);

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
                filled: i == currentIndex,
                dimmed: step.completed,
                onTap: () => _runStep(context, step),
                trailing: step.completed
                    ? const Icon(Symbols.check_circle,
                        size: 24, color: AppColors.success)
                    : (step.timerSeconds != null && step.timerSeconds! > 0
                        ? Text(
                            formatDuration(
                                Duration(seconds: step.timerSeconds!)),
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null),
              );
            },
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: doneCount == 0
                        ? null
                        : () => ref
                            .read(repositoryProvider)
                            .clearCompletion(reminderId),
                    icon: const Icon(Symbols.refresh, size: 24),
                    label: const Text('Reset'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Symbols.done_all,
                      size: 24,
                      color: currentIndex == -1 ? AppColors.success : null,
                    ),
                    label: const Text('Done'),
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
