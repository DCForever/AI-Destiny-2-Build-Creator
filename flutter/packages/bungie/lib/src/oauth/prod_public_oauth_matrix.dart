import '../bungie_errors.dart';
import 'redirect_uri_config.dart';

/// Recommended Bungie portal label for the production Public application.
///
/// Operator-owned display name; redirect strings below are the registration
/// contract (DART-058 / GAP-AUTH-01).
const String kProdPublicBungieAppName = 'Destiny2BuildCreator-Public';

/// Windows Flutter production redirect — HTTPS loopback (self-signed local cert).
///
/// Must match Bungie Public app registration **exactly**.
const String kProdWindowsRedirectUri = 'https://127.0.0.1:8765/callback';

/// Fixed browser callback path for Jaspr / web host (DART-045 / DART-058).
const String kProdWebOAuthCallbackPath = '/auth/callback';

/// Android custom-scheme redirect for Bungie Public app registration.
const String kProdAndroidRedirectUri = 'd2buildcreator://oauth/callback';

/// iOS custom-scheme redirect for Bungie Public app registration.
///
/// Same string as Android to keep one portal entry when both platforms ship
/// the shared scheme (DART-058 assumption A5).
const String kProdIosRedirectUri = 'd2buildcreator://oauth/callback';

/// Shared mobile scheme redirect (Android + iOS).
const String kProdMobileRedirectUri = 'd2buildcreator://oauth/callback';

/// Builds the Jaspr production redirect for a deployed HTTPS [origin].
///
/// Example: `https://buildcreator.example` →
/// `https://buildcreator.example/auth/callback`.
String prodWebRedirectUri(String origin) {
  final trimmed = origin.trim();
  if (trimmed.isEmpty) {
    throw const BungieConfigException(
      'Web OAuth origin must be non-empty to build prod redirect_uri',
    );
  }
  final base = trimmed.endsWith('/')
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;
  return '$base$kProdWebOAuthCallbackPath';
}

/// Whether [platform] is cutover-required for RC-AUTH live sign-in smoke.
///
/// Windows + web are required; mobile schemes are published but live smoke
/// is N/A until a mobile OAuth session ships.
bool isCutoverRequiredOAuthPlatform(OAuthRedirectPlatform platform) {
  switch (platform) {
    case OAuthRedirectPlatform.windows:
    case OAuthRedirectPlatform.web:
      return true;
    case OAuthRedirectPlatform.android:
    case OAuthRedirectPlatform.ios:
      return false;
  }
}

/// Published production Public OAuth redirect matrix (DART-058).
///
/// Single Bungie Public application registers all URIs (D-BUNGIE hybrid).
/// Confidential Next secrets stay server-only; clients use Public+PKCE only.
class ProdPublicOAuthMatrix {
  const ProdPublicOAuthMatrix._();

  /// Exact redirect URI for [platform].
  ///
  /// For [OAuthRedirectPlatform.web], pass [webOrigin] (production HTTPS origin).
  static String redirectUri(
    OAuthRedirectPlatform platform, {
    String? webOrigin,
  }) {
    switch (platform) {
      case OAuthRedirectPlatform.windows:
        return kProdWindowsRedirectUri;
      case OAuthRedirectPlatform.android:
        return kProdAndroidRedirectUri;
      case OAuthRedirectPlatform.ios:
        return kProdIosRedirectUri;
      case OAuthRedirectPlatform.web:
        final origin = webOrigin?.trim() ?? '';
        if (origin.isEmpty) {
          throw const BungieConfigException(
            'webOrigin is required for OAuthRedirectPlatform.web',
          );
        }
        return prodWebRedirectUri(origin);
    }
  }

  /// All platforms covered by the published matrix.
  static const List<OAuthRedirectPlatform> platforms = [
    OAuthRedirectPlatform.windows,
    OAuthRedirectPlatform.web,
    OAuthRedirectPlatform.android,
    OAuthRedirectPlatform.ios,
  ];

  /// Builds a [PlatformRedirectUriConfig] for host injection.
  ///
  /// [webOrigin] is required for the web entry.
  static PlatformRedirectUriConfig asPlatformConfig({
    required String webOrigin,
  }) {
    return PlatformRedirectUriConfig({
      OAuthRedirectPlatform.windows: kProdWindowsRedirectUri,
      OAuthRedirectPlatform.web: prodWebRedirectUri(webOrigin),
      OAuthRedirectPlatform.android: kProdAndroidRedirectUri,
      OAuthRedirectPlatform.ios: kProdIosRedirectUri,
    });
  }

  /// Operator-facing rows for docs / Settings copy (no secrets).
  static List<ProdPublicOAuthMatrixRow> rows({
    String webOriginPlaceholder = 'https://YOUR_JASPR_ORIGIN',
  }) {
    return [
      ProdPublicOAuthMatrixRow(
        platform: OAuthRedirectPlatform.windows,
        redirectUri: kProdWindowsRedirectUri,
        cutoverRequired: true,
        notes: 'HTTPS loopback; self-signed certs/loopback-*.pem',
      ),
      ProdPublicOAuthMatrixRow(
        platform: OAuthRedirectPlatform.web,
        redirectUri: prodWebRedirectUri(webOriginPlaceholder),
        cutoverRequired: true,
        notes: 'Jaspr path $kProdWebOAuthCallbackPath under prod HTTPS origin',
      ),
      ProdPublicOAuthMatrixRow(
        platform: OAuthRedirectPlatform.android,
        redirectUri: kProdAndroidRedirectUri,
        cutoverRequired: false,
        notes: 'Custom scheme; host OAuth session deferred',
      ),
      ProdPublicOAuthMatrixRow(
        platform: OAuthRedirectPlatform.ios,
        redirectUri: kProdIosRedirectUri,
        cutoverRequired: false,
        notes: 'Custom scheme; host OAuth session deferred',
      ),
    ];
  }
}

/// One published matrix row (platform → redirect + ops notes).
class ProdPublicOAuthMatrixRow {
  const ProdPublicOAuthMatrixRow({
    required this.platform,
    required this.redirectUri,
    required this.cutoverRequired,
    required this.notes,
  });

  final OAuthRedirectPlatform platform;
  final String redirectUri;
  final bool cutoverRequired;
  final String notes;
}
