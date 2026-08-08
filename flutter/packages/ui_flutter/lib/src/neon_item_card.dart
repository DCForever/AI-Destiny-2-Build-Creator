/// Neon Network catalog item card.
///
/// Soft surface + rarity wash + **element bloom**. Bottom band aligns the
/// element disc with meta icons: **element · type · slot · ammo · frame**
/// (+ ×N / power). Weapon type is a silhouette (or letter last-resort), never
/// body text. Optional [footer] (Base/Adept chips) sits just above that band.
///
/// HTML mockups use Unicode placeholders (no Bungie CDN). Implement against
/// [destiny_official_icons] — not mock glyph/color inventions.
library;

import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import 'bungie_content_icon.dart';
import 'destiny_official_icons.dart';
import 'flap_element.dart';
import 'flap_palette.dart';
import 'neon_fonts.dart';

/// Rarity band for catalog cards.
enum NeonItemRarity {
  common,
  rare,
  legendary,
  exotic,
}

/// Parses common rarity labels / exotic flag into [NeonItemRarity].
NeonItemRarity neonItemRarity({
  bool isExotic = false,
  String? rarityLabel,
}) {
  if (isExotic) return NeonItemRarity.exotic;
  final r = (rarityLabel ?? '').trim().toLowerCase();
  if (r.contains('exotic')) return NeonItemRarity.exotic;
  if (r.contains('legendary')) return NeonItemRarity.legendary;
  if (r.contains('rare')) return NeonItemRarity.rare;
  return NeonItemRarity.common;
}

/// Compact rarity badge mark (UI chrome only — not a Bungie entity icon).
String neonRarityMark(NeonItemRarity rarity) {
  switch (rarity) {
    case NeonItemRarity.exotic:
      return '✦';
    case NeonItemRarity.legendary:
      return '◆';
    case NeonItemRarity.rare:
    case NeonItemRarity.common:
      return '·';
  }
}

/// Offline / mock fallback only — prefer [officialElementVisual] icons in UI.
String neonElementGlyphMark(String? element) {
  switch ((element ?? '').trim().toLowerCase()) {
    case 'void':
      return '❖';
    case 'solar':
      return '☀';
    case 'arc':
      return '⚡';
    case 'stasis':
      return '❄';
    case 'strand':
      return '⎔';
    case 'prismatic':
      return '✦';
    case 'kinetic':
    default:
      return '●';
  }
}

/// Offline / mock fallback only — prefer [officialAmmoVisual] icons in UI.
String neonAmmoGlyphMark(String? ammo) {
  switch ((ammo ?? '').trim().toLowerCase()) {
    case 'heavy':
      return '▲';
    case 'special':
      return '◈';
    case 'primary':
    default:
      return '●';
  }
}

/// Slot foot letter (no stable weapon-bucket icon in destiny-icons).
String neonSlotGlyphMark(String? slot) {
  switch ((slot ?? '').trim().toLowerCase()) {
    case 'kinetic':
      return 'K';
    case 'energy':
      return 'E';
    case 'power':
      return 'P';
    default:
      final s = (slot ?? '').trim();
      return s.isEmpty ? '?' : s[0].toUpperCase();
  }
}

/// Compact construct card for weapons / armor / catalog hits.
class NeonItemCard extends StatelessWidget {
  const NeonItemCard({
    super.key,
    required this.name,
    this.slot,
    this.element,
    this.ammo,
    this.frame,
    this.typeLine,
    this.rarity = NeonItemRarity.common,
    this.power,
    this.ownedLabel,
    this.leading,
    this.footer,
    this.selected = false,
    this.onTap,
    this.nameKey,
    this.metaKey,
    this.ownedKey,
    this.minHeight = 100,
  });

  final String name;
  final String? slot;
  final String? element;
  final String? ammo;
  final String? frame;

  /// Weapon type name for silhouette lookup + a11y (not rendered as body text).
  final String? typeLine;
  final NeonItemRarity rarity;
  final int? power;
  final String? ownedLabel;
  final Widget? leading;

  /// In-flow content under the meta row (e.g. Base/Adept version chips).
  final Widget? footer;
  final bool selected;
  final VoidCallback? onTap;
  final Key? nameKey;
  final Key? metaKey;
  final Key? ownedKey;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final elVisual = officialElementVisual(element);
    final el = elVisual?.color ?? flapElementColor(context, element);
    final ammoVisual = officialAmmoVisual(ammo);
    final frameVisual = officialWeaponFrameVisual(frame);
    final typeVisual = officialWeaponTypeVisual(typeLine);
    final exotic = rarity == NeonItemRarity.exotic;
    final legendary = rarity == NeonItemRarity.legendary;

