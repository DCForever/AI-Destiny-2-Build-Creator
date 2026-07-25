/// Settings inventory sync card for Jaspr (DART-056 / DART-053 diagnostics).
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../auth/web_oauth_session.dart';
import '../theme/theme.dart';
import 'inventory_sync_controller.dart';

/// Settings inventory sync: Sync now + busy/error + meta + diagnostics.
class InventorySyncCard extends StatefulComponent {
  const InventorySyncCard({
    required this.controller,
    required this.session,
    super.key,
  });

  final InventorySyncController controller;
  final WebOAuthSession session;

  @override
  State<InventorySyncCard> createState() => _InventorySyncCardState();
}

class _InventorySyncCardState extends State<InventorySyncCard> {
  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    component.session.addListener(_onSessionChanged);
    component.controller.addListener(_onChanged);
    // Load local meta after first frame (signed-in restore may already be done).
    Future<void>.microtask(() {
      if (mounted) {
        component.controller.refreshStatus();
      }
    });
  }

  @override
  void didUpdateComponent(covariant InventorySyncCard oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.session != component.session) {
      oldComponent.session.removeListener(_onSessionChanged);
      component.session.addListener(_onSessionChanged);
    }
    if (oldComponent.controller != component.controller) {
      oldComponent.controller.removeListener(_onChanged);
      component.controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    component.session.removeListener(_onSessionChanged);
    component.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    component.controller.refreshStatus();
  }

  @override
  Component build(BuildContext context) {
    final c = component.controller;
    final signedIn = c.isSignedIn;
    final syncing = c.isSyncing;
    final error = c.errorMessage;
    final showError = error != null &&
        (c.phase == InventorySyncPhase.error || error.isNotEmpty);

    return div(
      classes: 'settings-panel inventory-sync-card',
      attributes: {'data-testid': 'inventory-sync-card'},
      [
        h2([.text('Inventory sync')]),
        if (!signedIn)
          p(
            attributes: {'data-testid': 'inventory-sync-signed-out'},
            [
              .text(
                'Sign in to sync owned inventory into the local database '
                '(vault/postmaster resolved with equipment buckets).',
              ),
            ],
          )
        else ...[
          p(
            attributes: {'data-testid': 'inventory-sync-summary'},
            [.text(_summaryLine(c))],
          ),
          ul(classes: 'inventory-sync-meta', [
            li(
              attributes: {'data-testid': 'inventory-item-count'},
              [.text('Items: ${c.itemCount?.toString() ?? '—'}')],
            ),
            li(
              attributes: {'data-testid': 'inventory-sync-version'},
              [.text('Sync version: ${c.syncVersion?.toString() ?? '—'}')],
            ),
            li(
              attributes: {'data-testid': 'inventory-last-sync'},
              [.text('Last full sync: ${c.lastFullSyncAt ?? 'never'}')],
            ),
            li(
              attributes: {'data-testid': 'inventory-freshness'},
              [.text('Freshness: ${_freshnessLabel(c)}')],
            ),
          ]),
          if (c.lastDiagnostics != null) ...[
            h3(
              attributes: {'data-testid': 'inventory-sync-diagnostics-title'},
              [.text('Last sync diagnostics')],
            ),
            ul(classes: 'inventory-sync-meta', [
              li(
                attributes: {'data-testid': 'inventory-diag-raw'},
                [.text('Raw (Bungie): ${c.lastRawTotal ?? '—'}')],
              ),
              li(
                attributes: {'data-testid': 'inventory-diag-parsed'},
                [.text('Parsed: ${c.lastParsedTotal ?? '—'}')],
              ),
              li(
                attributes: {'data-testid': 'inventory-diag-dropped'},
                [
                  .text(
                    'Dropped: ${c.lastDroppedTotal ?? '—'} '
                    '(unknown: ${c.lastDiagnostics!.dropped.unknownBucket}, '
                    'missing id: ${c.lastDiagnostics!.dropped.missingInstanceId})',
                  ),
                ],
              ),
              li(
                attributes: {'data-testid': 'inventory-diag-resolved-transfer'},
                [
                  .text(
                    'Resolved from vault/postmaster: '
                    '${c.lastResolvedFromTransfer ?? '—'}',
                  ),
                ],
              ),
              li(
                attributes: {
                  'data-testid': 'inventory-diag-dropped-non-equipment',
                },
                [
                  .text(
                    'Dropped non-equipment: ${c.lastDroppedNonEquipment ?? '—'}',
                  ),
                ],
              ),
              li(
                attributes: {'data-testid': 'inventory-diag-stored-total'},
                [.text('Stored total: ${c.lastStoredTotal ?? '—'}')],
              ),
            ]),
            pre(
              classes: 'inventory-sync-diagnostics',
              attributes: {'data-testid': 'inventory-sync-diagnostics'},
              [.text(c.lastDiagnosticsFormatted ?? '')],
            ),
          ],
        ],
        if (showError)
          p(
            classes: 'inventory-sync-error',
            attributes: {'data-testid': 'inventory-sync-error'},
            [.text(error!)],
          ),
        if (syncing)
          p(
            attributes: {'data-testid': 'inventory-sync-busy'},
            [.text('Syncing inventory…')],
          )
        else
          button(
            classes: 'inventory-sync-now',
            attributes: {
              'type': 'button',
              'data-testid': 'inventory-sync-now',
              if (!c.canSync) 'disabled': 'true',
            },
            events: {
              if (c.canSync) 'click': (_) => c.syncNow(),
            },
            [.text('Sync now')],
          ),
        p(classes: 'settings-policy', [
          .text(
            'Full replace into local Drift (OPFS). Vault/postmaster use the same '
            'equipment-bucket resolution as Windows (catalog slot map on web). '
            'Soft suggestions never auto-apply. No CLIENT_SECRET.',
          ),
        ]),
      ],
    );
  }

  static String _summaryLine(InventorySyncController c) {
    if (c.isLoadingStatus) return 'Loading sync status…';
    if (c.lastFullSyncAt == null) {
      return 'No inventory synced yet for this account.';
    }
    return 'Local owned inventory is available for Catalog Owned, pickers, and equip gates.';
  }

  static String _freshnessLabel(InventorySyncController c) {
    if (c.lastFullSyncAt == null) return 'never synced';
    return c.isFresh ? 'fresh (< 60s)' : 'stale';
  }

  @css
  static List<StyleRule> get styles => [
        css('.inventory-sync-card', [
          css('.inventory-sync-meta').styles(
            margin: .zero,
            padding: .only(left: 1.25.rem),
            color: flapForegroundColor,
            fontSize: 0.9.rem,
          ),
          css('h3').styles(
            margin: .only(top: 0.75.rem, bottom: 0.35.rem),
            fontSize: 0.9.rem,
            fontWeight: .w600,
            color: flapForegroundColor,
          ),
          css('.inventory-sync-diagnostics').styles(
            width: 100.percent,
            maxWidth: 36.rem,
            margin: .only(top: 0.35.rem),
            padding: .all(0.6.rem),
            overflow: .auto,
            color: flapMutedColor,
            fontSize: 0.75.rem,
            fontFamily: .list([
              FontFamily('ui-monospace'),
              FontFamilies.monospace,
            ]),
            lineHeight: 1.35.em,
            backgroundColor: flapBackgroundColor,
          ),
          css('.inventory-sync-error').styles(
            color: Color('#c45c26'),
            fontSize: 0.9.rem,
          ),
          css('.inventory-sync-now').styles(
            margin: .only(top: 0.5.rem, bottom: 0.5.rem),
            padding: .symmetric(horizontal: 0.85.rem, vertical: 0.45.rem),
            border: .all(style: .solid, color: flapAccentColor, width: 1.px),
            radius: .all(.circular(0.px)),
            color: flapBackgroundColor,
            fontSize: 0.9.rem,
            fontWeight: .w600,
            backgroundColor: flapAccentColor,
            cursor: .pointer,
          ),
        ]),
      ];
}
