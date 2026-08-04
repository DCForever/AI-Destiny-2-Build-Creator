import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../bungie_content_icon.dart';
import '../destiny_official_icons.dart';
import '../flap_palette.dart';
import '../neon_fonts.dart';
import '../neon_item_card.dart';

/// Pure icon-only weapon meta strip (type · frame · element · slot · ammo + ×N).
///
/// No type·frame text subtitle and no KINETIC/OWNED text pills (COMPARE residual).
/// Official Destiny icons when known; slot/type use letter/abbrev structure chrome.
class CatalogWeaponMetaStrip extends StatelessWidget {
  const CatalogWeaponMetaStrip({
    super.key,
    this.itemTypeName,
    this.frame,
    this.element,
    this.slot,
    this.ammo,
    this.owned = false,
    this.ownedCount = 0,
    this.showOwnedMark = true,
  });

  final String? itemTypeName;
  final String? frame;
  final String? element;
  final String? slot;
  final String? ammo;
  final bool owned;
  final int ownedCount;

  /// When false, never render ×N / not-owned marks (signed-out honesty).
  final bool showOwnedMark;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    final frameVisual = officialWeaponFrameVisual(frame);
    final elVisual = officialElementVisual(element);
    final ammoVisual = officialAmmoVisual(ammo);

    final chips = <Widget>[
      if (itemTypeName != null && itemTypeName!.trim().isNotEmpty)
        _MetaGlyphChip(
          key: const Key('catalog_meta_type'),
          tooltip: itemTypeName!,
          mark: _typeMark(itemTypeName!),
          color: palette.muted,
        ),
      if (frameVisual != null)
        _MetaOfficialChip(
          key: const Key('catalog_meta_frame'),
          visual: frameVisual,
          tooltip: frame ?? 'Frame',
          fallbackMark: '◇',
        )
      else if (frame != null && frame!.trim().isNotEmpty)
        _MetaGlyphChip(
          key: const Key('catalog_meta_frame'),
          tooltip: frame!,
          mark: '◇',
          color: palette.muted,
        ),
      if (elVisual != null)
        _MetaOfficialChip(
          key: const Key('catalog_meta_element'),
          visual: elVisual,
          tooltip: element ?? 'Element',
          fallbackMark: neonElementGlyphMark(element),
        )
      else if (element != null && element!.trim().isNotEmpty)
        _MetaGlyphChip(
          key: const Key('catalog_meta_element'),
          tooltip: element!,
          mark: neonElementGlyphMark(element),
          color: palette.muted,
        ),
      if (slot != null && slot!.trim().isNotEmpty)
        _MetaGlyphChip(
          key: const Key('catalog_meta_slot'),
          tooltip: slot!,
          mark: neonSlotGlyphMark(slot),
          color: _slotColor(palette, slot),
        ),
      if (ammoVisual != null)
        _MetaOfficialChip(
          key: const Key('catalog_meta_ammo'),
          visual: ammoVisual,
          tooltip: '$ammo ammo',
          fallbackMark: neonAmmoGlyphMark(ammo),
        )
      else if (ammo != null && ammo!.trim().isNotEmpty)
        _MetaGlyphChip(
          key: const Key('catalog_meta_ammo'),
          tooltip: '$ammo ammo',
          mark: neonAmmoGlyphMark(ammo),
          color: palette.muted,
        ),
      if (showOwnedMark && owned && ownedCount > 0)
        _OwnedCountChip(
          key: const Key('catalog_meta_owned_count'),
          count: ownedCount,
        ),
    ];

    if (chips.isEmpty) {
      return const SizedBox.shrink(key: Key('catalog_weapon_meta_strip_empty'));
    }

    return Semantics(
      key: const Key('catalog_weapon_meta_strip'),
      label: _a11yLabel(),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: chips,
      ),
    );
  }

  String _a11yLabel() {
    final parts = <String>[
      if (itemTypeName != null && itemTypeName!.trim().isNotEmpty) itemTypeName!,
      if (frame != null && frame!.trim().isNotEmpty) frame!,
      if (element != null && element!.trim().isNotEmpty) element!,
      if (slot != null && slot!.trim().isNotEmpty) slot!,
      if (ammo != null && ammo!.trim().isNotEmpty) ammo!,
      if (showOwnedMark && owned && ownedCount > 0) 'owned ×$ownedCount',
    ];
    return parts.join(', ');
  }

  static String _typeMark(String type) {
    final t = type.trim();
    if (t.isEmpty) return '?';
    // Compact structure mark when no official weapon-type icon path is wired.
    final words = t.split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return t.length <= 2 ? t.toUpperCase() : t.substring(0, 2).toUpperCase();
  }

  static Color _slotColor(FlapPalette palette, String? slot) {
    switch ((slot ?? '').toLowerCase()) {
      case 'kinetic':
        return palette.elementKinetic;
      case 'energy':
      case 'power':
        return palette.muted;
      default:
        return palette.muted;
    }
  }
}

class _MetaOfficialChip extends StatelessWidget {
  const _MetaOfficialChip({
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
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.surfaceRaised.withValues(alpha: 0.6),
          border: Border.all(
            color: visual.color.withValues(alpha: 0.55),
            width: kFlapRuleThickness,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: DestinyOfficialIcon(
          visual: visual,
          size: 15,
          fallbackMark: fallbackMark,
        ),
      ),
    );
  }
}

class _MetaGlyphChip extends StatelessWidget {
  const _MetaGlyphChip({
    super.key,
    required this.tooltip,
    required this.mark,
    required this.color,
  });

  final String tooltip;
  final String mark;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: Container(
        constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
        padding: const EdgeInsets.symmetric(horizontal: 3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.surfaceRaised.withValues(alpha: 0.6),
          border: Border.all(
            color: color.withValues(alpha: 0.45),
            width: kFlapRuleThickness,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          mark,
          style: neonMono(color: color, fontSize: 10),
        ),
      ),
    );
  }
}

/// ×N only — never "OWNED" text pill.
class _OwnedCountChip extends StatelessWidget {
  const _OwnedCountChip({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Tooltip(
      message: 'Owned copies',
      child: Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.success.withValues(alpha: 0.06),
          border: Border.all(
            color: palette.success.withValues(alpha: 0.35),
            width: kFlapRuleThickness,
          ),
          borderRadius: BorderRadius.circular(kRadiusMax),
        ),
        child: Text(
          '×$count',
          style: neonMono(color: palette.success, fontSize: 11),
        ),
      ),
    );
  }
}
