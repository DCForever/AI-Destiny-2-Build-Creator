import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:flutter/material.dart';

import '../host_bootstrap.dart';

/// Settings minimum: storage/DB path + manifest status (DART-040).
///
/// No OAuth secrets / CLIENT_SECRET. Mobile sign-in deferred.
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.services,
  });

  final MobileAppServices services;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  ManifestStatus? _status;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('settings_page'),
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
          else if (_status != null)
            _ManifestStatusCard(status: _status!),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('reload_status'),
              onPressed: _loading ? null : _loadStatus,
              icon: const Icon(Icons.refresh),
              label: const Text('Reload status'),
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
