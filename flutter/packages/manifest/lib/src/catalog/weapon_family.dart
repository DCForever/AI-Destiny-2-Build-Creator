import '../normalize.dart';
import 'catalog_item.dart';
import 'filter_catalog.dart';
import 'canonical_order.dart';
import 'group_catalog.dart';
import 'sort_by_name.dart';
import 'sort_weapons.dart';

/// Version kind derived from display name (Adept / Holofoil / base).
///
/// No invented collectible graph — name-suffix only (GAP-CAT-BROWSE-001).
enum WeaponVersionKind {
  base,
  adept,
  holofoil,
}

/// Short label for owned version chips / detail switcher.
String weaponVersionLabel(WeaponVersionKind kind) {
  switch (kind) {
    case WeaponVersionKind.base:
      return 'Base';
    case WeaponVersionKind.adept:
      return 'Adept';
    case WeaponVersionKind.holofoil:
      return 'Holofoil';
  }
}

/// Detail version-switch label for [m] within [members].
///
/// **Base is implied** (BUG-20260807-005): unique base → "Default" / owned ×N
/// without the word "Base". Adept / Holofoil stay explicit.
/// **Never append hashes** when kinds collide — use stable `#n` ordinals.
String weaponVersionSwitchLabel(
  WeaponFamilyMember m,
  List<WeaponFamilyMember> members,
) {
  final sameKind = <WeaponFamilyMember>[
    for (final other in members)
      if (other.kind == m.kind) other,
  ];
  final kindCount = sameKind.length;
  final ownedSuffix = m.ownedCount > 0 ? ' ×${m.ownedCount}' : '';

  if (m.kind == WeaponVersionKind.base) {
    if (kindCount <= 1) {
      // Base implied — do not print "Base".
      return m.ownedCount > 0 ? '×${m.ownedCount}' : 'Default';
    }
    final index = sameKind.indexWhere((o) => o.hash == m.hash) + 1;
    return '#$index$ownedSuffix';
  }

  // Adept / Holofoil always explicit.
  final kindLabel = m.label;
  if (kindCount <= 1) return '$kindLabel$ownedSuffix';
  final index = sameKind.indexWhere((o) => o.hash == m.hash) + 1;
  return '$kindLabel #$index$ownedSuffix';
}

/// Detect Adept / Holofoil from a weapon display name.
WeaponVersionKind weaponVersionKindFromName(String name) {
  final n = name.trim().toLowerCase();
  // Holofoil before Adept: some marketing strings may stack tokens.
  if (RegExp(r'\bholofoil\b').hasMatch(n) ||
      n.endsWith('(holofoil)') ||
      n.contains(' holofoil')) {
    return WeaponVersionKind.holofoil;
  }
  if (RegExp(r'\badept\b').hasMatch(n) ||
      n.endsWith('(adept)') ||
      n.contains(' adept')) {
    return WeaponVersionKind.adept;
  }
  return WeaponVersionKind.base;
}

/// Strip Adept/Holofoil version tokens for family merge (under-merge OK).
String stripWeaponVersionSuffix(String name) {
  var s = name.trim();
  // Parenthetical forms: "Midnight Coup (Adept)"
  s = s.replaceAll(
    RegExp(r'\s*\((adept|holofoil)\)\s*$', caseSensitive: false),
    '',
  );
  // Trailing tokens: "Midnight Coup Adept" / "… Holofoil"
  s = s.replaceAll(
    RegExp(r'\s+(adept|holofoil)\s*$', caseSensitive: false),
    '',
  );
  return s.trim().isEmpty ? name.trim() : s.trim();
}

/// Family merge key: name-normalized (version stripped) + slot + element + type.
String weaponFamilyKey(CatalogItem item) {
  final baseName = stripWeaponVersionSuffix(item.name);
  final nameKey = normalizeName(baseName);
  final slot = (item.slot ?? '').trim().toLowerCase();
  final element = (item.element ?? '').trim().toLowerCase();
  final type = (item.itemTypeName ?? item.frame ?? '').trim().toLowerCase();
  return '$nameKey|$slot|$element|$type';
}

/// One definition member of a weapon family (base / adept / holofoil, etc.).
class WeaponFamilyMember {
  const WeaponFamilyMember({
    required this.item,
    required this.kind,
  });

  final CatalogItem item;
  final WeaponVersionKind kind;

  int get hash => item.hash;
  String get label => weaponVersionLabel(kind);
  bool get owned => item.owned || item.ownedCount > 0;
  int get ownedCount => item.ownedCount;
}

