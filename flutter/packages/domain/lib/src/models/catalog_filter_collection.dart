/// Named Catalog filter collections / presets (FEAT-20260807-004).
///
/// Soft-only restore of filter criteria — never invents catalog rows and never
/// auto-applies to a host session (host must call apply and bind).
///
/// **Product locks (chosen defaults):**
/// - Collections are scoped **per browse mode** (`weapons` | `armor` |
///   `universal`), not global across modes.
/// - Same name under the same user + mode **replaces** the existing collection
///   (id preserved when possible).
/// - Soft cap: [kMaxCatalogFilterCollectionsPerUserMode] (~20) per user+mode
///   (enforced at persist / use-case layer, not here).
/// - Included state: scope, free-text query, exotic tri-state, facet
///   include/exclude for element / ammo / slot / class / archetype / synergies,
///   optional sort keys + group-by dimensions (string wire names).
/// - Excluded: item hash include/exclude sets (session/ad-hoc, not presets),
///   presentation chrome, nested group trees.
library;

/// Soft max named collections per user per browse mode.
const int kMaxCatalogFilterCollectionsPerUserMode = 20;

/// Wire values for browse mode (matches manifest [CatalogBrowseMode] names).
const String kCatalogBrowseModeWeapons = 'weapons';
const String kCatalogBrowseModeArmor = 'armor';
const String kCatalogBrowseModeUniversal = 'universal';

const Set<String> kCatalogBrowseModes = {
  kCatalogBrowseModeWeapons,
  kCatalogBrowseModeArmor,
  kCatalogBrowseModeUniversal,
};

/// Wire values for ownership scope (matches manifest [CatalogScope] names).
const String kCatalogScopeAll = 'all';
const String kCatalogScopeOwned = 'owned';

const Set<String> kCatalogScopes = {
  kCatalogScopeAll,
  kCatalogScopeOwned,
};

/// Facet include/exclude selection (pure wire form of manifest FacetFilter).
class CatalogFacetSelection {
  const CatalogFacetSelection({
    this.include = const [],
    this.exclude = const [],
  });

  final List<String> include;
  final List<String> exclude;

  bool get isEmpty => include.isEmpty && exclude.isEmpty;

  Map<String, Object?> toJson() => {
        'include': List<String>.from(include),
        'exclude': List<String>.from(exclude),
      };

  static CatalogFacetSelection fromJson(Object? raw) {
    if (raw is! Map) return const CatalogFacetSelection();
    return CatalogFacetSelection(
      include: _stringList(raw['include']),
      exclude: _stringList(raw['exclude']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CatalogFacetSelection &&
        _listEq(include, other.include) &&
        _listEq(exclude, other.exclude);
  }

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(include), Object.hashAll(exclude));
}

/// One named filter collection (serializable pure model).
class CatalogFilterCollection {
  const CatalogFilterCollection({
    required this.id,
    required this.userId,
    required this.name,
    required this.browseMode,
    this.scope = kCatalogScopeAll,
    this.query,
    this.exotic,
    this.elements = const CatalogFacetSelection(),
    this.ammos = const CatalogFacetSelection(),
    this.slots = const CatalogFacetSelection(),
    this.archetypes = const CatalogFacetSelection(),
    this.classNames = const CatalogFacetSelection(),
    this.synergies = const CatalogFacetSelection(),
    this.sortKeys = const [],
    this.groupBy = const [],
    this.createdAtMs,
    this.updatedAtMs,
  });

  final String id;

  /// Local user id (string form of DB users.id).
  final String userId;

  /// Display name (trimmed by validators / persist).
  final String name;

  /// [kCatalogBrowseModeWeapons] | [kCatalogBrowseModeArmor] |
  /// [kCatalogBrowseModeUniversal].
  final String browseMode;

  /// [kCatalogScopeAll] | [kCatalogScopeOwned].
  final String scope;

  final String? query;

  /// true = only exotic; false = exclude exotic; null = no constraint.
  final bool? exotic;

  final CatalogFacetSelection elements;
  final CatalogFacetSelection ammos;
  final CatalogFacetSelection slots;
  final CatalogFacetSelection archetypes;
  final CatalogFacetSelection classNames;
  final CatalogFacetSelection synergies;

  /// Ordered [CatalogSortKey] wire names (e.g. `slot`, `exotic`, `name`).
  final List<String> sortKeys;

  /// Ordered [CatalogGroupDimension] wire names (e.g. `element`, `ammo`).
  final List<String> groupBy;

  final int? createdAtMs;
  final int? updatedAtMs;

