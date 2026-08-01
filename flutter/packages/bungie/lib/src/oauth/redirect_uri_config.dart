import '../bungie_errors.dart';

/// Platforms that register distinct OAuth `redirect_uri` values.
enum OAuthRedirectPlatform {
  /// Flutter Windows loopback (e.g. `http://127.0.0.1:<port>/callback`).
  windows,

  /// Android custom scheme / app link.
  android,

  /// iOS custom scheme / universal link.
  ios,

  /// Jaspr / browser HTTPS origin callback.
  web,
}

/// Host-supplied map of platform → registered Bungie Public app redirect URI.
///
/// Values are not secrets, but must match the Bungie application configuration.
/// This package does not open browsers or bind ports.
class PlatformRedirectUriConfig {
  PlatformRedirectUriConfig(Map<OAuthRedirectPlatform, String> uris)
      : _uris = Map.unmodifiable(_validate(uris));

  final Map<OAuthRedirectPlatform, String> _uris;

  /// Registered platforms.
  Iterable<OAuthRedirectPlatform> get platforms => _uris.keys;

  /// Returns the redirect URI for [platform], or throws if missing.
  String resolve(OAuthRedirectPlatform platform) {
    final uri = _uris[platform];
    if (uri == null) {
      throw BungieConfigException(
        'No OAuth redirect_uri configured for platform ${platform.name}',
      );
    }
    return uri;
  }

  /// Whether [platform] has a registered URI.
  bool has(OAuthRedirectPlatform platform) => _uris.containsKey(platform);

  static Map<OAuthRedirectPlatform, String> _validate(
    Map<OAuthRedirectPlatform, String> uris,
  ) {
    if (uris.isEmpty) {
      throw const BungieConfigException(
        'PlatformRedirectUriConfig requires at least one redirect_uri',
      );
    }
    final out = <OAuthRedirectPlatform, String>{};
    for (final entry in uris.entries) {
      final value = entry.value.trim();
      if (value.isEmpty) {
        throw BungieConfigException(
          'OAuth redirect_uri for ${entry.key.name} must be non-empty',
        );
      }
      out[entry.key] = value;
    }
    return out;
  }
}
