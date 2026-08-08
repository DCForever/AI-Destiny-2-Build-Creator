import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_database.dart';

/// Soft max named filter collections per user per browse mode.
const int kMaxCatalogFilterCollectionsPerUserModeDb = 20;

/// Facet include/exclude stored in filters_json.
class CatalogFacetRecord {
  const CatalogFacetRecord({
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

  static CatalogFacetRecord fromJson(Object? raw) {
    if (raw is! Map) return const CatalogFacetRecord();
    return CatalogFacetRecord(
      include: _stringList(raw['include']),
      exclude: _stringList(raw['exclude']),
    );
  }
}

/// Persisted Catalog filter collection (FEAT-20260807-004).
///
/// Product locks: per browse mode; same name replaces; soft cap ~20.
class CatalogFilterCollectionRecord {
  const CatalogFilterCollectionRecord({
    required this.id,
    required this.userId,
    required this.name,
    required this.browseMode,
    this.scope = 'all',
    this.query,
    this.exotic,
    this.elements = const CatalogFacetRecord(),
    this.ammos = const CatalogFacetRecord(),
    this.slots = const CatalogFacetRecord(),
    this.archetypes = const CatalogFacetRecord(),
    this.classNames = const CatalogFacetRecord(),
    this.synergies = const CatalogFacetRecord(),
    this.sortKeys = const [],
    this.groupBy = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int userId;
  final String name;
  final String browseMode;
  final String scope;
  final String? query;
  final bool? exotic;
  final CatalogFacetRecord elements;
  final CatalogFacetRecord ammos;
  final CatalogFacetRecord slots;
  final CatalogFacetRecord archetypes;
  final CatalogFacetRecord classNames;
  final CatalogFacetRecord synergies;
  final List<String> sortKeys;
  final List<String> groupBy;
  final String createdAt;
  final String updatedAt;

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
}

/// Thrown when filter-collection persist rules fail.
class CatalogFilterCollectionPersistException implements Exception {
  const CatalogFilterCollectionPersistException(
    this.message, {
    required this.code,
  });

  final String code;
  final String message;

  @override
  String toString() =>
      'CatalogFilterCollectionPersistException($code: $message)';
}

const _validBrowseModes = {'weapons', 'armor', 'universal'};
const _validScopes = {'all', 'owned'};

String encodeCatalogFilterFilters(CatalogFilterCollectionRecord record) {
  return jsonEncode(record.filtersToJson());
}

Map<String, Object?> parseCatalogFilterFiltersJson(String raw) {
  if (raw.isEmpty) return const {};
  try {
    final parsed = jsonDecode(raw);
    if (parsed is! Map) return const {};
    return parsed.map((k, v) => MapEntry(k.toString(), v as Object?));
  } catch (_) {
    return const {};
  }
}

CatalogFilterCollectionRecord rowToCatalogFilterCollectionRecord(
  CatalogFilterCollectionRow row,
) {
  final m = parseCatalogFilterFiltersJson(row.filtersJson);
  final scopeRaw = m['scope']?.toString() ?? 'all';
  final scope = _validScopes.contains(scopeRaw) ? scopeRaw : 'all';
  return CatalogFilterCollectionRecord(
    id: row.id,
    userId: row.userId,
    name: row.name,
    browseMode: row.browseMode,
    scope: scope,
    query: m['query']?.toString(),
    exotic: _boolOrNull(m['exotic']),
    elements: CatalogFacetRecord.fromJson(m['elements']),
    ammos: CatalogFacetRecord.fromJson(m['ammos']),
    slots: CatalogFacetRecord.fromJson(m['slots']),
    archetypes: CatalogFacetRecord.fromJson(m['archetypes']),
    classNames: CatalogFacetRecord.fromJson(m['classNames']),
    synergies: CatalogFacetRecord.fromJson(m['synergies']),
    sortKeys: _stringList(m['sortKeys']),
    groupBy: _stringList(m['groupBy']),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

/// List collections for [userId], optionally filtered by [browseMode].
Future<List<CatalogFilterCollectionRecord>> listCatalogFilterCollections(
  AppDatabase db,
  int userId, {
  String? browseMode,
}) async {
  final q = db.select(db.catalogFilterCollections)
    ..where((t) => t.userId.equals(userId));
  if (browseMode != null) {
    q.where((t) => t.browseMode.equals(browseMode));
  }
  final rows = await q.get();
  rows.sort((a, b) {
    final m = a.browseMode.compareTo(b.browseMode);
    if (m != 0) return m;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return rows.map(rowToCatalogFilterCollectionRecord).toList();
}

Future<CatalogFilterCollectionRecord?> getCatalogFilterCollection(
  AppDatabase db,
  int userId,
  String id,
) async {
  final row = await (db.select(db.catalogFilterCollections)
        ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
      .getSingleOrNull();
  if (row == null) return null;
  return rowToCatalogFilterCollectionRecord(row);
}

Future<CatalogFilterCollectionRecord?> findCatalogFilterCollectionByName(
  AppDatabase db,
  int userId, {
  required String browseMode,
  required String name,
}) async {
  final trimmed = name.trim();
  final row = await (db.select(db.catalogFilterCollections)
        ..where(
          (t) =>
              t.userId.equals(userId) &
              t.browseMode.equals(browseMode) &
              t.name.equals(trimmed),
        ))
      .getSingleOrNull();
  if (row == null) return null;
  return rowToCatalogFilterCollectionRecord(row);
}

Future<int> countCatalogFilterCollections(
  AppDatabase db,
  int userId, {
  required String browseMode,
}) async {
  final rows = await (db.select(db.catalogFilterCollections)
        ..where(
          (t) => t.userId.equals(userId) & t.browseMode.equals(browseMode),
        ))
      .get();
  return rows.length;
}

/// Create a new collection, or **replace** filters when the same name exists
/// for user + browse mode (id preserved). Soft-caps new inserts.
Future<CatalogFilterCollectionRecord> createCatalogFilterCollection(
  AppDatabase db,
  int userId, {
  required String id,
  required String browseMode,
  required String name,
  String scope = 'all',
  String? query,
  bool? exotic,
  CatalogFacetRecord elements = const CatalogFacetRecord(),
  CatalogFacetRecord ammos = const CatalogFacetRecord(),
  CatalogFacetRecord slots = const CatalogFacetRecord(),
  CatalogFacetRecord archetypes = const CatalogFacetRecord(),
  CatalogFacetRecord classNames = const CatalogFacetRecord(),
  CatalogFacetRecord synergies = const CatalogFacetRecord(),
  List<String> sortKeys = const [],
  List<String> groupBy = const [],
  required String now,
  int maxPerMode = kMaxCatalogFilterCollectionsPerUserModeDb,
}) async {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    throw const CatalogFilterCollectionPersistException(
      'Name is required',
      code: 'FILTER_COLLECTION_NAME_REQUIRED',
    );
  }
  if (!_validBrowseModes.contains(browseMode)) {
    throw CatalogFilterCollectionPersistException(
      'Unknown browse mode: $browseMode',
      code: 'FILTER_COLLECTION_BROWSE_MODE_INVALID',
    );
  }
  final nextScope = _validScopes.contains(scope) ? scope : 'all';

  final existing = await findCatalogFilterCollectionByName(
    db,
    userId,
    browseMode: browseMode,
    name: trimmed,
  );

  final payload = CatalogFilterCollectionRecord(
    id: existing?.id ?? id,
    userId: userId,
    name: trimmed,
    browseMode: browseMode,
    scope: nextScope,
    query: query,
    exotic: exotic,
    elements: elements,
    ammos: ammos,
    slots: slots,
    archetypes: archetypes,
    classNames: classNames,
    synergies: synergies,
    sortKeys: sortKeys,
    groupBy: groupBy,
    createdAt: existing?.createdAt ?? now,
    updatedAt: now,
  );

  if (existing != null) {
    await (db.update(db.catalogFilterCollections)
          ..where(
            (t) => t.id.equals(existing.id) & t.userId.equals(userId),
          ))
        .write(
      CatalogFilterCollectionsCompanion(
        filtersJson: Value(encodeCatalogFilterFilters(payload)),
        updatedAt: Value(now),
      ),
    );
    return (await getCatalogFilterCollection(db, userId, existing.id))!;
  }

  final count = await countCatalogFilterCollections(
    db,
    userId,
    browseMode: browseMode,
  );
  if (count >= maxPerMode) {
    throw CatalogFilterCollectionPersistException(
      'Maximum of $maxPerMode filter collections per browse mode',
      code: 'FILTER_COLLECTION_MAX_EXCEEDED',
    );
  }

  try {
    await db.into(db.catalogFilterCollections).insert(
          CatalogFilterCollectionsCompanion.insert(
            id: id,
            userId: userId,
            browseMode: browseMode,
            name: trimmed,
            filtersJson: Value(encodeCatalogFilterFilters(payload)),
            createdAt: now,
            updatedAt: now,
          ),
        );
  } catch (e) {
    throw const CatalogFilterCollectionPersistException(
      'Could not create filter collection',
      code: 'FILTER_COLLECTION_CREATE_FAILED',
    );
  }
  return (await getCatalogFilterCollection(db, userId, id))!;
}

/// Update name and/or filter fields. Returns null if missing / not owned.
///
/// Rename onto an existing name under the same mode replaces that row's
/// filters and deletes this row (surviving id is the collision target).
Future<CatalogFilterCollectionRecord?> updateCatalogFilterCollection(
  AppDatabase db,
  int userId,
  String id, {
  String? name,
  String? scope,
  String? query,
  bool? exotic,
  bool clearExotic = false,
  CatalogFacetRecord? elements,
  CatalogFacetRecord? ammos,
  CatalogFacetRecord? slots,
  CatalogFacetRecord? archetypes,
  CatalogFacetRecord? classNames,
  CatalogFacetRecord? synergies,
  List<String>? sortKeys,
  List<String>? groupBy,
  required String now,
}) async {
  final existing = await getCatalogFilterCollection(db, userId, id);
  if (existing == null) return null;

  final nextName = (name ?? existing.name).trim();
  if (nextName.isEmpty) {
    throw const CatalogFilterCollectionPersistException(
      'Name is required',
      code: 'FILTER_COLLECTION_NAME_REQUIRED',
    );
  }

  final nextScopeRaw = scope ?? existing.scope;
  final nextScope =
      _validScopes.contains(nextScopeRaw) ? nextScopeRaw : existing.scope;

  final payload = CatalogFilterCollectionRecord(
    id: existing.id,
    userId: existing.userId,
    name: nextName,
    browseMode: existing.browseMode,
    scope: nextScope,
    query: query ?? existing.query,
    exotic: clearExotic ? null : (exotic ?? existing.exotic),
    elements: elements ?? existing.elements,
    ammos: ammos ?? existing.ammos,
    slots: slots ?? existing.slots,
    archetypes: archetypes ?? existing.archetypes,
    classNames: classNames ?? existing.classNames,
    synergies: synergies ?? existing.synergies,
    sortKeys: sortKeys ?? existing.sortKeys,
    groupBy: groupBy ?? existing.groupBy,
    createdAt: existing.createdAt,
    updatedAt: now,
  );

  if (nextName != existing.name) {
    final collision = await findCatalogFilterCollectionByName(
      db,
      userId,
      browseMode: existing.browseMode,
      name: nextName,
    );
    if (collision != null && collision.id != existing.id) {
      await (db.update(db.catalogFilterCollections)
            ..where(
              (t) => t.id.equals(collision.id) & t.userId.equals(userId),
            ))
          .write(
        CatalogFilterCollectionsCompanion(
          filtersJson: Value(encodeCatalogFilterFilters(payload)),
          updatedAt: Value(now),
        ),
      );
      await deleteCatalogFilterCollection(db, userId, existing.id);
      return getCatalogFilterCollection(db, userId, collision.id);
    }
  }

  try {
    final n = await (db.update(db.catalogFilterCollections)
          ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
        .write(
      CatalogFilterCollectionsCompanion(
        name: Value(nextName),
        filtersJson: Value(encodeCatalogFilterFilters(payload)),
        updatedAt: Value(now),
      ),
    );
    if (n == 0) return null;
  } catch (e) {
    throw const CatalogFilterCollectionPersistException(
      'Could not update filter collection',
      code: 'FILTER_COLLECTION_UPDATE_FAILED',
    );
  }
  return getCatalogFilterCollection(db, userId, id);
}

Future<bool> deleteCatalogFilterCollection(
  AppDatabase db,
  int userId,
  String id,
) async {
  final n = await (db.delete(db.catalogFilterCollections)
        ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
      .go();
  return n > 0;
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
