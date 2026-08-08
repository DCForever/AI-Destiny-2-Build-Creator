/// Named Catalog filter collection use cases (FEAT-20260807-004).
///
/// Soft-only: [applyCatalogFilterCollection] returns the model for the host
/// to bind — never mutates catalog session state and never invents items.
library;

import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';

import 'clock_ids.dart';

CatalogFacetSelection _facetFromRecord(CatalogFacetRecord r) =>
    CatalogFacetSelection(include: r.include, exclude: r.exclude);

CatalogFacetRecord _facetToRecord(CatalogFacetSelection s) =>
    CatalogFacetRecord(include: s.include, exclude: s.exclude);

/// Map DB record → domain model.
CatalogFilterCollection toDomainCatalogFilterCollection(
  CatalogFilterCollectionRecord r,
) {
  return CatalogFilterCollection(
    id: r.id,
    userId: r.userId.toString(),
    name: r.name,
    browseMode: r.browseMode,
    scope: r.scope,
    query: r.query,
    exotic: r.exotic,
    elements: _facetFromRecord(r.elements),
    ammos: _facetFromRecord(r.ammos),
    slots: _facetFromRecord(r.slots),
    archetypes: _facetFromRecord(r.archetypes),
    classNames: _facetFromRecord(r.classNames),
    synergies: _facetFromRecord(r.synergies),
    sortKeys: List<String>.from(r.sortKeys),
    groupBy: List<String>.from(r.groupBy),
    createdAtMs: DateTime.tryParse(r.createdAt)?.millisecondsSinceEpoch,
    updatedAtMs: DateTime.tryParse(r.updatedAt)?.millisecondsSinceEpoch,
  );
}

/// Build [CatalogClientFilters] for host binding (soft apply data only).
CatalogClientFilters catalogClientFiltersFromCollection(
  CatalogFilterCollection c,
) {
  FacetFilter? facetOrNull(CatalogFacetSelection s) {
    if (s.isEmpty) return null;
    return FacetFilter(include: s.include, exclude: s.exclude);
  }

  final scope = c.scope == kCatalogScopeOwned
      ? CatalogScope.owned
      : CatalogScope.all;

  return CatalogClientFilters(
    query: c.query,
    elements: facetOrNull(c.elements),
    ammos: facetOrNull(c.ammos),
    slots: facetOrNull(c.slots),
    archetypes: facetOrNull(c.archetypes),
    classNames: facetOrNull(c.classNames),
    synergies: facetOrNull(c.synergies),
    exotic: c.exotic,
    scope: scope,
  );
}

/// Parse wire sort key names → [CatalogSortKey] (unknown names dropped).
List<CatalogSortKey> catalogSortKeysFromCollection(
  CatalogFilterCollection c,
) {
  final out = <CatalogSortKey>[];
  for (final name in c.sortKeys) {
    for (final k in CatalogSortKey.values) {
      if (k.name == name) {
        out.add(k);
        break;
      }
    }
  }
  return out;
}

/// Parse wire group-by names → [CatalogGroupDimension] (unknown dropped).
List<CatalogGroupDimension> catalogGroupByFromCollection(
  CatalogFilterCollection c,
) {
  final out = <CatalogGroupDimension>[];
  for (final name in c.groupBy) {
    for (final d in CatalogGroupDimension.values) {
      if (d.name == name) {
        out.add(d);
        break;
      }
    }
  }
  return out;
}

/// Validate domain shape then create or replace-by-name.
Future<CatalogFilterCollection> createCatalogFilterCollectionUseCase(
  AppDatabase db, {
  required int userId,
  required String name,
  required String browseMode,
  String scope = kCatalogScopeAll,
  String? query,
  bool? exotic,
  CatalogFacetSelection elements = const CatalogFacetSelection(),
  CatalogFacetSelection ammos = const CatalogFacetSelection(),
  CatalogFacetSelection slots = const CatalogFacetSelection(),
  CatalogFacetSelection archetypes = const CatalogFacetSelection(),
  CatalogFacetSelection classNames = const CatalogFacetSelection(),
  CatalogFacetSelection synergies = const CatalogFacetSelection(),
  List<String> sortKeys = const [],
  List<String> groupBy = const [],
  String? id,
  String? nowIso,
  int maxPerMode = kMaxCatalogFilterCollectionsPerUserMode,
}) async {
  final targetId = id ?? defaultNewId();
  final now = nowIso ?? defaultNow();
  final domain = CatalogFilterCollection(
    id: targetId,
    userId: userId.toString(),
    name: name.trim(),
    browseMode: browseMode,
    scope: scope,
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
  );
  validateCatalogFilterCollection(domain);

  final record = await createCatalogFilterCollection(
    db,
    userId,
    id: targetId,
    browseMode: browseMode,
    name: name,
    scope: scope,
    query: query,
    exotic: exotic,
    elements: _facetToRecord(elements),
    ammos: _facetToRecord(ammos),
    slots: _facetToRecord(slots),
    archetypes: _facetToRecord(archetypes),
    classNames: _facetToRecord(classNames),
    synergies: _facetToRecord(synergies),
    sortKeys: sortKeys,
    groupBy: groupBy,
    now: now,
    maxPerMode: maxPerMode,
  );
  return toDomainCatalogFilterCollection(record);
}

