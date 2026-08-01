/// Production entity-bundle distribution channel (DART-059 / GAP-WEB-02).
///
/// Hybrid: ship-in-app primary for offline-after-install; optional CDN first
/// when configured; legacy prebuilt path as last-resort fallback.
library;

/// How the active channel is distributed.
enum EntityBundleDistribution {
  /// Same-origin static assets only.
  shipInApp,

  /// Remote CDN URL only (not recommended for offline-after-install alone).
  cdn,

  /// Try CDN when set, then ship-in-app (production default).
  hybrid,
}

/// Which candidate URL actually supplied the bundle body.
enum EntityBundleLoadSource {
  /// Optional CDN URL succeeded.
  cdn,

  /// Same-origin production ship-in-app path succeeded.
  shipInApp,

  /// Legacy DART-044 demo path `/entities/prebuilt/bundle.json`.
  legacyPrebuilt,
}

/// Default same-origin channel pointer (versioning + paths).
const String kDefaultEntityBundleChannelUrl = '/entities/channel.json';

/// Default production ship-in-app bundle body path.
const String kDefaultProdEntityBundleUrl = '/entities/prod/bundle.json';

/// Legacy DART-044 MVP fixture path (dev/demo fallback only).
const String kLegacyPrebuiltEntityBundleUrl = '/entities/prebuilt/bundle.json';

/// Production channel id used by default assets.
const String kDefaultEntityBundleChannelId = 'prod';

/// Thrown when channel JSON is missing required fields or invalid.
class EntityBundleChannelException implements Exception {
  EntityBundleChannelException(this.message);
  final String message;

  @override
  String toString() => 'EntityBundleChannelException: $message';
}

/// Versioned pointer for web entity-bundle distribution (DART-059).
///
/// Typically served at [kDefaultEntityBundleChannelUrl].
class EntityBundleChannel {
  const EntityBundleChannel({
    required this.schemaVersion,
    required this.channelId,
    required this.bundleVersion,
    required this.distribution,
    required this.shipInAppPath,
    this.cdnUrl,
    this.notes,
  });

  /// Pointer schema version (currently `1`).
  final int schemaVersion;

  /// Logical channel name (e.g. `prod`).
  final String channelId;

  /// Active bundle version (should match or describe [EntityBundleDocument] version).
  final String bundleVersion;

  /// Distribution strategy for this channel.
  final EntityBundleDistribution distribution;

  /// Same-origin path to the ship-in-app bundle JSON.
  final String shipInAppPath;

  /// Optional absolute CDN URL for hot updates (hybrid / cdn).
  final String? cdnUrl;

  /// Operator notes (non-functional).
  final String? notes;

  /// Whether a non-empty CDN URL is configured.
  bool get hasCdn => cdnUrl != null && cdnUrl!.trim().isNotEmpty;

  /// Default production hybrid channel (repo sample).
  static const EntityBundleChannel defaultProd = EntityBundleChannel(
    schemaVersion: 1,
    channelId: kDefaultEntityBundleChannelId,
    bundleVersion: 'entity-bundle-prod-1',
    distribution: EntityBundleDistribution.hybrid,
    shipInAppPath: kDefaultProdEntityBundleUrl,
    cdnUrl: null,
    notes:
        'Ship-in-app primary for offline after install; set cdnUrl for hybrid hot update',
  );

