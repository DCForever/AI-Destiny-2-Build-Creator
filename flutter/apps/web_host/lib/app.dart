/// Root shell + client router for the Jaspr web host (DART-042–056).
library;

import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';

import 'auth/web_oauth_session.dart';
import 'builds/build_compose_page.dart';
import 'builds/builds_page.dart';
import 'catalog/entity_bundle_loader.dart';
import 'catalog/owned_catalog_bridge.dart';
import 'components/shell_header.dart';
import 'compose/compose_services.dart';
import 'db/web_database_bootstrap.dart';
import 'db/web_db_status.dart';
import 'equip/equipment_bucket_lookup_provider.dart';
import 'equip/roll_tag_lookup_provider.dart';
import 'equip/weapon_socket_context_provider.dart';
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

  /// Bungie clients for inventory sync (DART-056).
  final BungieProfileClient? profileClient;
  final BungieWriteClient? writeClient;

  /// Optional prebuilt inventory sync (tests inject).
  final InventorySyncController? inventorySync;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late WebDbSessionStatus _dbStatus;
  StreamSubscription<WebDbSessionStatus>? _sub;
  ComposeServices? _compose;
  InventorySyncController? _inventorySync;
  OwnedCatalogBridge? _ownedBridge;

  @override
  void initState() {
    super.initState();
    _compose = component.compose;
    _inventorySync = component.inventorySync;
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

  /// Lazy roll-tag + socket enrichment from entity loader catalog when ready.
  ({
    PerkNameMapBuilder perkNameMapBuilder,
    WeaponRollMetaLookupBuilder weaponRollMetaLookupBuilder,
    WeaponSocketContextBuilder weaponSocketContextBuilder,
  })? _inventoryEnrichment() {
    final loader = component.entityLoader;
    if (loader == null) return null;

    Future<OfflineCatalog?> resolveCatalog() async {
      var catalog = loader.catalog;
      if (catalog == null || catalog.baseItems.isEmpty) {
        await loader.load();
        catalog = loader.catalog;
      }
      return catalog;
    }

    Future<Map<int, String>> perkBuilder(List<int> plugHashes) async {
      final catalog = await resolveCatalog();
      if (catalog == null) return const {};
      final extraNamed = <({int hash, String name})>[];
      final doc = loader.document;
      if (doc != null) {
        for (final store in doc.stores.values) {
          for (final row in store) {
            if (row is EntityRecordBase && row.name.isNotEmpty) {
              extraNamed.add((hash: row.hash, name: row.name));
            }
          }
        }
      }
      final tags = createWebRollTagEnrichment(
        offlineCatalog: catalog,
        extraNamedHashes: extraNamed,
      );
      return tags.perkNameMapBuilder(plugHashes);
    }

    Future<Map<int, RollTagWeaponMeta>> weaponBuilder(
      List<int> itemHashes,
    ) async {
      final catalog = await resolveCatalog();
      if (catalog == null) return const {};
      final tags = createWebRollTagEnrichment(offlineCatalog: catalog);
      return tags.weaponRollMetaLookupBuilder(itemHashes);
    }

    // Entity channel: empty context unless raw/defs maps are injected later.
    // Tests inject via InventorySyncController.weaponSocketContextBuilder.
    final socket = createWebWeaponSocketEnrichment();

    return (
      perkNameMapBuilder: perkBuilder,
      weaponRollMetaLookupBuilder: weaponBuilder,
      weaponSocketContextBuilder: socket.weaponSocketContextBuilder,
    );
  }

  void _syncComposeFromBootstrap(WebDatabaseBootstrap boot) {
    if (component.compose != null) return;
    final db = boot.database;
    if (db != null && _compose == null) {
      _compose = ComposeServices(db: db);
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
      final enrich = _inventoryEnrichment();
      _inventorySync = InventorySyncController(
        db: db,
        session: session,
        profileClient: profile,
        equipmentBucketLookupBuilder: lookupBuilder,
        perkNameMapBuilder: enrich?.perkNameMapBuilder,
        weaponRollMetaLookupBuilder: enrich?.weaponRollMetaLookupBuilder,
        weaponSocketContextBuilder: enrich?.weaponSocketContextBuilder,
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
      plugNameMapBuilder: _inventoryEnrichment()?.perkNameMapBuilder,
    );
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel() ?? Future<void>.value());
    super.dispose();
  }

  ComposeServices? get _effectiveCompose => component.compose ?? _compose;

  InventorySyncController? get _effectiveInventorySync =>
      component.inventorySync ?? _inventorySync;

  @override
  Component build(BuildContext context) {
    final compose = _effectiveCompose;
    final inventorySync = _effectiveInventorySync;
    return div(classes: 'app-shell neon-shell', [
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
                ),
              ),
              Route(
                path: '/sets',
                title: 'Sets',
                builder: (context, state) => SetsPage(
                  controller: compose?.sets,
                  bridge: _ownedBridge,
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
            // Atmosphere lives on .neon-shell (void + blooms); keep shell transparent.
            backgroundColor: Colors.transparent,
          ),
          css('.app-main').styles(
            display: .flex,
            flex: Flex(grow: 1),
            flexDirection: .column,
            alignItems: .stretch,
            // Soft stacking over shell blooms.
            raw: {'position': 'relative', 'z-index': '1'},
          ),
        ]),
      ];
}
