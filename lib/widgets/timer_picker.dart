import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_theme.dart';
import 'cookie_timer.dart';

/// Collapsible hours/minutes/seconds picker for a step's countdown.
/// A total of zero means the step has no timer.
class TimerPicker extends StatefulWidget {
  const TimerPicker({
    super.key,
    required this.seconds,
    required this.onChanged,
  });

  final int seconds;
  final ValueChanged<int> onChanged;

  @override
  State<TimerPicker> createState() => _TimerPickerState();
}

class _TimerPickerState extends State<TimerPicker> {
  late bool _expanded = widget.seconds > 0;

  void _setUnit({int? hours, int? minutes, int? secs}) {
    final s = widget.seconds;
    final h = hours ?? s ~/ 3600;
    final m = minutes ?? (s % 3600) ~/ 60;
    final sec = secs ?? s % 60;
    widget.onChanged(h * 3600 + m * 60 + sec);
  }

  @override
  Widget build(BuildContext context) {
    final seconds = widget.seconds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          shape: const StadiumBorder(side: BorderSide(color: AppColors.outline)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  const Icon(Symbols.timer, size: 28),
                  const SizedBox(width: 18),
                  const Expanded(
                    child: Text('Step timer', style: TextStyle(fontSize: 20)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(
                      seconds > 0
                          ? formatDuration(Duration(seconds: seconds))
                          : 'None',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: seconds > 0
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: AppMotion.fast,
                    child: const Icon(Symbols.arrow_drop_down, size: 30),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: AppMotion.fast,
          crossFadeState:
              _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.only(top: 22),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _UnitPicker(
                        label: 'Hours',
                        value: seconds ~/ 3600,
                        max: 23,
                        onChanged: (v) => _setUnit(hours: v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _UnitPicker(
                        label: 'Minutes',
                        value: (seconds % 3600) ~/ 60,
                        max: 59,
                        onChanged: (v) => _setUnit(minutes: v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _UnitPicker(
                        label: 'Seconds',
                        value: seconds % 60,
                        max: 59,
                        onChanged: (v) => _setUnit(secs: v),
                      ),
                    ),
                  ],
                ),
                if (seconds > 0)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => widget.onChanged(0),
                      icon: const Icon(Symbols.close, size: 20),
                      label: const Text('No timer'),
                    ),
                  ),
              ],
            ),
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _UnitPicker extends StatelessWidget {
  const _UnitPicker({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(18),
          style: const TextStyle(fontSize: 20, color: AppColors.onSurface),
          items: [
            for (var i = 0; i <= max; i++)
              DropdownMenuItem(
                value: i,
                child: Text(i.toString().padLeft(2, '0')),
              ),
          ],
          onChanged: (v) => onChanged(v ?? 0),
        ),
      ),
    );
  }
}
