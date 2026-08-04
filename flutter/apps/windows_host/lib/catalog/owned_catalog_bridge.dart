import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';

import '../auth/windows_oauth_session.dart';
import '../settings/inventory_sync_controller.dart';

/// Joins offline catalog definitions with local Drift inventory (DART-026).
///
/// DART-063: also annotates library synergy membership for membership filters
/// and reverse tags (BR-SYN-004). Soft guidance never auto-applies.
///
/// Plug display names + icons (Next parity with `buildPlugMapForInventory`):
/// - seed names/icons from OfflineCatalog base rows
/// - fill gaps via [plugNameMapBuilder] / [plugIconMapBuilder]
///   (raw DestinyInventoryItemDefinition) so perk grid is icon-first.
class OwnedCatalogBridge {
  OwnedCatalogBridge({
    required this.db,
    required this.offlineCatalog,
    required this.session,
    required this.inventorySync,
    Map<int, String> plugNameByHash = const {},
    Map<int, String> plugIconByHash = const {},
    this.plugNameMapBuilder,
    this.plugIconMapBuilder,
  })  : _plugNameByHash = Map<int, String>.from(plugNameByHash),
        _plugIconByHash = Map<int, String>.from(plugIconByHash);

  final AppDatabase db;
  final OfflineCatalog offlineCatalog;
  final WindowsOAuthSession session;
  final InventorySyncController inventorySync;

  /// Production builder: plug hashes → names from raw item defs (DART-051 / Next).
  final PerkNameMapBuilder? plugNameMapBuilder;

  /// Production builder: plug hashes → Bungie icon paths.
  final PerkNameMapBuilder? plugIconMapBuilder;

  Map<int, String> _plugNameByHash;
  Map<int, String> _plugIconByHash;

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

  /// Resolved plug hash → Bungie icon path (grows with [ensurePlugNames]).
  Map<int, String> get plugIconByHash =>
      Map<int, String>.unmodifiable(_plugIconByHash);

  /// Load entity base (if needed) + inventory annotate + synergy membership.
  Future<void> refresh({bool reloadEntities = true}) async {
    if (reloadEntities) {
      await offlineCatalog.loadBase();
    }

    // Seed names/icons from MVP entity projection (mods, weapons, armor, etc.).
    _seedNamesFromCatalogBase();

    _userId = await _resolveUserId();
    if (_userId == null) {
      _inventory = const [];
      _ownedCounts = const {};
      _synergyNames = const {};
      _synergyMembership = const [];
      _annotatedBase = annotateCatalogWithOwned(
        offlineCatalog.baseItems,
        const {},
      );
      return;
    }

    _inventory = await listInventoryItems(db, _userId!);
    _ownedCounts = ownedHashCountsFromInventory(_inventory);

    // Plug names resolve on demand in instancesForResolved (selected item only),
    // matching Next perk-grid — avoid loading full raw defs for entire inventory.

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

    final owned = annotateCatalogWithOwned(
      offlineCatalog.baseItems,
      _ownedCounts,
    );
    _annotatedBase = annotateCatalogWithLinkedSynergies(owned, linkedByHash);
  }

  /// Ensure [hashes] have display names **and** icons (entity seed + raw defs).
  ///
  /// Safe to call repeatedly; only fetches missing hashes.
  /// Never throws — Catalog must not red-screen on resolution failure.
  Future<void> ensurePlugNames(Iterable<int> hashes) async {
    final list = [for (final h in hashes) if (h != 0) h];
    if (list.isEmpty) return;

    await _resolveInto(
      list,
      map: _plugNameByHash,
      setMap: (m) => _plugNameByHash = m,
      explicit: inventorySync.perkNameMap,
      builder: plugNameMapBuilder ?? inventorySync.perkNameMapBuilder,
    );
    await _resolveInto(
      list,
      map: _plugIconByHash,
      setMap: (m) => _plugIconByHash = m,
      explicit: null,
      builder: plugIconMapBuilder ?? inventorySync.perkIconMapBuilder,
    );
  }

  Future<void> _resolveInto(
    List<int> hashes, {
    required Map<int, String> map,
    required void Function(Map<int, String>) setMap,
    required Map<int, String>? explicit,
    required PerkNameMapBuilder? builder,
  }) async {
    var current = Map<int, String>.from(map);
    var missing = <int>[
      for (final h in hashes)
        if (!current.containsKey(h)) h,
    ];
    if (missing.isEmpty) return;

    if (explicit != null && explicit.isNotEmpty) {
      final more = <int, String>{};
      for (final h in missing) {
        final v = explicit[h];
        if (v != null && v.isNotEmpty) more[h] = v;
      }
      if (more.isNotEmpty) {
        current = {...current, ...more};
        setMap(current);
        missing = [
          for (final h in missing)
            if (!more.containsKey(h)) h,
        ];
      }
    }
    if (missing.isEmpty || builder == null) return;

    try {
      final dynamic fut = builder(List<int>.from(missing));
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
      setMap({...current, ...more});
    } catch (_) {
      // Degrade gracefully; do not fail catalog load.
    }
  }

  void _seedNamesFromCatalogBase() {
    for (final item in offlineCatalog.baseItems) {
      if (item.name.isEmpty) continue;
      _plugNameByHash.putIfAbsent(item.hash, () => item.name);
      final icon = item.icon;
      if (icon != null && icon.isNotEmpty) {
        _plugIconByHash.putIfAbsent(item.hash, () => icon);
      }
    }
  }

  /// Filter annotated base for [mode] with client facets + [scope].
  ///
  /// Weapons mode re-sorts after filter: slot → exotic → ammo → archetype → name.
  /// Armor / universal keep alpha from [filterCatalogClient].
  List<CatalogItem> browse(
    CatalogClientFilters filters, {
    CatalogBrowseMode mode = CatalogBrowseMode.universal,
  }) {
    final scoped = itemsForBrowseMode(_annotatedBase, mode);
    final filtered = filterCatalogClient(scoped, filters);
    if (mode == CatalogBrowseMode.weapons) {
      return sortCatalogWeapons(filtered);
    }
    return filtered;
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

  /// Linked synergy badges for an annotated catalog item.
  List<LinkedSynergyBadge> badgesFor(CatalogItem item) {
    return linkedSynergyBadgesForItem(item, _synergyNames);
  }

  /// Reverse-lookup badges for [item] via by-target (weapon / exotic_armor).
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
    final fromSync = inventorySync.localUserId;
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
                  : int.tryParse('$e');
          if (h != null && h != 0) out.add(h);
        }
      }
    }
  }
  return out;
}
