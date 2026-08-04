import 'dart:async';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:flutter/foundation.dart';

import 'browser_launcher.dart';
import 'loopback_callback_server.dart';
import 'token_store.dart';

/// High-level session status for Settings UI.
enum OAuthSessionStatus {
  signedOut,
  signingIn,
  signedIn,
  error,
}

/// Sign-in / sign-out orchestration for Flutter Windows (DART-023).
///
/// Uses DART-022 [BungieOAuthClient] + loopback callback + [TokenStore].
/// Injectable [BrowserLauncher], [LoopbackCallbackServer], and optional
/// [waitForCallbackOverride] keep CI free of live Bungie / real browser.
class WindowsOAuthSession extends ChangeNotifier {
  WindowsOAuthSession({
    required this.clientId,
    required this.redirectUri,
    required TokenStore tokenStore,
    required BungieOAuthClient oauthClient,
    BrowserLauncher? browserLauncher,
    LoopbackCallbackServer? loopbackServer,
    Future<LoopbackCallbackResult> Function()? waitForCallbackOverride,
    Duration loopbackTimeout = const Duration(minutes: 5),
  })  : _tokenStore = tokenStore,
        _oauthClient = oauthClient,
        _browser = browserLauncher ?? const UrlLauncherBrowser(),
        _loopback = loopbackServer ?? LoopbackCallbackServer(),
        _waitForCallbackOverride = waitForCallbackOverride,
        _loopbackTimeout = loopbackTimeout;

  final String clientId;
  final String redirectUri;

  final TokenStore _tokenStore;
  final BungieOAuthClient _oauthClient;
  final BrowserLauncher _browser;
  final LoopbackCallbackServer _loopback;
  final Future<LoopbackCallbackResult> Function()? _waitForCallbackOverride;
  final Duration _loopbackTimeout;

  OAuthSessionStatus _status = OAuthSessionStatus.signedOut;
  BungieTokens? _tokens;
  String? _errorMessage;
  bool _loaded = false;

  OAuthSessionStatus get status => _status;
  BungieTokens? get tokens => _tokens;
  String? get errorMessage => _errorMessage;
  bool get isSignedIn =>
      _tokens != null && _status == OAuthSessionStatus.signedIn;
  bool get isConfigured => clientId.trim().isNotEmpty && redirectUri.trim().isNotEmpty;
  String? get membershipId => _tokens?.bungieMembershipId;

