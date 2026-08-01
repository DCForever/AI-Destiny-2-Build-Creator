import 'catalog_item.dart';
import 'facet_filter.dart';
import 'sort_by_name.dart';

/// Catalog browse ownership scope (product `scope: "all" | "owned"`).
enum CatalogScope {
  /// All base definitions (annotated ownership is informational).
  all,

  /// Only rows with [CatalogItem.ownedCount] &gt; 0.
  owned,
}

/// Combined client-side catalog filters (product `CatalogClientFilters`).
class CatalogClientFilters {
  const CatalogClientFilters({
    this.query,
    this.slot,
    this.slots,
    this.elements,
    this.ammos,
    this.archetypes,
    this.classNames,
    this.className,
    this.exotic,
    this.onlyExotic = false,
    this.synergies,
    this.itemHashesInclude,
    this.itemHashesExclude,
    this.scope = CatalogScope.all,
  });

  final String? query;

  /// @deprecated Prefer [slots]; single slot treated as include.
  final String? slot;

  /// FacetFilter or List&lt;String&gt; (include-only).
  final Object? slots;
  final Object? elements;
  final Object? ammos;

  /// Weapon itemTypeName or armor frame.
  final Object? archetypes;
  final Object? classNames;
  final String? className;

  /// true = only exotic; false = exclude exotic; null = no constraint.
  final bool? exotic;

  /// Legacy: maps to exotic == true when [exotic] is null.
  final bool onlyExotic;

  final FacetFilter? synergies;
  final Set<int>? itemHashesInclude;
  final Set<int>? itemHashesExclude;

  /// All vs owned (DART-026). Owned requires annotated [CatalogItem.ownedCount].
  final CatalogScope scope;

  CatalogClientFilters copyWith({
    String? query,
    String? slot,
    Object? slots,
    Object? elements,
    Object? ammos,
    Object? archetypes,
    Object? classNames,
    String? className,
    bool? exotic,
    bool? onlyExotic,
    FacetFilter? synergies,
    Set<int>? itemHashesInclude,
    Set<int>? itemHashesExclude,
    CatalogScope? scope,
  }) {
    return CatalogClientFilters(
      query: query ?? this.query,
      slot: slot ?? this.slot,
      slots: slots ?? this.slots,
      elements: elements ?? this.elements,
      ammos: ammos ?? this.ammos,
      archetypes: archetypes ?? this.archetypes,
      classNames: classNames ?? this.classNames,
      className: className ?? this.className,
      exotic: exotic ?? this.exotic,
      onlyExotic: onlyExotic ?? this.onlyExotic,
      synergies: synergies ?? this.synergies,
      itemHashesInclude: itemHashesInclude ?? this.itemHashesInclude,
      itemHashesExclude: itemHashesExclude ?? this.itemHashesExclude,
      scope: scope ?? this.scope,
    );
  }
}

bool matchesArchetypeFacet(FacetFilter? facet, CatalogItem item) {
  final f = normalizeFacet(facet);
  if (isFacetEmpty(f)) return true;

  final candidates = <String>[];
  for (final raw in [item.itemTypeName, item.frame]) {
    if (raw == null || raw.trim().isEmpty) continue;
    final t = raw.trim();
    candidates.add(t);
    final bare = t.replaceAll(RegExp(r'\s*Frame$', caseSensitive: false), '').trim();
    if (bare.isNotEmpty && bare != t) candidates.add(bare);
  }

  for (final c in candidates) {
    for (final ex in f.exclude) {
      if (c == ex || c.contains(ex) || ex.contains(c)) return false;
    }
  }
  if (f.include.isEmpty) return true;
  return f.include.any(
    (inc) => candidates.any((c) => c == inc || c.contains(inc) || inc.contains(c)),
  );
}

bool matchesSynergyIds(FacetFilter? facet, List<String>? linked) {
  final f = normalizeFacet(facet);
  if (isFacetEmpty(f)) return true;
  final set = {...?linked};
  for (final id in f.exclude) {
    if (set.contains(id)) return false;
  }
  if (f.include.isEmpty) return true;
  return f.include.any(set.contains);
}

/// Live client-side narrowing of a base catalog list.
/// Across facets: AND. Within include: OR. Any exclude match: drop.
/// Results are alpha-sorted by display name (GAP-UI-CATALOG-07).
List<CatalogItem> filterCatalogClient(
  List<CatalogItem> items,
  CatalogClientFilters filters,
) {
  final q = filters.query?.trim().toLowerCase() ?? '';

  final elements = normalizeFacet(filters.elements);
  final ammos = normalizeFacet(filters.ammos);
  final archetypes = normalizeFacet(filters.archetypes);

  final slots = normalizeFacet(
    filters.slots ??
        (filters.slot != null
            ? FacetFilter(include: [filters.slot!])
            : null),
  );

  final classNames = normalizeFacet(
    filters.classNames ??
        (filters.className != null
            ? FacetFilter(include: [filters.className!])
            : null),
  );

  final bool? exotic = filters.exotic ??
      (filters.onlyExotic == true ? true : null);

  final synergies = filters.synergies;
  final includeHashes = filters.itemHashesInclude;
  final excludeHashes = filters.itemHashesExclude;
  final hasIncludeHashes = includeHashes != null && includeHashes.isNotEmpty;
  final hasExcludeHashes = excludeHashes != null && excludeHashes.isNotEmpty;

  final ownedOnly = filters.scope == CatalogScope.owned;

  final filtered = items.where((item) {
    if (ownedOnly && item.ownedCount <= 0) return false;

    if (exotic == true && !item.isExotic) return false;
    if (exotic == false && item.isExotic) return false;

    if (!matchesFacet(slots, item.slot)) return false;
    if (!matchesFacet(elements, item.element)) return false;
    if (!matchesFacet(ammos, item.ammo)) return false;
    if (!matchesFacet(classNames, item.classType)) return false;
    if (!matchesArchetypeFacet(archetypes, item)) return false;

    if (!matchesSynergyIds(synergies, item.linkedSynergyIds)) return false;

    if (hasIncludeHashes && !includeHashes.contains(item.hash)) return false;
    if (hasExcludeHashes && excludeHashes.contains(item.hash)) return false;

    if (q.isEmpty) return true;
    final hay = [
      item.name,
      item.slot,
      item.element,
      item.ammo,
      item.itemTypeName,
      item.frame,
      item.classType,
      item.description,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' ').toLowerCase();
    return hay.contains(q);
  }).toList();

  return sortByDisplayName(filtered, (i) => i.name);
}
