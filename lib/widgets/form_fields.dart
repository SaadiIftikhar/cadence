import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// `HH : MM` boxes with the stacked AM/PM selector from the New/Edit mockups.
class TimeField extends StatelessWidget {
  const TimeField({super.key, required this.time, required this.onChanged});

  final TimeOfDay? time;
  final ValueChanged<TimeOfDay> onChanged;

  bool get _isPm => (time?.period ?? DayPeriod.pm) == DayPeriod.pm;

  String get _hourText {
    final t = time;
    if (t == null) return 'HH';
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    return h.toString().padLeft(2, '0');
  }

  String get _minuteText =>
      time == null ? 'MM' : time!.minute.toString().padLeft(2, '0');

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: time ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) onChanged(picked);
  }

  void _setPeriod(DayPeriod period) {
    final t = time ?? const TimeOfDay(hour: 8, minute: 0);
    if (t.period == period) return;
    final shifted = period == DayPeriod.pm ? t.hour + 12 : t.hour - 12;
    onChanged(TimeOfDay(hour: shifted % 24, minute: t.minute));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _TimeBox(text: _hourText, onTap: () => _pick(context)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(':', style: TextStyle(fontSize: 40, color: AppColors.onSurface)),
        ),
        _TimeBox(text: _minuteText, onTap: () => _pick(context)),
        const SizedBox(width: 12),
        _PeriodToggle(
          isPm: _isPm,
          onChanged: _setPeriod,
        ),
      ],
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 98,
          height: 74,
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 44,
                color: AppColors.onSurface,
                fontWeight: FontWeight.w400,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({required this.isPm, required this.onChanged});

  final bool isPm;
  final ValueChanged<DayPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 74,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _PeriodHalf(
            label: 'AM',
            selected: !isPm,
            onTap: () => onChanged(DayPeriod.am),
          ),
          _PeriodHalf(
            label: 'PM',
            selected: isPm,
            onTap: () => onChanged(DayPeriod.pm),
          ),
        ],
      ),
    );
  }
}

class _PeriodHalf extends StatelessWidget {
  const _PeriodHalf({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.accentPink : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.onAccentPink : AppColors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// M T W T F S S selector. [mask] bit 0 is Monday through bit 6 Sunday.
class DaySelector extends StatelessWidget {
  const DaySelector({super.key, required this.mask, required this.onChanged});

  final int mask;
  final ValueChanged<int> onChanged;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 7),
          Expanded(
            child: _DayChip(
              label: _labels[i],
              selected: mask & (1 << i) != 0,
              // Outer edges of the group are rounder, matching the mockup.
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(i == 0 ? 24 : 10),
                right: Radius.circular(i == 6 ? 24 : 10),
              ),
              onTap: () => onChanged(mask ^ (1 << i)),
            ),
          ),
        ],
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.borderRadius,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.outline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.onPrimary : AppColors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LabeledSwitch extends StatelessWidget {
  const LabeledSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 21, color: AppColors.onSurface),
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