/// Collapsed browse identity: one card for base + Adept + Holofoil variants.
///
/// Merge is name-normalized + slot/element/type only (no collectible graph).
class WeaponFamily {
  WeaponFamily({
    required this.key,
    required List<WeaponFamilyMember> members,
  }) : members = List<WeaponFamilyMember>.unmodifiable(
          _stableMemberOrder(members),
        );

  final String key;
  final List<WeaponFamilyMember> members;

  /// Base (non-Adept/non-Holofoil) when present; else first stable member.
  WeaponFamilyMember get primaryMember {
    for (final m in members) {
      if (m.kind == WeaponVersionKind.base) return m;
    }
    return members.first;
  }

  /// Cleaned display name for the family card (version tokens stripped).
  String get displayName => stripWeaponVersionSuffix(primaryMember.item.name);

  /// Art / identity for the grid card (base when present).
  CatalogItem get cardItem {
    final p = primaryMember.item;
    final clean = displayName;
    if (p.name == clean) return p;
    return p.copyWith(name: clean);
  }

  /// Sum of owned instance counts across family members.
  int get ownedTotal {
    var n = 0;
    for (final m in members) {
      n += m.ownedCount;
    }
    return n;
  }

  bool get anyOwned => ownedTotal > 0;

  /// Owned members only (all definition hashes with copies).
  ///
  /// Prefer [ownedVersionChipMembers] for grid chips — Destiny often has
  /// multiple hashes for one Base/Adept/Holofoil kind (tiers, watermarks).
  List<WeaponFamilyMember> get ownedMembers =>
      members.where((m) => m.ownedCount > 0).toList();

  /// Grid version chips: **one chip per version kind** among owned members.
  ///
  /// Collapses multi-hash same-kind rows (e.g. five "Ribbontail" Base defs)
  /// so the card shows Base / Adept / Holofoil once each, not Base×N.
  /// Representative is the first owned member of that kind in stable order.
  List<WeaponFamilyMember> get ownedVersionChipMembers {
    final seen = <WeaponVersionKind>{};
    final out = <WeaponFamilyMember>[];
    for (final m in members) {
      if (m.ownedCount <= 0) continue;
      if (!seen.add(m.kind)) continue;
      out.add(m);
    }
    return out;
  }

  /// Count of members sharing [kind] (definition-hash fan-out).
  int memberCountForKind(WeaponVersionKind kind) {
    var n = 0;
    for (final m in members) {
      if (m.kind == kind) n++;
    }
    return n;
  }

  /// Detail switch label: kind (+ owned ×N), disambiguated when kinds collide.
  String versionSwitchLabel(WeaponFamilyMember m) =>
      weaponVersionSwitchLabel(m, members);

  WeaponFamilyMember? memberByHash(int hash) {
    for (final m in members) {
      if (m.hash == hash) return m;
    }
    return null;
  }

  /// Stable order: base → adept → holofoil → other (by hash).
  static List<WeaponFamilyMember> _stableMemberOrder(
    List<WeaponFamilyMember> raw,
  ) {
    final list = List<WeaponFamilyMember>.from(raw);
    int rank(WeaponVersionKind k) {
      switch (k) {
        case WeaponVersionKind.base:
          return 0;
        case WeaponVersionKind.adept:
          return 1;
        case WeaponVersionKind.holofoil:
          return 2;
      }
    }

    list.sort((a, b) {
      final r = rank(a.kind).compareTo(rank(b.kind));
      if (r != 0) return r;
      return a.hash.compareTo(b.hash);
    });
    return list;
  }
}

/// Merge [items] into families (one card per family).
///
/// Order of first-seen families is preserved; members sorted stably inside.
List<WeaponFamily> groupWeaponFamilies(Iterable<CatalogItem> items) {
  final buckets = <String, List<WeaponFamilyMember>>{};
  final order = <String>[];
  for (final item in items) {
    final key = weaponFamilyKey(item);
    if (!buckets.containsKey(key)) {
      order.add(key);
      buckets[key] = <WeaponFamilyMember>[];
    }
    buckets[key]!.add(
      WeaponFamilyMember(
        item: item,
        kind: weaponVersionKindFromName(item.name),
      ),
    );
  }
  return [
    for (final key in order) WeaponFamily(key: key, members: buckets[key]!),
  ];
}

/// Filter families so a family survives if **any** member matches [filters].
///
/// Owned scope: family visible only when [WeaponFamily.ownedTotal] &gt; 0
/// (after member annotation). Exclude drops the family only if all members fail.
List<WeaponFamily> filterWeaponFamilies(
  Iterable<WeaponFamily> families,
  CatalogClientFilters filters,
) {
  final out = <WeaponFamily>[];
  for (final family in families) {
    final surviving = filterCatalogClient(
      family.members.map((m) => m.item).toList(),
      // Scope is applied at family level for owned totals.
      filters.copyWith(scope: CatalogScope.all),
    );
    if (surviving.isEmpty) continue;
    if (filters.scope == CatalogScope.owned && family.ownedTotal <= 0) {
      continue;
    }
    // Keep full family membership for detail version strip.
    out.add(family);
  }
  return out;
}

