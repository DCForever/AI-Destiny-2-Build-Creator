import 'types/services.dart';

/// Web stub — native HttpClient is unavailable.
ManifestHttpGet createUtf8ManifestHttpGet({Object? client}) {
  return (Uri uri, {Map<String, String>? headers}) async {
    throw UnsupportedError(
      'Default ManifestHttpGet requires dart:io. '
      'Inject a custom ManifestHttpGet or use prebuilt entity bundles (DART-044).',
    );
  };
}
