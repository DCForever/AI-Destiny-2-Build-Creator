/// Neon Network catalog item card.
///
/// Soft surface + rarity wash + element corner bloom + **official** damage-type
/// icon. Type-only body text; slot letter / official ammo / official frame icons
/// in the foot.
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

  /// Type-only body meta (weapon type). Element/slot/ammo/frame are icons.
  final String? typeLine;
  final NeonItemRarity rarity;
  final int? power;
  final String? ownedLabel;
  final Widget? leading;
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

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      constraints: BoxConstraints(minHeight: minHeight),
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
        fit: StackFit.passthrough,
        children: [
          // Element corner bloom from official damage-type color.
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
          // Official damage-type icon (not mock Unicode).
          if (element != null && element!.trim().isNotEmpty)
            Positioned(
              left: 5,
              bottom: 5,
              child: _ElementOfficialGlyph(
                key: const Key('neon_card_element_glyph'),
                element: element!,
                visual: elVisual,
                color: el ?? palette.muted,
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
            // Tight inset — density over airy mock padding.
            padding: const EdgeInsets.fromLTRB(kSpace6, kSpace6, kSpace6, kSpace6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: kSpace6),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + rarity on one row (no wasted badge-only line).
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                          if (typeLine != null && typeLine!.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Text(
                                typeLine!,
                                key: metaKey,
                                style: neonBody(
                                  color: palette.muted,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: kSpace6),
                Container(
                  // Room for larger element disc at BL.
                  padding: const EdgeInsets.only(top: 5, left: 28),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: palette.line.withValues(alpha: 0.55),
                        width: kFlapRuleThickness,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          key: const Key('neon_card_foot_icons'),
                          children: [
                            if (slot != null && slot!.isNotEmpty)
                              _SlotLetterIcon(
                                key: const Key('neon_card_slot_icon'),
                                slot: slot!,
                                color: _slotColor(palette, slot),
                              ),
                            if (ammoVisual != null) ...[
                              const SizedBox(width: 4),
                              _OfficialMetaIcon(
                                key: const Key('neon_card_ammo_icon'),
                                visual: ammoVisual,
                                tooltip: '$ammo ammo',
                                fallbackMark: neonAmmoGlyphMark(ammo),
                              ),
                            ] else if (ammo != null && ammo!.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              _FallbackGlyphIcon(
                                key: const Key('neon_card_ammo_icon'),
                                mark: neonAmmoGlyphMark(ammo),
                                tooltip: '$ammo ammo',
                                color: palette.muted,
                              ),
                            ],
                            if (frameVisual != null) ...[
                              const SizedBox(width: 4),
                              _OfficialMetaIcon(
                                key: const Key('neon_card_frame_icon'),
                                visual: frameVisual,
                                tooltip: frame ?? 'Frame',
                                fallbackMark: '◇',
                              ),
                            ] else if (frame != null && frame!.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              _FallbackGlyphIcon(
                                key: const Key('neon_card_frame_icon'),
                                mark: '◇',
                                tooltip: frame!,
                                color: palette.muted,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (power != null)
                        Text(
                          key: const Key('neon_card_power'),
                          'P$power',
                          style: neonMono(
                            color: palette.muted,
                            fontSize: 10,
                          ),
                        ),
                      if (ownedLabel != null) ...[
                        if (power != null) const SizedBox(width: 4),
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
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
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

/// Corner element disc with official damage-type PNG.
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
    return Tooltip(
      message: element,
      child: Container(
        width: 24,
        height: 24,
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
              blurRadius: 12,
            ),
          ],
        ),
        // Tooltip owns a11y name — no nested Semantics on CDN image (Windows AX).
        child: visual != null
            ? DestinyOfficialIcon(
                visual: visual!,
                size: 16,
                fallbackMark: neonElementGlyphMark(element),
              )
            : Text(
                neonElementGlyphMark(element),
                style: TextStyle(
                  fontSize: 13,
                  height: 1,
                  color: color,
                  fontWeight: FontWeight.w600,
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
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.background.withValues(alpha: 0.6),
          border: Border.all(
            color: visual.color.withValues(alpha: 0.55),
            width: kFlapRuleThickness,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        // Tooltip owns a11y name — keep CDN image non-semantic.
        child: DestinyOfficialIcon(
          visual: visual,
          size: 15,
          fallbackMark: fallbackMark,
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
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 20,
        height: 20,
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
            fontSize: 11,
            height: 1,
            color: color,
            fontWeight: FontWeight.w600,
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
