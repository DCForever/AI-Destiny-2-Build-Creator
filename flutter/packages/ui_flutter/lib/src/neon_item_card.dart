/// Neon Network catalog item card (OD Vex Network `.item-card` construct).
///
/// Soft surface + rarity wash + element corner bloom. Selection = cyan inset bar.
/// Structure hairlines only — not a cyan cage by default.
library;

import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

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

/// Compact construct card for weapons / armor / catalog hits.
class NeonItemCard extends StatelessWidget {
  const NeonItemCard({
    super.key,
    required this.name,
    this.slot,
    this.element,
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
    this.minHeight = 132,
  });

  final String name;
  final String? slot;
  final String? element;
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
    final el = flapElementColor(context, element);
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
          // Element corner bloom (OD ::before radial).
          if (el != null)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.bottomLeft,
                      radius: 1.05,
                      colors: [
                        el.withValues(alpha: 0.42),
                        el.withValues(alpha: 0.14),
                        el.withValues(alpha: 0),
                      ],
                      stops: const [0.0, 0.18, 0.42],
                    ),
                  ),
                ),
              ),
            ),
          // Selection inset bar (cyan signal).
          if (selected)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 2,
              child: ColoredBox(color: palette.accent),
            ),
          Padding(
            padding: const EdgeInsets.all(kSpace12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: kSpace8),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  (slot ?? 'Node').toUpperCase(),
                                  style: neonMono(
                                    color: palette.muted.withValues(alpha: 0.85),
                                    fontSize: 10,
                                    letterSpacing: 1.0,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _RarityBadge(rarity: rarity),
                            ],
                          ),
                          const SizedBox(height: kSpace4),
                          Text(
                            name,
                            key: nameKey,
                            style: neonDisplay(
                              color: nameColor,
                              fontSize: 13,
                              letterSpacing: 0.04 * 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (typeLine != null && typeLine!.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                typeLine!,
                                key: metaKey,
                                style: neonBody(
                                  color: palette.muted,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: kSpace12),
                Container(
                  padding: const EdgeInsets.only(top: kSpace8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: palette.line.withValues(alpha: 0.7),
                        width: kFlapRuleThickness,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (element != null && element!.isNotEmpty)
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: el ?? palette.muted,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  element!.toUpperCase(),
                                  style: neonMono(
                                    color: palette.muted,
                                    fontSize: 10,
                                    letterSpacing: 0.8,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const Spacer(),
                      if (power != null)
                        Text(
                          '$power',
                          style: neonMono(
                            color: palette.foreground,
                            fontSize: 12,
                          ),
                        ),
                      if (ownedLabel != null) ...[
                        if (power != null) const SizedBox(width: kSpace8),
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
}

class _RarityBadge extends StatelessWidget {
  const _RarityBadge({required this.rarity});

  final NeonItemRarity rarity;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    late final String label;
    late final Color fg;
    late final Color border;
    switch (rarity) {
      case NeonItemRarity.exotic:
        label = 'Exotic';
        fg = Color(kRarityExotic);
        border = Color(kRarityExotic).withValues(alpha: 0.45);
      case NeonItemRarity.legendary:
        label = 'Legendary';
        fg = Color(kRarityLegendaryEdge);
        border = Color(kRarityLegendaryEdge).withValues(alpha: 0.40);
      case NeonItemRarity.rare:
        label = 'Rare';
        fg = palette.muted;
        border = palette.line;
      case NeonItemRarity.common:
        label = 'Common';
        fg = palette.muted;
        border = palette.line;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: border, width: kFlapRuleThickness),
        borderRadius: BorderRadius.circular(kRadiusMax),
      ),
      child: Text(
        label.toUpperCase(),
        style: neonMono(color: fg, fontSize: 10, letterSpacing: 0.8),
      ),
    );
  }
}
