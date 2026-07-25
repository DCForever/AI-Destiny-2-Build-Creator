/// Settings surface with Hello + web DB status (DART-042/043).
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../db/web_db_status.dart';
import '../theme/theme.dart';

/// Primary landing surface for the Jaspr web host.
///
/// Shows Settings identity, Hello greeting, and local database / OPFS session
/// status (writer vs blocked). OAuth remains a later slice (DART-045).
class SettingsPage extends StatelessComponent {
  const SettingsPage({
    this.dbStatus,
    super.key,
  });

  /// When null, shows a loading placeholder for the DB panel.
  final WebDbSessionStatus? dbStatus;

  /// Stable copy for tests and a11y.
  static const String titleText = 'Settings';
  static const String helloText = 'Hello';
  static const String subtitleText =
      'Jaspr web host — Matte Flap tokens, client routing, Drift WASM/OPFS. '
      'No Next.js dependency. Single-tab writer for local SQLite.';

  static const String blockedBannerText =
      'Another tab holds the database writer. This tab is blocked from writing. '
      'Close other tabs of this app, then reload.';

  static const String writerReadyHint =
      'This tab is the database writer. Prefer a single tab for local data.';

  @override
  Component build(BuildContext context) {
    final status = dbStatus ?? WebDbSessionStatus.loadingWriter;
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
        if (status.isBlocked)
          div(
            classes: 'settings-banner settings-banner-blocked',
            attributes: {
              'data-testid': 'db-blocked-banner',
              'role': 'status',
            },
            [.text(blockedBannerText)],
          ),
        if (status.isWriter && status.isReady)
          div(
            classes: 'settings-banner settings-banner-writer',
            attributes: {
              'data-testid': 'db-writer-banner',
              'role': 'status',
            },
            [.text(writerReadyHint)],
          ),
        div(classes: 'settings-panel', [
          h2([.text('Host status')]),
          ul([
            li([.text('Shell: Jaspr client SPA')]),
            li([.text('Tokens: destiny2_ui_tokens → CSS')]),
            li(
              attributes: {'data-testid': 'db-summary'},
              [.text(status.summaryLine)],
            ),
            li(
              attributes: {'data-testid': 'db-role'},
              [.text(status.roleLabel)],
            ),
            if (status.storageImplementation != null)
              li(
                attributes: {'data-testid': 'db-storage'},
                [.text('Storage: ${status.storageImplementation}')],
              ),
            li([.text('Sign-in: not configured (DART-045)')]),
          ]),
        ]),
        div(classes: 'settings-panel', [
          h2([.text('Local database policy')]),
          p(classes: 'settings-policy', [
            .text(
              'Single-tab writer (D-WEB-DB): only one browser tab may write. '
              'Additional tabs are blocked. See docs/multiplatform-dart-web-opfs-limits.md.',
            ),
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
          css('.settings-banner').styles(
            width: 100.percent,
            maxWidth: 36.rem,
            padding: .all(0.75.rem),
            border: .only(
              left: .solid(color: flapAccentColor, width: 3.px),
            ),
            radius: .all(.circular(0.px)),
            backgroundColor: flapSurfaceColor,
            color: flapForegroundColor,
            fontSize: 0.95.rem,
            lineHeight: 1.45.em,
          ),
          css('.settings-banner-blocked').styles(
            border: .only(
              left: .solid(color: Color('#c45c26'), width: 3.px),
            ),
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
            css('.settings-policy').styles(
              margin: .zero,
              color: flapForegroundColor,
              fontSize: 0.95.rem,
              lineHeight: 1.45.em,
            ),
          ]),
        ]),
      ];
}
