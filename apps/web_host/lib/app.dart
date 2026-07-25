/// Root shell + client router for the Jaspr web host (DART-042–056).
library;

import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';

import 'auth/web_oauth_session.dart';
import 'builds/build_compose_page.dart';
import 'builds/builds_page.dart';
import 'catalog/entity_bundle_loader.dart';
import 'catalog/owned_catalog_bridge.dart';
import 'components/shell_header.dart';
import 'compose/compose_services.dart';
import 'db/web_database_bootstrap.dart';
import 'db/web_db_status.dart';
import 'dim_export/dim_export_controller.dart';
import 'equip/equipment_bucket_lookup_provider.dart';
import 'equip/roll_tag_lookup_provider.dart';
import 'loadouts/loadouts_controller.dart';
import 'loadouts/loadouts_page.dart';
import 'pages/auth_callback_page.dart';
import 'pages/catalog_page.dart';
import 'pages/settings_page.dart';
import 'sets/sets_page.dart';
import 'settings/inventory_sync_controller.dart';
import 'synergies/synergies_page.dart';
import 'theme/theme.dart' as theme;

/// Main application: shell chrome + routed pages + optional DB / entity / OAuth.
///
/// When [bootstrap] is null (tests), Settings shows loading DB status unless
/// [initialDbStatus] is provided. Catalog uses [entityLoader] or injected page.
/// Compose spine uses [compose] (writer DB) when available.
/// Inventory sync (DART-056) uses writer DB + profile + session.
class App extends StatefulComponent {
  const App({
    this.bootstrap,
    this.initialDbStatus,
    this.entityLoader,
    this.oauthSession,
    this.compose,
    this.profileClient,
    this.writeClient,
    this.clipboardWriter,
    this.loadoutsController,
    this.inventorySync,
    super.key,
  });

  final WebDatabaseBootstrap? bootstrap;
  final WebDbSessionStatus? initialDbStatus;

  /// Prebuilt entity bundle loader for Catalog (DART-044).
  final WebEntityBundleLoader? entityLoader;

  /// Browser Public+PKCE session (DART-045). Optional in pure UI tests.
  final WebOAuthSession? oauthSession;

  /// Compose spine services (DART-046/047). Null when writer DB unavailable.
  final ComposeServices? compose;

  /// Optional equip clients (DART-047). Used when auto-building ComposeServices.
  final BungieProfileClient? profileClient;
  final BungieWriteClient? writeClient;
  final DimClipboardWriter? clipboardWriter;

  /// Optional prebuilt loadouts controller (tests inject fixtures).
  final LoadoutsController? loadoutsController;

  /// Optional prebuilt inventory sync (tests inject).
  final InventorySyncController? inventorySync;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late WebDbSessionStatus _dbStatus;
  StreamSubscription<WebDbSessionStatus>? _sub;
  ComposeServices? _compose;
  LoadoutsController? _loadouts;
  InventorySyncController? _inventorySync;
  OwnedCatalogBridge? _ownedBridge;

  @override
  void initState() {
    super.initState();
    _compose = component.compose;
    _loadouts = component.loadoutsController;
    _inventorySync = component.inventorySync;
    _ensureLoadoutsController();
    _dbStatus = component.initialDbStatus ??
        component.bootstrap?.status ??
        WebDbSessionStatus.loadingWriter;

    final boot = component.bootstrap;
    if (boot != null) {
      _sub = boot.statusStream.listen((status) {
        if (mounted) {
          setState(() {
            _dbStatus = status;
            _syncComposeFromBootstrap(boot);
            _syncInventoryFromBootstrap(boot);
          });
        }
      });
      unawaited(
        boot.start().then((status) {
          if (mounted) {
            setState(() {
              _dbStatus = status;
              _syncComposeFromBootstrap(boot);
              _syncInventoryFromBootstrap(boot);
            });
          }
        }),
      );
    }

    final oauth = component.oauthSession;
    if (oauth != null && !oauth.hasRestored) {
      unawaited(oauth.restore());
    }
  }

  /// Lazy lookup: entity bundle may load after writer DB opens (DART-056).
  EquipmentBucketLookupBuilder? _lookupBuilder() {
    final loader = component.entityLoader;
    if (loader == null) return null;
    return (List<int> transferItemHashes) async {
      if (transferItemHashes.isEmpty) return const {};
      var catalog = loader.catalog;
      if (catalog == null || catalog.baseItems.isEmpty) {
        await loader.load();
        catalog = loader.catalog;
      }
      if (catalog == null) return const {};
      return createWebEquipmentBucketLookupBuilder(
        offlineCatalog: catalog,
      )(transferItemHashes);
    };
  }

  /// Lazy roll-tag enrichment from entity loader catalog when ready.
  ({
    PerkNameMapBuilder perkNameMapBuilder,
    WeaponRollMetaLookupBuilder weaponRollMetaLookupBuilder,
  })? _rollTags() {
    final loader = component.entityLoader;
    if (loader == null) return null;
    Future<Map<int, String>> perkBuilder(List<int> plugHashes) async {
      return const {};
    }

    Future<Map<int, RollTagWeaponMeta>> weaponBuilder(
      List<int> itemHashes,
    ) async {
      if (itemHashes.isEmpty) return const {};
      var catalog = loader.catalog;
      if (catalog == null || catalog.baseItems.isEmpty) {
        await loader.load();
        catalog = loader.catalog;
      }
      if (catalog == null) return const {};
      final tags = createWebRollTagEnrichment(offlineCatalog: catalog);
      return tags.weaponRollMetaLookupBuilder(itemHashes);
    }

    return (
      perkNameMapBuilder: perkBuilder,
      weaponRollMetaLookupBuilder: weaponBuilder,
    );
  }

