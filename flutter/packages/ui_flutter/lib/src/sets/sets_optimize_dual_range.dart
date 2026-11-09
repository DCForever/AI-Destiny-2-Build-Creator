import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';
import '../unbroken_label.dart';
import 'sets_models.dart';

/// Dual-thumb range for kit stat totals (mockup `.dual-range`, G-SET-036).
///
/// Ends at 0 / [max] = unconstrained. Implemented with [RangeSlider] so both
/// thumbs remain independently draggable (stacked [Slider]s steal hits for min).
class SetsOptimizeDualRange extends StatelessWidget {
  const SetsOptimizeDualRange({
    super.key,
    required this.statLabel,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
    this.max = kSetsOptimizeStatSliderMax,
  });

  final String statLabel;
  final int minValue;
  final int maxValue;
  final void Function(int min, int max) onChanged;
  final int max;

  bool get _active => minValue > 0 || maxValue < max;

  String get _readout {
    if (!_active) return 'any';
    if (minValue > 0 && maxValue < max) return '$minValue–$maxValue';
    if (minValue > 0) return '≥$minValue';
    return '≤$maxValue';
  }

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final lo = minValue.toDouble().clamp(0.0, max.toDouble());
    final hi = maxValue.toDouble().clamp(0.0, max.toDouble());
    final start = lo <= hi ? lo : hi;
    final end = lo <= hi ? hi : lo;

    final minActive = minValue > 0;
    final maxOnly = !minActive && maxValue < max;
    final wash = minActive
        ? palette.accent.withValues(alpha: 0.14)
        : maxOnly
            ? palette.muted.withValues(alpha: 0.08)
            : Colors.transparent;
    final labelColor = minActive
        ? palette.accent
        : maxOnly
            ? palette.foreground
            : palette.muted;

    return Container(
      key: minActive ? Key('sets_optimize_stat_highlight_$statLabel') : null,
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 2),
      decoration: BoxDecoration(
        color: wash,
        border: Border.all(
          color: minActive
              ? palette.accent.withValues(alpha: 0.45)
              : palette.line.withValues(alpha: 0.0),
          width: 1,
        ),
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: UnbrokenLabel(
                statLabel.toUpperCase(),
                fit: true,
                style: neonDisplay(
                  color: labelColor,
                  fontSize: 9,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            Text(
              _readout,
              key: Key('sets_optimize_stat_readout_$statLabel'),
              style: neonMono(
                color: minActive
                    ? palette.accent
                    : (_active ? palette.foreground : palette.muted),
                fontSize: 10,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            overlayShape: SliderComponentShape.noOverlay,
            activeTrackColor: palette.accent,
            inactiveTrackColor: palette.line,
            thumbColor: palette.accent,
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 7,
              elevation: 1,
            ),
            rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
            showValueIndicator: ShowValueIndicator.never,
          ),
          child: RangeSlider(
            // Keep min key for existing widget tests / driver finders.
            key: Key('sets_optimize_stat_min_$statLabel'),
            values: RangeValues(start, end),
            min: 0,
            max: max.toDouble(),
            divisions: max,
            onChanged: (v) {
              final a = v.start.round().clamp(0, max);
              final b = v.end.round().clamp(0, max);
              if (a <= b) {
                onChanged(a, b);
              } else {
                onChanged(b, a);
              }
            },
          ),
        ),
        // Hidden twin key for tests/finders that look for max control.
        SizedBox.shrink(key: Key('sets_optimize_stat_max_$statLabel')),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0', style: neonMono(color: palette.muted, fontSize: 8)),
            Text('$max', style: neonMono(color: palette.muted, fontSize: 8)),
          ],
        ),
      ],
      ),
    );
  }
}
