import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../flap_palette.dart';
import '../neon_fonts.dart';
import '../neon_item_card.dart';
import 'catalog_group_chrome.dart';

/// Identity-primary weapon card (NeonItemCard adapter).
///
/// Type-only body; element/slot/ammo as mock glyphs. Owned badge only when
/// [showOwned] and item.owned — never fakes ownership.
class CatalogWeaponCard extends StatelessWidget {
  const CatalogWeaponCard({
    super.key,
    required this.item,
    this.selected = false,
    this.showOwned = true,
    this.leading,
    this.onTap,
    this.ownedCountOverride,
    this.footer,
  });

  final CatalogItem item;
  final bool selected;

  /// When false (signed-out), never render owned badge even if data present.
  final bool showOwned;
  final Widget? leading;
  final VoidCallback? onTap;

  /// When set (family ×N sum), overrides [item.ownedCount] for the badge.
  final int? ownedCountOverride;

  /// Optional footer below foot icons (owned-only version chips).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final count = ownedCountOverride ?? item.ownedCount;
    final owned = showOwned && (item.owned || count > 0);
    final ownedLabel = owned && count > 0 ? '×$count' : null;
    // Type-only body (mock): element/slot/ammo live as glyphs, not text.
    final typeParts = <String>[
      if (item.itemTypeName != null && item.itemTypeName!.isNotEmpty)
        item.itemTypeName!,
    ];
    final typeLine = typeParts.isEmpty ? 'Weapon' : typeParts.join(' · ');

    final card = NeonItemCard(
      key: Key('catalog_item_${item.hash}'),
      name: item.name,
      slot: item.slot,
      element: item.element,
      ammo: item.ammo,
      frame: item.frame,
      typeLine: typeLine,
      // Destiny weapons are legendary unless exotic (mock chrome ◆ vs ✦).
      rarity: item.isExotic
          ? NeonItemRarity.exotic
          : NeonItemRarity.legendary,
      ownedLabel: ownedLabel,
      selected: selected,
      minHeight: 100,
      onTap: onTap,
      nameKey: Key('catalog_item_name_${item.hash}'),
      metaKey: Key('catalog_item_meta_${item.hash}'),
      ownedKey: owned ? Key('owned_badge_${item.hash}') : null,
      leading: leading,
    );

    if (footer == null) return card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(child: card),
        footer!,
      ],
    );
  }
}

/// Family card: one per name-normalized family; owned-only non-selectable chips.
class CatalogWeaponFamilyCard extends StatelessWidget {
  const CatalogWeaponFamilyCard({
    super.key,
    required this.family,
    this.selected = false,
    this.showOwned = true,
    this.leading,
    this.onTap,
  });

  final WeaponFamily family;
  final bool selected;
  final bool showOwned;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final item = family.cardItem;
    // One chip per Base/Adept/Holofoil kind — not one per definition hash.
    final ownedChips =
        showOwned ? family.ownedVersionChipMembers : const <WeaponFamilyMember>[];
    final card = CatalogWeaponCard(
      item: item,
      selected: selected,
      showOwned: showOwned,
      ownedCountOverride: showOwned ? family.ownedTotal : 0,
      leading: leading,
      onTap: onTap,
    );

