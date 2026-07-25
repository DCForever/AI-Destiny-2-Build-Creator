/// Settings surface with Hello + web DB status + OAuth + inventory sync (DART-042–056).
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../auth/web_oauth_session.dart';
import '../components/oauth_account_card.dart';
import '../db/web_db_status.dart';
import '../settings/inventory_sync_card.dart';
import '../settings/inventory_sync_controller.dart';
import '../theme/theme.dart';

/// Primary landing surface for the Jaspr web host.
///
/// Shows Settings identity, Hello greeting, local database / OPFS session
/// status (writer vs blocked), Public+PKCE Bungie account (DART-045), and
/// inventory sync with vault/transfer resolution (DART-056).
class SettingsPage extends StatelessComponent {
  const SettingsPage({
    this.dbStatus,
    this.oauthSession,
    this.inventorySync,
    super.key,
  });

  /// When null, shows a loading placeholder for the DB panel.
  final WebDbSessionStatus? dbStatus;

  /// When null, account card is omitted (tests that only cover DB/Hello).
  final WebOAuthSession? oauthSession;

  /// When non-null and [oauthSession] is set, shows inventory Sync now card.
  final InventorySyncController? inventorySync;

  /// Stable copy for tests and a11y.
  static const String titleText = 'Settings';
  static const String helloText = 'Hello';
  static const String subtitleText =
      'Jaspr web host — Matte Flap tokens, client routing, Drift WASM/OPFS, '
      'prebuilt entity bundles for Catalog, Public+PKCE Bungie sign-in, '
      'inventory sync with vault/postmaster resolution (DART-056). '
      'No Next.js dependency. Single-tab writer for local SQLite. '
      'No confidential client secret.';

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
        if (oauthSession != null) OAuthAccountCard(session: oauthSession!),
        if (inventorySync != null && oauthSession != null)
          InventorySyncCard(
            controller: inventorySync!,
            session: oauthSession!,
          )
        else if (oauthSession != null && !status.isWriter)
          div(classes: 'settings-panel', [
            h2([.text('Inventory sync')]),
            p(
              classes: 'settings-policy',
              attributes: {'data-testid': 'inventory-sync-writer-required'},
              [
                .text(
                  'Inventory sync requires the database writer tab. '
                  'Close other tabs of this app, then reload.',
                ),
              ],
            ),
          ]),
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
            li([.text('Entities: prebuilt bundles (DART-044) — see Catalog')]),
            li(
              attributes: {'data-testid': 'oauth-host-line'},
              [
                .text(
                  oauthSession == null
                      ? 'Sign-in: session not injected'
                      : (oauthSession!.isConfigured
                          ? 'Sign-in: Public+PKCE (DART-045)'
                          : 'Sign-in: configure BUNGIE_CLIENT_ID'),
                ),
              ],
            ),
            li(
              attributes: {'data-testid': 'inventory-host-line'},
              [
                .text(
                  inventorySync == null
                      ? 'Inventory: controller not available (writer DB + profile)'
                      : 'Inventory: full-replace sync + vault resolution (DART-056)',
                ),
              ],
            ),
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
        div(classes: 'settings-panel', [
          h2([.text('Entity bundles')]),
          p(classes: 'settings-policy', [
            .text(
              'Catalog uses prebuilt MVP entity JSON (no full raw manifest rebuild '
              'in the browser). Fixture: /entities/prebuilt/bundle.json.',
            ),
          ]),
          p(
            classes: 'settings-policy settings-entity-owned-warning',
            attributes: {
              'data-testid': 'entity-owned-warning',
              'role': 'status',
            },
            [
              .text(
                'Owned catalog joins inventory counts onto entity definitions. '
                'If entity bundles are empty or missing, empty Owned is not solely '
                'an inventory sync problem — load entity bundles and sync inventory '
                '(DART-053 / GAP-INV-06). Web Settings Sync now uses the same '
                'vault/postmaster equipment-bucket resolution as Windows (DART-056). '
                'Diagnostics show raw/parsed/dropped/resolution after Sync now (GAP-INV-04).',
              ),
            ],
          ),
        ]),
        div(classes: 'settings-panel', [
          h2([.text('OAuth token storage')]),
          p(classes: 'settings-policy', [
            .text(
              'Access and refresh tokens use origin-scoped browser storage '
              '(localStorage), never SQLite/Drift. Pending PKCE lives in '
              'sessionStorage for the redirect only. Prefer HTTPS origins. '
              'No CLIENT_SECRET in this client.',
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
