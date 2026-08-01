import 'dart:convert';

import 'package:destiny2_bungie/destiny2_bungie.dart';

/// JSON codec for [BungieTokens] secure-storage payloads (DART-023).
///
/// Keys match data-model.md — never log the encoded string in production UI.
String encodeBungieTokens(BungieTokens tokens) {
  return jsonEncode(<String, Object?>{
    'access_token': tokens.accessToken,
    'refresh_token': tokens.refreshToken,
    'expires_at': tokens.expiresAt.toUtc().toIso8601String(),
    'refresh_expires_at': tokens.refreshExpiresAt.toUtc().toIso8601String(),
    'membership_id': tokens.bungieMembershipId,
  });
}

/// Decodes tokens from secure-storage JSON. Returns `null` if corrupt/missing fields.
BungieTokens? decodeBungieTokens(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  try {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final map = Map<String, dynamic>.from(decoded);

    final access = map['access_token'];
    final refresh = map['refresh_token'];
    final membershipId = map['membership_id'];
    final expiresAtRaw = map['expires_at'];
    final refreshExpiresAtRaw = map['refresh_expires_at'];

    // Bungie Public OAuth does not issue refresh_token. Empty/omitted refresh
    // is valid; requiring non-empty made every cold start look signed-out while
    // access was still good (BUG-20260725-002).
    if (access is! String ||
        access.isEmpty ||
        membershipId is! String ||
        membershipId.isEmpty ||
        expiresAtRaw is! String ||
        refreshExpiresAtRaw is! String) {
      return null;
    }
    if (refresh != null && refresh is! String) {
      return null;
    }
    final refreshToken = refresh is String ? refresh : '';

    final expiresAt = DateTime.tryParse(expiresAtRaw)?.toUtc();
    final refreshExpiresAt = DateTime.tryParse(refreshExpiresAtRaw)?.toUtc();
    if (expiresAt == null || refreshExpiresAt == null) return null;

    return BungieTokens(
      accessToken: access,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      refreshExpiresAt: refreshExpiresAt,
      bungieMembershipId: membershipId,
    );
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  }
}
