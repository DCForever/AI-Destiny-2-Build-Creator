/// App shell header / primary nav (DART-042).
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../theme/theme.dart';

class ShellHeader extends StatelessComponent {
  const ShellHeader({super.key});

  static const routes = [
    (label: 'Catalog', path: '/catalog'),
    (label: 'Settings', path: '/'),
  ];

  @override
  Component build(BuildContext context) {
    final activePath = RouteState.of(context).location;

    return header(classes: 'shell-header', [
      div(classes: 'shell-brand', [
        span(classes: 'shell-mark', [.text('D2')]),
        span(classes: 'shell-title', [.text('Build Creator')]),
        span(classes: 'shell-badge', [.text('Web')]),
      ]),
      nav(classes: 'shell-nav', [
        for (final route in routes)
          div(
            classes: _isActive(activePath, route.path) ? 'active' : null,
            [
              Link(to: route.path, child: .text(route.label)),
            ],
          ),
      ]),
    ]);
  }

  static bool _isActive(String location, String path) {
    if (path == '/') {
      return location == '/' || location.startsWith('/settings');
    }
    return location == path || location.startsWith('$path/');
  }

  @css
  static List<StyleRule> get styles => [
        css('.shell-header', [
          css('&').styles(
            display: .flex,
            width: 100.percent,
            padding: .symmetric(horizontal: 1.25.rem, vertical: 0.75.rem),
            border: .only(bottom: .solid(color: flapLineColor, width: 1.px)),
            flexDirection: .row,
            justifyContent: .spaceBetween,
            alignItems: .center,
            backgroundColor: flapSurfaceColor,
          ),
          css('.shell-brand').styles(
            display: .flex,
            alignItems: .center,
            gap: Gap(column: 0.5.rem),
          ),
          css('.shell-mark').styles(
            padding: .symmetric(horizontal: 0.4.rem, vertical: 0.15.rem),
            radius: .all(.circular(0.px)),
            color: flapBackgroundColor,
            fontWeight: .w700,
            fontSize: 0.75.rem,
            letterSpacing: 0.04.em,
            backgroundColor: flapAccentColor,
          ),
          css('.shell-title').styles(
            color: flapForegroundColor,
            fontWeight: .w600,
            fontSize: 0.95.rem,
          ),
          css('.shell-badge').styles(
            padding: .symmetric(horizontal: 0.35.rem, vertical: 0.1.rem),
            border: .all(style: .solid, color: flapLineColor, width: 1.px),
            color: flapMutedColor,
            fontSize: 0.7.rem,
            letterSpacing: 0.08.em,
            textTransform: .upperCase,
          ),
          css('.shell-nav', [
            css('&').styles(
              display: .flex,
              alignItems: .center,
              gap: Gap(column: 0.25.rem),
            ),
            css('a').styles(
              display: .flex,
              padding: .symmetric(horizontal: 0.85.rem, vertical: 0.45.rem),
              color: flapMutedColor,
              fontWeight: .w600,
              fontSize: 0.85.rem,
              textDecoration: TextDecoration(line: .none),
            ),
            css('a:hover').styles(
              color: flapForegroundColor,
            ),
            css('div.active a').styles(
              border: .only(bottom: .solid(color: flapAccentColor, width: 2.px)),
              color: flapAccentColor,
            ),
          ]),
        ]),
      ];
}