/// Members that individually match [filters] (for openVersion disambiguation).
List<WeaponFamilyMember> matchingFamilyMembers(
  WeaponFamily family,
  CatalogClientFilters filters,
) {
  final hashes = filterCatalogClient(
    family.members.map((m) => m.item).toList(),
    filters.copyWith(scope: CatalogScope.all),
  ).map((i) => i.hash).toSet();
  return family.members.where((m) => hashes.contains(m.hash)).toList();
}

/// Card-tap open target: owned max-power → base → stable first.
///
/// When filters disambiguate to a single matching member, open that member.
/// [maxPowerByHash] is optional host max-power among owned instances per hash.
CatalogItem openVersionForFamily(
  WeaponFamily family, {
  CatalogClientFilters? filters,
  Map<int, int>? maxPowerByHash,
}) {
  final f = filters ?? const CatalogClientFilters();
  final matching = matchingFamilyMembers(family, f);
  if (matching.length == 1) {
    return matching.single.item;
  }

  final pool = matching.isNotEmpty ? matching : family.members;

  // Prefer owned with highest power when power data exists.
  final power = maxPowerByHash;
  if (power != null && power.isNotEmpty) {
    WeaponFamilyMember? best;
    var bestPower = -1;
    for (final m in pool) {
      if (m.ownedCount <= 0) continue;
      final p = power[m.hash];
      if (p == null) continue;
      if (best == null || p > bestPower) {
        best = m;
        bestPower = p;
      }
    }
    if (best != null) return best.item;

    // Owned without power map entries: prefer any owned in pool.
    for (final m in pool) {
      if (m.ownedCount > 0) return m.item;
    }
  } else {
    // No power map: still prefer owned among pool, base first.
    final owned = pool.where((x) => x.ownedCount > 0).toList();
    if (owned.isNotEmpty) {
      for (final o in owned) {
        if (o.kind == WeaponVersionKind.base) return o.item;
      }
      return owned.first.item;
    }
  }

  // Base / non-Adept / non-Holofoil when present among pool.
  for (final m in pool) {
    if (m.kind == WeaponVersionKind.base) return m.item;
  }
  return pool.first.item;
}

/// Sort families using multi-key priority (applied to [WeaponFamily.cardItem]).
List<WeaponFamily> sortWeaponFamilies(
  Iterable<WeaponFamily> families, {
  List<CatalogSortKey> sortKeys = kDefaultWeaponSortKeys,
}) {
  final list = List<WeaponFamily>.from(families);
  list.sort(
    (a, b) => compareCatalogItemsByKeys(
      a.cardItem,
      b.cardItem,
      sortKeys,
    ),
  );
  return list;
}

/// Build browse rows: group → filter any-member → multi-key sort.
List<WeaponFamily> buildWeaponFamilyBrowse(
  Iterable<CatalogItem> items, {
  CatalogClientFilters filters = const CatalogClientFilters(),
  List<CatalogSortKey> sortKeys = kDefaultWeaponSortKeys,
}) {
  final families = groupWeaponFamilies(items);
  final surviving = filterWeaponFamilies(families, filters);
  return sortWeaponFamilies(surviving, sortKeys: sortKeys);
}

/// Partition of family browse results (mirrors [CatalogGroup] for items).
class CatalogFamilyGroup {
  const CatalogFamilyGroup({
    required this.key,
    required this.label,
    required this.families,
  });

  final String key;
  final String label;
  final List<WeaponFamily> families;
}

/// Group families by catalog dimensions (BR-CAT-007; view-only partitions).
///
/// Uses [WeaponFamily.cardItem] for dimension values. Empty dimensions → one
/// "All results" group preserving input order.
///
/// Prefer [groupWeaponFamilyBrowseNested] for multi-level trees; this flat API
/// remains for single-dim / migration callers.
List<CatalogFamilyGroup> groupWeaponFamilyBrowse(
  List<WeaponFamily> families,
  List<CatalogGroupDimension> dimensions,
) {
  if (dimensions.isEmpty) {
    return [
      CatalogFamilyGroup(
        key: '__all__',
        label: 'All results',
        families: List<WeaponFamily>.from(families),
      ),
    ];
  }

  final buckets = <String, List<WeaponFamily>>{};
  for (final family in families) {
    final parts =
        dimensions.map((d) => dimensionValue(family.cardItem, d)).toList();
    final key = catalogGroupPathKey(parts);
    (buckets[key] ??= <WeaponFamily>[]).add(family);
  }

  final groups = buckets.entries
      .map(
        (e) => CatalogFamilyGroup(
          key: e.key,
          label: e.key,
          families: List<WeaponFamily>.from(e.value),
        ),
      )
      .toList();
  groups.sort(
    (a, b) => compareCatalogGroupPathKeys(a.key, b.key, dimensions),
  );
  return groups;
}

