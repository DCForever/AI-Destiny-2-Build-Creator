import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../neon_item_card.dart';

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
  });

  final CatalogItem item;
  final bool selected;

  /// When false (signed-out), never render owned badge even if data present.
  final bool showOwned;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final owned = showOwned && item.owned;
    final ownedLabel = owned ? '×${item.ownedCount}' : null;
    // Type-only body (mock): element/slot/ammo live as glyphs, not text.
    final typeParts = <String>[
      if (item.itemTypeName != null && item.itemTypeName!.isNotEmpty)
        item.itemTypeName!,
    ];
    final typeLine = typeParts.isEmpty ? 'Weapon' : typeParts.join(' · ');

    return NeonItemCard(
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
  }
}

/// Flat identity-primary icon grid for weapons results.
class CatalogWeaponsGrid extends StatelessWidget {
  const CatalogWeaponsGrid({
    super.key,
    required this.items,
    this.selectedHash,
    this.showOwned = true,
    this.onSelect,
    this.leadingBuilder,
    this.headerLabel = 'CATALOG NODES · GRID',
    this.groups,
  });

  final List<CatalogItem> items;
  final int? selectedHash;
  final bool showOwned;
  final ValueChanged<CatalogItem>? onSelect;
  final Widget Function(CatalogItem item)? leadingBuilder;
  final String headerLabel;

  /// Optional pre-grouped rows (label + items). When null, flat [items].
  final List<({String key, String label, List<CatalogItem> items})>? groups;

  @override
  Widget build(BuildContext context) {
    // Dense grid: shorter cells, tighter gaps; card chrome fills height.
    const gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 200,
      mainAxisExtent: 112,
      mainAxisSpacing: kSpace8,
      crossAxisSpacing: kSpace8,
    );

    final grouped = groups;
    final useGroups = grouped != null && grouped.isNotEmpty;

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
        if (!useGroups)
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
          for (final group in grouped) ...[
            if (group.label.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  key: Key('catalog_group_${group.key}'),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Text(
                    '${group.label} (${group.items.length})'.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
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
                      onTap: onSelect == null ? null : () => onSelect!(item),
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
