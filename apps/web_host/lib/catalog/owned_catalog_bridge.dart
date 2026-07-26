/// Joins offline catalog definitions with local Drift inventory (DART-056/063).
library;

import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';

import '../auth/web_oauth_session.dart';
import '../settings/inventory_sync_controller.dart';
import 'entity_bundle_loader.dart';

/// Entity × inventory join for Jaspr Catalog All|Owned + synergy tags.
///
/// Soft never auto-applies.
class OwnedCatalogBridge {
  OwnedCatalogBridge({
    required this.db,
    required this.session,
    this.inventorySync,
    this.offlineCatalog,
    this.entityLoader,
    List<CatalogItem>? baseItems,
    this.plugNameByHash = const {},
  }) : _injectedBase = baseItems;

  final AppDatabase db;
  final WebOAuthSession session;
  final InventorySyncController? inventorySync;
  final OfflineCatalog? offlineCatalog;
  final WebEntityBundleLoader? entityLoader;
  final Map<int, String> plugNameByHash;

  /// Optional fixed base (tests) when no catalog/loader.
  final List<CatalogItem>? _injectedBase;

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
        entityLoader!.catalog == null) {
      await entityLoader!.load();
    }

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
