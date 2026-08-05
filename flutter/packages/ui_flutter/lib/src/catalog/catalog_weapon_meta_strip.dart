import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../bungie_content_icon.dart';
import '../destiny_official_icons.dart';
import '../flap_palette.dart';
import '../neon_fonts.dart';
import '../neon_item_card.dart';

/// Fixed meta chip edge (COMPARE residual — compact horizontal, not full-width bars).
const double kCatalogMetaChipSize = 22;

/// Pure icon-only weapon meta strip (type · frame · element · slot · ammo + ×N).
///
/// No type·frame text subtitle and no KINETIC/OWNED text pills (COMPARE residual).
/// Official Destiny icons when known; type uses destiny-icons silhouette or letter
/// last-resort; slot stays letter.
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
    final typeVisual = officialWeaponTypeVisual(itemTypeName);
    final frameVisual = officialWeaponFrameVisual(frame);
    final elVisual = officialElementVisual(element);
    final ammoVisual = officialAmmoVisual(ammo);

    final chips = <Widget>[
      if (itemTypeName != null && itemTypeName!.trim().isNotEmpty)
        if (typeVisual != null)
          _MetaTypeSilhouetteChip(
            key: const Key('catalog_meta_type'),
            visual: typeVisual,
            tooltip: itemTypeName!,
            fallbackMark: weaponTypeLetterMark(itemTypeName),
          )
        else
          _MetaGlyphChip(
            key: const Key('catalog_meta_type'),
            tooltip: itemTypeName!,
            mark: weaponTypeLetterMark(itemTypeName),
            color: palette.muted,
            semanticLabel: itemTypeName!,
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
          semanticLabel: '$slot slot',
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

    // Compact horizontal strip (max-content): fixed chips; never full-width bars.
    // Key on the Row (mainAxisSize.min) — Semantics alone expands to max constraints.
    return Semantics(
      label: _a11yLabel(),
      child: Row(
        key: const Key('catalog_weapon_meta_strip'),
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            chips[i],
          ],
        ],
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

/// Fixed 22×22 chip with destiny-icons type silhouette.
class _MetaTypeSilhouetteChip extends StatelessWidget {
  const _MetaTypeSilhouetteChip({
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
      child: Semantics(
        label: tooltip,
        image: true,
        child: Container(
          width: kCatalogMetaChipSize,
          height: kCatalogMetaChipSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.surfaceRaised.withValues(alpha: 0.6),
            border: Border.all(
              color: visual.color.withValues(alpha: 0.55),
              width: kFlapRuleThickness,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: DestinyWeaponTypeIcon(
            visual: visual,
            size: 15,
            fallbackMark: fallbackMark,
          ),
        ),
      ),
    );
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
        width: kCatalogMetaChipSize,
        height: kCatalogMetaChipSize,
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

/// Fixed 22×22 letter/glyph chip — never expands to full-width bars.
class _MetaGlyphChip extends StatelessWidget {
  const _MetaGlyphChip({
    super.key,
    required this.tooltip,
    required this.mark,
    required this.color,
    this.semanticLabel,
  });

  final String tooltip;
  final String mark;
  final Color color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: semanticLabel ?? tooltip,
        child: Container(
          width: kCatalogMetaChipSize,
          height: kCatalogMetaChipSize,
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
            style: neonMono(color: color, fontSize: 9),
            maxLines: 1,
            overflow: TextOverflow.clip,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// ×N only — never "OWNED" text pill. Height fixed 22; width hugs content.
class _OwnedCountChip extends StatelessWidget {
  const _OwnedCountChip({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Tooltip(
      message: 'Owned copies',
      child: Container(
        height: kCatalogMetaChipSize,
        constraints: const BoxConstraints(
          minWidth: kCatalogMetaChipSize,
          minHeight: kCatalogMetaChipSize,
          maxHeight: kCatalogMetaChipSize,
        ),
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
