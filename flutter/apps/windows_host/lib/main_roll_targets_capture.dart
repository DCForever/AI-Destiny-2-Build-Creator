import 'dart:io';

import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'auth/browser_launcher.dart';
import 'auth/token_store.dart';
import 'catalog/catalog_page.dart';
import 'catalog/owned_catalog_bridge.dart';
import 'catalog/roll_targets_capture_fixtures.dart';
import 'host_bootstrap.dart';
import 'theme/flap_theme.dart';

/// CatalogRollTargets dual-truth Capture entrypoint (`drive: host-fixture`).
///
/// Seeds inventory + PvE active profile for hash [kRollTargetWeaponHash], then
/// opens [CatalogPage]. Flutter Driver screenshots go under
/// `docs/ux-redesign/catalog/implementation-shots/003-catalog-roll-targets/`.
///
/// ```text
/// flutter run -d windows -t lib/main_roll_targets_capture.dart
/// ```
///
/// Matrix ids (search / keys):
/// - Roll Target HC → open detail for dual segs / rank / wash
/// - instance chips: `instance_chip_rt-perfect` · `rt-partial` · `rt-dirty`
/// - switcher: `roll_target_opt_off` · PvE chip
/// - Edit: open editor for Want|Avoid|Off
/// - Roll Target Unowned → empty instances
Future<void> main() async {
  enableFlutterDriverExtension();
  debugPrint(
    'main_roll_targets_capture: Flutter Driver on · 003 roll-targets host fixtures',
  );
  WidgetsFlutterBinding.ensureInitialized();

  final temp = await Directory.systemTemp.createTemp('roll_targets_capture_');
  final root = StorageRoot(basePath: temp.path);
  await root.ensureLayout();

  final db = AppDatabase.memory();
  final tokenStore = MemoryTokenStore();
  final now = DateTime.now().toUtc();
  final syncedAt = now.toIso8601String();
  await tokenStore.write(
    BungieTokens(
      accessToken: 'access-roll-targets-capture',
      refreshToken: 'refresh-roll-targets-capture',
      expiresAt: now.add(const Duration(hours: 1)),
      refreshExpiresAt: now.add(const Duration(days: 1)),
      bungieMembershipId: 'bungie-roll-targets-capture',
    ),
  );

  final services = await HostBootstrap.open(
    storageRoot: root,
    database: db,
    manifestRefresh: _NoopRefresh(),
    offlineCatalog: OfflineCatalog.preloaded(
      storageRoot: root,
      items: rollTargetCatalogItems(),
      version: 'roll-targets-capture-live',
      perkColumnsByHash: rollTargetPerkColumns(),
    ),
    clientId: 'roll-targets-capture',
    tokenStore: tokenStore,
    browserLauncher: FakeBrowserLauncher(),
    profileClient: _EmptyProfileClient(),
    oauthClient: BungieOAuthClient(
      clientId: 'roll-targets-capture',
      redirectUri: kDefaultWindowsRedirectUri,
      transport: (_) async => throw StateError('unused'),
    ),
  );

  final user = await ensureUser(
    db,
    bungieMembershipId: 'bungie-roll-targets-capture',
    membershipType: 3,
    displayName: 'Roll Targets Capture',
  );
  await replaceInventoryBatch(
    db,
    user.id,
    now: syncedAt,
    items: rollTargetInventoryItems(syncedAt: syncedAt),
  );

  await createWeaponRollTarget(
    db,
    userId: user.id,
    weaponKey: '$kRollTargetWeaponHash',
    name: 'PvE',
    columns: rollTargetPveColumns(),
    id: 'rt-pve-fixture',
    nowIso: syncedAt,
  );
  await setActiveWeaponRollTarget(
    db,
    userId: user.id,
    weaponKey: '$kRollTargetWeaponHash',
    targetId: 'rt-pve-fixture',
    nowIso: syncedAt,
  );

  final bridge = OwnedCatalogBridge(
    db: db,
    offlineCatalog: services.offlineCatalog,
    session: services.oauthSession,
    inventorySync: services.inventorySync,
    plugNameByHash: kRollTargetPlugNames,
    plugNameMapBuilder: (hashes) async => {
      for (final h in hashes)
        if (kRollTargetPlugNames.containsKey(h)) h: kRollTargetPlugNames[h]!,
    },
  );

  runApp(
    MaterialApp(
      title: 'Catalog roll targets capture',
      debugShowCheckedModeBanner: true,
      theme: buildFlapTheme(),
      home: Scaffold(
        body: CatalogPage(
          key: const Key('catalog_page'),
          services: services,
          bridge: bridge,
        ),
      ),
    ),
  );
}

class _NoopRefresh implements ManifestRefreshApi {
  @override
  Future<bool> isStale() async => false;

  @override
  Future<ManifestStatus> refresh({
    bool forceFullDownload = false,
    bool rebuildInIsolate = true,
  }) async =>
      const ManifestStatus(
        cachedVersion: null,
        remoteVersion: null,
        isStale: true,
        entityCache: null,
      );

  @override
  Future<ManifestStatus> status() async =>
      const ManifestStatus(
        cachedVersion: null,
        remoteVersion: null,
        isStale: true,
        entityCache: null,
      );
}

class _EmptyProfileClient implements BungieProfileClient {
  @override
  Future<List<DestinyMembership>> getMemberships(String accessToken) async =>
      const [
        DestinyMembership(
          membershipType: 3,
          membershipId: 'destiny-roll-targets',
          displayName: 'Roll Targets Capture',
        ),
      ];

  @override
  Future<List<CharacterSummary>> getCharacters(
    String accessToken,
    DestinyMembership membership,
  ) async =>
      const [];

  @override
  Future<Object?> getCharacterLoadoutsProfile(
    String accessToken,
    DestinyMembership membership,
  ) async =>
      null;

  @override
  Future<List<RawInventoryItem>> getFullInventory(
    String accessToken,
    DestinyMembership membership,
  ) async =>
      const [];

  @override
  Future<FullInventoryParseResult> getFullInventoryWithDiagnostics(
    String accessToken,
    DestinyMembership membership,
  ) async =>
      FullInventoryParseResult(
        items: const [],
        diagnostics: InventoryParseDiagnostics(
          membership: membership,
          raw: InventoryRawCounts(),
          parsed: InventoryParsedCounts(),
          dropped: InventoryDroppedCounts(),
        ),
      );
}
