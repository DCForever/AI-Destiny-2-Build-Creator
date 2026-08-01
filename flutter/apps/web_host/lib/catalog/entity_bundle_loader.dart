/// Load prebuilt entity bundles for the Jaspr web host (DART-044 / DART-059).
///
/// Production channel is **hybrid**: optional CDN first, then ship-in-app
/// `/entities/prod/bundle.json`, then legacy prebuilt fallback. No raw rebuild;
/// no Next.js manifest API.
library;

import 'dart:convert';

import 'package:destiny2_manifest/destiny2_manifest.dart';

/// Default same-origin channel pointer (DART-059).
const kDefaultEntityChannelUrl = kDefaultEntityBundleChannelUrl;

/// Default production ship-in-app bundle path (DART-059).
const kDefaultProdBundleUrl = kDefaultProdEntityBundleUrl;

/// Legacy DART-044 MVP fixture path.
const kDefaultPrebuiltBundleUrl = kLegacyPrebuiltEntityBundleUrl;

/// Injectable text fetch (tests inject a memory string; browser uses fetch).
typedef EntityBundleTextFetcher = Future<String> Function(String url);

/// Status of prebuilt entity bundle load for Catalog UI.
enum EntityBundleLoadPhase {
  idle,
  loading,
  ready,
  empty,
  error,
}

class EntityBundleLoadStatus {
  const EntityBundleLoadStatus({
    required this.phase,
    this.version,
    this.itemCount = 0,
    this.error,
    this.emptyReason = CatalogEmptyReason.none,
    this.loadSource,
    this.channelId,
    this.distribution,
  });

  final EntityBundleLoadPhase phase;
  final String? version;
  final int itemCount;
  final String? error;
  final CatalogEmptyReason emptyReason;

  /// Which candidate URL supplied the body (when ready/empty).
  final EntityBundleLoadSource? loadSource;

  /// Channel id from pointer when available.
  final String? channelId;

  /// Wire distribution label when available.
  final String? distribution;

  bool get isReady => phase == EntityBundleLoadPhase.ready;
  bool get isLoading => phase == EntityBundleLoadPhase.loading;
  bool get hasError => phase == EntityBundleLoadPhase.error;

  String get summaryLine {
    switch (phase) {
      case EntityBundleLoadPhase.idle:
        return 'Entities: not loaded';
      case EntityBundleLoadPhase.loading:
        return 'Entities: loading production channel bundle…';
      case EntityBundleLoadPhase.ready:
        final src = loadSource != null
            ? entityBundleLoadSourceWire(loadSource!)
            : 'prebuilt';
        final ch = channelId != null ? ' channel=$channelId' : '';
        return 'Entities: $version ($itemCount items, $src$ch — no raw rebuild)';
      case EntityBundleLoadPhase.empty:
        return 'Entities: empty channel bundle'
            '${version != null ? ' ($version)' : ''}';
      case EntityBundleLoadPhase.error:
        return 'Entities: failed to load channel bundle'
            '${error != null ? ' — $error' : ''}';
    }
  }

  static const loading = EntityBundleLoadStatus(
    phase: EntityBundleLoadPhase.loading,
  );

  static const idle = EntityBundleLoadStatus(
    phase: EntityBundleLoadPhase.idle,
  );
}

/// Loads a prebuilt [EntityBundleDocument] via the production channel (DART-059).
///
/// Resolution order (hybrid default):
/// 1. Fetch [channelUrl] when set (or use [injectedChannel])
/// 2. Try [resolveEntityBundleCandidates] in order (CDN → ship-in-app → legacy)
/// 3. Parse first successful body into [OfflineCatalog]
class WebEntityBundleLoader {
  WebEntityBundleLoader({
    required this.fetcher,
    this.channelUrl = kDefaultEntityChannelUrl,
    this.injectedChannel,
    this.bundleUrl,
    this.includeLegacyPrebuiltFallback = true,
  });

  final EntityBundleTextFetcher fetcher;

