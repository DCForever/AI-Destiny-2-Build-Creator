/// Shared Bungie Platform HTTP client + Public+PKCE OAuth (DART-021/022).
///
/// Public API key and public client id only — hosts inject credentials.
/// No `CLIENT_SECRET` / `client_secret` fields.
library;

export 'src/bungie_envelope.dart';
export 'src/bungie_errors.dart';
export 'src/bungie_http_client.dart';
export 'src/http_transport.dart';
export 'src/rate_limit.dart';
export 'src/oauth/bungie_oauth_client.dart';
export 'src/oauth/bungie_tokens.dart';
export 'src/oauth/oauth_errors.dart';
export 'src/oauth/oauth_pending.dart';
export 'src/oauth/oauth_state.dart';
export 'src/oauth/pkce.dart';
export 'src/oauth/redirect_uri_config.dart';