    final surface = palette.surface.withValues(alpha: 0.88);
    final surface2 = palette.surfaceRaised.withValues(alpha: 0.92);

    final layers = <Color>[];
    if (exotic) {
      layers.addAll([
        Color(kRarityExotic).withValues(alpha: selected ? 0.30 : 0.22),
        Color(kRarityExotic).withValues(alpha: 0.10),
        Colors.transparent,
      ]);
    } else if (legendary) {
      layers.addAll([
        Color(kRarityLegendaryEdge).withValues(alpha: selected ? 0.30 : 0.26),
        Color(kRarityLegendary).withValues(alpha: 0.20),
        Colors.transparent,
      ]);
    }

    final base = selected
        ? Color.lerp(surface2, palette.accent, 0.08) ?? surface2
        : surface;

    final borderColor = selected
        ? palette.accent.withValues(alpha: 0.45)
        : palette.line.withValues(alpha: 0.55);

    final nameColor = exotic ? Color(kRarityExotic) : palette.foreground;

    final hasType = typeLine != null && typeLine!.trim().isNotEmpty;
    final hasElement = element != null && element!.trim().isNotEmpty;

    // Meta icons share the bottom band with the element disc (same baseline).
    final metaIcons = <Widget>[
      if (hasType)
        if (typeVisual != null)
          _TypeSilhouetteIcon(
            key: metaKey ?? const Key('neon_card_type_icon'),
            visual: typeVisual,
            tooltip: typeLine!,
            fallbackMark: weaponTypeLetterMark(typeLine),
          )
        else
          _FallbackGlyphIcon(
            key: metaKey ?? const Key('neon_card_type_icon'),
            mark: weaponTypeLetterMark(typeLine),
            tooltip: typeLine!,
            color: palette.muted,
          ),
      if (slot != null && slot!.isNotEmpty)
        _SlotLetterIcon(
          key: const Key('neon_card_slot_icon'),
          slot: slot!,
          color: _slotColor(palette, slot),
        ),
      if (ammoVisual != null)
        _OfficialMetaIcon(
          key: const Key('neon_card_ammo_icon'),
          visual: ammoVisual,
          tooltip: '$ammo ammo',
          fallbackMark: neonAmmoGlyphMark(ammo),
        )
      else if (ammo != null && ammo!.isNotEmpty)
        _FallbackGlyphIcon(
          key: const Key('neon_card_ammo_icon'),
          mark: neonAmmoGlyphMark(ammo),
          tooltip: '$ammo ammo',
          color: palette.muted,
        ),
      if (frameVisual != null)
        _OfficialMetaIcon(
          key: const Key('neon_card_frame_icon'),
          visual: frameVisual,
          tooltip: frame ?? 'Frame',
          fallbackMark: '◇',
        )
      else if (frame != null && frame!.isNotEmpty)
        _FallbackGlyphIcon(
          key: const Key('neon_card_frame_icon'),
          mark: '◇',
          tooltip: frame!,
          color: palette.muted,
        ),
    ];

