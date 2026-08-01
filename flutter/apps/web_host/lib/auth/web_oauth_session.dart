/// Browser Public+PKCE OAuth session for the Jaspr web host (DART-045).
library;

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:jaspr/jaspr.dart';

import 'pending_auth_store.dart';
import 'token_store.dart';
import 'web_auth_navigator.dart';
import 'web_oauth_config.dart';

/// High-level session status for Settings UI.
enum OAuthSessionStatus {
  signedOut,
  signingIn,
  signedIn,
  error,
}

/// Sign-in / sign-out orchestration for Jaspr web (Public+PKCE only).
///
/// Uses DART-022 [BungieOAuthClient] + same-origin callback + [TokenStore].
/// Injectable navigator / stores / transport keep CI free of live Bungie.
class WebOAuthSession extends ChangeNotifier {
  WebOAuthSession({
    required WebOAuthConfig config,
    required TokenStore tokenStore,
    required BungieOAuthClient oauthClient,
    required WebAuthNavigator navigator,
    PendingAuthStore? pendingAuthStore,
  })  : _config = config,
        _tokenStore = tokenStore,
        _oauthClient = oauthClient,
        _navigator = navigator,
        _pendingStore = pendingAuthStore ?? MemoryPendingAuthStore();

  final WebOAuthConfig _config;
  final TokenStore _tokenStore;
  final BungieOAuthClient _oauthClient;
  final WebAuthNavigator _navigator;
  final PendingAuthStore _pendingStore;

  OAuthSessionStatus _status = OAuthSessionStatus.signedOut;
  BungieTokens? _tokens;
  String? _errorMessage;
  bool _loaded = false;

  OAuthSessionStatus get status => _status;
  BungieTokens? get tokens => _tokens;
  String? get errorMessage => _errorMessage;
  bool get isSignedIn =>
      _tokens != null && _status == OAuthSessionStatus.signedIn;
  bool get isConfigured => _config.isConfigured;
  String get clientId => _config.clientId;
  String get redirectUri => _config.redirectUri;
  String? get membershipId => _tokens?.bungieMembershipId;
  bool get hasRestored => _loaded;

  /// Loads tokens from origin-scoped storage (call once after bootstrap).
  Future<void> restore() async {
    try {
      final existing = await _tokenStore.read();
      _tokens = existing;
      _status = existing != null
          ? OAuthSessionStatus.signedIn
          : OAuthSessionStatus.signedOut;
      _errorMessage = null;
    } catch (_) {
      _tokens = null;
      _status = OAuthSessionStatus.signedOut;
      _errorMessage = 'Could not restore session';
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  /// Starts Public+PKCE sign-in by navigating to Bungie authorize URL.
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

    try {
      final pkce = generatePkcePair();
      final state = generateOAuthState();
      final pending = OAuthPendingAuth(
        state: state,
        codeVerifier: pkce.codeVerifier,
        redirectUri: _config.redirectUri,
        createdAt: DateTime.now().toUtc(),
      );
      await _pendingStore.write(pending);

      final authorizeUrl = _oauthClient.buildAuthorizeUrl(
        state: state,
        codeChallenge: pkce.codeChallenge,
      );
      // Full navigation to Bungie; callback returns to /auth/callback.
      _navigator.assign(authorizeUrl);
    } catch (e) {
      _tokens = null;
      _status = OAuthSessionStatus.error;
      _errorMessage = _safeErrorMessage(e);
      try {
        await _pendingStore.clear();
      } catch (_) {}
      notifyListeners();
    }
  }

  /// Completes OAuth after landing on `/auth/callback` with query params.
  ///
  /// On success, stores tokens and navigates to [postAuthPath] (default Settings).
  Future<void> completeCallback({
    Uri? callbackUri,
    String postAuthPath = '/settings',
  }) async {
    final uri = callbackUri ?? _navigator.currentUri;
    final params = uri.queryParameters;

    _status = OAuthSessionStatus.signingIn;
    _errorMessage = null;
    notifyListeners();

    try {
      final error = params['error'];
      if (error != null && error.isNotEmpty) {
        final desc = params['error_description'];
        throw BungieOAuthException(
          (desc != null && desc.isNotEmpty)
              ? desc
              : 'Authorization failed ($error)',
        );
      }

      final code = params['code'];
      final returnedState = params['state'] ?? '';
      if (code == null || code.isEmpty) {
        throw const BungieOAuthException(
          'Authorization callback missing code',
        );
      }

      final pending = await _pendingStore.read();
      if (pending == null) {
        throw const BungieOAuthException(
          'No pending OAuth handoff (restart sign-in)',
        );
      }

      if (!validateOAuthState(
        expected: pending.state,
        actual: returnedState,
      )) {
        throw const BungieOAuthException(
          'OAuth state mismatch (CSRF validation failed)',
        );
      }

      final tokens = await _oauthClient.exchangeCode(
        code: code,
        codeVerifier: pending.codeVerifier,
      );
      await _tokenStore.write(tokens);
      await _pendingStore.clear();
      _tokens = tokens;
      _status = OAuthSessionStatus.signedIn;
      _errorMessage = null;
      notifyListeners();
      _navigator.assign(postAuthPath);
    } catch (e) {
      _tokens = null;
      _status = OAuthSessionStatus.error;
      _errorMessage = _safeErrorMessage(e);
      try {
        await _pendingStore.clear();
      } catch (_) {}
      try {
        await _tokenStore.clear();
      } catch (_) {}
      notifyListeners();
    }
  }

  /// Clears origin-scoped tokens and returns to signed-out.
  Future<void> signOut() async {
    try {
      await _tokenStore.clear();
      await _pendingStore.clear();
    } finally {
      _tokens = null;
      _status = OAuthSessionStatus.signedOut;
      _errorMessage = null;
      notifyListeners();
    }
  }

  static String _safeErrorMessage(Object e) {
    final text = e.toString();
    if (text.length > 240) {
      return '${text.substring(0, 240)}…';
    }
    return text;
  }
}
