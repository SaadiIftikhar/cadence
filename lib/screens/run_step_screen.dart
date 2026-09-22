import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../data/database.dart';
import '../data/providers.dart';
import '../services/chime.dart';
import '../theme/app_theme.dart';
import '../util/icon_catalog.dart';
import '../widgets/timer_pill.dart';

/// Runs a single step. Pops `true` when the user leaves after marking it done.
///
/// The timer never starts on its own — the step opens paused, showing play.
class RunStepScreen extends ConsumerStatefulWidget {
  const RunStepScreen({super.key, required this.step, this.reminderId});

  final ReminderStep step;

  /// Set only when opened from within a routine's checklist, so Done can look
  /// for what comes next. Null for a reminder that is just the one step, which
  /// has nothing to advance to.
  final int? reminderId;

  @override
  ConsumerState<RunStepScreen> createState() => _RunStepScreenState();
}

class _RunStepScreenState extends ConsumerState<RunStepScreen> {
  Timer? _ticker;
  late Duration _remaining = _total;
  bool _running = false;

  /// Reopening a finished step should still look finished, so the tick starts
  /// green and Reset starts available.
  late bool _completed = widget.step.completed;

  Duration get _total => Duration(seconds: widget.step.timerSeconds ?? 0);
  bool get _hasTimer => _total > Duration.zero;
  bool get _finished => _remaining <= Duration.zero;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    // Pressing play on a finished timer runs it again from the top.
    if (_finished) _remaining = _total;
    if (_remaining <= Duration.zero) return;

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remaining -= const Duration(seconds: 1);
        if (_remaining <= Duration.zero) {
          _remaining = Duration.zero;
          _running = false;
          _ticker?.cancel();
          HapticFeedback.heavyImpact();
          Chime.instance.timerFinished();
        }
      });
    });
    setState(() => _running = true);
  }

  void _pause() {
    _ticker?.cancel();
    setState(() => _running = false);
  }

  /// Back to the full duration, still paused.
  void _restartTimer() {
    _ticker?.cancel();
    setState(() {
      _remaining = _total;
      _running = false;
    });
  }

  Future<void> _reset() async {
    _restartTimer();
    setState(() => _completed = false);
    await ref.read(repositoryProvider).markStep(widget.step.id, false);
  }

  /// Marks the step done, then moves straight to whatever comes next in the
  /// routine. That is the whole answer to a step needing "forward" navigation:
  /// Done already means "I'm finished here, take me onward," so a separate
  /// forward control would only duplicate it and raise the question of what
  /// back should do to match — a question a checklist should not have to
  /// answer, since it has no fixed order to walk back through.
  Future<void> _done() async {
    setState(() => _completed = true);
    final repo = ref.read(repositoryProvider);
    await repo.markStep(widget.step.id, true);
    if (!mounted) return;

    final reminderId = widget.reminderId;
    if (reminderId != null) {
      final steps = await ref.read(databaseProvider).stepsFor(reminderId);
      final next = nextIncompleteStep(steps, widget.step.id);
      if (next != null) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                RunStepScreen(step: next, reminderId: reminderId),
          ),
        );
        return;
      }
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.step.title.trim().isEmpty ? 'Step' : widget.step.title.trim();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Both kinds of step lead with exactly the same thing, at the
            // same size: the icon that was chosen for it and its name. A
            // timed step used to shrink this to make room for a clock beside
            // it; now the clock is a row of its own underneath, so the two
            // kinds of step look identical until you reach it.
            Expanded(
              child: Padding(
                // A floor under the natural centring, so the controls read as
                // sitting a little below the heading and a little above the
                // Reset/Done row even when the content nearly fills the space.
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StepHeading(iconKey: widget.step.iconKey, title: title),
                    if (_hasTimer) ...[
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _CircleControl(
                            icon:
                                _running ? Symbols.pause : Symbols.play_arrow,
                            label: _running ? 'Pause' : 'Start',
                            onTap: _running ? _pause : _start,
                          ),
                          const SizedBox(width: 20),
                          TimerPill(remaining: _remaining, total: _total),
                          const SizedBox(width: 20),
                          _CircleControl(
                            icon: Symbols.restart_alt,
                            label: 'Back to full time',
                            onTap: _restartTimer,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      // Undoes completion, so there is nothing to undo until
                      // the step has been marked done. Putting the timer back
                      // to full is the control next to the timer itself.
                      onPressed: _completed ? _reset : null,
                      icon: const Icon(Symbols.refresh, size: 24),
                      label: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _done,
                      icon: Icon(
                        Symbols.done_all,
                        size: 24,
                        color: _completed ? AppColors.success : null,
                      ),
                      label: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The step's own icon with its name beneath, always at the same size and
/// position whether or not the step has a timer.
class _StepHeading extends StatelessWidget {
  const _StepHeading({required this.iconKey, required this.title});

  final String? iconKey;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            IconCatalog.resolve(iconKey),
            size: 112,
            color: AppColors.primary,
          ),
          const SizedBox(height: 28),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 26,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleControl extends StatelessWidget {
  const _CircleControl({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(
            icon,
            size: 40,
            color: AppColors.onSurface,
            semanticLabel: label,
          ),
        ),
      ),
    );
  }
}
