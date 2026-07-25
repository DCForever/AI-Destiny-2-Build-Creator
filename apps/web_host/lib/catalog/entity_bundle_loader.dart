/// Load prebuilt entity bundles for the Jaspr web host (DART-044).
library;

import 'package:destiny2_manifest/destiny2_manifest.dart';

/// Default same-origin path for the ship-in-app fixture bundle.
const kDefaultPrebuiltBundleUrl = '/entities/prebuilt/bundle.json';

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
  });

  final EntityBundleLoadPhase phase;
  final String? version;
  final int itemCount;
  final String? error;
  final CatalogEmptyReason emptyReason;

  bool get isReady => phase == EntityBundleLoadPhase.ready;
  bool get isLoading => phase == EntityBundleLoadPhase.loading;
  bool get hasError => phase == EntityBundleLoadPhase.error;

  String get summaryLine {
    switch (phase) {
      case EntityBundleLoadPhase.idle:
        return 'Entities: not loaded';
      case EntityBundleLoadPhase.loading:
        return 'Entities: loading prebuilt bundle…';
      case EntityBundleLoadPhase.ready:
        return 'Entities: $version ($itemCount items, prebuilt — no raw rebuild)';
      case EntityBundleLoadPhase.empty:
        return 'Entities: empty prebuilt bundle'
            '${version != null ? ' ($version)' : ''}';
      case EntityBundleLoadPhase.error:
        return 'Entities: failed to load prebuilt bundle'
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

/// Loads a prebuilt [EntityBundleDocument] (no raw manifest rebuild).
class WebEntityBundleLoader {
  WebEntityBundleLoader({
    required this.fetcher,
    this.bundleUrl = kDefaultPrebuiltBundleUrl,
  });

  final EntityBundleTextFetcher fetcher;
  final String bundleUrl;

  EntityBundleDocument? document;
  OfflineCatalog? catalog;
  EntityBundleLoadStatus status = EntityBundleLoadStatus.idle;

  /// Fetch + parse prebuilt JSON → [OfflineCatalog] (load-only).
  Future<EntityBundleLoadStatus> load() async {
    status = EntityBundleLoadStatus.loading;
    try {
      final text = await fetcher(bundleUrl);
      final doc = EntityBundleDocument.parse(text);
      document = doc;
      catalog = offlineCatalogFromBundle(doc);
      final result = await catalog!.loadBase();
      if (result.error != null) {
        status = EntityBundleLoadStatus(
          phase: EntityBundleLoadPhase.error,
          error: result.error,
        );
        return status;
      }
      if (result.items.isEmpty) {
        status = EntityBundleLoadStatus(
          phase: EntityBundleLoadPhase.empty,
          version: result.version,
          emptyReason: result.emptyReason,
        );
        return status;
      }
      status = EntityBundleLoadStatus(
        phase: EntityBundleLoadPhase.ready,
        version: result.version,
        itemCount: result.items.length,
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

  /// Browse using last loaded catalog (empty if not ready).
  List<CatalogItem> browse([
    CatalogClientFilters filters = const CatalogClientFilters(),
  ]) {
    final c = catalog;
    if (c == null) return const [];
    return c.browse(filters);
  }
}
