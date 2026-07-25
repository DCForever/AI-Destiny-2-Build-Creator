/// Joins offline catalog definitions with local Drift inventory (DART-056).
library;

import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';

import '../auth/web_oauth_session.dart';
import '../settings/inventory_sync_controller.dart';
import 'entity_bundle_loader.dart';

/// Entity × inventory join for Jaspr Catalog All|Owned + instance projections.
///
/// Pure entity browse stays on [OfflineCatalog] / base list; ownership comes
/// from inventory rows only (no Bungie network on browse). Soft never auto-applies.
class OwnedCatalogBridge {
  OwnedCatalogBridge({
    required this.db,
    required this.session,
    this.inventorySync,
    this.offlineCatalog,
    this.entityLoader,
    List<CatalogItem>? baseItems,
  }) : _injectedBase = baseItems;

  final AppDatabase db;
  final WebOAuthSession session;
  final InventorySyncController? inventorySync;
  final OfflineCatalog? offlineCatalog;
  final WebEntityBundleLoader? entityLoader;

  /// Optional fixed base (tests) when no catalog/loader.
  final List<CatalogItem>? _injectedBase;

  List<CatalogItem> _annotatedBase = const [];
  List<InventoryItemRecord> _inventory = const [];
  Map<int, int> _ownedCounts = const {};
  int? _userId;

  List<CatalogItem> get annotatedBase => _annotatedBase;
  List<InventoryItemRecord> get inventory => _inventory;
  Map<int, int> get ownedCounts => _ownedCounts;
  int? get userId => _userId;
  int get ownedDefinitionCount =>
      _ownedCounts.values.where((c) => c > 0).length;

  OfflineCatalog? get _resolvedCatalog =>
      offlineCatalog ?? entityLoader?.catalog;

  List<CatalogItem> get _entityBase {
    if (_injectedBase != null) return _injectedBase!;
    return _resolvedCatalog?.baseItems ?? const [];
  }

  /// Load entity base (if needed) + inventory annotate for the signed-in user.
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
      _annotatedBase = annotateCatalogWithOwned(
        _entityBase,
        const {},
      );
      return;
    }

    _inventory = await listInventoryItems(db, _userId!);
    _ownedCounts = ownedHashCountsFromInventory(_inventory);
    _annotatedBase = annotateCatalogWithOwned(
      _entityBase,
      _ownedCounts,
    );
  }

  /// Filter annotated base with client facets + [scope].
  List<CatalogItem> browse(CatalogClientFilters filters) {
    return filterCatalogClient(_annotatedBase, filters);
  }

  /// Instance projections for a definition hash (power-desc).
  List<CatalogInstanceProjection> instancesFor(int itemHash) {
    return projectInstancesForHash(_inventory, itemHash);
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