  /// Loads tokens from secure storage (call once after bootstrap).
  ///
  /// Persistence strategy:
  /// - Access still valid → signed in immediately.
  /// - Access near/expired + live refresh token → refresh and persist.
  /// - No refresh and access expired → clear (re-auth required).
  /// - Transient network/refresh errors → **do not clear** stored credentials
  ///   so the next launch can retry without a full browser sign-in.
  Future<void> restore() async {
    try {
      final existing = await _tokenStore.read();
      if (existing == null) {
        _tokens = null;
        _status = OAuthSessionStatus.signedOut;
        _errorMessage = null;
        // ignore: avoid_print
        print('OAuth: restore — no stored tokens');
        return;
      }

      // ignore: avoid_print
      print(
        'OAuth: restore — loaded membership=${existing.bungieMembershipId} '
        'accessLen=${existing.accessToken.length} '
        'refreshLen=${existing.refreshToken.length} '
        'needsRefresh=${needsRefresh(existing)} '
        'sessionExpired=${isSessionExpired(existing)}',
      );

      if (!needsRefresh(existing)) {
        _tokens = existing;
        _status = OAuthSessionStatus.signedIn;
        _errorMessage = null;
        // ignore: avoid_print
        print('OAuth: restore — signed in (access still valid)');
        return;
      }

      // Access expired (or inside safety margin).
      if (existing.refreshToken.isEmpty) {
        // Access-only session cannot be extended.
        // ignore: avoid_print
        print(
          'OAuth: restore — access expired and no refresh_token; clearing',
        );
        try {
          await _tokenStore.clear();
        } catch (_) {}
        _tokens = null;
        _status = OAuthSessionStatus.signedOut;
        _errorMessage = null;
        return;
      }

      if (isSessionExpired(existing)) {
        // ignore: avoid_print
        print('OAuth: restore — refresh token expired; clearing');
        try {
          await _tokenStore.clear();
        } catch (_) {}
        _tokens = null;
        _status = OAuthSessionStatus.signedOut;
        _errorMessage = null;
        return;
      }

      // ignore: avoid_print
      print('OAuth: restore — refreshing access token…');
      try {
        final refreshed = await _oauthClient.refreshTokens(existing).timeout(
              const Duration(seconds: 45),
              onTimeout: () => throw const BungieOAuthException(
                'Token refresh timed out after 45s',
              ),
            );
        await _tokenStore.write(refreshed);
        _tokens = refreshed;
        _status = OAuthSessionStatus.signedIn;
        _errorMessage = null;
        // ignore: avoid_print
        print(
          'OAuth: restore — refresh OK membership=${refreshed.bungieMembershipId} '
          'refreshLen=${refreshed.refreshToken.length}',
        );
      } on BungieOAuthException catch (e) {
        // invalid_grant / revoked → clear; network/timeout → keep store.
        final msg = e.message.toLowerCase();
        final definitive = msg.contains('invalid_grant') ||
            msg.contains('invalid_token') ||
            (e.statusCode != null &&
                (e.statusCode == 400 || e.statusCode == 401));
        // ignore: avoid_print
        print(
          'OAuth: restore — refresh failed definitive=$definitive: $e',
        );
        if (definitive) {
          try {
            await _tokenStore.clear();
          } catch (_) {}
          _tokens = null;
          _status = OAuthSessionStatus.signedOut;
          _errorMessage = null;
        } else {
          // Keep credentials for next launch; UI shows signed-out until online.
          _tokens = null;
          _status = OAuthSessionStatus.error;
          _errorMessage =
              'Could not refresh session (network). Try again when online — '
              'you should not need to re-authorize.';
        }
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('OAuth: restore failed (keeping store): $e\n$st');
      // Never wipe storage on unexpected I/O errors — that forces re-auth.
      _tokens = null;
      _status = OAuthSessionStatus.error;
      _errorMessage = 'Could not restore session (storage). Retry or re-sign-in.';
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  bool get hasRestored => _loaded;

  /// Starts Public+PKCE sign-in via loopback + system browser.
  Future<void> signIn() async {
    if (!isConfigured) {
      _status = OAuthSessionStatus.error;
      _errorMessage =
          'Bungie client id / redirect URI not configured (BUNGIE_CLIENT_ID)';
      notifyListeners();
      return;
    }
    if (_status == OAuthSessionStatus.signingIn) {
      return;
    }

    _status = OAuthSessionStatus.signingIn;
    _errorMessage = null;
    notifyListeners();

    OAuthPendingAuth? pending;
    try {
      // ignore: avoid_print
      print('OAuth: starting sign-in redirectUri=$redirectUri clientIdLen=${clientId.length}');
      final pkce = generatePkcePair();
      final state = generateOAuthState();
      pending = OAuthPendingAuth(
        state: state,
        codeVerifier: pkce.codeVerifier,
        redirectUri: redirectUri,
        createdAt: DateTime.now().toUtc(),
      );

      final authorizeUrl = _oauthClient.buildAuthorizeUrl(
        state: state,
        codeChallenge: pkce.codeChallenge,
      );
      final authUri = Uri.parse(authorizeUrl);
      // ignore: avoid_print
      print(
        'OAuth: authorize URL built (len=${authorizeUrl.length}) '
        'params=${authUri.queryParameters.keys.toList()} '
        'redirect_uri=${authUri.queryParameters['redirect_uri']} '
        'client_id=${authUri.queryParameters['client_id']}',
      );

      final loopback = parseLoopbackRedirectUri(redirectUri);

      if (_waitForCallbackOverride == null) {
        await _loopback.start(
          host: loopback.host,
          port: loopback.port,
          callbackPath: loopback.path,
          useTls: loopback.useTls,
        );
        // ignore: avoid_print
        print(
          'OAuth: loopback listening on '
          '${loopback.useTls ? 'https' : 'http'}://'
          '${loopback.host}:${loopback.port}${loopback.path}',
        );
      }

      try {
        await _browser.open(authorizeUrl);
        // ignore: avoid_print
        print('OAuth: browser opened; waiting for callback…');

        final waitOverride = _waitForCallbackOverride;
        final LoopbackCallbackResult callback = waitOverride != null
            ? await waitOverride()
            : await _loopback.waitForCallback(timeout: _loopbackTimeout);

        // ignore: avoid_print
        print(
          'OAuth: callback received hasCode=${callback.hasCode} '
          'hasError=${callback.hasError} error=${callback.error}',
        );

        if (callback.hasError) {
          final desc = callback.errorDescription;
          throw BungieOAuthException(
            (desc != null && desc.isNotEmpty)
                ? desc
                : 'Authorization failed (${callback.error})',
          );
        }
        if (!callback.hasCode) {
          throw const BungieOAuthException(
            'Authorization callback missing code',
          );
        }
        final returnedState = callback.state ?? '';
        if (!validateOAuthState(
          expected: pending.state,
          actual: returnedState,
        )) {
          throw const BungieOAuthException(
            'OAuth state mismatch (CSRF validation failed)',
          );
        }

        // ignore: avoid_print
        print('OAuth: exchanging code for tokens…');
        final tokens = await _oauthClient
            .exchangeCode(
              code: callback.code!,
              codeVerifier: pending.codeVerifier,
            )
            .timeout(
              const Duration(seconds: 45),
              onTimeout: () => throw const BungieOAuthException(
                'Token exchange timed out after 45s (network or Bungie token endpoint)',
              ),
            );
        // ignore: avoid_print
        print(
          'OAuth: token exchange OK accessLen=${tokens.accessToken.length} '
          'refreshLen=${tokens.refreshToken.length} '
          'membership=${tokens.bungieMembershipId}; writing secure storage…',
        );
        if (tokens.refreshToken.isEmpty) {
          // Bungie portal docs: Public clients are not issued refresh_token.
          // Confidential (Next) gets ~90d refresh. Live API re-auth ~hourly;
          // local inventory browse must not depend on this (see OwnedCatalogBridge).
          // ignore: avoid_print
          print(
            'OAuth: empty refresh_token (Bungie Public clients do not receive one) — '
            'live access lasts ~1h; re-sign-in only required for Sync/API, not local Owned',
          );
        }
        await _tokenStore.write(tokens).timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw const BungieOAuthException(
                'Secure token storage write timed out',
              ),
            );
        final verified = await _tokenStore.read();
        if (verified == null ||
            verified.accessToken != tokens.accessToken ||
            verified.bungieMembershipId != tokens.bungieMembershipId) {
          throw const BungieOAuthException(
            'Secure token storage write did not persist (read-back failed)',
          );
        }
        _tokens = tokens;
        _status = OAuthSessionStatus.signedIn;
        _errorMessage = null;
        // ignore: avoid_print
        print(
          'OAuth: signed in membership=${tokens.bungieMembershipId} '
          'stored refreshLen=${verified.refreshToken.length}',
        );
      } finally {
        if (_waitForCallbackOverride == null) {
          await _loopback.stop();
        }
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('WindowsOAuthSession.signIn failed: $e\n$st');
      debugPrint('WindowsOAuthSession.signIn failed: $e\n$st');
      _tokens = null;
      _status = OAuthSessionStatus.error;
      _errorMessage = _safeErrorMessage(e);
      // Best-effort clear so partial writes cannot linger.
      try {
        await _tokenStore.clear();
      } catch (_) {}
    }
    notifyListeners();
  }

  /// Aborts an in-flight loopback wait (e.g. user closed the browser).
  Future<void> cancelSignIn() async {
    if (_status != OAuthSessionStatus.signingIn) return;
    try {
      await _loopback.stop();
    } catch (_) {}
    _status = OAuthSessionStatus.signedOut;
    _errorMessage = 'Sign-in cancelled';
    notifyListeners();
  }

  /// Clears secure tokens and returns to signed-out.
  Future<void> signOut() async {
    try {
      await _tokenStore.clear();
    } finally {
      _tokens = null;
      _status = OAuthSessionStatus.signedOut;
      _errorMessage = null;
      notifyListeners();
    }
  }

  static String _safeErrorMessage(Object e) {
    // Prefer full OAuth exception text (includes Bungie error_description).
    final text = e is BungieOAuthException
        ? e.toString()
        : e.toString();
    // Avoid echoing long token-like payloads; keep message usable for UI.
    if (text.length > 480) {
      return '${text.substring(0, 480)}…';
    }
    return text;
  }
}
