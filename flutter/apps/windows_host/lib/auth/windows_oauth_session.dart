import 'dart:async';
import 'dart:io';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:flutter/foundation.dart';

import 'browser_launcher.dart';
import 'client_credential_store.dart';
import 'loopback_callback_server.dart';
import 'token_store.dart';

export 'browser_launcher.dart'
    show isAllowedBungieAuthorizeUrl, kUnsafeAuthorizeUrlMessage;
export 'client_credential_store.dart';

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

  /// Callback reached loopback without an authorization `code`.
  missingAuthorizationCode,

  /// Authorize URL host/scheme failed the www.bungie.net https allowlist.
  unsafeAuthorizeUrl,
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
/// Optional [ClientCredentialStore] enables Confidential desktop mode (plan
/// b2): credential lives in Credential Manager; absent → Public+PKCE.
/// Injectable [BrowserLauncher], [LoopbackCallbackServer], and optional
/// [waitForCallbackOverride] keep CI free of live Bungie / real browser.
class WindowsOAuthSession extends ChangeNotifier {
  WindowsOAuthSession({
    required this.clientId,
    required this.redirectUri,
    required TokenStore tokenStore,
    required BungieOAuthClient oauthClient,
    ClientCredentialStore? credentialStore,
    BrowserLauncher? browserLauncher,
    LoopbackCallbackServer? loopbackServer,
    Future<LoopbackCallbackResult> Function()? waitForCallbackOverride,
    Duration loopbackTimeout = const Duration(minutes: 5),
    void Function(String message)? log,
  })  : _tokenStore = tokenStore,
        _oauthClient = oauthClient,
        _credentialStore = credentialStore ?? MemoryClientCredentialStore(),
        _browser = browserLauncher ?? const UrlLauncherBrowser(),
        _loopback = loopbackServer ?? LoopbackCallbackServer(),
        _waitForCallbackOverride = waitForCallbackOverride,
        _loopbackTimeout = loopbackTimeout,
        _log = log ?? _defaultLog;

  final String clientId;
  final String redirectUri;

  final TokenStore _tokenStore;
  final BungieOAuthClient _oauthClient;
  final ClientCredentialStore _credentialStore;
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
  /// True from [signIn] entry until its `finally` finishes (blocks overlap).
  bool _signInBusy = false;
  bool _confidentialMode = false;
  bool _promptForgetCredential = false;
  Future<void>? _refreshInFlight;

  OAuthSessionStatus get status => _status;
  BungieTokens? get tokens => _tokens;
  String? get errorMessage => _errorMessage;
  bool get isSignedIn =>
      _tokens != null && _status == OAuthSessionStatus.signedIn;
  bool get isConfigured => clientId.trim().isNotEmpty && redirectUri.trim().isNotEmpty;
  String? get membershipId => _tokens?.bungieMembershipId;

  /// True when a Confidential app credential is stored (never log the value).
  bool get isConfidentialMode => _confidentialMode;

