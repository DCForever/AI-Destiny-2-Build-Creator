import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';

import '../host_bootstrap.dart';
import '../surface_matrix.dart';

/// Settings minimum: storage/DB path + manifest status (DART-040).
///
/// No OAuth secrets / CLIENT_SECRET. Mobile sign-in deferred.
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.services,
    this.themeMode = ThemeMode.system,
    this.onThemeModeChanged,
  });

  final MobileAppServices services;

  /// Appearance preference (Cold Graphite dark / Paper Ledger light).
  final ThemeMode themeMode;

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

  @override
  void initState() {
    super.initState();
    _loadStatus();
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

  /// Download/partial update + rebuild entity stores (needs BUNGIE_API_KEY).
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
      setState(() {
        _status = status;
        _loading = false;
        _error = null;
        _refreshing = false;
        _refreshMessage = 'Manifest refreshed.';
      });
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
      key: const Key('settings_page'),
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
            'Local storage',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'SQLite: ${widget.services.storageRoot.appDbPath}',
            key: const Key('db_path'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Account: local library (mobile OAuth deferred). '
            'No CLIENT_SECRET in this client.',
            key: const Key('settings_account_note'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          Text(
            'Manifest status',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Entity stores power offline definitions. Inventory sync is not '
            'available on mobile; use Refresh manifest (BUNGIE_API_KEY) to '
            'populate the entity cache.',
            key: const Key('manifest_section_help'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
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
                    'Entity cache is empty or missing. Use Refresh manifest '
                    'below to download tables and build entity stores '
                    '(GAP-INV-06).',
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
                    'Downloading manifest and rebuilding entity stores…',
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
          const SizedBox(height: 24),
          Text(
            'Mobile surface matrix',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'DART-057 product matrix. Equip/catalog/DIM are N/A on phone '
            '(use Windows/Jaspr). Soft never auto-applies. No CLIENT_SECRET.',
            key: const Key('surface_matrix_caption'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Card(
            key: const Key('surface_matrix_card'),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  for (final entry in kMobileSurfaceMatrix)
                    ListTile(
                      key: Key('surface_matrix_row_${entry.key}'),
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: Text('${entry.key} · ${entry.status.label}'),
                      subtitle: Text(entry.note),
                    ),
                ],
              ),
            ),
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
