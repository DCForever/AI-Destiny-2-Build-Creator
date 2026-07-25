import 'http_transport.dart';

/// Web / non-IO stub — hosts must inject a [BungieHttpTransport].
///
/// Browser OAuth (DART-045) always passes an explicit transport (or a
/// fetch-based factory from the web host). Default [HttpClient] is unavailable.
BungieHttpTransport createDefaultBungieHttpTransport({Object? client}) {
  return (BungieHttpRequest request) async {
    throw UnsupportedError(
      'Default BungieHttpTransport requires dart:io. '
      'Inject a custom BungieHttpTransport (e.g. browser fetch) for web hosts.',
    );
  };
}
