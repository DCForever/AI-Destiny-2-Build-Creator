import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';

import '../host_bootstrap.dart';
import 'inventory_sync_card.dart';
import 'inventory_sync_controller.dart';
import 'legacy_db_import_card.dart';
import 'legacy_db_import_controller.dart';
import 'oauth_account_card.dart';

/// Settings: account (OAuth) + inventory sync + legacy DB import + manifest (DART-019/023/025/048).
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.services,
    this.legacyImportController,
    this.themeMode = ThemeMode.system,
    this.onThemeModeChanged,
  });

  final AppServices services;

  /// Optional injectable importer controller (tests).
  final LegacyDbImportController? legacyImportController;

  /// Appearance preference (Cold Graphite dark / Paper Ledger light).
  final ThemeMode themeMode;

  /// When non-null, shows [FlapThemeModeTile] to cycle appearance.
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  ManifestStatus? _status;
  Object? _error;
  bool _loading = true;
  bool _refreshing = false;
  Object? _refreshError;
  String? _refreshMessage;
  late final LegacyDbImportController _legacyImport;
  var _ownsLegacyImport = false;

  @override
  void initState() {
    super.initState();
    if (widget.legacyImportController != null) {
      _legacyImport = widget.legacyImportController!;
    } else {
      _legacyImport = LegacyDbImportController(
        storageRoot: widget.services.storageRoot,
      );
      _ownsLegacyImport = true;
    }
    _loadStatus();
  }

  @override
  void dispose() {
    if (_ownsLegacyImport) {
      _legacyImport.dispose();
    }
    super.dispose();
  }

  /// True when entity stores are missing or report zero entities (GAP-INV-06).
  static bool _isEntityCacheEmpty(ManifestStatus status) {
    final meta = status.entityCache;
    if (meta == null) return true;
    final total = meta.counts.values.fold<int>(0, (a, b) => a + b);
    return total == 0;
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = await widget.services.manifestRefresh.status();
      if (!mounted) return;
      setState(() {
        _status = status;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  /// Download/partial update + rebuild entity stores (DART-018). Inventory sync
  /// alone cannot populate entity definitions (GAP-INV-06).
  Future<void> _refreshManifest() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _refreshError = null;
      _refreshMessage = null;
    });
    try {
      final status = await widget.services.manifestRefresh.refresh();
      if (!mounted) return;

      var message = 'Manifest refreshed.';
      if (widget.services.inventorySync.isSignedIn) {
        await widget.services.inventorySync.syncNow();
        if (!mounted) return;
        final syncError = widget.services.inventorySync.errorMessage;
        if (syncError != null &&
            widget.services.inventorySync.phase == InventorySyncPhase.error) {
          message =
              'Manifest refreshed. Inventory sync failed: $syncError';
        } else {
          final count = widget.services.inventorySync.itemCount;
          message = count == null
              ? 'Manifest refreshed. Inventory synced.'
              : 'Manifest refreshed. Inventory synced ($count items).';
        }
      }

      if (!mounted) return;
      setState(() {
        _status = status;
        _loading = false;
        _error = null;
        _refreshing = false;
        _refreshMessage = message;
      });

      // Reload entity-backed catalog after UI settles (Catalog also reloads on visit).
      widget.services.offlineCatalog.loadBase().then(
        (_) {},
        onError: (_, __) {},
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _refreshError = e;
        _refreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading || _refreshing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.onThemeModeChanged != null) ...[
            Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: FlapThemeModeTile(
                mode: widget.themeMode,
                onChanged: widget.onThemeModeChanged!,
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'Account',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          OAuthAccountCard(
            key: const Key('settings_oauth_card'),
            session: widget.services.oauthSession,
          ),
          const SizedBox(height: 24),
          Text(
            'Inventory',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          InventorySyncCard(
            key: const Key('settings_inventory_sync_card'),
            controller: widget.services.inventorySync,
            session: widget.services.oauthSession,
          ),
          const SizedBox(height: 24),
          Text(
            'Data migration',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          LegacyDbImportCard(
            key: const Key('settings_legacy_db_import_card'),
            controller: _legacyImport,
          ),
          const SizedBox(height: 24),
          Text(
            'Manifest status',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Bungie manifest tables and derived entity stores. Required for '
            'catalog, Owned joins, and composition. Inventory sync alone does '
            'not build entity definitions — use Refresh manifest (needs '
            'BUNGIE_API_KEY). When signed in, refresh also syncs inventory.',
            key: const Key('manifest_section_help'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Local SQLite: ${widget.services.storageRoot.appDbPath}',
            key: const Key('db_path'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(key: Key('status_loading')),
              ),
            )
          else if (_error != null)
            Card(
              key: const Key('status_error'),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load manifest status: $_error',
                  key: const Key('status_error_text'),
                ),
              ),
            )
          else if (_status != null) ...[
            if (_isEntityCacheEmpty(_status!)) ...[
              Card(
                key: const Key('entity_cache_empty_warning'),
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Entity cache is empty or missing. Catalog Owned joins '
                    'inventory counts onto entity definitions — empty Owned is '
                    'not solely an inventory sync problem. Use Refresh manifest '
                    'below so entity stores are built (GAP-INV-06).',
                    key: const Key('entity_cache_empty_warning_text'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _ManifestStatusCard(status: _status!),
          ],
          if (_refreshing) ...[
            const SizedBox(height: 12),
            Row(
              key: const Key('manifest_refresh_progress'),
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Downloading manifest and rebuilding entity stores… '
                    'this can take a few minutes',
                    key: const Key('manifest_refresh_progress_text'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          if (_refreshError != null) ...[
            const SizedBox(height: 12),
            Card(
              key: const Key('manifest_refresh_error'),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Manifest refresh failed: $_refreshError',
                  key: const Key('manifest_refresh_error_text'),
                ),
              ),
            ),
          ],
          if (_refreshMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _refreshMessage!,
              key: const Key('manifest_refresh_message'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: const Key('refresh_manifest'),
                onPressed: busy ? null : _refreshManifest,
                icon: const Icon(Icons.cloud_download),
                label: Text(_refreshing ? 'Refreshing…' : 'Refresh manifest'),
              ),
              OutlinedButton.icon(
                key: const Key('reload_status'),
                onPressed: busy ? null : _loadStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('Reload status'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManifestStatusCard extends StatelessWidget {
  const _ManifestStatusCard({required this.status});

  final ManifestStatus status;

  @override
  Widget build(BuildContext context) {
    final cached = status.cachedVersion ?? 'none';
    final remote = status.remoteVersion ?? 'unknown';
    final staleLabel = status.isStale ? 'stale' : 'up to date';
    final entitySummary = _entitySummary(status);

    return Card(
      key: const Key('manifest_status_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Cached version', cached, 'cached_version'),
            _row('Remote version', remote, 'remote_version'),
            _row('Status', staleLabel, 'stale_status'),
            _row('Entity cache', entitySummary, 'entity_cache'),
          ],
        ),
      ),
    );
  }

  static String _entitySummary(ManifestStatus status) {
    final meta = status.entityCache;
    if (meta == null) return 'none';
    final total = meta.counts.values.fold<int>(0, (a, b) => a + b);
    return '${meta.manifestVersion} · $total entities · built ${meta.builtAt}';
  }

  Widget _row(String label, String value, String keyName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, key: Key(keyName)),
          ),
        ],
      ),
    );
  }
}