    final hasBottomBand = hasElement ||
        metaIcons.isNotEmpty ||
        power != null ||
        ownedLabel != null ||
        footer != null;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      // Fixed height matches catalog grid cells so the meta band pins bottom.
      height: minHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kRadiusMax),
        border: Border.all(color: borderColor, width: kFlapRuleThickness),
        color: base,
        gradient: layers.isEmpty
            ? null
            : LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                stops: const [0.0, 0.30, 0.62],
                colors: layers,
              ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: palette.accent.withValues(alpha: 0.18),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Element corner bloom (disc sits in the bottom meta band).
          if (el != null)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.bottomLeft,
                      radius: 1.15,
                      colors: [
                        el.withValues(alpha: 0.48),
                        el.withValues(alpha: 0.16),
                        el.withValues(alpha: 0),
                      ],
                      stops: const [0.0, 0.22, 0.55],
                    ),
                  ),
                ),
              ),
            ),
          if (selected)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 2,
              child: ColoredBox(color: palette.accent),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              kSpace6,
              kSpace6,
              kSpace6,
              kSpace6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (leading != null) ...[
                      // Fixed corner plate size (avoid FittedBox → parentDataDirty).
                      SizedBox(width: 32, height: 32, child: leading!),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        name,
                        key: nameKey,
                        style: neonDisplay(
                          color: nameColor,
                          fontSize: 12,
                          letterSpacing: 0.03 * 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _RarityBadge(rarity: rarity),
                  ],
                ),
                if (hasBottomBand) ...[
                  const Spacer(),
                  if (footer != null) ...[
                    // Version chips (Base/Adept) — right-aligned above meta band.
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: footer!,
                      ),
                    ),
                  ],
                  // Bottom band: element disc + type/slot/ammo/frame + ×N.
                  Container(
                    padding: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: palette.line.withValues(alpha: 0.55),
                          width: kFlapRuleThickness,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          // Horizontal scroll absorbs tight widths (phone
                          // viewport / outline demos) without FittedBox —
                          // FittedBox left parentDataDirty during semantics.
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              key: const Key('neon_card_foot_icons'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (hasElement) ...[
                                  _ElementOfficialGlyph(
                                    key: const Key('neon_card_element_glyph'),
                                    element: element!,
                                    visual: elVisual,
                                    color: el ?? palette.muted,
                                  ),
                                  if (metaIcons.isNotEmpty)
                                    const SizedBox(width: 6),
                                ],
                                for (var i = 0; i < metaIcons.length; i++) ...[
                                  if (i > 0) const SizedBox(width: 3),
                                  metaIcons[i],
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (power != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            key: const Key('neon_card_power'),
                            'P$power',
                            style: neonMono(
                              color: palette.muted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                        if (ownedLabel != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            ownedLabel!,
                            key: ownedKey,
                            style: neonMono(
                              color: palette.accent,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    // One semantic node per card (Windows AX). Nested Text / Tooltip / icon
    // nodes reparent on select/scroll and thrash accessibility_bridge.
    final a11y = _cardA11yLabel(
      name: name,
      typeLine: typeLine,
      element: element,
      slot: slot,
      ammo: ammo,
      frame: frame,
      power: power,
      ownedLabel: ownedLabel,
      selected: selected,
    );

    Widget body = card;
    if (onTap != null) {
      body = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kRadiusMax),
          focusColor: palette.accent.withValues(alpha: 0.12),
          hoverColor: palette.surfaceRaised.withValues(alpha: 0.35),
          child: card,
        ),
      );
    }

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: a11y,
      excludeSemantics: true,
      child: body,
    );
  }

  static String _cardA11yLabel({
    required String name,
    String? typeLine,
    String? element,
    String? slot,
    String? ammo,
    String? frame,
    int? power,
    String? ownedLabel,
    required bool selected,
  }) {
    final parts = <String>[
      name,
      if (typeLine != null && typeLine.trim().isNotEmpty) typeLine.trim(),
      if (element != null && element.trim().isNotEmpty) element.trim(),
      if (slot != null && slot.trim().isNotEmpty) '$slot slot',
      if (ammo != null && ammo.trim().isNotEmpty) '$ammo ammo',
      if (frame != null && frame.trim().isNotEmpty) frame.trim(),
      if (power != null) 'power $power',
      if (ownedLabel != null && ownedLabel.trim().isNotEmpty) ownedLabel.trim(),
      if (selected) 'selected',
    ];
    return parts.join(', ');
  }

  /// Slot letters are structure chrome (no stable official weapon-bucket icons).
  /// Keep kinetic white; energy/power muted — do **not** reuse void/solar tints.
  static Color _slotColor(FlapPalette palette, String? slot) {
    switch ((slot ?? '').toLowerCase()) {
      case 'kinetic':
        return palette.elementKinetic;
      case 'energy':
        return palette.muted;
      case 'power':
        return palette.muted;
      default:
        return palette.muted;
    }
  }
}

/// Dense meta chip edge (fits ~120px foot with element + 4 icons + ×N).
const double _kMetaChip = 16;
const double _kElementDisc = 20;

/// Weapon-type silhouette chip (meta row).
class _TypeSilhouetteIcon extends StatelessWidget {
  const _TypeSilhouetteIcon({
    super.key,
    required this.visual,
    required this.tooltip,
    this.fallbackMark,
  });

  final DestinyWeaponTypeVisual visual;
  final String tooltip;
  final String? fallbackMark;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Tooltip(
      message: tooltip,
      excludeFromSemantics: true,
      child: ExcludeSemantics(
        child: Container(
          width: _kMetaChip,
          height: _kMetaChip,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.background.withValues(alpha: 0.6),
            border: Border.all(
              color: visual.color.withValues(alpha: 0.55),
              width: kFlapRuleThickness,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: DestinyWeaponTypeIcon(
            visual: visual,
            size: 12,
            fallbackMark: fallbackMark,
          ),
        ),
      ),
    );
  }
}

/// Element disc in the bottom meta band (+ bloom behind the card).
class _ElementOfficialGlyph extends StatelessWidget {
  const _ElementOfficialGlyph({
    super.key,
    required this.element,
    required this.visual,
    required this.color,
  });

  final String element;
  final DestinyOfficialVisual? visual;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Hover-only; NeonItemCard owns the accessible name (Windows AX).
    return Tooltip(
      message: element,
      excludeFromSemantics: true,
      child: ExcludeSemantics(
        child: Container(
          width: _kElementDisc,
          height: _kElementDisc,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.22),
            border: Border.all(
              color: color.withValues(alpha: 0.75),
              width: kFlapRuleThickness,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 10,
              ),
            ],
          ),
          child: visual != null
              ? DestinyOfficialIcon(
                  visual: visual!,
                  size: 13,
                  fallbackMark: neonElementGlyphMark(element),
                )
              : Text(
                  neonElementGlyphMark(element),
                  style: TextStyle(
                    fontSize: 11,
                    height: 1,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

class _OfficialMetaIcon extends StatelessWidget {
  const _OfficialMetaIcon({
    super.key,
    required this.visual,
    required this.tooltip,
    this.fallbackMark,
  });

  final DestinyOfficialVisual visual;
  final String tooltip;
  final String? fallbackMark;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    // Hover-only; parent card owns a11y name (Windows AX).
    return Tooltip(
      message: tooltip,
      excludeFromSemantics: true,
      child: ExcludeSemantics(
        child: Container(
          width: _kMetaChip,
          height: _kMetaChip,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.background.withValues(alpha: 0.6),
            border: Border.all(
              color: visual.color.withValues(alpha: 0.55),
              width: kFlapRuleThickness,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: DestinyOfficialIcon(
            visual: visual,
            size: 12,
            fallbackMark: fallbackMark,
          ),
        ),
      ),
    );
  }
}

class _SlotLetterIcon extends StatelessWidget {
  const _SlotLetterIcon({
    super.key,
    required this.slot,
    required this.color,
  });

  final String slot;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _FallbackGlyphIcon(
      mark: neonSlotGlyphMark(slot),
      tooltip: slot,
      color: color,
    );
  }
}

class _FallbackGlyphIcon extends StatelessWidget {
  const _FallbackGlyphIcon({
    super.key,
    required this.mark,
    required this.tooltip,
    required this.color,
  });

  final String mark;
  final String tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    // Hover-only; parent card owns a11y name (Windows AX).
    return Tooltip(
      message: tooltip,
      excludeFromSemantics: true,
      child: ExcludeSemantics(
        child: Container(
          width: _kMetaChip,
          height: _kMetaChip,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.background.withValues(alpha: 0.6),
            border: Border.all(
              color: color.withValues(alpha: 0.45),
              width: kFlapRuleThickness,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            mark,
            style: TextStyle(
              fontSize: 10,
              height: 1,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _RarityBadge extends StatelessWidget {
  const _RarityBadge({required this.rarity});

  final NeonItemRarity rarity;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    late final Color fg;
    late final Color border;
    late final Color? bg;
    switch (rarity) {
      case NeonItemRarity.exotic:
        fg = Color(kRarityExotic);
        border = Color(kRarityExotic).withValues(alpha: 0.45);
        bg = null;
      case NeonItemRarity.legendary:
        fg = Color(kRarityLegendaryEdge);
        border = Color(kRarityLegendaryEdge).withValues(alpha: 0.40);
        bg = Color(kRarityLegendary).withValues(alpha: 0.45);
      case NeonItemRarity.rare:
      case NeonItemRarity.common:
        fg = palette.muted;
        border = palette.line;
        bg = null;
    }
    return Container(
      key: const Key('neon_card_rarity_badge'),
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: kFlapRuleThickness),
        borderRadius: BorderRadius.circular(kRadiusMax),
      ),
      child: Text(
        neonRarityMark(rarity),
        style: TextStyle(
          fontSize: 10,
          height: 1,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
