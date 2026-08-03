import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../neon_item_card.dart';

/// Identity-primary weapon card (NeonItemCard adapter).
///
/// Owned badge only when [showOwned] and item.owned — never fakes ownership.
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
    final identityLine = [
      if (item.element != null) item.element!,
      if (item.slot != null) item.slot!,
      if (item.ammo != null) item.ammo!,
      if (item.isExotic) 'Exotic',
    ].join(' · ');
    final typeParts = <String>[
      if (identityLine.isNotEmpty) identityLine,
      if (item.itemTypeName != null) item.itemTypeName!,
      if (item.frame != null && item.frame!.isNotEmpty) item.frame!,
    ];

    return NeonItemCard(
      key: Key('catalog_item_${item.hash}'),
      name: item.name,
      slot: item.slot,
      element: item.element,
      typeLine: typeParts.isEmpty ? null : typeParts.join(' · '),
      rarity: neonItemRarity(isExotic: item.isExotic),
      ownedLabel: ownedLabel,
      selected: selected,
      minHeight: 152,
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
  });

  final List<CatalogItem> items;
  final int? selectedHash;
  final bool showOwned;
  final ValueChanged<CatalogItem>? onSelect;
  final Widget Function(CatalogItem item)? leadingBuilder;
  final String headerLabel;

  @override
  Widget build(BuildContext context) {
    const gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 260,
      mainAxisExtent: 168,
      mainAxisSpacing: kSpace12,
      crossAxisSpacing: kSpace12,
    );

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
        ),
      ],
    );
  }
}