  CatalogFilterCollection copyWith({
    String? id,
    String? userId,
    String? name,
    String? browseMode,
    String? scope,
    String? query,
    bool? exotic,
    bool clearExotic = false,
    CatalogFacetSelection? elements,
    CatalogFacetSelection? ammos,
    CatalogFacetSelection? slots,
    CatalogFacetSelection? archetypes,
    CatalogFacetSelection? classNames,
    CatalogFacetSelection? synergies,
    List<String>? sortKeys,
    List<String>? groupBy,
    int? createdAtMs,
    int? updatedAtMs,
  }) {
    return CatalogFilterCollection(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      browseMode: browseMode ?? this.browseMode,
      scope: scope ?? this.scope,
      query: query ?? this.query,
      exotic: clearExotic ? null : (exotic ?? this.exotic),
      elements: elements ?? this.elements,
      ammos: ammos ?? this.ammos,
      slots: slots ?? this.slots,
      archetypes: archetypes ?? this.archetypes,
      classNames: classNames ?? this.classNames,
      synergies: synergies ?? this.synergies,
      sortKeys: sortKeys ?? this.sortKeys,
      groupBy: groupBy ?? this.groupBy,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }

  /// Filter payload only (no id/user/name/timestamps) for [filters_json].
  Map<String, Object?> filtersToJson() => {
        'scope': scope,
        if (query != null && query!.isNotEmpty) 'query': query,
        if (exotic != null) 'exotic': exotic,
        if (!elements.isEmpty) 'elements': elements.toJson(),
        if (!ammos.isEmpty) 'ammos': ammos.toJson(),
        if (!slots.isEmpty) 'slots': slots.toJson(),
        if (!archetypes.isEmpty) 'archetypes': archetypes.toJson(),
        if (!classNames.isEmpty) 'classNames': classNames.toJson(),
        if (!synergies.isEmpty) 'synergies': synergies.toJson(),
        if (sortKeys.isNotEmpty) 'sortKeys': List<String>.from(sortKeys),
        if (groupBy.isNotEmpty) 'groupBy': List<String>.from(groupBy),
      };

  /// Full serializable map (tests / export).
  Map<String, Object?> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'browseMode': browseMode,
        ...filtersToJson(),
        if (createdAtMs != null) 'createdAtMs': createdAtMs,
        if (updatedAtMs != null) 'updatedAtMs': updatedAtMs,
      };

  /// Parse filter criteria from a [filters_json] map (no identity fields).
  static CatalogFilterCollection filtersFromJson(
    Map<String, Object?> m, {
    required String id,
    required String userId,
    required String name,
    required String browseMode,
    int? createdAtMs,
    int? updatedAtMs,
  }) {
    return CatalogFilterCollection(
      id: id,
      userId: userId,
      name: name,
      browseMode: browseMode,
      scope: _scope(m['scope']),
      query: m['query']?.toString(),
      exotic: _boolOrNull(m['exotic']),
      elements: CatalogFacetSelection.fromJson(m['elements']),
      ammos: CatalogFacetSelection.fromJson(m['ammos']),
      slots: CatalogFacetSelection.fromJson(m['slots']),
      archetypes: CatalogFacetSelection.fromJson(m['archetypes']),
      classNames: CatalogFacetSelection.fromJson(m['classNames']),
      synergies: CatalogFacetSelection.fromJson(m['synergies']),
      sortKeys: _stringList(m['sortKeys']),
      groupBy: _stringList(m['groupBy']),
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs,
    );
  }

  static CatalogFilterCollection fromJson(Map<String, Object?> m) {
    return filtersFromJson(
      m,
      id: m['id']?.toString() ?? '',
      userId: m['userId']?.toString() ?? '',
      name: m['name']?.toString() ?? '',
      browseMode: m['browseMode']?.toString() ?? kCatalogBrowseModeWeapons,
      createdAtMs: _intOrNull(m['createdAtMs']),
      updatedAtMs: _intOrNull(m['updatedAtMs']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CatalogFilterCollection) return false;
    return other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.browseMode == browseMode &&
        other.scope == scope &&
        other.query == query &&
        other.exotic == exotic &&
        other.elements == elements &&
        other.ammos == ammos &&
        other.slots == slots &&
        other.archetypes == archetypes &&
        other.classNames == classNames &&
        other.synergies == synergies &&
        _listEq(other.sortKeys, sortKeys) &&
        _listEq(other.groupBy, groupBy) &&
        other.createdAtMs == createdAtMs &&
        other.updatedAtMs == updatedAtMs;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        name,
        browseMode,
        scope,
        query,
        exotic,
        elements,
        ammos,
        slots,
        archetypes,
        classNames,
        synergies,
        Object.hashAll(sortKeys),
        Object.hashAll(groupBy),
        createdAtMs,
        updatedAtMs,
      );
}

/// Thrown when a filter collection fails pure validation.
class CatalogFilterCollectionValidationException implements Exception {
  const CatalogFilterCollectionValidationException(
    this.message, {
    this.code = 'FILTER_COLLECTION_INVALID',
  });

  final String code;
  final String message;

  @override
  String toString() =>
      'CatalogFilterCollectionValidationException($code: $message)';
}

/// Validates name / mode / scope wire values.
///
/// Throws [CatalogFilterCollectionValidationException] when invalid.
void validateCatalogFilterCollection(CatalogFilterCollection collection) {
  final name = collection.name.trim();
  if (name.isEmpty) {
    throw const CatalogFilterCollectionValidationException(
      'Name is required',
      code: 'FILTER_COLLECTION_NAME_REQUIRED',
    );
  }
  if (!kCatalogBrowseModes.contains(collection.browseMode)) {
    throw CatalogFilterCollectionValidationException(
      'Unknown browse mode: ${collection.browseMode}',
      code: 'FILTER_COLLECTION_BROWSE_MODE_INVALID',
    );
  }
  if (!kCatalogScopes.contains(collection.scope)) {
    throw CatalogFilterCollectionValidationException(
      'Unknown scope: ${collection.scope}',
      code: 'FILTER_COLLECTION_SCOPE_INVALID',
    );
  }
}

List<String> _stringList(Object? raw) {
  if (raw is! List) return const [];
  return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
}

bool? _boolOrNull(Object? raw) {
  if (raw == null) return null;
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  final s = raw.toString().toLowerCase();
  if (s == 'true' || s == '1') return true;
  if (s == 'false' || s == '0') return false;
  return null;
}

int? _intOrNull(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '');
}

String _scope(Object? raw) {
  final s = raw?.toString() ?? kCatalogScopeAll;
  return kCatalogScopes.contains(s) ? s : kCatalogScopeAll;
}

bool _listEq(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
