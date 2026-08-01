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
/// Bungie typically returns:
/// `access_token`, `token_type`, `expires_in`, `refresh_token`,
/// `refresh_expires_in`, `membership_id`.
///
/// Tolerances for real-world responses:
/// - numeric fields may be [num] **or** numeric [String]
/// - `membership_id` may be [String] or [num]
/// - `refresh_token` / `refresh_expires_in` may be omitted (access-only session)
BungieTokens mapTokenResponse(
  Map<String, dynamic> raw, {
  DateTime? now,
}) {
  final access = _asNonEmptyString(raw['access_token']);
  final refresh = _asNonEmptyString(raw['refresh_token']) ?? '';
  final expiresIn = _asPositiveSeconds(raw['expires_in']);
  final refreshExpiresIn = _asPositiveSeconds(raw['refresh_expires_in']);
  final membershipId = _asNonEmptyString(raw['membership_id']) ??
      _asNonEmptyString(raw['membershipId']);

  if (access == null || expiresIn == null || membershipId == null) {
    throw FormatException(
      'Bungie token response has unexpected shape '
      '(${_shapeDiagnostic(raw)}; '
      'need access_token+expires_in+membership_id; '
      'refresh optional)',
    );
  }

  final clock = now ?? DateTime.now().toUtc();
  final accessTtl = Duration(seconds: expiresIn);
  // If Bungie omits refresh lifetime, keep session alive for access TTL only.
  final refreshTtl = refreshExpiresIn != null
      ? Duration(seconds: refreshExpiresIn)
      : accessTtl;

  return BungieTokens(
    accessToken: access,
    refreshToken: refresh,
    expiresAt: clock.add(accessTtl).subtract(kAccessTokenExpiryMargin),
    refreshExpiresAt: clock.add(refreshTtl),
    bungieMembershipId: membershipId,
  );
}

String? _asNonEmptyString(Object? value) {
  if (value is String) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }
  if (value is num) {
    return value.toString();
  }
  return null;
}

/// Parses OAuth lifetime fields that may be JSON numbers or numeric strings.
int? _asPositiveSeconds(Object? value) {
  if (value is num) {
    final n = value.round();
    return n > 0 ? n : null;
  }
  if (value is String) {
    final n = int.tryParse(value.trim());
    if (n != null && n > 0) return n;
  }
  return null;
}

/// Safe diagnostic: key names + runtime types only (never token values).
String _shapeDiagnostic(Map<String, dynamic> raw) {
  if (raw.isEmpty) return 'empty object';
  final parts = <String>[];
  for (final e in raw.entries) {
    final v = e.value;
    final typeName = v == null ? 'null' : v.runtimeType.toString();
    parts.add('${e.key}:$typeName');
  }
  return parts.join(', ');
}
