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
  Future<void> restore() async {
    try {
      final existing = await _tokenStore.read();
      _tokens = existing;
      _status = existing != null
          ? OAuthSessionStatus.signedIn
          : OAuthSessionStatus.signedOut;
      _errorMessage = null;
    } catch (e) {
      _tokens = null;
      _status = OAuthSessionStatus.signedOut;
      _errorMessage = 'Could not restore session';
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
        print('OAuth: token exchange OK; writing secure storage…');
        await _tokenStore.write(tokens).timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw const BungieOAuthException(
                'Secure token storage write timed out',
              ),
            );
        _tokens = tokens;
        _status = OAuthSessionStatus.signedIn;
        _errorMessage = null;
        // ignore: avoid_print
        print('OAuth: signed in membership=${tokens.bungieMembershipId}');
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
