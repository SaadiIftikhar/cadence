import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_theme.dart';

/// A stadium row that names a setting and shows its current value.
/// Used for the time and repeat pickers so both read the same way.
class ValuePill extends StatelessWidget {
  const ValuePill({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.placeholder = false,
    this.invalid = false,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Dims the value when nothing has been chosen yet.
  final bool placeholder;

  /// Reddens the outline when a save was attempted without this filled in.
  final bool invalid;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: invalid ? AppColors.danger : AppColors.outline,
          width: invalid ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: [
              Icon(icon, size: 26, color: AppColors.onSurface),
              const SizedBox(width: 18),
              Text(label,
                  style: const TextStyle(
                      fontSize: 19, color: AppColors.onSurface)),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: placeholder
                        ? AppColors.onSurfaceVariant
                        : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Symbols.chevron_right,
                  size: 24, color: AppColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Human-readable summary of a weekday [mask]. Bit 0 is Monday.
String describeDays(int mask) {
  if (mask == 0) return 'Once';
  if (mask == 0x7F) return 'Every day';
  if (mask == 0x1F) return 'Weekdays';
  if (mask == 0x60) return 'Weekend';

  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return [
    for (var i = 0; i < 7; i++)
      if (mask & (1 << i) != 0) names[i],
  ].join(', ');
}

/// One-tap shortcuts for the selections people actually reach for. The labels
/// match what [describeDays] reports back, so the dialog uses one vocabulary.
const _dayPresets = <({String label, int mask})>[
  (label: 'Every day', mask: 0x7F),
  (label: 'Weekdays', mask: 0x1F),
  (label: 'Weekend', mask: 0x60),
];

/// Opens the weekday chips in a dialog. Returns null if dismissed.
Future<int?> showDayPickerDialog(BuildContext context, int mask) {
  return showDialog<int>(
    context: context,
    builder: (ctx) {
      var local = mask;
      return StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Repeat on'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DaySelector(
                  mask: local,
                  onChanged: (m) => setLocal(() => local = m),
                ),
                const SizedBox(height: 18),
                Text(
                  describeDays(local),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    for (var i = 0; i < _dayPresets.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _PresetChip(
                          label: _dayPresets[i].label,
                          selected: local == _dayPresets[i].mask,
                          onTap: () =>
                              setLocal(() => local = _dayPresets[i].mask),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, local),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    },
  );
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.outline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.onPrimary : AppColors.onSurface,
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
          height: 52,
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
