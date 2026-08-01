/// Joins offline catalog definitions with local Drift inventory (DART-056/063).
library;

import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';

import '../auth/web_oauth_session.dart';
import '../settings/inventory_sync_controller.dart';
import 'entity_bundle_loader.dart';

/// Entity × inventory join for Jaspr Catalog All|Owned + synergy tags.
///
/// Plug display names (GAP-INV-02 / GAP-UI-CATALOG-08 residual):
/// - seed from OfflineCatalog / entity base rows
/// - fill gaps via [plugNameMapBuilder] or inventorySync.perkNameMapBuilder
/// Soft never auto-applies.
class OwnedCatalogBridge {
  OwnedCatalogBridge({
    required this.db,
    required this.session,
    this.inventorySync,
    this.offlineCatalog,
    this.entityLoader,
    List<CatalogItem>? baseItems,
    Map<int, String> plugNameByHash = const {},
    this.plugNameMapBuilder,
  })  : _injectedBase = baseItems,
        _plugNameByHash = Map<int, String>.from(plugNameByHash);

  final AppDatabase db;
  final WebOAuthSession session;
  final InventorySyncController? inventorySync;
  final OfflineCatalog? offlineCatalog;
  final WebEntityBundleLoader? entityLoader;

  /// Production builder: plug hashes → names (entity seed + residual channel).
  final PerkNameMapBuilder? plugNameMapBuilder;

  /// Optional fixed base (tests) when no catalog/loader.
  final List<CatalogItem>? _injectedBase;

  Map<int, String> _plugNameByHash;

  List<CatalogItem> _annotatedBase = const [];
  List<InventoryItemRecord> _inventory = const [];
  Map<int, int> _ownedCounts = const {};
  Map<String, String> _synergyNames = const {};
  List<CatalogSynergyMembership> _synergyMembership = const [];
  int? _userId;

  List<CatalogItem> get annotatedBase => _annotatedBase;
  List<InventoryItemRecord> get inventory => _inventory;
  Map<int, int> get ownedCounts => _ownedCounts;
  Map<String, String> get synergyNames => _synergyNames;
  List<CatalogSynergyMembership> get synergyMembership => _synergyMembership;
  int? get userId => _userId;
  int get ownedDefinitionCount =>
      _ownedCounts.values.where((c) => c > 0).length;

  /// Resolved plug hash → display name (grows as [ensurePlugNames] runs).
  Map<int, String> get plugNameByHash =>
      Map<int, String>.unmodifiable(_plugNameByHash);

  OfflineCatalog? get _resolvedCatalog =>
      offlineCatalog ?? entityLoader?.catalog;

  List<CatalogItem> get _entityBase {
    if (_injectedBase != null) return _injectedBase!;
    return _resolvedCatalog?.baseItems ?? const [];
  }

  /// Load entity base (if needed) + inventory annotate + synergy membership.
  Future<void> refresh({bool reloadEntities = true}) async {
    final catalog = _resolvedCatalog;
    if (reloadEntities && catalog != null) {
      await catalog.loadBase();
    } else if (reloadEntities &&
        entityLoader != null &&
        entityLoader.catalog == null) {
      await entityLoader.load();
    }

    _seedNamesFromCatalogBase();

    _userId = await _resolveUserId();
    if (_userId == null) {
      _inventory = const [];
      _ownedCounts = const {};
      _synergyNames = const {};
      _synergyMembership = const [];
      _annotatedBase = annotateCatalogWithOwned(
        _entityBase,
        const {},
      );
      return;
    }

    _inventory = await listInventoryItems(db, _userId!);
    _ownedCounts = ownedHashCountsFromInventory(_inventory);

    final synergies = await listUserSynergies(db, _userId!);
    _synergyMembership = [
      for (final s in synergies)
        CatalogSynergyMembership(
          id: s.id,
          name: s.name,
          links: [
            for (final link in s.links)
              CatalogSynergyLinkRef(
                kind: link.kind,
                itemHash: link.itemHash,
                perkHash: link.perkHash,
                originTraitHash: link.originTraitHash,
                originTraitName: link.originTraitName,
                armorSetHash: link.armorSetHash,
                armorSetName: link.armorSetName,
              ),
          ],
        ),
    ];
    _synergyNames = buildSynergyNameById(_synergyMembership);
    final linkedByHash = buildLinkedSynergyIdsByItemHash(_synergyMembership);

    final owned = annotateCatalogWithOwned(_entityBase, _ownedCounts);
    _annotatedBase = annotateCatalogWithLinkedSynergies(owned, linkedByHash);
  }