/// One node in a nested multi-level family group-by tree (DART-072 / UX nested).
///
/// Mirrors [CatalogGroupNode] with [WeaponFamily] leaves. Path keys and collapse
/// helpers are shared with the item tree API.
class CatalogFamilyGroupNode {
  const CatalogFamilyGroupNode({
    required this.key,
    required this.label,
    required this.count,
    this.children = const [],
    this.families = const [],
  });

  final String key;
  final String label;
  final int count;
  final List<CatalogFamilyGroupNode> children;
  final List<WeaponFamily> families;

  bool get isExpandable => children.isNotEmpty;
}

/// Nested multi-level family group-by tree from ordered [dimensions].
///
/// Same contracts as [groupCatalogItemsNested]: filters applied before group;
/// collapse is view-only (BR-CAT-007); labels are segment-only.
List<CatalogFamilyGroupNode> groupWeaponFamilyBrowseNested(
  List<WeaponFamily> families,
  List<CatalogGroupDimension> dimensions,
) {
  if (dimensions.isEmpty) {
    return [
      CatalogFamilyGroupNode(
        key: '__all__',
        label: 'All results',
        count: families.length,
        families: List<WeaponFamily>.from(families),
      ),
    ];
  }
  return _partitionFamilyNested(families, dimensions, const []);
}

List<CatalogFamilyGroupNode> _partitionFamilyNested(
  List<WeaponFamily> families,
  List<CatalogGroupDimension> dimensions,
  List<String> pathPrefix,
) {
  final dim = dimensions.first;
  final rest = dimensions.sublist(1);
  final buckets = <String, List<WeaponFamily>>{};
  for (final family in families) {
    final segment = dimensionValue(family.cardItem, dim);
    (buckets[segment] ??= <WeaponFamily>[]).add(family);
  }

  final segments = buckets.keys.toList()
    ..sort((a, b) => compareCatalogDimensionLabels(dim, a, b));

  return [
    for (final segment in segments)
      _familyNodeForBucket(
        segment: segment,
        bucket: buckets[segment]!,
        pathPrefix: pathPrefix,
        rest: rest,
      ),
  ];
}

CatalogFamilyGroupNode _familyNodeForBucket({
  required String segment,
  required List<WeaponFamily> bucket,
  required List<String> pathPrefix,
  required List<CatalogGroupDimension> rest,
}) {
  final path = [...pathPrefix, segment];
  final key = catalogGroupPathKey(path);
  if (rest.isEmpty) {
    return CatalogFamilyGroupNode(
      key: key,
      label: segment,
      count: bucket.length,
      families: List<WeaponFamily>.from(bucket),
    );
  }
  final children = _partitionFamilyNested(bucket, rest, path);
  final count = children.fold<int>(0, (n, c) => n + c.count);
  return CatalogFamilyGroupNode(
    key: key,
    label: segment,
    count: count,
    children: children,
  );
}

/// Expandable path keys under family nested roots.
Set<String> expandableFamilyGroupKeys(Iterable<CatalogFamilyGroupNode> roots) {
  final keys = <String>{};
  void walk(CatalogFamilyGroupNode node) {
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

/// Depth-first flatten of all family nodes (for JUMP outline; ignores collapse).
List<({CatalogFamilyGroupNode node, int depth})> flattenAllFamilyGroupNodes(
  Iterable<CatalogFamilyGroupNode> roots,
) {
  final out = <({CatalogFamilyGroupNode node, int depth})>[];
  void walk(CatalogFamilyGroupNode node, int depth) {
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

/// Visible family nodes under a **collapsed** set (roots always visited).
void visitVisibleFamilyGroupNodes(
  Iterable<CatalogFamilyGroupNode> roots,
  Set<String> collapsedKeys,
  void Function(CatalogFamilyGroupNode node, int depth) visit,
) {
  void walk(CatalogFamilyGroupNode node, int depth) {
    visit(node, depth);
    if (!node.isExpandable) return;
    if (collapsedKeys.contains(node.key)) return;
    for (final child in node.children) {
      walk(child, depth + 1);
    }
  }

  for (final root in roots) {
    walk(root, 0);
  }
}