  /// Same-origin (or absolute) URL for `channel.json`. Empty skips fetch.
  final String channelUrl;

  /// When set, skips channel fetch and uses this pointer.
  final EntityBundleChannel? injectedChannel;

  /// When set, bypasses channel resolution and loads this single URL
  /// (tests / emergency override). Source reported as ship-in-app.
  final String? bundleUrl;

  final bool includeLegacyPrebuiltFallback;

  EntityBundleDocument? document;
  OfflineCatalog? catalog;
  EntityBundleChannel? channel;
  EntityBundleLoadStatus status = EntityBundleLoadStatus.idle;

  /// Fetch channel (if needed) + parse prebuilt JSON → [OfflineCatalog].
  Future<EntityBundleLoadStatus> load() async {
    status = EntityBundleLoadStatus.loading;
    try {
      final resolvedChannel = await _resolveChannel();
      channel = resolvedChannel;

      final candidates = bundleUrl != null && bundleUrl!.trim().isNotEmpty
          ? [
              EntityBundleUrlCandidate(
                url: bundleUrl!.trim(),
                source: EntityBundleLoadSource.shipInApp,
              ),
            ]
          : resolveEntityBundleCandidates(
              resolvedChannel,
              includeLegacyPrebuiltFallback: includeLegacyPrebuiltFallback,
            );
      assertNoNextManifestEntityUrls(candidates);

      Object? lastError;
      for (final candidate in candidates) {
        try {
          final text = await fetcher(candidate.url);
          final doc = EntityBundleDocument.parse(text);
          document = doc;
          catalog = offlineCatalogFromBundle(doc);
          final result = await catalog!.loadBase();
          final distWire =
              entityBundleDistributionWire(resolvedChannel.distribution);
          if (result.error != null) {
            status = EntityBundleLoadStatus(
              phase: EntityBundleLoadPhase.error,
              error: result.error,
              channelId: resolvedChannel.channelId,
              distribution: distWire,
              loadSource: candidate.source,
            );
            return status;
          }
          if (result.items.isEmpty) {
            status = EntityBundleLoadStatus(
              phase: EntityBundleLoadPhase.empty,
              version: result.version,
              emptyReason: result.emptyReason,
              channelId: resolvedChannel.channelId,
              distribution: distWire,
              loadSource: candidate.source,
            );
            return status;
          }
          status = EntityBundleLoadStatus(
            phase: EntityBundleLoadPhase.ready,
            version: result.version,
            itemCount: result.items.length,
            channelId: resolvedChannel.channelId,
            distribution: distWire,
            loadSource: candidate.source,
          );
          return status;
        } catch (e) {
          lastError = e;
          // try next candidate
        }
      }

      status = EntityBundleLoadStatus(
        phase: EntityBundleLoadPhase.error,
        error: lastError?.toString() ?? 'No entity bundle candidates succeeded',
        channelId: resolvedChannel.channelId,
        distribution:
            entityBundleDistributionWire(resolvedChannel.distribution),
      );
      return status;
    } catch (e) {
      status = EntityBundleLoadStatus(
        phase: EntityBundleLoadPhase.error,
        error: e.toString(),
      );
      return status;
    }
  }

  Future<EntityBundleChannel> _resolveChannel() async {
    if (injectedChannel != null) return injectedChannel!;
    final url = channelUrl.trim();
    if (url.isEmpty) return EntityBundleChannel.defaultProd;
    try {
      final text = await fetcher(url);
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        throw EntityBundleChannelException('channel root must be a JSON object');
      }
      return EntityBundleChannel.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      // Offline or missing pointer → built-in prod defaults.
      return EntityBundleChannel.defaultProd;
    }
  }

  /// Browse using last loaded catalog (empty if not ready).
  List<CatalogItem> browse([
    CatalogClientFilters filters = const CatalogClientFilters(),
  ]) {
    final c = catalog;
    if (c == null) return const [];
    return c.browse(filters);
  }
}
