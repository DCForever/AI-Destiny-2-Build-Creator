/// Root shell + client router for the Jaspr web host (DART-042–045).
library;

import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'auth/web_oauth_session.dart';
import 'catalog/entity_bundle_loader.dart';
import 'components/shell_header.dart';
import 'db/web_database_bootstrap.dart';
import 'db/web_db_status.dart';
import 'pages/auth_callback_page.dart';
import 'pages/catalog_page.dart';
import 'pages/settings_page.dart';
import 'theme/theme.dart' as theme;

/// Main application: shell chrome + routed pages + optional DB / entity / OAuth.
///
/// When [bootstrap] is null (tests), Settings shows loading DB status unless
/// [initialDbStatus] is provided. Catalog uses [entityLoader] or injected page.
class App extends StatefulComponent {
  const App({
    this.bootstrap,
    this.initialDbStatus,
    this.entityLoader,
    this.oauthSession,
    super.key,
  });

  final WebDatabaseBootstrap? bootstrap;
  final WebDbSessionStatus? initialDbStatus;

  /// Prebuilt entity bundle loader for Catalog (DART-044).
  final WebEntityBundleLoader? entityLoader;

  /// Browser Public+PKCE session (DART-045). Optional in pure UI tests.
  final WebOAuthSession? oauthSession;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late WebDbSessionStatus _dbStatus;
  StreamSubscription<WebDbSessionStatus>? _sub;

  @override
  void initState() {
    super.initState();
    _dbStatus = component.initialDbStatus ??
        component.bootstrap?.status ??
        WebDbSessionStatus.loadingWriter;

    final boot = component.bootstrap;
    if (boot != null) {
      _sub = boot.statusStream.listen((status) {
        if (mounted) setState(() => _dbStatus = status);
      });
      // Idempotent: main may already have called start().
      unawaited(
        boot.start().then((status) {
          if (mounted) setState(() => _dbStatus = status);
        }),
      );
    }

    final oauth = component.oauthSession;
    if (oauth != null && !oauth.hasRestored) {
      unawaited(oauth.restore());
    }
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel() ?? Future<void>.value());
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
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
