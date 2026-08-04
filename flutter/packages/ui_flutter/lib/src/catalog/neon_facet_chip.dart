import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../bungie_content_icon.dart';
import '../destiny_official_icons.dart';
import '../flap_palette.dart';
import '../neon_fonts.dart';

/// Facet chip: off → include → exclude → off (OR-within / exclude drop).
///
/// Prefer [icon] / official Destiny visuals over mock Unicode. When [value]
/// matches an element or ammo name, official CDN icons are used automatically.
class NeonFacetChip extends StatelessWidget {
  const NeonFacetChip({
    super.key,
    required this.label,
    required this.state,
    required this.onCycle,
    this.tooltip,
    this.color,
    this.value,
    this.icon,
    this.iconOnly = false,
  });

  final String label;
  final FacetChipState state;
  final VoidCallback onCycle;
  final String? tooltip;
  final Color? color;

  /// Raw facet value (e.g. `Void`, `Heavy`) for official icon lookup.
  final String? value;

  /// Optional leading icon override (official PNG preferred).
  final Widget? icon;

  /// When true, show only the icon (+ state mark); label stays in tooltip/a11y.
  final bool iconOnly;

  bool get isInclude => state == FacetChipState.include;
  bool get isExclude => state == FacetChipState.exclude;
  bool get isActive => state != FacetChipState.off;

  DestinyOfficialVisual? get _official {
    final v = value ?? label;
    return officialElementVisual(v) ?? officialAmmoVisual(v);
  }

  /// Slot letter (K/E/P) when no official PNG — structure chrome only.
  String? get _slotLetter {
    switch ((value ?? label).trim().toLowerCase()) {
      case 'kinetic':
        return 'K';
      case 'energy':
        return 'E';
      case 'power':
        return 'P';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final official = _official;
    final accent = color ?? official?.color ?? palette.accent;
    final selected = isActive;
    final exclude = isExclude;
    final slotLetter = _slotLetter;

    Widget? avatar = icon;
    if (avatar == null && official != null) {
      // Chip/Tooltip provide the name; keep CDN icon non-semantic (Windows AX).
      avatar = DestinyOfficialIcon(
        visual: official,
        size: 14,
      );
    } else if (avatar == null && iconOnly && slotLetter != null) {
      avatar = Text(
        slotLetter,
        style: neonMono(
          color: accent,
          fontSize: 12,
          letterSpacing: 0,
        ),
      );
    }
    if (!iconOnly) {
      avatar ??= switch (state) {
        FacetChipState.include => Icon(Icons.add, size: 16, color: accent),
        FacetChipState.exclude =>
          Icon(Icons.remove, size: 16, color: palette.danger),
        FacetChipState.off => null,
      };
    }

    final chip = FilterChip(
      label: iconOnly
          ? (avatar != null
              ? const SizedBox(width: 0, height: 0)
              : Text(
                  slotLetter ??
                      (label.isNotEmpty ? label[0].toUpperCase() : '?'),
                  style: neonMono(color: accent, fontSize: 12),
                ))
          : Text(
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
      avatar: iconOnly ? avatar : avatar,
      showCheckmark: !iconOnly && official == null,
      padding: iconOnly ? const EdgeInsets.all(4) : null,
      labelPadding: iconOnly ? EdgeInsets.zero : null,
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
    this.compact = false,
  });

  /// null = any, true = only exotic, false = exclude exotic.
  final bool? exotic;
  final VoidCallback onCycle;

  /// Dense primary-line form: short label, full text in tooltip.
  final bool compact;

  String get label {
    if (exotic == true) return compact ? '✦ only' : 'Exotic only';
    if (exotic == false) return compact ? 'No ✦' : 'No exotic';
    return compact ? '✦' : 'Exotic: any';
  }

  String get tooltip {
    if (exotic == true) return 'Exotic only (tap to cycle)';
    if (exotic == false) return 'Exclude exotic (tap to cycle)';
    return 'Exotic: any (tap to cycle)';
  }

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: FilterChip(
        key: const Key('exotic_chip'),
        label: Text(
          label,
          style: neonMono(
            color: exotic == false
                ? palette.danger
                : exotic == true
                    ? const Color(kRarityExotic)
                    : palette.foreground,
            fontSize: compact ? 10 : 11,
          ),
        ),
        selected: exotic != null,
        onSelected: (_) => onCycle(),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: compact ? const EdgeInsets.symmetric(horizontal: 4) : null,
      ),
    );
  }
}
