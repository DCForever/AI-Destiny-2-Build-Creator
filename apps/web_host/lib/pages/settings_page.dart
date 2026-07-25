/// Hello Settings stub (DART-042) — no OAuth, no OPFS/DB.
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../theme/theme.dart';

/// Primary landing surface for the Jaspr skeleton.
///
/// Shows a clear Settings identity and Hello greeting. Later slices add
/// inventory sync, OPFS status, and OAuth (DART-043+).
class SettingsPage extends StatelessComponent {
  const SettingsPage({super.key});

  /// Stable copy for tests and a11y.
  static const String titleText = 'Settings';
  static const String helloText = 'Hello';
  static const String subtitleText =
      'Jaspr web host skeleton — Matte Flap tokens, client routing. '
      'No Next.js dependency. Sign-in and OPFS arrive in later DART slices.';

  @override
  Component build(BuildContext context) {
    return section(
      classes: 'settings-page',
      attributes: {'data-page': 'settings'},
      [
        h1([.text(titleText)]),
        p(
          classes: 'settings-hello',
          attributes: {'data-testid': 'hello'},
          [.text(helloText)],
        ),
        p(classes: 'settings-sub', [.text(subtitleText)]),
        div(classes: 'settings-panel', [
          h2([.text('Host status')]),
          ul([
            li([.text('Shell: Jaspr client SPA')]),
            li([.text('Tokens: destiny2_ui_tokens → CSS')]),
            li([.text('Database: not opened (DART-043)')]),
            li([.text('Sign-in: not configured (DART-045)')]),
          ]),
        ]),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
        css('.settings-page', [
          css('&').styles(
            display: .flex,
            width: 100.percent,
            maxWidth: 40.rem,
            padding: .symmetric(horizontal: 1.25.rem, vertical: 1.5.rem),
            flexDirection: .column,
            alignItems: .start,
            gap: Gap(row: 0.75.rem),
          ),
          css('.settings-hello').styles(
            color: flapAccentColor,
            fontSize: 1.25.rem,
            fontWeight: .w600,
          ),
          css('.settings-sub').styles(
            maxWidth: 36.rem,
            lineHeight: 1.5.em,
          ),
          css('.settings-panel', [
            css('&').styles(
              width: 100.percent,
              margin: .only(top: 1.rem),
              padding: .all(1.rem),
              border: .only(top: .solid(color: flapLineColor, width: 1.px)),
              radius: .all(.circular(0.px)),
              backgroundColor: flapSurfaceColor,
            ),
            css('h2').styles(
              margin: .only(bottom: 0.5.rem),
              fontSize: 0.85.rem,
              fontWeight: .w600,
              letterSpacing: 0.06.em,
              color: flapMutedColor,
              textTransform: .upperCase,
            ),
            css('ul').styles(
              margin: .zero,
              padding: .only(left: 1.25.rem),
              color: flapForegroundColor,
            ),
            css('li').styles(
              margin: .only(bottom: 0.35.rem),
              fontSize: 0.95.rem,
            ),
          ]),
        ]),
      ];
}
