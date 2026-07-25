import 'dart:convert';

import 'package:destiny2_domain/destiny2_domain.dart';

/// Advisory: soft never auto-applies; DIM export is owned pins only.
const String kDimExportSoftAdvisoryCaption =
    'Soft suggestions never auto-apply. DIM export requires equip-ready owned pins.';

/// Success status after clipboard write.
const String kDimExportCopiedStatus = 'Copied DIM loadout JSON';

/// Human label for one pin status (wishlist / pinned / stale).
String formatDimExportPinStatusLabel(PinStatus status) {
  final slot = status.slot.wireName;
  switch (status.status) {
    case PinStatusKind.wishlist:
      return '$slot: wishlist (needs owned instance pin)';
    case PinStatusKind.pinned:
      return '$slot: owned pin';
    case PinStatusKind.stale:
      final reason = status.reason?.wireName ?? 'stale';
      return '$slot: stale ($reason)';
  }
}

/// Short readiness summary for the DIM export panel.
String formatDimExportReadySummary(EquipReadyResult result) {
  if (result.equipReady) return 'Equip-ready — DIM export allowed';
  if (result.pinStatuses.isEmpty) {
    return 'Not equip-ready (no combat pins) — export blocked';
  }
  final gaps = result.pinStatuses
      .where((s) => s.status != PinStatusKind.pinned)
      .length;
  return 'Not equip-ready ($gaps gap${gaps == 1 ? '' : 's'}) — export blocked';
}

/// Whether Copy DIM JSON CTA should be enabled (UI gate; controller re-asserts).
bool canEnableDimExportCta({
  required bool equipReady,
  required bool exporting,
  required bool loading,
  required bool hasVariant,
}) {
  if (!hasVariant) return false;
  if (exporting || loading) return false;
  if (!equipReady) return false;
  return true;
}

/// Pretty-print a jsonOnly `{ loadout }` map for clipboard / preview.
String encodeDimExportJson(Map<String, Object?> payload) {
  return const JsonEncoder.withIndent('  ').convert(payload);
}

/// Truncate JSON for on-screen preview.
String truncateDimExportPreview(String json, {int maxChars = 480}) {
  if (json.length <= maxChars) return json;
  return '${json.substring(0, maxChars)}…';
}

/// Blocked message for NOT_EQUIP_READY style errors.
String formatDimExportBlockedMessage(EquipReadyResult? readiness) {
  if (readiness == null) return 'Not equip-ready — export blocked';
  return formatDimExportReadySummary(readiness);
}
