/// Pure display helpers for variant compose UI (DART-041 mobile).
///
/// Pin labels: absent/empty [instanceId] → wishlist; otherwise instance.

/// Wishlist vs instance pin label for a slot claim / set item.
String formatSlotPinLabel(String? instanceId) {
  final id = instanceId?.trim() ?? '';
  if (id.isEmpty) return 'wishlist';
  return 'instance';
}

/// Compact pin display: `wishlist` or `instance · <id>`.
String formatSlotPinDetail(String? instanceId) {
  final id = instanceId?.trim() ?? '';
  if (id.isEmpty) return 'wishlist';
  return 'instance · $id';
}

/// One-line attachment summary: `setName (mode)` or setId fallback.
String formatAttachmentSummary({
  required String setId,
  String? setName,
  required String mode,
}) {
  final name = setName?.trim();
  final label = (name != null && name.isNotEmpty) ? name : setId;
  final m = mode.trim().isEmpty ? 'live' : mode.trim();
  return '$label ($m)';
}

/// Join attachment summaries with ", ".
String formatAttachmentListSummary(
  Iterable<({String setId, String? setName, String mode})> attachments,
) {
  final parts = <String>[];
  for (final a in attachments) {
    parts.add(
      formatAttachmentSummary(
        setId: a.setId,
        setName: a.setName,
        mode: a.mode,
      ),
    );
  }
  return parts.join(', ');
}

/// User-facing hard-gate / use-case error text (trim; empty → generic).
String formatComposeError(String? message, {String fallback = 'Compose failed'}) {
  final m = message?.trim() ?? '';
  if (m.isEmpty) return fallback;
  return m;
}
