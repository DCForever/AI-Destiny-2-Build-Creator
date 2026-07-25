/// Root shell + client router for the Jaspr web host (DART-042).
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'components/shell_header.dart';
import 'pages/settings_page.dart';
import 'theme/theme.dart' as theme;

/// Main application component: shell chrome + routed pages.
class App extends StatelessComponent {
  const App({super.key});

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
                builder: (context, state) => const SettingsPage(),
              ),
              Route(
                path: '/settings',
                title: 'Settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
        // Pull in global flap theme (CSS variables + body).
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