/// Save from an existing domain model (create / replace-by-name).
Future<CatalogFilterCollection> saveCatalogFilterCollection(
  AppDatabase db,
  CatalogFilterCollection collection, {
  String? nowIso,
  int maxPerMode = kMaxCatalogFilterCollectionsPerUserMode,
}) {
  final userId = int.tryParse(collection.userId);
  if (userId == null) {
    throw const CatalogFilterCollectionValidationException(
      'userId must be a numeric local user id',
      code: 'FILTER_COLLECTION_USER_INVALID',
    );
  }
  return createCatalogFilterCollectionUseCase(
    db,
    userId: userId,
    name: collection.name,
    browseMode: collection.browseMode,
    scope: collection.scope,
    query: collection.query,
    exotic: collection.exotic,
    elements: collection.elements,
    ammos: collection.ammos,
    slots: collection.slots,
    archetypes: collection.archetypes,
    classNames: collection.classNames,
    synergies: collection.synergies,
    sortKeys: collection.sortKeys,
    groupBy: collection.groupBy,
    id: collection.id,
    nowIso: nowIso,
    maxPerMode: maxPerMode,
  );
}

Future<CatalogFilterCollection?> updateCatalogFilterCollectionUseCase(
  AppDatabase db, {
  required int userId,
  required String id,
  String? name,
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
  String? nowIso,
}) async {
  final now = nowIso ?? defaultNow();
  if (name != null || scope != null) {
    validateCatalogFilterCollection(
      CatalogFilterCollection(
        id: id,
        userId: userId.toString(),
        name: name ?? 'x',
        browseMode: kCatalogBrowseModeWeapons,
        scope: scope ?? kCatalogScopeAll,
      ),
    );
  }

  final record = await updateCatalogFilterCollection(
    db,
    userId,
    id,
    name: name,
    scope: scope,
    query: query,
    exotic: exotic,
    clearExotic: clearExotic,
    elements: elements == null ? null : _facetToRecord(elements),
    ammos: ammos == null ? null : _facetToRecord(ammos),
    slots: slots == null ? null : _facetToRecord(slots),
    archetypes: archetypes == null ? null : _facetToRecord(archetypes),
    classNames: classNames == null ? null : _facetToRecord(classNames),
    synergies: synergies == null ? null : _facetToRecord(synergies),
    sortKeys: sortKeys,
    groupBy: groupBy,
    now: now,
  );
  if (record == null) return null;
  return toDomainCatalogFilterCollection(record);
}

/// Rename helper (preferred over delete+recreate).
Future<CatalogFilterCollection?> renameCatalogFilterCollection(
  AppDatabase db, {
  required int userId,
  required String id,
  required String name,
  String? nowIso,
}) {
  return updateCatalogFilterCollectionUseCase(
    db,
    userId: userId,
    id: id,
    name: name,
    nowIso: nowIso,
  );
}

Future<bool> deleteCatalogFilterCollectionUseCase(
  AppDatabase db, {
  required int userId,
  required String id,
}) {
  return deleteCatalogFilterCollection(db, userId, id);
}

Future<List<CatalogFilterCollection>> listCatalogFilterCollectionsUseCase(
  AppDatabase db, {
  required int userId,
  String? browseMode,
}) async {
  final rows = await listCatalogFilterCollections(
    db,
    userId,
    browseMode: browseMode,
  );
  return rows.map(toDomainCatalogFilterCollection).toList();
}

Future<CatalogFilterCollection?> getCatalogFilterCollectionUseCase(
  AppDatabase db, {
  required int userId,
  required String id,
}) async {
  final row = await getCatalogFilterCollection(db, userId, id);
  if (row == null) return null;
  return toDomainCatalogFilterCollection(row);
}

/// Soft apply: load by id and return the collection for the host to bind.
///
/// Does **not** mutate any session, catalog, or inventory state.
Future<CatalogFilterCollection?> applyCatalogFilterCollection(
  AppDatabase db, {
  required int userId,
  required String id,
}) {
  return getCatalogFilterCollectionUseCase(db, userId: userId, id: id);
}

/// Soft apply as [CatalogClientFilters] (host binds filters only).
Future<CatalogClientFilters?> applyCatalogFilterCollectionAsClientFilters(
  AppDatabase db, {
  required int userId,
  required String id,
}) async {
  final c = await applyCatalogFilterCollection(db, userId: userId, id: id);
  if (c == null) return null;
  return catalogClientFiltersFromCollection(c);
}
