/// Client-side library list filters (DART-066 / product filterSets + filterSynergies).

/// Minimal set row shape for [filterSets].
class FilterableSet {
  const FilterableSet({
    required this.id,
    required this.name,
    required this.type,
    this.tagIds = const [],
  });

  final String id;
  final String name;
  final String type;
  final List<String> tagIds;
}

/// Filters for sets library rail (GAP-UI-SETS-04).
class SetListFilters {
  const SetListFilters({
    this.query = '',
    this.types = const [],
    this.tags = const [],
  });

  final String query;

  /// When non-empty, set.type must be one of these wire names.
  final List<String> types;

  /// Multi-select AND: every tag id must be present on the set.
  final List<String> tags;
}

/// Client-side filter for Sets library rows (product `filterSets`).
List<T> filterSets<T extends FilterableSet>(
  List<T> sets,
  SetListFilters filters,
) {
  final q = filters.query.trim().toLowerCase();
  final types = filters.types;
  final tags = filters.tags;

  return sets.where((set) {
    if (types.isNotEmpty && !types.contains(set.type)) return false;
    if (tags.isNotEmpty) {
      final setTags = set.tagIds;
      if (!tags.every(setTags.contains)) return false;
    }
    if (q.isEmpty) return true;
    final hay =
        '${set.name} ${set.type} ${set.tagIds.join(' ')}'.toLowerCase();
    return hay.contains(q);
  }).toList();
}

/// Minimal synergy row shape for [filterSynergies].
class FilterableSynergy {
  const FilterableSynergy({
    required this.id,
    required this.name,
    required this.type,
    this.subType,
  });

  final String id;
  final String name;
  final String type;
  final String? subType;
}

/// Filters for synergy library rail (GAP-UI-SYN-06).
class SynergyListFilters {
  const SynergyListFilters({
    this.query = '',
    this.types = const [],
    this.subTypes = const [],
  });

  final String query;
  final List<String> types;
  final List<String> subTypes;
}

/// Client-side filter for Synergy library rows (product `filterSynergies`).
List<T> filterSynergies<T extends FilterableSynergy>(
  List<T> rows,
  SynergyListFilters filters,
) {
  final q = filters.query.trim().toLowerCase();
  final types = filters.types;
  final subTypes = filters.subTypes;

  return rows.where((row) {
    if (types.isNotEmpty && !types.contains(row.type)) return false;
    if (subTypes.isNotEmpty) {
      final sub = row.subType?.trim() ?? '';
      if (sub.isEmpty || !subTypes.contains(sub)) return false;
    }
    if (q.isEmpty) return true;
    final hay = '${row.name} ${row.type} ${row.subType ?? ''}'.toLowerCase();
    return hay.contains(q);
  }).toList();
}
