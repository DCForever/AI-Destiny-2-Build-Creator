import 'dart:convert';

import '../bungie_errors.dart';
import '../http_transport.dart';
import 'bungie_tokens.dart';
import 'pkce.dart';

/// Default Bungie OAuth authorize endpoint.
final Uri kBungieAuthorizeBaseUrl =
    Uri.parse('https://www.bungie.net/en/oauth/authorize');

/// Default Bungie OAuth token endpoint (OAuth JSON, not Platform envelope).
final Uri kBungieTokenEndpoint =
    Uri.parse('https://www.bungie.net/platform/app/oauth/token/');

/// Public + PKCE OAuth client for Bungie.
///
/// Host injects the **public** `clientId` and active `redirectUri`.
/// There is **no** client secret parameter — confidential OAuth stays on
/// legacy Next only.
class BungieOAuthClient {
  BungieOAuthClient({
    required String clientId,
    required String redirectUri,
    Uri? authorizeBaseUrl,
    Uri? tokenEndpoint,
    BungieHttpTransport? transport,
  })  : clientId = _requireNonEmpty(clientId, 'clientId'),
        redirectUri = _requireNonEmpty(redirectUri, 'redirectUri'),
        authorizeBaseUrl = authorizeBaseUrl ?? kBungieAuthorizeBaseUrl,
        tokenEndpoint = tokenEndpoint ?? kBungieTokenEndpoint,
        transport = transport ?? createDefaultBungieHttpTransport();

  /// Public Bungie application client id (not a secret).
  final String clientId;

  /// Active platform redirect URI (must match Bungie app registration).
  final String redirectUri;

  final Uri authorizeBaseUrl;
  final Uri tokenEndpoint;
  final BungieHttpTransport transport;

  /// Builds the browser authorize URL including PKCE S256 challenge + CSRF state.
  String buildAuthorizeUrl({
    required String state,
    required String codeChallenge,
    String codeChallengeMethod = kPkceMethodS256,
  }) {
    if (state.isEmpty) {
      throw const BungieConfigException('OAuth state must be non-empty');
    }
    if (codeChallenge.isEmpty) {
      throw const BungieConfigException('PKCE code_challenge must be non-empty');
    }
    if (codeChallengeMethod != kPkceMethodS256) {
      throw const BungieConfigException(
        'Only S256 code_challenge_method is supported',
      );
    }

    return authorizeBaseUrl.replace(
      queryParameters: <String, String>{
        'client_id': clientId,
        'response_type': 'code',
        'state': state,
        'redirect_uri': redirectUri,
        'code_challenge': codeChallenge,
        'code_challenge_method': codeChallengeMethod,
      },
    ).toString();
  }

  /// Exchanges an authorization code + PKCE verifier for tokens.
  Future<BungieTokens> exchangeCode({
    required String code,
    required String codeVerifier,
    DateTime? now,
  }) async {
    if (code.isEmpty) {
      throw const BungieConfigException('Authorization code must be non-empty');
    }
    if (codeVerifier.isEmpty) {
      throw const BungieConfigException('PKCE code_verifier must be non-empty');
    }

    final body = <String, String>{
      'grant_type': 'authorization_code',
      'code': code,
      'client_id': clientId,
      'code_verifier': codeVerifier,
      'redirect_uri': redirectUri,
    };
    return _postToken(body, now: now);
  }

  /// Refreshes tokens using the refresh token grant (public client).
  ///
  /// When Bungie omits `refresh_token` on the response (common for non-rotating
  /// refresh grants), the previous refresh token and its expiry are preserved so
  /// cold starts can keep refreshing instead of forcing re-auth.
  Future<BungieTokens> refreshTokens(
    BungieTokens tokens, {
    DateTime? now,
  }) async {
    if (tokens.refreshToken.isEmpty) {
      throw const BungieConfigException('refresh_token must be non-empty');
    }

    final body = <String, String>{
      'grant_type': 'refresh_token',
      'refresh_token': tokens.refreshToken,
      'client_id': clientId,
    };
    final mapped = await _postToken(body, now: now);
    return preserveRefreshCredentials(previous: tokens, next: mapped);
  }