  factory EntityBundleChannel.fromJson(Map<String, dynamic> json) {
    final schemaVersion = (json['schemaVersion'] as num?)?.toInt() ?? 1;
    final channelId = (json['channelId'] as String?)?.trim() ?? '';
    if (channelId.isEmpty) {
      throw EntityBundleChannelException('channelId is required');
    }
    final bundleVersion = (json['bundleVersion'] as String?)?.trim() ??
        (json['manifestVersion'] as String?)?.trim() ??
        '';
    if (bundleVersion.isEmpty) {
      throw EntityBundleChannelException('bundleVersion is required');
    }
    final shipInAppPath = (json['shipInAppPath'] as String?)?.trim() ?? '';
    if (shipInAppPath.isEmpty) {
      throw EntityBundleChannelException('shipInAppPath is required');
    }
    final distribution = parseEntityBundleDistribution(
      json['distribution'] as String?,
    );
    final rawCdn = json['cdnUrl'] as String?;
    final cdnUrl = rawCdn?.trim();
    return EntityBundleChannel(
      schemaVersion: schemaVersion,
      channelId: channelId,
      bundleVersion: bundleVersion,
      distribution: distribution,
      shipInAppPath: shipInAppPath,
      cdnUrl: (cdnUrl == null || cdnUrl.isEmpty) ? null : cdnUrl,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'channelId': channelId,
        'bundleVersion': bundleVersion,
        'distribution': entityBundleDistributionWire(distribution),
        'shipInAppPath': shipInAppPath,
        if (cdnUrl != null) 'cdnUrl': cdnUrl,
        if (notes != null) 'notes': notes,
      };
}

/// Parse distribution wire string (`ship-in-app` | `cdn` | `hybrid`).
EntityBundleDistribution parseEntityBundleDistribution(String? raw) {
  switch ((raw ?? 'hybrid').trim().toLowerCase()) {
    case 'ship-in-app':
    case 'ship_in_app':
    case 'shipinapp':
      return EntityBundleDistribution.shipInApp;
    case 'cdn':
      return EntityBundleDistribution.cdn;
    case 'hybrid':
    case '':
      return EntityBundleDistribution.hybrid;
    default:
      throw EntityBundleChannelException(
        'Unknown distribution "$raw" (expected ship-in-app | cdn | hybrid)',
      );
  }
}

String entityBundleDistributionWire(EntityBundleDistribution d) {
  switch (d) {
    case EntityBundleDistribution.shipInApp:
      return 'ship-in-app';
    case EntityBundleDistribution.cdn:
      return 'cdn';
    case EntityBundleDistribution.hybrid:
      return 'hybrid';
  }
}

String entityBundleLoadSourceWire(EntityBundleLoadSource s) {
  switch (s) {
    case EntityBundleLoadSource.cdn:
      return 'cdn';
    case EntityBundleLoadSource.shipInApp:
      return 'ship-in-app';
    case EntityBundleLoadSource.legacyPrebuilt:
      return 'legacy-prebuilt';
  }
}

/// One ordered fetch candidate for channel resolution.
class EntityBundleUrlCandidate {
  const EntityBundleUrlCandidate({
    required this.url,
    required this.source,
  });

  final String url;
  final EntityBundleLoadSource source;
}

/// Resolve ordered URLs to try for a channel (CDN → ship-in-app → legacy).
///
/// Never emits Next.js `/api` manifest paths — static entities or CDN only.
List<EntityBundleUrlCandidate> resolveEntityBundleCandidates(
  EntityBundleChannel channel, {
  bool includeLegacyPrebuiltFallback = true,
  String legacyPrebuiltUrl = kLegacyPrebuiltEntityBundleUrl,
}) {
  final out = <EntityBundleUrlCandidate>[];
  final seen = <String>{};

  void add(String url, EntityBundleLoadSource source) {
    final trimmed = url.trim();
    if (trimmed.isEmpty || seen.contains(trimmed)) return;
    seen.add(trimmed);
    out.add(EntityBundleUrlCandidate(url: trimmed, source: source));
  }

  switch (channel.distribution) {
    case EntityBundleDistribution.cdn:
      if (channel.hasCdn) {
        add(channel.cdnUrl!, EntityBundleLoadSource.cdn);
      }
      // Still fall back so offline install is not hard-broken if CDN-only misconfigured.
      add(channel.shipInAppPath, EntityBundleLoadSource.shipInApp);
      break;
    case EntityBundleDistribution.shipInApp:
      add(channel.shipInAppPath, EntityBundleLoadSource.shipInApp);
      break;
    case EntityBundleDistribution.hybrid:
      if (channel.hasCdn) {
        add(channel.cdnUrl!, EntityBundleLoadSource.cdn);
      }
      add(channel.shipInAppPath, EntityBundleLoadSource.shipInApp);
      break;
  }

  if (includeLegacyPrebuiltFallback) {
    add(legacyPrebuiltUrl, EntityBundleLoadSource.legacyPrebuilt);
  }

  if (out.isEmpty) {
    throw EntityBundleChannelException(
      'No entity bundle URL candidates for channel "${channel.channelId}"',
    );
  }
  return out;
}

/// True when [url] looks like a Next.js manifest API path (forbidden for web entities).
bool isForbiddenNextManifestEntityUrl(String url) {
  final lower = url.trim().toLowerCase();
  if (lower.contains('/api/manifest')) return true;
  if (lower.contains('/api/entities')) return true;
  if (lower.contains('/api/catalog/manifest')) return true;
  return false;
}

/// Validate that no candidate uses a forbidden Next manifest API path.
void assertNoNextManifestEntityUrls(Iterable<EntityBundleUrlCandidate> candidates) {
  for (final c in candidates) {
    if (isForbiddenNextManifestEntityUrl(c.url)) {
      throw EntityBundleChannelException(
        'Entity bundle URL must not use Next manifest API: ${c.url}',
      );
    }
  }
}
