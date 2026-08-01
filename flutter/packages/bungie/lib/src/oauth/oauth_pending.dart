/// Host-held OAuth handoff between authorize redirect and callback.
///
/// Not persisted by this package — store securely in DART-023+.
class OAuthPendingAuth {
  const OAuthPendingAuth({
    required this.state,
    required this.codeVerifier,
    required this.redirectUri,
    this.createdAt,
  });

  /// CSRF state issued at authorize time.
  final String state;

  /// PKCE `code_verifier` (never send to authorize URL; only token exchange).
  final String codeVerifier;

  /// Must match authorize query and token exchange body.
  final String redirectUri;

  /// Optional bookkeeping timestamp.
  final DateTime? createdAt;
}
