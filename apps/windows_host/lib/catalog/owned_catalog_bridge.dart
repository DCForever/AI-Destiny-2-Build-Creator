import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';

import '../auth/windows_oauth_session.dart';
import '../settings/inventory_sync_controller.dart';

/// Joins offline catalog definitions with local Drift inventory (DART-026).
///
/// Pure entity browse stays on [OfflineCatalog]; ownership comes from inventory
/// rows only (no Bungie network on browse). Soft guidance never auto-applies.
class OwnedCatalogBridge {
  OwnedCatalogBridge({
    required this.db,
    required this.offlineCatalog,
    required this.session,
    required this.inventorySync,
  });

  final AppDatabase db;
  final OfflineCatalog offlineCatalog;
  final WindowsOAuthSession session;
  final InventorySyncController inventorySync;

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

  /// Load entity base (if needed) + inventory annotate for the signed-in user.
  Future<void> refresh({bool reloadEntities = true}) async {
    if (reloadEntities) {
      await offlineCatalog.loadBase();
    }

    _userId = await _resolveUserId();
    if (_userId == null) {
      _inventory = const [];
      _ownedCounts = const {};
      _annotatedBase = annotateCatalogWithOwned(
        offlineCatalog.baseItems,
        const {},
      );
      return;
    }

    _inventory = await listInventoryItems(db, _userId!);
    _ownedCounts = ownedHashCountsFromInventory(_inventory);
    _annotatedBase = annotateCatalogWithOwned(
      offlineCatalog.baseItems,
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
