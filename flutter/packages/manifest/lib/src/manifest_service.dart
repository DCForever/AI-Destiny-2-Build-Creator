import 'dart:convert';

import 'package:destiny2_storage/destiny2_storage.dart';

import 'http_client.dart';
import 'io/text_file.dart' as text_file;
import 'types/services.dart';
import 'types/stores.dart';

const kManifestUrl = 'https://www.bungie.net/Platform/Destiny2/Manifest/';
const kBungieBaseUrl = 'https://www.bungie.net';

const kMissingApiKeyMessage =
    'BUNGIE_API_KEY is required to download manifest data';

/// Stage 1: versioned download of raw manifest tables under [StorageRoot].
///
/// Port of product `BungieManifestService` for Windows / pure Dart hosts
/// (DART-018). Paths use [StorageRoot], not repo `.cache`.
/// File IO is conditional — web uses prebuilt entity bundles (DART-044).
class BungieManifestService {
  BungieManifestService({
    required this.storageRoot,
    required this.apiKey,
    ManifestHttpGet? httpGet,
    this.cacheRawTables = true,
    List<String>? tablesToDownload,
  })  : httpGet = httpGet ?? createUtf8ManifestHttpGet(),
        tablesToDownload = tablesToDownload ?? downloadRawTables;

  final StorageRoot storageRoot;

  /// Public Bungie API key only — never a client secret.
  final String? apiKey;

  final ManifestHttpGet httpGet;

  /// In-process memo of parsed raw tables.
  final bool cacheRawTables;

  /// Tables downloaded by [ensureCurrent] (default: product [downloadRawTables]).
  final List<String> tablesToDownload;

  final Map<String, Future<RawTable>> _rawTableCache = {};

  /// Settings-friendly status: cached / remote / stale / entity meta.
  Future<ManifestStatus> getStatus() async {
    final cachedVersion = await readCurrentVersion();
    final remoteVersion = await fetchRemoteVersion();
    final entityCache = cachedVersion == null
        ? null
        : await readEntityCacheMeta(cachedVersion);

    return ManifestStatus(
      cachedVersion: cachedVersion,
      remoteVersion: remoteVersion,
      isStale: computeIsStale(cachedVersion, remoteVersion),
      entityCache: entityCache,
    );
  }

  /// Downloads tables for the latest remote version.
  Future<String> ensureCurrent({bool forceFullDownload = false}) async {
    final key = apiKey;
    if (key == null || key.isEmpty) {
      throw ManifestServiceException(kMissingApiKeyMessage);
    }

    final metadata = await fetchManifestMetadata(key);
    await downloadTables(
      metadata,
      forceFullDownload: forceFullDownload,
    );
    await writeCurrentVersion(metadata.version);
    _rawTableCache.clear();
    return metadata.version;
  }

  /// Loads one raw table for a downloaded [version] from disk.
  Future<RawTable> loadRawTable(String version, String table) async {
    final cacheKey = '$version::$table';
    if (cacheRawTables) {
      final hit = _rawTableCache[cacheKey];
      if (hit != null) return hit;
    }

    final loadPromise = _readAndParseRawTable(version, table);
    if (cacheRawTables) {
      _rawTableCache[cacheKey] = loadPromise;
      loadPromise.then<void>(
        (_) {},
        onError: (Object _, StackTrace __) {
          if (identical(_rawTableCache[cacheKey], loadPromise)) {
            _rawTableCache.remove(cacheKey);
          }
        },
      );
    }
    return loadPromise;
  }

  Future<RawTable> _readAndParseRawTable(String version, String table) async {
    final filePath = storageRoot.rawTablePath(version, table);
    final content = await text_file.readTextFile(filePath);
    if (content == null) {
      throw ManifestServiceException(
        'Raw table "$table" for version "$version" is not on disk. '
        'Call ensureCurrent() to download manifest tables.',
      );
    }
    final parsed = jsonDecode(content);
    if (parsed is! Map) {
      throw ManifestServiceException(
        'Raw table "$table" for version "$version" is not a valid JSON object.',
      );
    }
    // Prefer the decoded map as-is — Map.from on DestinyInventoryItemDefinition
    // (~190MB JSON) roughly doubles peak memory and can OOM Windows hosts.
    if (parsed is Map<String, dynamic>) return parsed;
    return Map<String, dynamic>.from(parsed);
  }