    // Density lock 200×112: chips overlay inside the cell (not extra height).
    return KeyedSubtree(
      key: Key('catalog_family_${family.key}'),
      child: ownedChips.isEmpty
          ? card
          : Stack(
              fit: StackFit.expand,
              children: [
                card,
                Positioned(
                  left: 6,
                  right: 6,
                  bottom: 22,
                  child: _OwnedVersionChips(
                    familyKey: family.key,
                    members: ownedChips,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Owned-only version indicators — not selectable, not NeonFacetChip cycle.
class _OwnedVersionChips extends StatelessWidget {
  const _OwnedVersionChips({
    required this.familyKey,
    required this.members,
  });

  final String familyKey;
  final List<WeaponFamilyMember> members;

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Semantics(
      label: 'Owned versions (indicators only, not selectable)',
      child: Wrap(
        key: Key('family_version_chips_$familyKey'),
        spacing: 4,
        runSpacing: 2,
        children: [
          for (final m in members)
            Container(
              // Include hash so multi-hash same-kind never trips duplicate-key
              // ErrorWidget (red unclickable card) if a caller skips kind dedupe.
              key: Key('family_version_chip_${m.kind.name}_${m.hash}_$familyKey'),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                border: Border.all(
                  color: palette.line.withValues(alpha: 0.65),
                  width: kFlapRuleThickness,
                ),
                borderRadius: BorderRadius.circular(2),
                color: palette.surfaceRaised.withValues(alpha: 0.5),
              ),
              child: Text(
                m.label,
                style: neonMono(color: palette.muted, fontSize: 8),
              ),
            ),
        ],
      ),
    );
  }
}

/// Flat or grouped family/item grid for weapons results.
///
/// Prefer [families] (GAP-CAT-BROWSE-001). Legacy [items] path kept for armor.
class CatalogWeaponsGrid extends StatelessWidget {
  const CatalogWeaponsGrid({
    super.key,
    this.items = const [],
    this.families,
    this.selectedHash,
    this.selectedFamilyKey,
    this.showOwned = true,
    this.onSelect,
    this.onSelectFamily,
    this.leadingBuilder,
    this.familyLeadingBuilder,
    this.headerLabel = 'CATALOG NODES · GRID',
    this.groups,
    this.familyGroups,
    this.collapsedGroupKeys = const {},
    this.onToggleGroup,
    this.groupKeys = const {},
  });

  final List<CatalogItem> items;

  /// Family browse rows (one card per family). When non-null, used over [items].
  final List<WeaponFamily>? families;

  final int? selectedHash;
  final String? selectedFamilyKey;
  final bool showOwned;
  final ValueChanged<CatalogItem>? onSelect;
  final ValueChanged<WeaponFamily>? onSelectFamily;
  final Widget Function(CatalogItem item)? leadingBuilder;
  final Widget Function(WeaponFamily family)? familyLeadingBuilder;
  final String headerLabel;

  /// Optional pre-grouped item rows (label + items). When null, flat [items].
  final List<({String key, String label, List<CatalogItem> items})>? groups;

  /// Optional pre-grouped family rows.
  final List<({String key, String label, List<WeaponFamily> families})>?
      familyGroups;

  /// Collapsed group keys (view-only; default all expanded).
  final Set<String> collapsedGroupKeys;
  final ValueChanged<String>? onToggleGroup;

  /// GlobalKeys for outline jump / ensureVisible (group key → key).
  final Map<String, GlobalKey> groupKeys;

  static const gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 200,
    mainAxisExtent: 112,
    mainAxisSpacing: kSpace8,
    crossAxisSpacing: kSpace8,
  );

  bool _isExpanded(String key) => !collapsedGroupKeys.contains(key);

  @override
  Widget build(BuildContext context) {
    final fams = families;
    final useFamilies = fams != null;
    final fGroups = familyGroups;
    final iGroups = groups;
    final useFamilyGroups =
        useFamilies && fGroups != null && fGroups.isNotEmpty;
    final useItemGroups =
        !useFamilies && iGroups != null && iGroups.isNotEmpty;

    return CustomScrollView(
      key: const Key('catalog_list'),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            key: const Key('catalog_board_header'),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Text(
              headerLabel,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
        if (useFamilyGroups)
          for (final group in fGroups) ...[
            SliverToBoxAdapter(
              child: KeyedSubtree(
                key: groupKeys[group.key],
                child: CatalogGroupHeader(
                  groupKey: group.key,
                  label: group.label,
                  count: group.families.length,
                  expanded: _isExpanded(group.key),
                  onToggle: () => onToggleGroup?.call(group.key),
                ),
              ),
            ),
            if (_isExpanded(group.key))
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                sliver: SliverGrid(
                  gridDelegate: gridDelegate,
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final family = group.families[index];
                      return CatalogWeaponFamilyCard(
                        family: family,
                        selected: selectedFamilyKey == family.key ||
                            (selectedHash != null &&
                                family.memberByHash(selectedHash!) != null),
                        showOwned: showOwned,
                        leading: familyLeadingBuilder?.call(family),
                        onTap: onSelectFamily == null
                            ? null
                            : () => onSelectFamily!(family),
                      );
                    },
                    childCount: group.families.length,
                  ),
                ),
              ),
          ]
        else if (useFamilies)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            sliver: SliverGrid(
              gridDelegate: gridDelegate,
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final family = fams[index];
                  return CatalogWeaponFamilyCard(
                    family: family,
                    selected: selectedFamilyKey == family.key ||
                        (selectedHash != null &&
                            family.memberByHash(selectedHash!) != null),
                    showOwned: showOwned,
                    leading: familyLeadingBuilder?.call(family),
                    onTap: onSelectFamily == null
                        ? null
                        : () => onSelectFamily!(family),
                  );
                },
                childCount: fams.length,
              ),
            ),
          )
        else if (!useItemGroups)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            sliver: SliverGrid(
              gridDelegate: gridDelegate,
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = items[index];
                  return CatalogWeaponCard(
                    item: item,
                    selected: selectedHash == item.hash,
                    showOwned: showOwned,
                    leading: leadingBuilder?.call(item),
                    onTap: onSelect == null ? null : () => onSelect!(item),
                  );
                },
                childCount: items.length,
              ),
            ),
          )
        else
          for (final group in iGroups) ...[
            SliverToBoxAdapter(
              child: KeyedSubtree(
                key: groupKeys[group.key],
                child: CatalogGroupHeader(
                  groupKey: group.key,
                  label: group.label,
                  count: group.items.length,
                  expanded: _isExpanded(group.key),
                  onToggle: () => onToggleGroup?.call(group.key),
                ),
              ),
            ),
            if (_isExpanded(group.key))
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                sliver: SliverGrid(
                  gridDelegate: gridDelegate,
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = group.items[index];
                      return CatalogWeaponCard(
                        item: item,
                        selected: selectedHash == item.hash,
                        showOwned: showOwned,
                        leading: leadingBuilder?.call(item),
                        onTap:
                            onSelect == null ? null : () => onSelect!(item),
                      );
                    },
                    childCount: group.items.length,
                  ),
                ),
              ),
          ],
      ],
    );
  }
}
