import 'http_client_impl.dart' as impl;

import 'types/services.dart';

/// Default [ManifestHttpGet] using platform HTTP (dart:io on native).
///
/// Hosts may inject a mock for tests. On web this throws — inject [httpGet]
/// into [BungieManifestService] or use prebuilt entity bundles (DART-044).
ManifestHttpGet createUtf8ManifestHttpGet({Object? client}) =>
    impl.createUtf8ManifestHttpGet(client: client);

/// Alias kept for readability at call sites.
ManifestHttpGet createDefaultManifestHttpGet({Object? client}) =>
    createUtf8ManifestHttpGet(client: client);
