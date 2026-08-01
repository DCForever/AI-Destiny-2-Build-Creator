import 'package:destiny2_storage/destiny2_storage.dart';

import 'isolate_rebuild.dart';
import 'manifest_service.dart';
import 'types/services.dart';

/// Settings-level API for Windows host (DART-018).
///
/// Exposes **status / isStale / refresh** without UI chrome. Flutter Settings
/// card (DART-019) will call this in-process.
abstract class ManifestRefreshApi {
  Future<ManifestStatus> status();

  Future<bool> isStale();

  /// Download (partial or full) then rebuild MVP entity stores.
  ///
  /// When [rebuildInIsolate] is true (default), extract runs via
  /// [rebuildEntityCacheInIsolate].
  Future<ManifestStatus> refresh({
    bool forceFullDownload = false,
    bool rebuildInIsolate = true,
  });
}

/// Windows-oriented implementation of [ManifestRefreshApi].
class WindowsManifestRefresh implements ManifestRefreshApi {
  WindowsManifestRefresh({
    required this.storageRoot,
    required String? apiKey,
    ManifestHttpGet? httpGet,
    BungieManifestService? service,
    List<String>? tablesToDownload,
  }) : service = service ??
            BungieManifestService(
              storageRoot: storageRoot,
              apiKey: apiKey,
              httpGet: httpGet,
              tablesToDownload: tablesToDownload,
            );

  final StorageRoot storageRoot;
  final BungieManifestService service;

  @override
  Future<ManifestStatus> status() => service.getStatus();

  @override
  Future<bool> isStale() async => (await status()).isStale;

  @override
  Future<ManifestStatus> refresh({
    bool forceFullDownload = false,
    bool rebuildInIsolate = true,
  }) async {
    await storageRoot.ensureLayout();
    final version = await service.ensureCurrent(
      forceFullDownload: forceFullDownload,
    );

    if (rebuildInIsolate) {
      await rebuildEntityCacheInIsolate(
        basePath: storageRoot.basePath,
        version: version,
      );
    } else {
      await rebuildEntityCacheLocal(
        basePath: storageRoot.basePath,
        version: version,
      );
    }

    return service.getStatus();
  }
}
