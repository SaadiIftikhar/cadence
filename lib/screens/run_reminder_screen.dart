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
class RunReminderScreen extends ConsumerStatefulWidget {
  const RunReminderScreen({super.key, required this.reminderId});

  final int reminderId;

  @override
  ConsumerState<RunReminderScreen> createState() => _RunReminderScreenState();
}

class _RunReminderScreenState extends ConsumerState<RunReminderScreen> {
  final _completed = <int>{};

  Future<void> _runStep(ReminderStep step) async {
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RunStepScreen(step: step)),
    );
    if (done == true && mounted) {
      setState(() => _completed.add(step.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = ref.watch(stepsProvider(widget.reminderId));

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

        final allDone = items.every((s) => _completed.contains(s.id));
        final currentIndex =
            items.indexWhere((s) => !_completed.contains(s.id));

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Symbols.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('${_completed.length} of ${items.length} done'),
          ),
          body: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final step = items[i];
              final done = _completed.contains(step.id);
              return PillTile(
                label: step.title.trim().isEmpty
                    ? 'Step ${i + 1}'
                    : step.title.trim(),
                iconKey: step.iconKey,
                filled: i == currentIndex,
                dimmed: done,
                onTap: () => _runStep(step),
                trailing: done
                    ? const Icon(Symbols.check_circle,
                        size: 24, color: AppColors.primary)
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
                    onPressed: _completed.isEmpty
                        ? null
                        : () => setState(_completed.clear),
                    icon: const Icon(Symbols.refresh, size: 24),
                    label: const Text('Reset'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Symbols.done_all,
                      size: 24,
                      color: allDone ? AppColors.primary : null,
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
