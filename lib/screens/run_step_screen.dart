import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../data/database.dart';
import '../theme/app_theme.dart';
import '../widgets/cookie_timer.dart';
import '../widgets/pill_tile.dart';

/// Runs a single step. Pops `true` when the user marks it done.
class RunStepScreen extends StatefulWidget {
  const RunStepScreen({super.key, required this.step});

  final ReminderStep step;

  @override
  State<RunStepScreen> createState() => _RunStepScreenState();
}

class _RunStepScreenState extends State<RunStepScreen> {
  Timer? _ticker;
  late Duration _remaining = _total;
  bool _running = false;

  Duration get _total => Duration(seconds: widget.step.timerSeconds ?? 0);
  bool get _hasTimer => _total > Duration.zero;

  @override
  void initState() {
    super.initState();
    if (_hasTimer) _start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
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

  void _restart() {
    _ticker?.cancel();
    setState(() {
      _remaining = _total;
      _running = false;
    });
    _start();
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
                          tooltip: _running ? 'Pause' : 'Resume',
                          onTap: _running ? _pause : _start,
                        ),
                        const SizedBox(width: 24),
                        CookieTimer(remaining: _remaining, running: _running),
                        const SizedBox(width: 24),
                        _CircleControl(
                          icon: Symbols.restart_alt,
                          tooltip: 'Restart timer',
                          onTap: _restart,
                        ),
                      ],
                    )
                  : const SizedBox.expand(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: _hasTimer ? _restart : null,
                    icon: const Icon(Symbols.refresh, size: 24),
                    label: const Text('Reset'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Symbols.done_all, size: 24),
                    label: const Text('Done'),
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

class _CircleControl extends StatelessWidget {
  const _CircleControl({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(icon, size: 40, color: AppColors.onSurface),
          ),
        ),
      ),
    );
  }
}