  /// Ensure [hashes] have display names (entity seed + builder).
  Future<void> ensurePlugNames(Iterable<int> hashes) async {
    final missing = <int>[
      for (final h in hashes)
        if (h != 0 && !_plugNameByHash.containsKey(h)) h,
    ];
    if (missing.isEmpty) return;

    final explicit = inventorySync?.perkNameMap;
    if (explicit != null && explicit.isNotEmpty) {
      for (final h in missing) {
        final n = explicit[h];
        if (n != null && n.isNotEmpty) _plugNameByHash[h] = n;
      }
    }

    final stillMissing = <int>[
      for (final h in missing)
        if (!_plugNameByHash.containsKey(h)) h,
    ];
    if (stillMissing.isEmpty) return;

    final builder = plugNameMapBuilder ?? inventorySync?.perkNameMapBuilder;
    if (builder == null) return;

    try {
      final dynamic fut = builder(List<int>.from(stillMissing));
      final Object? raw = fut is Future ? await fut : fut;
      if (raw is! Map) return;
      final more = <int, String>{};
      for (final e in raw.entries) {
        final k = e.key;
        final v = e.value;
        final hash = k is int
            ? k
            : k is num
                ? k.toInt()
                : int.tryParse('$k');
        if (hash == null || v is! String || v.isEmpty) continue;
        more[hash] = v;
      }
      if (more.isEmpty) return;
      _plugNameByHash = {..._plugNameByHash, ...more};
    } catch (_) {
      // Degrade to #hash display.
    }
  }

  void _seedNamesFromCatalogBase() {
    for (final item in _entityBase) {
      if (item.name.isEmpty) continue;
      _plugNameByHash.putIfAbsent(item.hash, () => item.name);
    }
    final doc = entityLoader?.document;
    if (doc == null) return;
    for (final store in doc.stores.values) {
      for (final row in store) {
        if (row is EntityRecordBase && row.name.isNotEmpty) {
          _plugNameByHash.putIfAbsent(row.hash, () => row.name);
        }
      }
    }
  }

  /// Filter annotated base for [mode] with client facets + [scope].
  List<CatalogItem> browse(
    CatalogClientFilters filters, {
    CatalogBrowseMode mode = CatalogBrowseMode.universal,
  }) {
    final scoped = itemsForBrowseMode(_annotatedBase, mode);
    return filterCatalogClient(scoped, filters);
  }

  /// Instance projections for a definition hash (power-desc).
  List<CatalogInstanceProjection> instancesFor(
    int itemHash, {
    bool treatAsArmor = false,
  }) {
    return projectInstancesForHash(
      _inventory,
      itemHash,
      plugNameByHash: _plugNameByHash,
      treatAsArmor: treatAsArmor,
    );
  }

  /// Resolve names for plugs on [itemHash] copies, then return projections.
  Future<List<CatalogInstanceProjection>> instancesForResolved(
    int itemHash, {
    bool treatAsArmor = false,
  }) async {
    final rows = _inventory.where((i) => i.itemHash == itemHash);
    await ensurePlugNames(collectPlugHashesFromInventory(rows));
    return instancesFor(itemHash, treatAsArmor: treatAsArmor);
  }

  List<LinkedSynergyBadge> badgesFor(CatalogItem item) {
    return linkedSynergyBadgesForItem(item, _synergyNames);
  }

  Future<List<LinkedSynergyBadge>> reverseTagsFor(CatalogItem item) async {
    final uid = _userId;
    if (uid == null) return badgesFor(item);

    final kind = compositionKindFromCatalogItem(item);
    final linkKind = kind == null ? null : synergyLinkKindWireForKind(kind);
    if (linkKind == null) return badgesFor(item);

    final found = await listUserSynergiesByTarget(
      db,
      uid,
      SynergyTargetQuery(kind: linkKind, itemHash: item.hash),
    );
    if (found.isEmpty) return badgesFor(item);
    return [
      for (final s in found) LinkedSynergyBadge(id: s.id, name: s.name),
    ];
  }

  Future<int?> _resolveUserId() async {
    final fromSync = inventorySync?.localUserId;
    if (fromSync != null) return fromSync;

    final tokens = session.tokens;
    if (!session.isSignedIn || tokens == null) return null;

    final membershipId = tokens.bungieMembershipId;
    if (membershipId.isEmpty) return null;

    final user = await ensureUser(
      db,
      bungieMembershipId: membershipId,
      membershipType: 0,
      displayName: '',
    );
    return user.id;
  }
}

/// Collect equipped + reusable plug hashes from inventory rows.
Set<int> collectPlugHashesFromInventory(
  Iterable<InventoryItemRecord> items,
) {
  final out = <int>{};
  for (final item in items) {
    for (final h in item.plugHashes) {
      if (h != 0) out.add(h);
    }
    final sockets = item.socketPlugs;
    if (sockets == null) continue;
    for (final raw in sockets) {
      final equipped = raw['equippedPlugHash'];
      final eh = equipped is int
          ? equipped
          : equipped is num
              ? equipped.toInt()
              : null;
      if (eh != null && eh != 0) out.add(eh);
      final reusable = raw['reusablePlugHashes'];
      if (reusable is List) {
        for (final e in reusable) {
          final h = e is int
              ? e
              : e is num
                  ? e.toInt()
                  : null;
          if (h != null && h != 0) out.add(h);
        }
      }
    }
  }
  return out;
}
