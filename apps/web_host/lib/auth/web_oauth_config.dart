/// Public OAuth config for the Jaspr web host (DART-045).
///
/// Public client id only — never accepts or stores a client secret.
library;

/// Default callback path registered with the Bungie Public application.
const String kWebOAuthCallbackPath = '/auth/callback';

/// Resolve web host OAuth settings (public id + redirect URI).
class WebOAuthConfig {
  const WebOAuthConfig({
    required this.clientId,
    required this.redirectUri,
  });

  /// Public Bungie application client id (not a secret).
  final String clientId;

  /// Must match Bungie app registration (HTTPS loopback or prod origin).
  final String redirectUri;

  bool get isConfigured =>
      clientId.trim().isNotEmpty && redirectUri.trim().isNotEmpty;

  /// Builds config from dart-define / injected values.
  ///
  /// [origin] is used when [redirectUriOverride] is empty:
  /// `{origin}/auth/callback`.
  factory WebOAuthConfig.resolve({
    String clientId = const String.fromEnvironment('BUNGIE_CLIENT_ID'),
    String redirectUriOverride =
        const String.fromEnvironment('BUNGIE_REDIRECT_URI'),
    required String origin,
  }) {
    final redirect = redirectUriOverride.trim().isNotEmpty
        ? redirectUriOverride.trim()
        : _defaultRedirectUri(origin);
    return WebOAuthConfig(
      clientId: clientId.trim(),
      redirectUri: redirect,
    );
  }

  static String _defaultRedirectUri(String origin) {
    final base = origin.endsWith('/')
        ? origin.substring(0, origin.length - 1)
        : origin;
    return '$base$kWebOAuthCallbackPath';
  }
}
