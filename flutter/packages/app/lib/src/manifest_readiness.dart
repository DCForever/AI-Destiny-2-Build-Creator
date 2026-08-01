/// Manifest panel readiness badge (Next ManifestCard parity — DART-068 / GAP-UI-SETTINGS-01).

/// Readiness for Settings Manifest chrome.
enum ManifestReadiness {
  ready,
  stale,
  notDownloaded,
}

/// Compute readiness from cached entity presence + stale flag.
///
/// - [hasEntityCache] false → notDownloaded
/// - [isStale] true → stale
/// - else ready
ManifestReadiness manifestReadiness({
  required bool hasEntityCache,
  required bool isStale,
}) {
  if (!hasEntityCache) return ManifestReadiness.notDownloaded;
  if (isStale) return ManifestReadiness.stale;
  return ManifestReadiness.ready;
}

/// Badge label: READY / STALE / NOT DOWNLOADED.
String manifestReadinessLabel(ManifestReadiness readiness) {
  switch (readiness) {
    case ManifestReadiness.ready:
      return 'READY';
    case ManifestReadiness.stale:
      return 'STALE';
    case ManifestReadiness.notDownloaded:
      return 'NOT DOWNLOADED';
  }
}
