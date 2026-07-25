/// Root shell + client router for the Jaspr web host (DART-042/043).
library;

import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'components/shell_header.dart';
import 'db/web_database_bootstrap.dart';
import 'db/web_db_status.dart';
import 'pages/settings_page.dart';
import 'theme/theme.dart' as theme;

/// Main application: shell chrome + routed pages + optional DB bootstrap.
///
/// When [bootstrap] is null (tests), Settings shows loading DB status unless
/// [initialDbStatus] is provided.
class App extends StatefulComponent {
  const App({
    this.bootstrap,
    this.initialDbStatus,
    super.key,
  });

  final WebDatabaseBootstrap? bootstrap;
  final WebDbSessionStatus? initialDbStatus;

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
                builder: (context, state) => SettingsPage(dbStatus: _dbStatus),
              ),
              Route(
                path: '/settings',
                title: 'Settings',
                builder: (context, state) => SettingsPage(dbStatus: _dbStatus),
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
