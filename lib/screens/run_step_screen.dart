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
import '../widgets/cookie_timer.dart';

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
            // Both kinds of step lead with the same thing: the icon that was
            // chosen for it and its name. A timed one shrinks that to make
            // room for the clock underneath, rather than banishing the name
            // to a pill at the top and looking like a different screen.
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StepHeading(
                    iconKey: widget.step.iconKey,
                    title: title,
                    compact: _hasTimer,
                  ),
                  if (_hasTimer) ...[
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _CircleControl(
                          icon: _running ? Symbols.pause : Symbols.play_arrow,
                          label: _running ? 'Pause' : 'Start',
                          onTap: _running ? _pause : _start,
                        ),
                        const SizedBox(width: 20),
                        CookieTimer(remaining: _remaining, running: _running),
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

/// The step's own icon with its name beneath. [compact] shrinks it to leave
/// room for a countdown; without one it fills the screen on its own.
class _StepHeading extends StatelessWidget {
  const _StepHeading({
    required this.iconKey,
    required this.title,
    required this.compact,
  });

  final String? iconKey;
  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            IconCatalog.resolve(iconKey),
            size: compact ? 64 : 112,
            color: AppColors.primary,
          ),
          SizedBox(height: compact ? 16 : 28),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 22 : 26,
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
