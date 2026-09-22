import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../data/database.dart';
import '../data/providers.dart';
import '../theme/app_theme.dart';
import '../util/icon_catalog.dart';
import '../widgets/cookie_timer.dart';
import '../widgets/pill_tile.dart';

/// Runs a single step. Pops `true` when the user marks it done.
///
/// The timer never starts on its own — the step opens paused, showing play.
class RunStepScreen extends ConsumerStatefulWidget {
  const RunStepScreen({super.key, required this.step});

  final ReminderStep step;

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

  Future<void> _done() async {
    setState(() => _completed = true);
    await ref.read(repositoryProvider).markStep(widget.step.id, true);
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
            // A timed step needs its name out of the way at the top, because
            // the middle belongs to the clock. A step with no timer has that
            // space going spare, so the name takes it.
            if (_hasTimer)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: PillTile(
                  label: title,
                  iconKey: widget.step.iconKey,
                  filled: true,
                ),
              ),
            Expanded(
              child: _hasTimer
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _CircleControl(
                          icon: _running ? Symbols.pause : Symbols.play_arrow,
                          label: _running ? 'Pause' : 'Start',
                          onTap: _running ? _pause : _start,
                        ),
                        const SizedBox(width: 24),
                        CookieTimer(remaining: _remaining, running: _running),
                        const SizedBox(width: 24),
                        _CircleControl(
                          icon: Symbols.restart_alt,
                          label: 'Back to full time',
                          onTap: _restartTimer,
                        ),
                      ],
                    )
                  : _StepFocus(iconKey: widget.step.iconKey, title: title),
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

/// What a step with no timer shows: its own icon, large, with its name under
/// it, occupying the space a countdown would have had.
class _StepFocus extends StatelessWidget {
  const _StepFocus({required this.iconKey, required this.title});

  final String? iconKey;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
