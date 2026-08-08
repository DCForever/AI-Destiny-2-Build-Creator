import 'canonical_order.dart';
import 'catalog_item.dart';
import 'sort_by_name.dart';

/// Dimensions that may partition catalog browse results (BR-CAT-007).
///
/// Group-by never replaces filter semantics — call [groupCatalogItems] /
/// [groupCatalogItemsNested] only on an **already-filtered** list
/// (BR-CAT-006 facets apply **before** group only).
enum CatalogGroupDimension {
  element,
  ammo,
  archetype,
  frame,
  slot,
  classType,
}

/// Separator for composite / nested path keys (matches flat `parts.join`).
const String catalogGroupPathSeparator = ' · ';

/// Compare two segment labels for [dim] (group sibling / filter order).
///
/// Canonical ranks: slot Kinetic→Energy→Power; ammo Primary→Special→Heavy;
/// element Kinetic→Stasis→Strand→Arc→Solar→Void; archetype list with
/// **Rocket Launcher last**. Unknowns after known ranks, then alpha.
int compareCatalogDimensionLabels(
  CatalogGroupDimension dim,
  String a,
  String b,
) {
  switch (dim) {
    case CatalogGroupDimension.slot:
      // Prefer weapon slot order; armor slots after weapons; unknown last.
      final wa = catalogCanonicalIndex(kCatalogSlotOrder, a);
      final wb = catalogCanonicalIndex(kCatalogSlotOrder, b);
      final aa = catalogCanonicalIndex(kCatalogArmorSlotOrder, a);
      final ab = catalogCanonicalIndex(kCatalogArmorSlotOrder, b);
      final ra = wa < kCatalogSlotOrder.length
          ? wa
          : (aa < kCatalogArmorSlotOrder.length
              ? kCatalogSlotOrder.length + aa
              : kCatalogSlotOrder.length + kCatalogArmorSlotOrder.length);
      final rb = wb < kCatalogSlotOrder.length
          ? wb
          : (ab < kCatalogArmorSlotOrder.length
              ? kCatalogSlotOrder.length + ab
              : kCatalogSlotOrder.length + kCatalogArmorSlotOrder.length);
      if (ra != rb) return ra.compareTo(rb);
      return compareDisplayName(a, b);
    case CatalogGroupDimension.ammo:
      return compareCanonicalLabels(a, b, kCatalogAmmoOrder);
    case CatalogGroupDimension.element:
      return compareCanonicalLabels(a, b, kCatalogElementOrder);
    case CatalogGroupDimension.archetype:
      return compareCanonicalLabels(a, b, kCatalogWeaponArchetypeOrder);
    case CatalogGroupDimension.classType:
      return compareCanonicalLabels(a, b, kCatalogClassOrder);
    case CatalogGroupDimension.frame:
      return compareDisplayName(a, b);
  }
}

/// Compare flat multi-dim path keys (e.g. `Energy · Solar`) under [dimensions].
int compareCatalogGroupPathKeys(
  String keyA,
  String keyB,
  List<CatalogGroupDimension> dimensions,
) {
  if (dimensions.isEmpty) return compareDisplayName(keyA, keyB);
  final pa = keyA.split(catalogGroupPathSeparator);
  final pb = keyB.split(catalogGroupPathSeparator);
  final n = dimensions.length;
  for (var i = 0; i < n; i++) {
    final sa = i < pa.length ? pa[i] : '';
    final sb = i < pb.length ? pb[i] : '';
    final cmp = compareCatalogDimensionLabels(dimensions[i], sa, sb);
    if (cmp != 0) return cmp;
  }
  return compareDisplayName(keyA, keyB);
}

/// One **flat** partition of a filtered catalog list (DART-062).
///
/// Prefer [groupCatalogItemsNested] for multi-level trees; this flat API remains
/// for hosts still rendering composite `A · B · C` headers.
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

/// One node in a nested multi-level group-by tree (DART-072 / GAP-UI-CATALOG-11).
///
/// - [key] is the full path from the root of the tree
///   (`segment₁ · segment₂ · …`), stable for expand/collapse sets and JUMP.
/// - [label] is the segment at this depth only (not the full path).
/// - [count] is the rollup of all leaf items under this node.
/// - [children] are deeper dimension partitions (empty at the deepest level).
/// - [items] are leaf catalog rows only at the deepest dimension (or the single
///   "All results" node when no dimensions were requested).
///
/// Armor and weapons share this type — no weapons-only fork.
class CatalogGroupNode {
  const CatalogGroupNode({
    required this.key,
    required this.label,
    required this.count,
    this.children = const [],
    this.items = const [],
  });

  /// Full path key (e.g. `Energy · Solar`). Empty-dimension root is `__all__`.
  final String key;

  /// Display label for this level only (e.g. `Solar`, not `Energy · Solar`).
  final String label;

  /// Rollup count of leaf items under this node (includes nested children).
  final int count;

