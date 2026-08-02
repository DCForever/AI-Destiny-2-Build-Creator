/// Neon Network segmented tabs (Vex docs `.tab` / settings category rail).
///
/// Cyan only on the selected segment (≤1 strong signal). Hairline structure
/// elsewhere. Mono uppercase labels.
library;

import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import 'flap_palette.dart';
import 'neon_fonts.dart';

/// One option in a [NeonSegmentedTabs] control.
class NeonSegmentOption {
  const NeonSegmentOption({
    required this.id,
    required this.label,
    this.key,
  });

  final String id;
  final String label;
  final Key? key;
}

/// Horizontal mono uppercase segments — selected = cyan wash + accent type.
class NeonSegmentedTabs extends StatelessWidget {
  const NeonSegmentedTabs({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onSelected,
    this.dense = false,
  });

  final List<NeonSegmentOption> options;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Wrap(
      spacing: kSpace8,
      runSpacing: kSpace8,
      children: [
        for (final o in options)
          _Segment(
            option: o,
            selected: o.id == selectedId,
            dense: dense,
            palette: palette,
            onTap: () => onSelected(o.id),
          ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.option,
    required this.selected,
    required this.dense,
    required this.palette,
    required this.onTap,
  });

  final NeonSegmentOption option;
  final bool selected;
  final bool dense;
  final FlapPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final minH = dense ? 36.0 : 40.0;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: option.key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadiusMax),
        focusColor: palette.accent.withValues(alpha: 0.14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          constraints: BoxConstraints(minHeight: minH),
          padding: EdgeInsets.symmetric(
            horizontal: dense ? kSpace12 : 14,
            vertical: dense ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? palette.accent.withValues(alpha: 0.10)
                : palette.surface.withValues(alpha: 0.50),
            borderRadius: BorderRadius.circular(kRadiusMax),
            border: Border.all(
              color: selected
                  ? palette.accent.withValues(alpha: 0.35)
                  : palette.line.withValues(alpha: 0.5),
              width: kFlapRuleThickness,
            ),
          ),
          child: Text(
            option.label.toUpperCase(),
            style: neonMono(
              color: selected ? palette.accent : palette.muted,
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

/// Page kicker + Orbitron title + optional subtitle (Vex docs header pattern).
class NeonPageHeader extends StatelessWidget {
  const NeonPageHeader({
    super.key,
    required this.title,
    this.kicker,
    this.subtitle,
    this.trailing,
    this.titleKey,
  });

  final String title;
  final String? kicker;
  final String? subtitle;
  final Widget? trailing;
  final Key? titleKey;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(kSpace16, kSpace12, kSpace16, kSpace8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kicker != null && kicker!.trim().isNotEmpty)
                  Text(
                    kicker!.toUpperCase(),
                    style: neonMono(
                      color: palette.muted.withValues(alpha: 0.9),
                      fontSize: 11,
                      letterSpacing: 1.4,
                    ),
                  ),
                if (kicker != null) const SizedBox(height: kSpace8),
                Text(
                  title.toUpperCase(),
                  key: titleKey,
                  style: neonDisplay(
                    color: palette.foreground,
                    fontSize: 20,
                    letterSpacing: 0.06 * 20,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: kSpace8),
                  Text(
                    subtitle!,
                    style: neonBody(
                      color: palette.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
