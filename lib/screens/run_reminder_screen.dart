import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../data/database.dart';
import '../data/providers.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../util/duration_format.dart';
import '../widgets/empty_state.dart';
import '../widgets/pill_tile.dart';
import 'run_step_screen.dart';

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

/// Entry point for running a reminder. A single-step reminder goes straight to
/// the step screen; a multi-step one shows the checklist from the mockup.
///
/// Progress lives in the database, so leaving and re-entering keeps whatever
/// was already ticked off. Reset asks first, since it can undo far more than
/// one tap's worth of work; Done on a single step needs no such guard.
class RunReminderScreen extends ConsumerWidget {
  const RunReminderScreen({super.key, required this.reminderId});

  final int reminderId;

  Future<bool> _confirmDone(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).markRoutineDoneTitle),
        content: Text(AppLocalizations.of(context).markRoutineDoneMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context).markDone),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _runStep(BuildContext context, ReminderStep step) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RunStepScreen(step: step, reminderId: reminderId),
      ),
    );
  }

  Future<bool> _confirmReset(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).resetRoutineTitle),
        content: Text(AppLocalizations.of(context).resetRoutineMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context).actionReset,
                style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    return result ?? false;
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
        body: EmptyState(
          icon: Symbols.error,
          title: AppLocalizations.of(context).stepsLoadErrorTitle,
          message: AppLocalizations.of(context).loadErrorMessage,
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
            body: EmptyState(
              icon: Symbols.checklist,
              title: AppLocalizations.of(context).nothingToRunTitle,
              message: AppLocalizations.of(context).nothingToRunMessage,
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
            title: Text(AppLocalizations.of(context).progressDone(doneCount, items.length)),
          ),
          body: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final step = items[i];
              return PillTile(
                label: step.title.trim().isEmpty
                    ? AppLocalizations.of(context).stepNumber(i + 1)
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
                      // Confirmed: a routine can have far more to lose than a
                      // single step, and a stray tap should not be able to
                      // erase a morning's worth of ticks silently.
                      onPressed: doneCount == 0
                          ? null
                          : () async {
                              if (!await _confirmReset(context)) return;
                              await ref
                                  .read(repositoryProvider)
                                  .setAllCompleted(reminderId, false);
                            },
                      icon: const Icon(Symbols.refresh, size: 24),
                      label: Text(AppLocalizations.of(context).actionReset),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      // Confirmed, because Done here ticks off steps the user
                      // may not have run, and the wording is what teaches that
                      // going back is the way to leave progress alone.
                      //
                      // Once every step is ticked there is nothing left for it
                      // to do, so it goes quiet until Reset, keeping its green
                      // tick to say why.
                      onPressed: allDone
                          ? null
                          : () async {
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
                      label: Text(AppLocalizations.of(context).actionDone),
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
