import 'catalog_item.dart';
import 'sort_by_name.dart';

/// Dimensions that may partition catalog browse results (BR-CAT-007).
///
/// Group-by never replaces filter semantics — call [groupCatalogItems] only on
/// an already-filtered list.
enum CatalogGroupDimension {
  element,
  ammo,
  archetype,
  frame,
  slot,
  classType,
}

/// One partition of a filtered catalog list.
class CatalogGroup {
  const CatalogGroup({
    required this.key,
    required this.label,
    required this.items,
  });

  final String key;
  final String label;
  final List<CatalogItem> items;
}

const Map<CatalogGroupDimension, String> _dimUnknown = {
  CatalogGroupDimension.element: 'Unknown element',
  CatalogGroupDimension.ammo: 'Unknown ammo',
  CatalogGroupDimension.archetype: 'Unknown type',
  CatalogGroupDimension.frame: 'Unknown frame',
  CatalogGroupDimension.slot: 'Unknown slot',
  CatalogGroupDimension.classType: 'Unknown class',
};

/// Human labels for host group-by chips (weapons-oriented set).
const List<({CatalogGroupDimension id, String label})> weaponGroupDimensions = [
  (id: CatalogGroupDimension.element, label: 'Element'),
  (id: CatalogGroupDimension.ammo, label: 'Ammo'),
  (id: CatalogGroupDimension.archetype, label: 'Archetype'),
  (id: CatalogGroupDimension.frame, label: 'Frame'),
  (id: CatalogGroupDimension.slot, label: 'Slot'),
];

/// Human labels for host group-by chips (armor-oriented set).
const List<({CatalogGroupDimension id, String label})> armorGroupDimensions = [
  (id: CatalogGroupDimension.classType, label: 'Class'),
  (id: CatalogGroupDimension.slot, label: 'Slot'),
  (id: CatalogGroupDimension.frame, label: 'Archetype'),
];

/// All group dimensions offered in mixed MVP catalog hosts.
const List<({CatalogGroupDimension id, String label})> catalogGroupDimensions = [
  (id: CatalogGroupDimension.element, label: 'Element'),
  (id: CatalogGroupDimension.ammo, label: 'Ammo'),
  (id: CatalogGroupDimension.archetype, label: 'Archetype'),
  (id: CatalogGroupDimension.frame, label: 'Frame'),
  (id: CatalogGroupDimension.slot, label: 'Slot'),
  (id: CatalogGroupDimension.classType, label: 'Class'),
];

String dimensionValue(CatalogItem item, CatalogGroupDimension dim) {
  switch (dim) {
    case CatalogGroupDimension.element:
      final v = item.element?.trim();
      return (v == null || v.isEmpty) ? _dimUnknown[dim]! : v;
    case CatalogGroupDimension.ammo:
      final v = item.ammo?.trim();
      return (v == null || v.isEmpty) ? _dimUnknown[dim]! : v;
    case CatalogGroupDimension.archetype:
      final v = item.itemTypeName?.trim();
      return (v == null || v.isEmpty) ? _dimUnknown[dim]! : v;
    case CatalogGroupDimension.frame:
      final v = item.frame?.trim();
      return (v == null || v.isEmpty) ? _dimUnknown[dim]! : v;
    case CatalogGroupDimension.slot:
      final v = item.slot?.trim();
      return (v == null || v.isEmpty) ? _dimUnknown[dim]! : v;
    case CatalogGroupDimension.classType:
      final v = item.classType?.trim();
      return (v == null || v.isEmpty) ? _dimUnknown[dim]! : v;
  }
}

/// Partition [items] by [dimensions] without changing membership.
///
/// Empty [dimensions] → single "All results" group. Items and group labels are
/// alpha-sorted by display name (PRODUCT-CAT-ALPHA-SORT / BR-CAT-007).
List<CatalogGroup> groupCatalogItems(
  List<CatalogItem> items,
  List<CatalogGroupDimension> dimensions,
) {
  if (dimensions.isEmpty) {
    return [
      CatalogGroup(
        key: '__all__',
        label: 'All results',
        items: sortByDisplayName(items, (i) => i.name),
      ),
    ];
  }

  final buckets = <String, List<CatalogItem>>{};
  for (final item in items) {
    final parts = dimensions.map((d) => dimensionValue(item, d)).toList();
    final key = parts.join(' · ');
    (buckets[key] ??= <CatalogItem>[]).add(item);
  }

  final groups = buckets.entries
      .map(
        (e) => CatalogGroup(
          key: e.key,
          label: e.key,
          items: sortByDisplayName(e.value, (i) => i.name),
        ),
      )
      .toList();
  groups.sort((a, b) => compareDisplayName(a.label, b.label));
  return groups;
}
