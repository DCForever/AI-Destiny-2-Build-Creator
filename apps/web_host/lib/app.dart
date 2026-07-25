/// Root shell + client router for the Jaspr web host (DART-042–047).
library;

import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'package:destiny2_bungie/destiny2_bungie.dart';

import 'auth/web_oauth_session.dart';
import 'builds/build_compose_page.dart';
import 'builds/builds_page.dart';
import 'catalog/entity_bundle_loader.dart';
import 'components/shell_header.dart';
import 'compose/compose_services.dart';
import 'db/web_database_bootstrap.dart';
import 'db/web_db_status.dart';
import 'dim_export/dim_export_controller.dart';
import 'pages/auth_callback_page.dart';
import 'pages/catalog_page.dart';
import 'pages/settings_page.dart';
import 'sets/sets_page.dart';
import 'synergies/synergies_page.dart';
import 'theme/theme.dart' as theme;

/// Main application: shell chrome + routed pages + optional DB / entity / OAuth.
///
/// When [bootstrap] is null (tests), Settings shows loading DB status unless
/// [initialDbStatus] is provided. Catalog uses [entityLoader] or injected page.
/// Compose spine uses [compose] (writer DB) when available.
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

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late WebDbSessionStatus _dbStatus;
  StreamSubscription<WebDbSessionStatus>? _sub;
  ComposeServices? _compose;

  @override
  void initState() {
    super.initState();
    _compose = component.compose;
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
          });
        }
      });
      unawaited(
        boot.start().then((status) {
          if (mounted) {
            setState(() {
              _dbStatus = status;
              _syncComposeFromBootstrap(boot);
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

  void _syncComposeFromBootstrap(WebDatabaseBootstrap boot) {
    if (component.compose != null) return;
    final db = boot.database;
    if (db != null && _compose == null) {
      _compose = ComposeServices(
        db: db,
        session: component.oauthSession,
        profileClient: component.profileClient,
        writeClient: component.writeClient,
        clipboardWriter: component.clipboardWriter,
        skipSyncIfStale: false,
      );
    }
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel() ?? Future<void>.value());
    super.dispose();
  }

  ComposeServices? get _effectiveCompose => component.compose ?? _compose;

  @override
  Component build(BuildContext context) {
    final compose = _effectiveCompose;
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
                ),
              ),
              Route(
                path: '/settings',
                title: 'Settings',
                builder: (context, state) => SettingsPage(
                  dbStatus: _dbStatus,
                  oauthSession: component.oauthSession,
                ),
              ),
              Route(
                path: '/catalog',
                title: 'Catalog',
                builder: (context, state) => CatalogPage(
                  loader: component.entityLoader,
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