  Future<BungieTokens> _postToken(
    Map<String, String> form, {
    DateTime? now,
  }) async {
    // Public clients: form body only — never client_secret, never Basic secret.
    final encoded = _encodeForm(form);
    final request = BungieHttpRequest(
      method: 'POST',
      uri: tokenEndpoint,
      headers: const {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
        // Some edge networks treat missing UA poorly; identify as desktop host.
        'User-Agent': 'Destiny2BuildCreator-WindowsHost/0.1 (Public+PKCE)',
      },
      body: encoded,
    );

    final raw = await transport(request);
    final Object? decoded = _tryDecodeJson(raw.body);

    if (raw.statusCode < 200 || raw.statusCode >= 300) {
      throw BungieOAuthException(
        _oauthErrorMessage(
          fallback: 'Bungie token endpoint returned ${raw.statusCode}',
          decoded: decoded,
        ),
        statusCode: raw.statusCode,
        bodySnippet: _snippet(raw.body),
      );
    }

    if (decoded == null) {
      throw BungieOAuthException(
        'Bungie token response is not JSON',
        statusCode: raw.statusCode,
        bodySnippet: _snippet(raw.body),
      );
    }

    if (decoded is! Map) {
      throw BungieOAuthException(
        'Bungie token response has unexpected shape',
        statusCode: raw.statusCode,
        bodySnippet: _snippet(raw.body),
      );
    }

    final map = Map<String, dynamic>.from(decoded);
    // OAuth error object can theoretically arrive with 200.
    if (map['error'] is String && (map['error'] as String).isNotEmpty) {
      throw BungieOAuthException(
        _oauthErrorMessage(
          fallback: 'Bungie token endpoint returned an error',
          decoded: map,
        ),
        statusCode: raw.statusCode,
        bodySnippet: _snippet(raw.body),
      );
    }

    try {
      return mapTokenResponse(map, now: now);
    } on FormatException catch (e) {
      throw BungieOAuthException(
        e.message,
        statusCode: raw.statusCode,
        // Never attach raw body here — it contains access_token.
        bodySnippet: _shapeOnly(map),
      );
    }
  }

  static Object? _tryDecodeJson(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  /// Prefer OAuth `error` / `error_description` when present.
  static String _oauthErrorMessage({
    required String fallback,
    required Object? decoded,
  }) {
    if (decoded is! Map) return fallback;
    final err = decoded['error'];
    final desc = decoded['error_description'];
    final errText = err is String ? err : null;
    final descText = desc is String ? desc : null;
    if ((errText == null || errText.isEmpty) &&
        (descText == null || descText.isEmpty)) {
      return fallback;
    }
    if (errText != null &&
        errText.isNotEmpty &&
        descText != null &&
        descText.isNotEmpty) {
      return '$errText: $descText';
    }
    return (descText != null && descText.isNotEmpty) ? descText : errText!;
  }

  static String _encodeForm(Map<String, String> form) {
    return form.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
  }

  static String _requireNonEmpty(String value, String name) {
    if (value.trim().isEmpty) {
      throw BungieConfigException('OAuth $name must be non-empty');
    }
    return value;
  }

  static String _snippet(String body, [int max = 200]) {
    // Redact bearer material if a 4xx body ever echoes it.
    final redacted = body
        .replaceAllMapped(
          RegExp(r'"(access_token|refresh_token)"\s*:\s*"[^"]*"'),
          (m) => '"${m[1]}":"[redacted]"',
        );
    if (redacted.length <= max) return redacted;
    return '${redacted.substring(0, max)}…';
  }

  /// Key:type pairs only — safe for logs/UI.
  static String _shapeOnly(Map<String, dynamic> map) {
    if (map.isEmpty) return 'empty';
    return map.entries
        .map((e) => '${e.key}:${e.value == null ? 'null' : e.value.runtimeType}')
        .join(', ');
  }
}