  Future<String?> readCurrentVersion() async {
    final text = await text_file.readTextFile(storageRoot.currentVersionPath);
    if (text == null) return null;
    try {
      final json = jsonDecode(text);
      if (json is Map && json['version'] is String) {
        return json['version'] as String;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> writeCurrentVersion(String version) async {
    await text_file.writeTextFile(
      storageRoot.currentVersionPath,
      jsonEncode({'version': version}),
    );
  }

  Future<EntityCacheMeta?> readEntityCacheMeta(String version) async {
    final text =
        await text_file.readTextFile(storageRoot.entityCacheMetaPath(version));
    if (text == null) return null;
    try {
      return EntityCacheMeta.fromJson(
        Map<String, dynamic>.from(jsonDecode(text) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> fetchRemoteVersion() async {
    final key = apiKey;
    if (key == null || key.isEmpty) return null;
    try {
      final metadata = await fetchManifestMetadata(key);
      return metadata.version;
    } catch (_) {
      return null;
    }
  }

  Future<ManifestMetadata> fetchManifestMetadata(String apiKey) async {
    final response = await httpGet(
      Uri.parse(kManifestUrl),
      headers: {'X-API-Key': apiKey},
    );
    if (!response.ok) {
      throw ManifestServiceException(
        'Manifest version check failed with status ${response.statusCode}',
      );
    }
    return parseManifestResponse(jsonDecode(response.body));
  }

  Future<void> downloadTables(
    ManifestMetadata metadata, {
    required bool forceFullDownload,
  }) async {
    final key = apiKey;
    if (key == null || key.isEmpty) {
      throw ManifestServiceException(kMissingApiKeyMessage);
    }

    for (final table in tablesToDownload) {
      final destination = storageRoot.rawTablePath(metadata.version, table);
      if (!forceFullDownload && await text_file.textFileExists(destination)) {
        continue;
      }
      await downloadTable(key, metadata, table, destination);
    }
  }

  Future<void> downloadTable(
    String apiKey,
    ManifestMetadata metadata,
    String table,
    String destination,
  ) async {
    final relativePath = metadata.tablePaths[table];
    if (relativePath == null || relativePath.isEmpty) {
      throw ManifestServiceException(
        'Manifest response missing download path for $table',
      );
    }

    final url = Uri.parse('$kBungieBaseUrl$relativePath');
    final response = await httpGet(
      url,
      headers: {'X-API-Key': apiKey},
    );
    if (!response.ok) {
      throw ManifestServiceException(
        'Failed to download $table: HTTP ${response.statusCode}',
      );
    }

    final parsed = jsonDecode(response.body);
    if (parsed is! Map) {
      throw ManifestServiceException(
        'Downloaded $table is not a valid JSON object',
      );
    }

    await text_file.writeTextFile(destination, jsonEncode(parsed));
  }
}

/// Parse Bungie Platform Destiny2/Manifest JSON body.
ManifestMetadata parseManifestResponse(Object? json) {
  if (json is! Map) {
    throw ManifestServiceException('Unexpected Bungie manifest response shape');
  }
  final response = json['Response'];
  if (response is! Map) {
    throw ManifestServiceException('Unexpected Bungie manifest response shape');
  }
  final version = response['version'];
  if (version is! String) {
    throw ManifestServiceException('Manifest response missing version');
  }

  final pathsRoot = response['jsonWorldComponentContentPaths'];
  if (pathsRoot is! Map) {
    throw ManifestServiceException(
      'Manifest response missing English table paths',
    );
  }
  final en = pathsRoot['en'];
  if (en is! Map) {
    throw ManifestServiceException(
      'Manifest response missing English table paths',
    );
  }

  final tablePaths = <String, String>{};
  for (final entry in en.entries) {
    if (entry.value is String) {
      tablePaths[entry.key.toString()] = entry.value as String;
    }
  }

  return ManifestMetadata(version: version, tablePaths: tablePaths);
}
