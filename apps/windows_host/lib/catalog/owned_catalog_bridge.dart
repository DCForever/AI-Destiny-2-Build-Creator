import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';

import '../auth/windows_oauth_session.dart';
import '../settings/inventory_sync_controller.dart';

/// Joins offline catalog definitions with local Drift inventory (DART-026).
///
/// DART-063: also annotates library synergy membership for membership filters
/// and reverse tags (BR-SYN-004). Soft guidance never auto-applies.
class OwnedCatalogBridge {
  OwnedCatalogBridge({
    required this.db,
    required this.offlineCatalog,
    required this.session,
    required this.inventorySync,
    this.plugNameByHash = const {},
  });

  final AppDatabase db;
  final OfflineCatalog offlineCatalog;
  final WindowsOAuthSession session;
  final InventorySyncController inventorySync;

  /// Optional plug hash → display name for owned instance cards.
  final Map<int, String> plugNameByHash;

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

  /// Load entity base (if needed) + inventory annotate + synergy membership.
  Future<void> refresh({bool reloadEntities = true}) async {
    if (reloadEntities) {
      await offlineCatalog.loadBase();
    }

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
      plugNameByHash: plugNameByHash,
      treatAsArmor: treatAsArmor,
    );
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