  /// Child partitions at the next dimension; empty when this node holds [items].
  final List<CatalogGroupNode> children;

  /// Leaf items when this node is at the deepest dimension (or ungrouped root).
  final List<CatalogItem> items;

  /// True when this node has nested dimension children (can expand/collapse).
  bool get isExpandable => children.isNotEmpty;
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

/// Build a composite / nested path key from ordered path [segments].
String catalogGroupPathKey(Iterable<String> segments) =>
    segments.join(catalogGroupPathSeparator);

/// Partition [items] by [dimensions] into a **flat** list of composite groups.
///
/// Empty [dimensions] → single "All results" group that **preserves** [items]
/// order (caller owns sort: weapons slot→exotic→ammo→archetype, armor/universal
/// alpha via [filterCatalogClient]). Group labels use **canonical** dimension
/// order; within a multi-dim group, relative input order is preserved (BR-CAT-007).
///
/// **Contract:** filters (BR-CAT-006) must already have been applied; this
/// function never re-filters.
List<CatalogGroup> groupCatalogItems(
  List<CatalogItem> items,
  List<CatalogGroupDimension> dimensions,
) {
  if (dimensions.isEmpty) {
    return [
      CatalogGroup(
        key: '__all__',
        label: 'All results',
        items: List<CatalogItem>.from(items),
      ),
    ];
  }

  final buckets = <String, List<CatalogItem>>{};
  for (final item in items) {
    final parts = dimensions.map((d) => dimensionValue(item, d)).toList();
    final key = catalogGroupPathKey(parts);
    (buckets[key] ??= <CatalogItem>[]).add(item);
  }

  final groups = buckets.entries
      .map(
        (e) => CatalogGroup(
          key: e.key,
          label: e.key,
          // Preserve encounter order within the bucket (input order).
          items: List<CatalogItem>.from(e.value),
        ),
      )
      .toList();
  groups.sort(
    (a, b) => compareCatalogGroupPathKeys(a.key, b.key, dimensions),
  );
  return groups;
}

/// Partition [items] into a **nested** multi-level tree ordered by [dimensions].
///
/// Each dimension becomes one tree level. Sibling nodes at a level use
/// **canonical** order for that dimension (slot/ammo/element/archetype); relative
/// input order of items within a leaf is preserved. Reordering [dimensions]
/// re-parents the tree (same membership).
///
/// Single-dimension trees match [groupCatalogItems] shape: same keys, same
/// leaf item lists (labels are the segment only, equal to the flat key when
/// there is one dimension).
///
/// Empty [dimensions] → single "All results" root with all [items] (same as flat).
///
/// **Contract:** call only on an already-filtered list (BR-CAT-006). Group-by
/// never rewrites filters; collapse (see [isCatalogGroupExpanded]) is view-only
/// (BR-CAT-007).
List<CatalogGroupNode> groupCatalogItemsNested(
  List<CatalogItem> items,
  List<CatalogGroupDimension> dimensions,
) {
  if (dimensions.isEmpty) {
    return [
      CatalogGroupNode(
        key: '__all__',
        label: 'All results',
        count: items.length,
        items: List<CatalogItem>.from(items),
      ),
    ];
  }
  return _partitionNested(items, dimensions, const []);
}

List<CatalogGroupNode> _partitionNested(
  List<CatalogItem> items,
  List<CatalogGroupDimension> dimensions,
  List<String> pathPrefix,
) {
  final dim = dimensions.first;
  final rest = dimensions.sublist(1);
  final buckets = <String, List<CatalogItem>>{};
  for (final item in items) {
    final segment = dimensionValue(item, dim);
    (buckets[segment] ??= <CatalogItem>[]).add(item);
  }

  final segments = buckets.keys.toList()
    ..sort((a, b) => compareCatalogDimensionLabels(dim, a, b));

  return [
    for (final segment in segments)
      _nodeForBucket(
        segment: segment,
        bucket: buckets[segment]!,
        pathPrefix: pathPrefix,
        rest: rest,
      ),
  ];
}

CatalogGroupNode _nodeForBucket({
  required String segment,
  required List<CatalogItem> bucket,
  required List<String> pathPrefix,
  required List<CatalogGroupDimension> rest,
}) {
  final path = [...pathPrefix, segment];
  final key = catalogGroupPathKey(path);
  if (rest.isEmpty) {
    return CatalogGroupNode(
      key: key,
      label: segment,
      count: bucket.length,
      items: List<CatalogItem>.from(bucket),
    );
  }
  final children = _partitionNested(bucket, rest, path);
  final count = children.fold<int>(0, (n, c) => n + c.count);
  return CatalogGroupNode(
    key: key,
    label: segment,
    count: count,
    children: children,
  );
}

// ---------------------------------------------------------------------------
// Collapse helpers (view-only — BR-CAT-007; never rewrites filters / membership)
// ---------------------------------------------------------------------------

/// Whether [pathKey] is expanded in the host's expand set.
///
/// Collapse is **view-only**: it never changes filter state or tree membership
/// produced by [groupCatalogItemsNested].
bool isCatalogGroupExpanded(String pathKey, Set<String> expandedKeys) =>
    expandedKeys.contains(pathKey);

/// All path keys of expandable (non-leaf) nodes under [roots].
///
/// Useful for expand-all / collapse-all UI without walking the tree in the host.
Set<String> expandableCatalogGroupKeys(Iterable<CatalogGroupNode> roots) {
  final keys = <String>{};
  void walk(CatalogGroupNode node) {
    if (node.isExpandable) {
      keys.add(node.key);
      for (final child in node.children) {
        walk(child);
      }
    }
  }

  for (final root in roots) {
    walk(root);
  }
  return keys;
}

/// Depth-first walk of nodes that should be **visible** under [expandedKeys].
///
/// - Root nodes are always visited.
/// - A node's children are visited only when [isCatalogGroupExpanded] is true
///   for that node's [CatalogGroupNode.key].
/// - Collapsing a parent hides all descendants without dropping them from the
///   underlying tree (view-only; BR-CAT-007).
///
/// [visit] receives the node and its depth (0 = roots).
void visitVisibleCatalogGroupNodes(
  Iterable<CatalogGroupNode> roots,
  Set<String> expandedKeys,
  void Function(CatalogGroupNode node, int depth) visit,
) {
  void walk(CatalogGroupNode node, int depth) {
    visit(node, depth);
    if (!node.isExpandable) return;
    if (!isCatalogGroupExpanded(node.key, expandedKeys)) return;
    for (final child in node.children) {
      walk(child, depth + 1);
    }
  }

  for (final root in roots) {
    walk(root, 0);
  }
}

/// Flatten visible nodes under [expandedKeys] as `(node, depth)` pairs.
///
/// Same visibility rules as [visitVisibleCatalogGroupNodes].
List<({CatalogGroupNode node, int depth})> flattenVisibleCatalogGroupNodes(
  Iterable<CatalogGroupNode> roots,
  Set<String> expandedKeys,
) {
  final out = <({CatalogGroupNode node, int depth})>[];
  visitVisibleCatalogGroupNodes(roots, expandedKeys, (node, depth) {
    out.add((node: node, depth: depth));
  });
  return out;
}

// ---------------------------------------------------------------------------
// Path / collapse helpers for host collapsed-set model (BR-CAT-007)
// ---------------------------------------------------------------------------

/// Ancestor path keys of [pathKey] (root-first), excluding [pathKey] itself.
///
/// Example: `Energy · Arc` → `[Energy]`; `A · B · C` → `[A, A · B]`.
List<String> catalogGroupAncestorKeys(String pathKey) {
  if (pathKey.isEmpty || pathKey == '__all__') return const [];
  final parts = pathKey.split(catalogGroupPathSeparator);
  if (parts.length <= 1) return const [];
  final out = <String>[];
  for (var i = 1; i < parts.length; i++) {
    out.add(parts.sublist(0, i).join(catalogGroupPathSeparator));
  }
  return out;
}

/// True when [pathKey] and all ancestors are **not** in [collapsedKeys].
///
/// Used by JUMP: re-click a fully open path collapses it; a closed path expands
/// ancestors + target (view-only).
bool isCatalogGroupPathFullyOpen(String pathKey, Set<String> collapsedKeys) {
  if (collapsedKeys.contains(pathKey)) return false;
  for (final a in catalogGroupAncestorKeys(pathKey)) {
    if (collapsedKeys.contains(a)) return false;
  }
  return true;
}

/// Expandable keys that are currently expanded under a **collapsed** set model.
///
/// Hosts that store collapsed path keys can convert for [visitVisibleCatalogGroupNodes].
Set<String> expandedCatalogGroupKeysFromCollapsed(
  Iterable<CatalogGroupNode> roots,
  Set<String> collapsedKeys,
) {
  final expandable = expandableCatalogGroupKeys(roots);
  return expandable.difference(collapsedKeys);
}

/// Depth-first flatten of **all** nodes (ignores collapse) for JUMP outline rows.
List<({CatalogGroupNode node, int depth})> flattenAllCatalogGroupNodes(
  Iterable<CatalogGroupNode> roots,
) {
  final out = <({CatalogGroupNode node, int depth})>[];
  void walk(CatalogGroupNode node, int depth) {
    out.add((node: node, depth: depth));
    for (final c in node.children) {
      walk(c, depth + 1);
    }
  }

  for (final r in roots) {
    walk(r, 0);
  }
  return out;
}

/// Dimension at [depth] for icon resolution (null when out of range).
CatalogGroupDimension? catalogGroupDimensionAt(
  List<CatalogGroupDimension> dimensions,
  int depth,
) {
  if (depth < 0 || depth >= dimensions.length) return null;
  return dimensions[depth];
}
