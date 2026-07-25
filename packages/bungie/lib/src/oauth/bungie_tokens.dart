/// Access-token expiry safety margin applied when mapping `expires_in`.
const Duration kAccessTokenExpiryMargin = Duration(seconds: 60);

/// Bungie OAuth token set for a signed-in user (runtime only).
///
/// Persistence is a host concern (secure storage in DART-023+). This model
/// must never include a client secret field.
class BungieTokens {
  const BungieTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.refreshExpiresAt,
    required this.bungieMembershipId,
  });

  final String accessToken;
  final String refreshToken;

  /// When the access token should be treated as expired (UTC).
  final DateTime expiresAt;

  /// When the refresh token expires (UTC).
  final DateTime refreshExpiresAt;

  final String bungieMembershipId;

  BungieTokens copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    DateTime? refreshExpiresAt,
    String? bungieMembershipId,
  }) {
    return BungieTokens(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      refreshExpiresAt: refreshExpiresAt ?? this.refreshExpiresAt,
      bungieMembershipId: bungieMembershipId ?? this.bungieMembershipId,
    );
  }
}

/// `true` when the access token is at/ past [BungieTokens.expiresAt].
bool needsRefresh(BungieTokens tokens, {DateTime? now}) {
  final clock = now ?? DateTime.now().toUtc();
  return !tokens.expiresAt.toUtc().isAfter(clock);
}

/// `true` when the refresh token is at/ past [BungieTokens.refreshExpiresAt].
bool isSessionExpired(BungieTokens tokens, {DateTime? now}) {
  final clock = now ?? DateTime.now().toUtc();
  return !tokens.refreshExpiresAt.toUtc().isAfter(clock);
}

/// Maps a Bungie OAuth token JSON object to [BungieTokens].
///
/// Expected keys: `access_token`, `expires_in`, `refresh_token`,
/// `refresh_expires_in`, `membership_id`.
BungieTokens mapTokenResponse(
  Map<String, dynamic> raw, {
  DateTime? now,
}) {
  final access = raw['access_token'];
  final refresh = raw['refresh_token'];
  final expiresIn = raw['expires_in'];
  final refreshExpiresIn = raw['refresh_expires_in'];
  final membershipId = raw['membership_id'];

  if (access is! String ||
      access.isEmpty ||
      refresh is! String ||
      refresh.isEmpty ||
      membershipId is! String ||
      membershipId.isEmpty ||
      expiresIn is! num ||
      refreshExpiresIn is! num) {
    throw const FormatException(
      'Bungie token response has unexpected shape',
    );
  }

  final clock = now ?? DateTime.now().toUtc();
  final accessTtl = Duration(seconds: expiresIn.round());
  final refreshTtl = Duration(seconds: refreshExpiresIn.round());

  return BungieTokens(
    accessToken: access,
    refreshToken: refresh,
    expiresAt: clock.add(accessTtl).subtract(kAccessTokenExpiryMargin),
    refreshExpiresAt: clock.add(refreshTtl),
    bungieMembershipId: membershipId,
  );
}