  /// UI should offer "Forget client secret" after `invalid_client`.
  bool get promptForgetCredential => _promptForgetCredential;

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
  /// - Transient network/refresh errors → **do not clear** stored tokens
  ///   so the next launch can retry without a full browser sign-in.
  /// - Token-store write failure after refresh → sign out (never use unsaved).
  Future<void> restore() async {
    try {
      await _refreshConfidentialFlag();
      final existing = await _tokenStore.read();
      if (existing == null) {
        _tokens = null;
        _status = OAuthSessionStatus.signedOut;
        _errorMessage = null;
        _log(
          'OAuth: restore — no stored tokens '
          'confidential=${_confidentialMode ? 'on' : 'off'}',
        );
        return;
      }

      _log(
        'OAuth: restore — loaded membership=${existing.bungieMembershipId} '
        'accessLen=${existing.accessToken.length} '
        'refreshLen=${existing.refreshToken.length} '
        'needsRefresh=${needsRefresh(existing)} '
        'sessionExpired=${isSessionExpired(existing)} '
        'confidential=${_confidentialMode ? 'on' : 'off'}',
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

      _tokens = existing;
      _log('OAuth: restore — refreshing access token…');
      try {
        await _refreshCoalesced();
        if (_tokens != null) {
          _status = OAuthSessionStatus.signedIn;
          _errorMessage = null;
          _log(
            'OAuth: restore — refresh OK '
            'membership=${_tokens!.bungieMembershipId}',
          );
        }
      } on BungieOAuthException catch (e) {
        await _handleRefreshFailure(e, fromRestore: true);
      } on _TokenPersistFailed {
        // Already signed out inside _persistTokensOrSignOut.
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

  /// Saves the Confidential app credential (Credential Manager). Does not log it.
  Future<void> saveClientCredential(String value) async {
    await _credentialStore.write(value);
    await _refreshConfidentialFlag();
    notifyListeners();
  }

  /// Removes the Confidential app credential. Tokens are left untouched.
  Future<void> forgetClientCredential() async {
    await _credentialStore.clear();
    _promptForgetCredential = false;
    await _refreshConfidentialFlag();
    notifyListeners();
  }

  /// Runs [action] with a live access token.
  ///
  /// On Platform/HTTP 401: at most one coalesced refresh, then one retry.
  /// A second 401 on that retry, `invalid_grant`, or `invalid_client` forces
  /// sign-in (and prompts Forget credential for `invalid_client`). Network
  /// errors keep tokens. Concurrent callers share one in-flight refresh.
  Future<T> runAuthorized<T>(
    Future<T> Function(String accessToken) action,
  ) async {
    if (_tokens == null) {
      throw const BungieConfigException('Not signed in');
    }
    if (needsRefresh(_tokens!)) {
      await _refreshCoalesced();
    }
    final first = _tokens;
    if (first == null) {
      throw const BungieConfigException('Not signed in');
    }
    try {
      return await action(first.accessToken);
    } catch (e) {
      if (!_isUnauthorized(e)) rethrow;
      try {
        await _refreshCoalesced();
      } on BungieOAuthException catch (oauthErr) {
        await _handleRefreshFailure(oauthErr, fromRestore: false);
        rethrow;
      }
      final second = _tokens;
      if (second == null) {
        throw const BungieConfigException('Not signed in');
      }
      try {
        return await action(second.accessToken);
      } catch (e2) {
        if (_isUnauthorized(e2)) {
          await _forceSignOutForAuthFailure(invalidClient: false);
        }
        rethrow;
      }
    }
  }

  Future<void> _refreshConfidentialFlag() async {
    try {
      _confidentialMode = await _credentialStore.hasCredential
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      // Plugin missing / hung in flutter_tester — treat as Public.
      _confidentialMode = false;
    }
  }

  Future<String?> _readCredentialSafe() async {
    try {
      return await _credentialStore.read()
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      return null;
    }
  }

  /// Shared in-flight refresh — concurrent callers await the same Future.
  Future<void> _refreshCoalesced() {
    final existing = _refreshInFlight;
    if (existing != null) return existing;
    final future = _refreshOnce();
    _refreshInFlight = future.whenComplete(() {
      _refreshInFlight = null;
    });
    return _refreshInFlight!;
  }

  Future<void> _refreshOnce() async {
    final current = _tokens;
    if (current == null || current.refreshToken.isEmpty) {
      throw const BungieConfigException('refresh_token must be non-empty');
    }
    final credential = await _readCredentialSafe();
    final refreshed = await _oauthClient
        .refreshTokens(current, appCredential: credential)
        .timeout(
          const Duration(seconds: 45),
          onTimeout: () => throw const BungieOAuthException(
            'Token refresh timed out after 45s',
          ),
        );
    await _persistTokensOrSignOut(refreshed);
  }

  Future<void> _persistTokensOrSignOut(BungieTokens tokens) async {
    try {
      await _tokenStore.write(tokens).timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw const BungieOAuthException(
              'Secure token storage write timed out',
            ),
          );
      _tokens = tokens;
      _status = OAuthSessionStatus.signedIn;
      _errorMessage = null;
    } catch (e) {
      _log(
        'OAuth: token persist failed — signing out (${e.runtimeType})',
      );
      try {
        await _tokenStore.clearSecureOnly();
      } catch (_) {}
      _tokens = null;
      _status = OAuthSessionStatus.signedOut;
      _errorMessage = 'Could not save session securely. Please sign in again.';
      notifyListeners();
      throw const _TokenPersistFailed();
    }
  }

  Future<void> _handleRefreshFailure(
    BungieOAuthException e, {
    required bool fromRestore,
  }) async {
    final msg = e.message.toLowerCase();
    final invalidClient = msg.contains('invalid_client');
    final definitive = invalidClient ||
        msg.contains('invalid_grant') ||
        msg.contains('invalid_token') ||
        (e.statusCode != null &&
            (e.statusCode == 400 || e.statusCode == 401));
    _log(
      'OAuth: refresh failed definitive=$definitive '
      'invalid_client=$invalidClient type=${e.runtimeType}',
    );
    if (definitive) {
      await _forceSignOutForAuthFailure(invalidClient: invalidClient);
      return;
    }
    // Network / transient — keep stored tokens.
    _tokens = null;
    _status = OAuthSessionStatus.error;
    _errorMessage = fromRestore
        ? 'Could not refresh session (network). Try again when online — '
            'you should not need to re-authorize.'
        : 'Could not refresh session (network). Try again when online.';
    notifyListeners();
  }

  Future<void> _forceSignOutForAuthFailure({
    required bool invalidClient,
  }) async {
    try {
      await _tokenStore.clearSecureOnly();
    } catch (_) {}
    _tokens = null;
    _status = OAuthSessionStatus.signedOut;
    _promptForgetCredential = invalidClient;
    _errorMessage = invalidClient
        ? 'Bungie rejected the app credential. Forget client secret and '
            'paste a new one, then sign in again.'
        : null;
    notifyListeners();
  }

  static bool _isUnauthorized(Object e) {
    if (e is BungieHttpException && e.statusCode == 401) return true;
    if (e is BungiePlatformException && e.statusCode == 401) return true;
    return false;
  }

  void _throwIfSignInCancelled() {
    if (_signInCancelled) {
      throw const OAuthSignInFailure(OAuthSignInFailureKind.cancelled);
    }
  }

  /// Rewrites [prior] into Locker, or clears secure storage when null.
  ///
  /// Call only when this sign-in attempt actually wrote (`didWrite`).
  Future<void> _rollbackSecureStore(BungieTokens? prior) async {
    try {
      if (prior != null) {
        await _tokenStore.write(prior);
      } else {
        await _tokenStore.clearSecureOnly();
      }
    } catch (_) {}
  }

  Future<void> _rollbackIfWrote({
    required bool didWrite,
    required BungieTokens? priorLockerTokens,
  }) async {
    if (!didWrite) return;
    await _rollbackSecureStore(priorLockerTokens);
  }

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
    // Block overlap until the previous signIn `finally` has finished — even
    // if status already flipped away from signingIn (e.g. mid-cancel).
    if (_signInBusy || _status == OAuthSessionStatus.signingIn) {
      return;
    }
    _signInBusy = true;

    // In-memory signed-in snapshot (re-sign-in while already signed in).
    final priorMemoryTokens = isSignedIn ? _tokens : null;
    // Locker snapshot independent of status — restore() may leave good Locker
    // tokens while status is error (transient refresh / storage failure).
    // Cancel must not clear those unless this attempt wrote.
    final priorLockerTokens = await _tokenStore.readSecureOnly();
    var didWrite = false;

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
      if (!isAllowedBungieAuthorizeUrl(authorizeUrl)) {
        _pendingAuthorizeUrl = null;
        throw const OAuthSignInFailure(
          OAuthSignInFailureKind.unsafeAuthorizeUrl,
        );
      }
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

      _throwIfSignInCancelled();

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
          OAuthSignInFailureKind.missingAuthorizationCode,
        );
      }
      final returnedState = callback.state ?? '';
      if (!validateOAuthState(
        expected: pending.state,
        actual: returnedState,
      )) {
        throw const OAuthSignInFailure(OAuthSignInFailureKind.stateMismatch);
      }

      _throwIfSignInCancelled();

      _log('OAuth: exchanging code for tokens…');
      final BungieTokens tokens;
      final exchangeCredential = await _readCredentialSafe();
      try {
        tokens = await _oauthClient
            .exchangeCode(
              code: callback.code!,
              codeVerifier: pending.codeVerifier,
              appCredential: exchangeCredential,
            )
            .timeout(
              const Duration(seconds: 45),
              onTimeout: () => throw const OAuthSignInFailure(
                OAuthSignInFailureKind.tokenExchangeFailed,
              ),
            );
      } on OAuthSignInFailure {
        rethrow;
      } on BungieOAuthException catch (e) {
        final msg = e.message.toLowerCase();
        if (msg.contains('invalid_client')) {
          _promptForgetCredential = true;
        }
        throw const OAuthSignInFailure(
          OAuthSignInFailureKind.tokenExchangeFailed,
        );
      } catch (e) {
        if (_signInCancelled) {
          throw const OAuthSignInFailure(OAuthSignInFailureKind.cancelled);
        }
        if (_isNetworkFailure(e)) {
          throw const OAuthSignInFailure(
            OAuthSignInFailureKind.networkUnreachable,
          );
        }
        throw const OAuthSignInFailure(
          OAuthSignInFailureKind.tokenExchangeFailed,
        );
      }

      // Cancel after callback/exchange must not write Locker.
      _throwIfSignInCancelled();

      _log(
        'OAuth: token exchange OK accessLen=${tokens.accessToken.length} '
        'refreshLen=${tokens.refreshToken.length} '
        'membership=${tokens.bungieMembershipId} '
        'confidential=${_confidentialMode ? 'on' : 'off'}; '
        'writing secure storage…',
      );
      if (tokens.refreshToken.isEmpty) {
        // Bungie portal docs: Public clients are not issued refresh_token.
        // Confidential gets ~90d refresh. Live API re-auth ~hourly without it;
        // local inventory browse must not depend on this (see OwnedCatalogBridge).
        _log(
          'OAuth: empty refresh_token (Bungie Public clients do not receive one) — '
          'live access lasts ~1h; re-sign-in only required for Sync/API, not local Owned',
        );
      }
      await _persistTokensOrSignOut(tokens);
      didWrite = true;

      // Cancel between write and verify → roll Locker back to pre-write snapshot.
      _throwIfSignInCancelled();

      // Secure store only — DualTokenStore.read() could migrate+delete sidecar
      // if the Locker write did not stick.
      final verified = await _tokenStore.readSecureOnly();
      if (verified == null ||
          verified.accessToken != tokens.accessToken ||
          verified.bungieMembershipId != tokens.bungieMembershipId) {
        await _rollbackIfWrote(
          didWrite: didWrite,
          priorLockerTokens: priorLockerTokens,
        );
        throw const BungieOAuthException(
          'Secure token storage write did not persist (read-back failed)',
        );
      }

      // Verified Locker write is committed. A cancel arriving after verify
      // completes is treated as a completed sign-in — do not roll back a
      // verified write the user already authorized via Bungie.

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
      final failureKind = e is OAuthSignInFailure ? e.kind : null;
      if (e is _TokenPersistFailed) {
        // Already signed out by _persistTokensOrSignOut — keep that state.
        _lastFailureKind = OAuthSignInFailureKind.tokenExchangeFailed;
      } else if (_signInCancelled ||
          (e is OAuthSignInFailure &&
              e.kind == OAuthSignInFailureKind.cancelled &&
              _status == OAuthSessionStatus.signedOut)) {
        // User cancel already applied signed-out; do not flip to error.
        // Touch Locker only if this attempt wrote — never clearSecureOnly on
        // cancel when status was error with untouched Locker credentials.
        await _rollbackIfWrote(
          didWrite: didWrite,
          priorLockerTokens: priorLockerTokens,
        );
        if (priorMemoryTokens != null) {
          _tokens = priorMemoryTokens;
          _status = OAuthSessionStatus.signedIn;
          _errorMessage = null;
          _lastFailureKind = OAuthSignInFailureKind.cancelled;
        } else {
          _tokens = null;
          _status = OAuthSessionStatus.signedOut;
          _errorMessage = null;
          _lastFailureKind = OAuthSignInFailureKind.cancelled;
        }
      } else if (priorMemoryTokens != null) {
        // Failed re-sign-in while memory was signed-in: restore both layers.
        await _rollbackIfWrote(
          didWrite: didWrite,
          priorLockerTokens: priorLockerTokens,
        );
        _tokens = priorMemoryTokens;
        _status = OAuthSessionStatus.signedIn;
        _errorMessage = _safeErrorMessage(e);
        _lastFailureKind = failureKind;
      } else {
        _tokens = null;
        _status = OAuthSessionStatus.error;
        _errorMessage = _safeErrorMessage(e);
        _lastFailureKind = failureKind;
        // Roll back / clear Locker only if this attempt wrote. If we never
        // wrote, leave existing Locker credentials (e.g. status=error after
        // transient refresh) untouched — do not wipe a migration sidecar.
        await _rollbackIfWrote(
          didWrite: didWrite,
          priorLockerTokens: priorLockerTokens,
        );
      }
    } finally {
      _pendingAuthorizeUrl = null;
      _signInCancelGate = null;
      if (loopbackStarted) {
        try {
          await _loopback.stop();
        } catch (_) {}
      }
      _signInBusy = false;
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
  ///
  /// Keeps any Confidential app credential (use [forgetClientCredential]).
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
        OAuthSignInFailureKind.missingAuthorizationCode =>
          "Bungie didn't send a sign-in code - try again.",
        OAuthSignInFailureKind.unsafeAuthorizeUrl =>
          kUnsafeAuthorizeUrlMessage,
      };
    }
    if (e is TimeoutException) {
      return 'Sign-in timed out waiting for Bungie. Please try again.';
    }
    if (_isNetworkFailure(e)) {
      return 'Network unavailable. Check your connection and try again.';
    }
    // Fixed text only — never echo exception type/message (may leak secrets).
    return 'Sign-in failed - please try again.';
  }

  static bool _isNetworkFailure(Object e) {
    return e is SocketException ||
        e is HandshakeException ||
        e is HttpException ||
        e is TlsException ||
        e is OSError;
  }
}

/// Marker: token pair could not be persisted after a successful grant.
class _TokenPersistFailed implements Exception {
  const _TokenPersistFailed();
}
