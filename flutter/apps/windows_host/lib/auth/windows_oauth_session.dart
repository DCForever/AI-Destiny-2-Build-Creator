import 'dart:async';
import 'dart:io';

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

/// Known Public+PKCE sign-in failure categories (safe for UI mapping).
enum OAuthSignInFailureKind {
  /// Bungie `access_denied` / user cancelled the authorize page.
  cancelled,

  /// CSRF state mismatch between authorize and callback.
  stateMismatch,

  /// Timed out waiting for the loopback redirect.
  callbackTimeout,

  /// Token endpoint HTTP / exchange failure (no raw body in UI).
  tokenExchangeFailed,

  /// Local network unreachable / socket failures.
  networkUnreachable,
}

/// Typed sign-in failure — [kind] only; never carries secret-bearing text.
class OAuthSignInFailure implements Exception {
  const OAuthSignInFailure(this.kind);

  final OAuthSignInFailureKind kind;

  @override
  String toString() => 'OAuthSignInFailure($kind)';
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
    void Function(String message)? log,
  })  : _tokenStore = tokenStore,
        _oauthClient = oauthClient,
        _browser = browserLauncher ?? const UrlLauncherBrowser(),
        _loopback = loopbackServer ?? LoopbackCallbackServer(),
        _waitForCallbackOverride = waitForCallbackOverride,
        _loopbackTimeout = loopbackTimeout,
        _log = log ?? _defaultLog;

  final String clientId;
  final String redirectUri;

  final TokenStore _tokenStore;
  final BungieOAuthClient _oauthClient;
  final BrowserLauncher _browser;
  final LoopbackCallbackServer _loopback;
  final Future<LoopbackCallbackResult> Function()? _waitForCallbackOverride;
  final Duration _loopbackTimeout;
  final void Function(String message) _log;

  static void _defaultLog(String message) {
    // ignore: avoid_print
    print(message);
  }

  OAuthSessionStatus _status = OAuthSessionStatus.signedOut;
  BungieTokens? _tokens;
  String? _errorMessage;
  bool _loaded = false;
  String? _pendingAuthorizeUrl;
  OAuthSignInFailureKind? _lastFailureKind;
  bool _signInCancelled = false;
  Completer<void>? _signInCancelGate;

  OAuthSessionStatus get status => _status;
  BungieTokens? get tokens => _tokens;
  String? get errorMessage => _errorMessage;
  bool get isSignedIn =>
      _tokens != null && _status == OAuthSessionStatus.signedIn;
  bool get isConfigured => clientId.trim().isNotEmpty && redirectUri.trim().isNotEmpty;
  String? get membershipId => _tokens?.bungieMembershipId;

  /// Authorize URL opened for the in-flight Public+PKCE sign-in (copy-link).
  ///
  /// Contains only public OAuth query params (client_id, state, PKCE challenge,
  /// redirect). Never tokens or a client secret. Null when not signing in.
  String? get pendingAuthorizeUrl => _pendingAuthorizeUrl;

  /// Last typed sign-in failure (null after success / cancel / fresh start).
  OAuthSignInFailureKind? get lastSignInFailureKind => _lastFailureKind;

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
        _log('OAuth: restore — no stored tokens');
        return;
      }

      _log(
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
        _log('OAuth: restore — signed in (access still valid)');
        return;
      }

      // Access expired (or inside safety margin).
      if (existing.refreshToken.isEmpty) {
        // Access-only session cannot be extended.
        _log(
          'OAuth: restore — access expired and no refresh_token; clearing',
        );
        try {
          // Locker only — keep legacy sidecar for a later verified migration.
          await _tokenStore.clearSecureOnly();
        } catch (_) {}
        _tokens = null;
        _status = OAuthSessionStatus.signedOut;
        _errorMessage = null;
        return;
      }

      if (isSessionExpired(existing)) {
        _log('OAuth: restore — refresh token expired; clearing');
        try {
          await _tokenStore.clearSecureOnly();
        } catch (_) {}
        _tokens = null;
        _status = OAuthSessionStatus.signedOut;
        _errorMessage = null;
        return;
      }

      _log('OAuth: restore — refreshing access token…');
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
        _log(
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
        _log(
          'OAuth: restore — refresh failed definitive=$definitive '
          'type=${e.runtimeType}',
        );
        if (definitive) {
          try {
            await _tokenStore.clearSecureOnly();
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
    } on TokenStoreCorruptException catch (e) {
      // Fail closed: treat as signed out; clear Locker only so a legacy
      // sidecar remains available for a later verified migration.
      _log('OAuth: restore — corrupt secure store');
      try {
        await _tokenStore.clearSecureOnly();
      } catch (_) {}
      _tokens = null;
      _status = OAuthSessionStatus.signedOut;
      _errorMessage = e.message;
    } catch (e, _) {
      // Type only — exception message/stack must never carry token material.
      _log('OAuth: restore failed (keeping store): ${e.runtimeType}');
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
      _lastFailureKind = null;
      notifyListeners();
      return;
    }
    if (_status == OAuthSessionStatus.signingIn) {
      return;
    }

    _status = OAuthSessionStatus.signingIn;
    _errorMessage = null;
    _lastFailureKind = null;
    _signInCancelled = false;
    _pendingAuthorizeUrl = null;
    notifyListeners();

    OAuthPendingAuth? pending;
    var loopbackStarted = false;
    final cancelGate = Completer<void>();
    _signInCancelGate = cancelGate;
    try {
      _log(
        'OAuth: starting sign-in redirectUri=$redirectUri '
        'clientIdLen=${clientId.length}',
      );
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
      _pendingAuthorizeUrl = authorizeUrl;
      notifyListeners();
      final authUri = Uri.parse(authorizeUrl);
      _log(
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
        loopbackStarted = true;
        _log(
          'OAuth: loopback listening on '
          '${loopback.useTls ? 'https' : 'http'}://'
          '${loopback.host}:${loopback.port}${loopback.path}',
        );
      }

      await _browser.open(authorizeUrl);
      _log('OAuth: browser opened; waiting for callback…');

      final LoopbackCallbackResult callback;
      try {
        final waitOverride = _waitForCallbackOverride;
        final waitFuture = waitOverride != null
            ? waitOverride()
            : _loopback.waitForCallback(timeout: _loopbackTimeout);
        callback = await Future.any<LoopbackCallbackResult>([
          waitFuture,
          cancelGate.future.then(
            (_) => throw const OAuthSignInFailure(
              OAuthSignInFailureKind.cancelled,
            ),
          ),
        ]);
      } on TimeoutException {
        throw const OAuthSignInFailure(OAuthSignInFailureKind.callbackTimeout);
      } on OAuthSignInFailure {
        rethrow;
      } catch (e) {
        if (_signInCancelled) {
          throw const OAuthSignInFailure(OAuthSignInFailureKind.cancelled);
        }
        if (_isNetworkFailure(e)) {
          throw const OAuthSignInFailure(
            OAuthSignInFailureKind.networkUnreachable,
          );
        }
        rethrow;
      } finally {
        // Stop loopback before token exchange / Locker write so a stop()
        // failure cannot reach the outer catch and clear a good write.
        if (loopbackStarted) {
          try {
            await _loopback.stop();
          } catch (_) {}
          loopbackStarted = false;
        }
      }

      // Path + flags only — never log raw OAuth error / description values.
      _log(
        'OAuth: callback received hasCode=${callback.hasCode} '
        'hasError=${callback.hasError}',
      );

      if (callback.hasError) {
        final err = (callback.error ?? '').toLowerCase();
        if (err == 'access_denied') {
          throw const OAuthSignInFailure(OAuthSignInFailureKind.cancelled);
        }
        // Other provider errors: fixed category, no raw error string.
        throw const OAuthSignInFailure(
          OAuthSignInFailureKind.tokenExchangeFailed,
        );
      }
      if (!callback.hasCode) {
        throw const OAuthSignInFailure(
          OAuthSignInFailureKind.tokenExchangeFailed,
        );
      }
      final returnedState = callback.state ?? '';
      if (!validateOAuthState(
        expected: pending.state,
        actual: returnedState,
      )) {
        throw const OAuthSignInFailure(OAuthSignInFailureKind.stateMismatch);
      }

      _log('OAuth: exchanging code for tokens…');
      final BungieTokens tokens;
      try {
        tokens = await _oauthClient
            .exchangeCode(
              code: callback.code!,
              codeVerifier: pending.codeVerifier,
            )
            .timeout(
              const Duration(seconds: 45),
              onTimeout: () => throw const OAuthSignInFailure(
                OAuthSignInFailureKind.tokenExchangeFailed,
              ),
            );
      } on OAuthSignInFailure {
        rethrow;
      } on BungieOAuthException {
        throw const OAuthSignInFailure(
          OAuthSignInFailureKind.tokenExchangeFailed,
        );
      } catch (e) {
        if (_isNetworkFailure(e)) {
          throw const OAuthSignInFailure(
            OAuthSignInFailureKind.networkUnreachable,
          );
        }
        throw const OAuthSignInFailure(
          OAuthSignInFailureKind.tokenExchangeFailed,
        );
      }

      _log(
        'OAuth: token exchange OK accessLen=${tokens.accessToken.length} '
        'refreshLen=${tokens.refreshToken.length} '
        'membership=${tokens.bungieMembershipId}; writing secure storage…',
      );
      if (tokens.refreshToken.isEmpty) {
        // Bungie portal docs: Public clients are not issued refresh_token.
        // Confidential (Next) gets ~90d refresh. Live API re-auth ~hourly;
        // local inventory browse must not depend on this (see OwnedCatalogBridge).
        _log(
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

      // Verified Locker write — drop any leftover plaintext sidecar.
      try {
        await _tokenStore.deleteLegacySidecarIfPresent();
      } catch (_) {}

      _tokens = tokens;
      _status = OAuthSessionStatus.signedIn;
      _errorMessage = null;
      _lastFailureKind = null;
      _log(
        'OAuth: signed in membership=${tokens.bungieMembershipId} '
        'stored refreshLen=${verified.refreshToken.length}',
      );
    } catch (e, _) {
      // Type only — never log exception message/stack (may carry secrets).
      _log('WindowsOAuthSession.signIn failed: ${e.runtimeType}');
      debugPrint('WindowsOAuthSession.signIn failed: ${e.runtimeType}');
      _tokens = null;
      if (_signInCancelled ||
          (e is OAuthSignInFailure &&
              e.kind == OAuthSignInFailureKind.cancelled &&
              _status == OAuthSessionStatus.signedOut)) {
        // User cancel already applied signed-out; do not flip to error.
        _status = OAuthSessionStatus.signedOut;
        _errorMessage = null;
        _lastFailureKind = OAuthSignInFailureKind.cancelled;
      } else {
        _status = OAuthSessionStatus.error;
        _errorMessage = _safeErrorMessage(e);
        _lastFailureKind = e is OAuthSignInFailure ? e.kind : null;
      }
      // Clear Locker only — do not wipe a pending migration sidecar.
      try {
        await _tokenStore.clearSecureOnly();
      } catch (_) {}
    } finally {
      _pendingAuthorizeUrl = null;
      _signInCancelGate = null;
      if (loopbackStarted) {
        try {
          await _loopback.stop();
        } catch (_) {}
      }
    }
    notifyListeners();
  }

  /// Aborts an in-flight loopback wait (e.g. user closed the browser).
  Future<void> cancelSignIn() async {
    if (_status != OAuthSessionStatus.signingIn) return;
    _signInCancelled = true;
    final gate = _signInCancelGate;
    if (gate != null && !gate.isCompleted) {
      gate.complete();
    }
    try {
      await _loopback.stop();
    } catch (_) {}
    _pendingAuthorizeUrl = null;
    _status = OAuthSessionStatus.signedOut;
    _errorMessage = null;
    _lastFailureKind = OAuthSignInFailureKind.cancelled;
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

  /// Friendly fixed copy for known failures; unknown → type only.
  ///
  /// Never echoes exception message text (tokens, auth codes, provider bodies).
  static String _safeErrorMessage(Object e) {
    if (e is OAuthSignInFailure) {
      return switch (e.kind) {
        OAuthSignInFailureKind.cancelled =>
          'Sign-in was cancelled. Try again when ready.',
        OAuthSignInFailureKind.stateMismatch =>
          'Sign-in could not be verified. Please try again.',
        OAuthSignInFailureKind.callbackTimeout =>
          'Sign-in timed out waiting for Bungie. Please try again.',
        OAuthSignInFailureKind.tokenExchangeFailed =>
          'Could not complete sign-in with Bungie. Please try again.',
        OAuthSignInFailureKind.networkUnreachable =>
          'Network unavailable. Check your connection and try again.',
      };
    }
    if (e is TimeoutException) {
      return 'Sign-in timed out waiting for Bungie. Please try again.';
    }
    if (_isNetworkFailure(e)) {
      return 'Network unavailable. Check your connection and try again.';
    }
    return 'Sign-in failed (${e.runtimeType}). Try again.';
  }

  static bool _isNetworkFailure(Object e) {
    return e is SocketException ||
        e is HandshakeException ||
        e is HttpException ||
        e is TlsException ||
        e is OSError;
  }
}
