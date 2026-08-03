import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';

/// Facet chip: off → include → exclude → off (OR-within / exclude drop).
class NeonFacetChip extends StatelessWidget {
  const NeonFacetChip({
    super.key,
    required this.label,
    required this.state,
    required this.onCycle,
    this.tooltip,
    this.color,
  });

  final String label;
  final FacetChipState state;
  final VoidCallback onCycle;
  final String? tooltip;
  final Color? color;

  bool get isInclude => state == FacetChipState.include;
  bool get isExclude => state == FacetChipState.exclude;
  bool get isActive => state != FacetChipState.off;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final accent = color ?? palette.accent;
    final selected = isActive;
    final exclude = isExclude;

    final chip = FilterChip(
      label: Text(
        label,
        style: TextStyle(
          decoration: exclude ? TextDecoration.lineThrough : null,
          color: exclude ? palette.danger : null,
        ),
      ),
      selected: selected,
      selectedColor: exclude
          ? palette.danger.withValues(alpha: 0.12)
          : accent.withValues(alpha: 0.18),
      checkmarkColor: exclude ? palette.danger : accent,
      onSelected: (_) => onCycle(),
      avatar: switch (state) {
        FacetChipState.include => Icon(Icons.add, size: 16, color: accent),
        FacetChipState.exclude =>
          Icon(Icons.remove, size: 16, color: palette.danger),
        FacetChipState.off => null,
      },
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(
        color: exclude
            ? palette.danger.withValues(alpha: 0.45)
            : selected
                ? accent.withValues(alpha: 0.45)
                : palette.line,
        width: kFlapRuleThickness,
      ),
    );

    final tip = tooltip ??
        (exclude
            ? 'Exclude $label (tap to cycle)'
            : selected
                ? 'Include $label (tap to cycle)'
                : 'Filter $label (tap include → exclude → off)');

    return Tooltip(message: tip, child: chip);
  }
}

/// Compact exotic tri-state chip (any → only → exclude → any).
class NeonExoticChip extends StatelessWidget {
  const NeonExoticChip({
    super.key,
    required this.exotic,
    required this.onCycle,
  });

  /// null = any, true = only exotic, false = exclude exotic.
  final bool? exotic;
  final VoidCallback onCycle;

  String get label {
    if (exotic == true) return 'Exotic only';
    if (exotic == false) return 'No exotic';
    return 'Exotic: any';
  }

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return FilterChip(
      key: const Key('exotic_chip'),
      label: Text(
        label,
        style: neonMono(
          color: exotic == false ? palette.danger : palette.foreground,
          fontSize: 11,
        ),
      ),
      selected: exotic != null,
      onSelected: (_) => onCycle(),
      visualDensity: VisualDensity.compact,
    );
  }
}