  void _syncComposeFromBootstrap(WebDatabaseBootstrap boot) {
    if (component.compose != null) return;
    final db = boot.database;
    if (db != null && _compose == null) {
      // DART-050/056: equip syncIfStale uses entity catalog slots for vault resolve.
      // DART-051: catalog frame meta for roll tags (perk names need raw/injected).
      final lookupBuilder = _lookupBuilder();
      final rollTags = _rollTags();
      _compose = ComposeServices(
        db: db,
        session: component.oauthSession,
        profileClient: component.profileClient,
        writeClient: component.writeClient,
        clipboardWriter: component.clipboardWriter,
        skipSyncIfStale: false,
        equipmentBucketLookupBuilder: lookupBuilder,
        perkNameMapBuilder: rollTags?.perkNameMapBuilder,
        weaponRollMetaLookupBuilder: rollTags?.weaponRollMetaLookupBuilder,
      );
    }
  }

  void _syncInventoryFromBootstrap(WebDatabaseBootstrap boot) {
    if (component.inventorySync != null) {
      _inventorySync = component.inventorySync;
      _ensureOwnedBridge(boot.database);
      return;
    }
    final db = boot.database;
    final session = component.oauthSession;
    final profile = component.profileClient;
    if (db != null &&
        session != null &&
        profile != null &&
        _inventorySync == null) {
      final lookupBuilder = _lookupBuilder();
      final rollTags = _rollTags();
      _inventorySync = InventorySyncController(
        db: db,
        session: session,
        profileClient: profile,
        equipmentBucketLookupBuilder: lookupBuilder,
        perkNameMapBuilder: rollTags?.perkNameMapBuilder,
        weaponRollMetaLookupBuilder: rollTags?.weaponRollMetaLookupBuilder,
      );
    }
    _ensureOwnedBridge(db);
  }

  void _ensureOwnedBridge(AppDatabase? db) {
    if (_ownedBridge != null || db == null) return;
    final session = component.oauthSession;
    if (session == null) return;
    _ownedBridge = OwnedCatalogBridge(
      db: db,
      session: session,
      inventorySync: _inventorySync,
      entityLoader: component.entityLoader,
      offlineCatalog: component.entityLoader?.catalog,
    );
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel() ?? Future<void>.value());
    super.dispose();
  }

  ComposeServices? get _effectiveCompose => component.compose ?? _compose;

  LoadoutsController? get _effectiveLoadouts =>
      component.loadoutsController ?? _loadouts;

  InventorySyncController? get _effectiveInventorySync =>
      component.inventorySync ?? _inventorySync;

  void _ensureLoadoutsController() {
    if (_loadouts != null) return;
    final session = component.oauthSession;
    final profile = component.profileClient;
    if (session != null && profile != null) {
      _loadouts = LoadoutsController(
        session: session,
        profileClient: profile,
      );
    }
  }

  @override
  Component build(BuildContext context) {
    final compose = _effectiveCompose;
    final loadouts = _effectiveLoadouts;
    final inventorySync = _effectiveInventorySync;
    return div(classes: 'app-shell', [
      Router(
        routes: [
          ShellRoute(
            builder: (context, state, child) => .fragment([
              const ShellHeader(),
              main_(
                classes: 'app-main',
                [child],
              ),
            ]),
            routes: [
              Route(
                path: '/',
                title: 'Settings',
                builder: (context, state) => SettingsPage(
                  dbStatus: _dbStatus,
                  oauthSession: component.oauthSession,
                  inventorySync: inventorySync,
                ),
              ),
              Route(
                path: '/settings',
                title: 'Settings',
                builder: (context, state) => SettingsPage(
                  dbStatus: _dbStatus,
                  oauthSession: component.oauthSession,
                  inventorySync: inventorySync,
                ),
              ),
              Route(
                path: '/catalog',
                title: 'Catalog',
                builder: (context, state) => CatalogPage(
                  loader: component.entityLoader,
                  bridge: _ownedBridge,
                ),
              ),
              Route(
                path: '/builds',
                title: 'Builds',
                builder: (context, state) => BuildsPage(
                  controller: compose?.builds,
                ),
              ),
              Route(
                path: '/builds/:buildId',
                title: 'Build compose',
                builder: (context, state) => BuildComposePage(
                  buildId: state.params['buildId'] ?? '',
                  controller: compose?.builds,
                  equipController: compose?.equip,
                  dimExportController: compose?.dimExport,
                ),
              ),
              Route(
                path: '/sets',
                title: 'Sets',
                builder: (context, state) => SetsPage(
                  controller: compose?.sets,
                ),
              ),
              Route(
                path: '/synergies',
                title: 'Synergies',
                builder: (context, state) => SynergiesPage(
                  controller: compose?.synergies,
                ),
              ),
              Route(
                path: '/loadouts',
                title: 'In-Game Loadouts',
                builder: (context, state) => LoadoutsPage(
                  controller: loadouts,
                ),
              ),
              Route(
                path: '/auth/callback',
                title: 'Signing in',
                builder: (context, state) => AuthCallbackPage(
                  session: component.oauthSession,
                ),
              ),
            ],
          ),
        ],
      ),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
        ...theme.styles,
        css('.app-shell', [
          css('&').styles(
            display: .flex,
            width: 100.percent,
            minHeight: 100.vh,
            flexDirection: .column,
            backgroundColor: theme.flapBackgroundColor,
          ),
          css('.app-main').styles(
            display: .flex,
            flex: Flex(grow: 1),
            flexDirection: .column,
            alignItems: .stretch,
          ),
        ]),
      ];
}
