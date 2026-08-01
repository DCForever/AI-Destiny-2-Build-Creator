/// DIM-informed facet: multi-value chips support include (OR within) and
/// exclude (any match drops). Free-text is separate on [CatalogClientFilters].
class FacetFilter {
  const FacetFilter({
    this.include = const [],
    this.exclude = const [],
  });

  final List<String> include;
  final List<String> exclude;

  FacetFilter copyWith({
    List<String>? include,
    List<String>? exclude,
  }) {
    return FacetFilter(
      include: include ?? this.include,
      exclude: exclude ?? this.exclude,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FacetFilter) return false;
    return _listEq(include, other.include) && _listEq(exclude, other.exclude);
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(include), Object.hashAll(exclude));
}

bool _listEq(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

FacetFilter emptyFacet() => const FacetFilter();

bool isFacetEmpty(FacetFilter? f) {
  if (f == null) return true;
  return f.include.isEmpty && f.exclude.isEmpty;
}

/// Accepts a [FacetFilter] or a legacy include-only `List<String>`.
FacetFilter normalizeFacet(Object? value) {
  if (value == null) return emptyFacet();
  if (value is FacetFilter) {
    return FacetFilter(
      include: List<String>.from(value.include),
      exclude: List<String>.from(value.exclude),
    );
  }
  if (value is List) {
    return FacetFilter(
      include: value.map((e) => e.toString()).toList(),
      exclude: const [],
    );
  }
  throw ArgumentError('Expected FacetFilter or List, got ${value.runtimeType}');
}

/// Chip cycle: off → include → exclude → off.
FacetFilter cycleFacetValue(FacetFilter facet, String value) {
  final inInc = facet.include.contains(value);
  final inExc = facet.exclude.contains(value);
  if (!inInc && !inExc) {
    return FacetFilter(
      include: [...facet.include, value],
      exclude: facet.exclude,
    );
  }
  if (inInc) {
    return FacetFilter(
      include: facet.include.where((v) => v != value).toList(),
      exclude: [...facet.exclude, value],
    );
  }
  return FacetFilter(
    include: facet.include,
    exclude: facet.exclude.where((v) => v != value).toList(),
  );
}

enum FacetChipState { off, include, exclude }

FacetChipState facetChipState(FacetFilter facet, String value) {
  if (facet.include.contains(value)) return FacetChipState.include;
  if (facet.exclude.contains(value)) return FacetChipState.exclude;
  return FacetChipState.off;
}

/// Pure facet predicate: OR within include; any exclude match drops.
bool matchesFacet(FacetFilter? facet, String? value) {
  final f = normalizeFacet(facet);
  if (isFacetEmpty(f)) return true;
  final v = value?.trim() ?? '';
  if (v.isNotEmpty && f.exclude.contains(v)) return false;
  if (f.include.isEmpty) return true;
  if (v.isEmpty) return false;
  return f.include.contains(v);
}

int facetActiveCount(FacetFilter f) => f.include.length + f.exclude.length;
