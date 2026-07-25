/// Shared Bungie Platform HTTP client (DART-021).
///
/// Public API key only — hosts inject `X-API-Key`. No `CLIENT_SECRET`.
library;

export 'src/bungie_envelope.dart';
export 'src/bungie_errors.dart';
export 'src/bungie_http_client.dart';
export 'src/http_transport.dart';
export 'src/rate_limit.dart';
