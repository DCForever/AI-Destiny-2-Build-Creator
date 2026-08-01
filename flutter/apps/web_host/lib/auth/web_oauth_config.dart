/// Public OAuth config for the Jaspr web host (DART-045 / DART-058).
///
/// Public client id only — never accepts or stores a client secret.
library;

import 'package:destiny2_bungie/destiny2_bungie.dart'
    show kProdWebOAuthCallbackPath, prodWebRedirectUri;

/// Default callback path registered with the Bungie Public application.
///
/// Same as [kProdWebOAuthCallbackPath] (prod Public matrix).
const String kWebOAuthCallbackPath = kProdWebOAuthCallbackPath;

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
  /// `{origin}/auth/callback` (DART-058 prod matrix).
  factory WebOAuthConfig.resolve({
    String clientId = const String.fromEnvironment('BUNGIE_CLIENT_ID'),
    String redirectUriOverride =
        const String.fromEnvironment('BUNGIE_REDIRECT_URI'),
    required String origin,
  }) {
    final redirect = redirectUriOverride.trim().isNotEmpty
        ? redirectUriOverride.trim()
        : prodWebRedirectUri(origin);
    return WebOAuthConfig(
      clientId: clientId.trim(),
      redirectUri: redirect,
    );
  }
}
