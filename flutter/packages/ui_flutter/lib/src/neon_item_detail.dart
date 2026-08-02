/// Neon Network item detail chrome (OD Vex catalog weapon/armor detail).
///
/// Hero mark, detail head (kicker / title / meta pills), tab-style section rail.
library;

import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import 'flap_element.dart';
import 'flap_palette.dart';
import 'neon_fonts.dart';
import 'neon_item_card.dart';

/// Diamond hero block with rarity / element tint (OD `.hero-block`).
class NeonDetailHero extends StatelessWidget {
  const NeonDetailHero({
    super.key,
    this.mark = 'WPN',
    this.rarity = NeonItemRarity.common,
    this.element,
    this.height = 128,
  });

  final String mark;
  final NeonItemRarity rarity;
  final String? element;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final el = flapElementColor(context, element);
    Color tint = palette.accent;
    if (rarity == NeonItemRarity.exotic) {
      tint = Color(kRarityExotic);
    } else if (rarity == NeonItemRarity.legendary) {
      tint = Color(kRarityLegendaryEdge);
    } else if (el != null) {
      tint = el;
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: palette.line, width: kFlapRuleThickness),
          ),
          gradient: RadialGradient(
            center: const Alignment(0, -0.2),
            radius: 0.95,
            colors: [
              tint.withValues(alpha: 0.16),
              palette.surfaceRaised.withValues(alpha: 0.9),
            ],
          ),
        ),
        child: Center(
          child: Transform.rotate(
            angle: 0.785398, // 45°
            child: Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: tint.withValues(alpha: 0.45),
                  width: kFlapRuleThickness,
                ),
                boxShadow: [
                  BoxShadow(
                    color: tint.withValues(alpha: 0.16),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Transform.rotate(
                angle: -0.785398,
                child: Text(
                  mark.toUpperCase(),
                  style: neonDisplay(
                    color: tint,
                    fontSize: 11,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mono uppercase pill (OD `.pill`).
class NeonMetaPill extends StatelessWidget {
  const NeonMetaPill(
    this.label, {
    super.key,
    this.tone = NeonPillTone.neutral,
  });

  final String label;
  final NeonPillTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    late final Color fg;
    late final Color border;
    switch (tone) {
      case NeonPillTone.ok:
        fg = palette.success;
        border = palette.success.withValues(alpha: 0.30);
      case NeonPillTone.warn:
        fg = palette.warning;
        border = palette.warning.withValues(alpha: 0.35);
      case NeonPillTone.exotic:
        fg = Color(kRarityExotic);
        border = Color(kRarityExotic).withValues(alpha: 0.45);
      case NeonPillTone.legendary:
        fg = Color(kRarityLegendaryEdge);
        border = Color(kRarityLegendaryEdge).withValues(alpha: 0.40);
      case NeonPillTone.accent:
        fg = palette.accent;
        border = palette.accent.withValues(alpha: 0.40);
      case NeonPillTone.neutral:
        fg = palette.muted;
        border = palette.line;
    }
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: palette.surfaceRaised.withValues(alpha: 0.80),
        border: Border.all(color: border, width: kFlapRuleThickness),
        borderRadius: BorderRadius.circular(kRadiusMax),
      ),
      child: Text(
        label.toUpperCase(),
        style: neonMono(color: fg, fontSize: 10, letterSpacing: 1.0),
      ),
    );
  }
}

enum NeonPillTone { neutral, ok, warn, exotic, legendary, accent }

/// Detail head: kicker · title · subtitle · meta pills · optional actions.
class NeonDetailHeader extends StatelessWidget {
  const NeonDetailHeader({
    super.key,
    required this.title,
    this.kicker,
    this.subtitle,
    this.pills = const [],
    this.actions,
    this.titleKey,
    this.kickerKey,
  });

  final String title;
  final String? kicker;
  final String? subtitle;
  final List<Widget> pills;
  final Widget? actions;
  final Key? titleKey;
  final Key? kickerKey;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(kSpace12, kSpace12, kSpace12, kSpace8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (kicker != null && kicker!.trim().isNotEmpty)
            Text(
              kicker!.toUpperCase(),
              key: kickerKey,
              style: neonMono(
                color: palette.muted,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
          const SizedBox(height: kSpace4),
          Text(
            title,
            key: titleKey,
            style: neonDisplay(
              color: palette.foreground,
              fontSize: 18,
              letterSpacing: 0.04 * 18,
            ),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: kSpace4),
            Text(
              subtitle!,
              style: neonBody(color: palette.muted, fontSize: 13),
            ),
          ],
          if (pills.isNotEmpty) ...[
            const SizedBox(height: kSpace12),
            Wrap(
              spacing: kSpace8,
              runSpacing: kSpace8,
              children: pills,
            ),
          ],
          if (actions != null) ...[
            const SizedBox(height: kSpace12),
            actions!,
          ],
        ],
      ),
    );
  }
}

/// Tab-style section control (OD `.tabs` / `.tab`).
class NeonDetailTabBar extends StatelessWidget {
  const NeonDetailTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.line, width: kFlapRuleThickness),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              _NeonTab(
                label: tabs[i],
                selected: i == selectedIndex,
                onTap: () => onSelected(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NeonTab extends StatelessWidget {
  const _NeonTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: kSpace16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? palette.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: neonMono(
            color: selected ? palette.accent : palette.muted,
            fontSize: 11,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

/// Hero mark letters from composition kind / item type.
String neonHeroMark({
  String? kindLabel,
  String? itemTypeName,
  String? slot,
}) {
  final k = (kindLabel ?? '').toLowerCase();
  if (k.contains('weapon')) return 'WPN';
  if (k.contains('armor')) return 'ARM';
  if (k.contains('mod')) return 'MOD';
  final t = (itemTypeName ?? '').toLowerCase();
  if (t.contains('weapon') ||
      t.contains('rifle') ||
      t.contains('cannon') ||
      t.contains('shotgun') ||
      t.contains('sword') ||
      t.contains('bow') ||
      t.contains('glaive') ||
      t.contains('sidearm') ||
      t.contains('smg') ||
      t.contains('machine')) {
    return 'WPN';
  }
  if (t.contains('armor') ||
      t.contains('helmet') ||
      t.contains('gauntlet') ||
      t.contains('chest') ||
      t.contains('leg') ||
      t.contains('class')) {
    return 'ARM';
  }
  final s = (slot ?? '').toLowerCase();
  if (s.contains('kinetic') ||
      s.contains('energy') ||
      s.contains('power') ||
      s.contains('heavy')) {
    return 'WPN';
  }
  if (s.contains('helmet') ||
      s.contains('arms') ||
      s.contains('chest') ||
      s.contains('legs') ||
      s.contains('class')) {
    return 'ARM';
  }
  return 'ITM';
}
