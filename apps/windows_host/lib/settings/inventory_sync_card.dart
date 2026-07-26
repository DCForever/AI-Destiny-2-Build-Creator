import 'package:flutter/material.dart';

import '../auth/windows_oauth_session.dart';
import 'inventory_sync_controller.dart';

/// Settings inventory sync card: Sync now + busy/error + meta (DART-025)
/// + last-sync diagnostics (DART-053 / GAP-INV-04).
class InventorySyncCard extends StatefulWidget {
  const InventorySyncCard({
    super.key,
    required this.controller,
    required this.session,
  });

  final InventorySyncController controller;
  final WindowsOAuthSession session;

  @override
  State<InventorySyncCard> createState() => _InventorySyncCardState();
}

class _InventorySyncCardState extends State<InventorySyncCard> {
  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSessionChanged);
    widget.controller.addListener(_onControllerChanged);
    // Load local meta after first frame (signed-in restore may already be done).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.controller.refreshStatus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant InventorySyncCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      oldWidget.session.removeListener(_onSessionChanged);
      widget.session.addListener(_onSessionChanged);
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionChanged);
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    widget.controller.refreshStatus();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final signedIn = c.isSignedIn;
    final syncing = c.isSyncing;
    final error = c.errorMessage;
    final showError = error != null &&
        (c.phase == InventorySyncPhase.error || error.isNotEmpty);

    return Card(
      key: const Key('inventory_sync_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory sync',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (!signedIn) ...[
              Text(
                'Sign in to sync owned inventory into the local database.',
                key: const Key('inventory_sync_signed_out'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ] else ...[
              Text(
                _summaryLine(c),
                key: const Key('inventory_sync_summary'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Items: ${c.itemCount?.toString() ?? '—'}',
                key: const Key('inventory_item_count'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Sync version: ${c.syncVersion?.toString() ?? '—'}',
                key: const Key('inventory_sync_version'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Last full sync: ${c.lastFullSyncAt ?? 'never'}',
                key: const Key('inventory_last_sync'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Freshness: ${_freshnessLabel(c)}',
                key: const Key('inventory_freshness'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (c.lastDiagnostics != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Last sync diagnostics',
                  key: const Key('inventory_sync_diagnostics_title'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Raw (Bungie): ${c.lastRawTotal ?? '—'}',
                  key: const Key('inventory_diag_raw'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Parsed: ${c.lastParsedTotal ?? '—'}',
                  key: const Key('inventory_diag_parsed'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Dropped: ${c.lastDroppedTotal ?? '—'} '
                  '(unknown: ${c.lastDiagnostics!.dropped.unknownBucket}, '
                  'missing id: ${c.lastDiagnostics!.dropped.missingInstanceId})',
                  key: const Key('inventory_diag_dropped'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Resolved from vault/postmaster: '
                  '${c.lastResolvedFromTransfer ?? '—'}',
                  key: const Key('inventory_diag_resolved_transfer'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Dropped non-equipment: ${c.lastDroppedNonEquipment ?? '—'}',
                  key: const Key('inventory_diag_dropped_non_equipment'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Stored total: ${c.lastStoredTotal ?? '—'}',
                  key: const Key('inventory_diag_stored_total'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                SelectableText(
                  c.lastDiagnosticsFormatted ?? '',
                  key: const Key('inventory_sync_diagnostics'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        height: 1.35,
                      ),
                ),
              ],
            ],
            if (showError) ...[
              const SizedBox(height: 8),
              Text(
                error,
                key: const Key('inventory_sync_error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            if (syncing)
              const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      key: Key('inventory_sync_busy'),
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Syncing inventory…',
                    key: Key('inventory_sync_busy_text'),
                  ),
                ],
              )
            else
              FilledButton.icon(
                key: const Key('inventory_sync_now'),
                onPressed: c.canSync ? () => c.syncNow() : null,
                icon: const Icon(Icons.cloud_download_outlined),
                label: const Text('Sync now'),
              ),
              // Soft post-sync better-kit banner (DART-067 / BR-OPT-004).
              // Confirm applies; Dismiss clears only — never auto-apply.
              if (c.loadingPostSyncSuggestions) ...[
                const SizedBox(height: 12),
                const Text(
                  'Checking for better armor kits…',
                  key: Key('inventory_post_sync_suggestions_loading'),
                ),
              ],
              if (c.postSyncSuggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  key: const Key('inventory_post_sync_better_kits_banner'),
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Better armor kits found',
                          key: const Key('inventory_post_sync_banner_title'),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Suggest-then-confirm only — nothing applied yet. Soft never auto-applies.',
                          key: const Key('inventory_post_sync_banner_policy'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        for (final s in c.postSyncSuggestions) ...[
                          Text(
                            s.armorSetName,
                            key: Key(
                              'inventory_post_sync_suggestion_${s.armorSetId}',
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              FilledButton(
                                key: Key(
                                  'inventory_post_sync_confirm_${s.armorSetId}',
                                ),
                                onPressed: () async {
                                  await c.confirmPostSyncSuggestion(
                                    s.armorSetId,
                                  );
                                },
                                child: const Text('Confirm'),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                key: Key(
                                  'inventory_post_sync_dismiss_${s.armorSetId}',
                                ),
                                onPressed: () =>
                                    c.dismissPostSyncSuggestion(s.armorSetId),
                                child: const Text('Dismiss'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
          ],
        ),
        ),
      ),
    );
  }

  static String _summaryLine(InventorySyncController c) {
    if (c.isLoadingStatus) return 'Loading sync status…';
    if (c.lastFullSyncAt == null) {
      return 'No inventory synced yet for this account.';
    }
    return 'Local owned inventory is available for pickers and equip gates.';
  }

  static String _freshnessLabel(InventorySyncController c) {
    if (c.lastFullSyncAt == null) return 'never synced';
    return c.isFresh ? 'fresh (< 60s)' : 'stale';
  }
}
