/// Human-readable inventory last-sync labels (Next `formatInventorySync` parity).
///
/// DART-068 / GAP-UI-SETTINGS-02 / BUG-20260725-003.

/// Prefer full inventory sync timestamp, then optional user lastSyncAt.
String? resolveLastSyncIso({
  String? lastFullSyncAt,
  String? lastSyncAt,
}) {
  final full = lastFullSyncAt?.trim();
  if (full != null && full.isNotEmpty) return full;
  final last = lastSyncAt?.trim();
  if (last != null && last.isNotEmpty) return last;
  return null;
}

/// True when any sync timestamp is present (Settings ONLINE chip).
bool inventoryHasSynced({
  String? lastFullSyncAt,
  String? lastSyncAt,
}) =>
    resolveLastSyncIso(
      lastFullSyncAt: lastFullSyncAt,
      lastSyncAt: lastSyncAt,
    ) !=
    null;

/// Human-readable last sync for Settings Inventory panel.
///
/// Same calendar day → time only; else short month/day + time; null → `Never`.
String formatLastSyncLabel({
  String? lastFullSyncAt,
  String? lastSyncAt,
  DateTime? now,
}) {
  final iso = resolveLastSyncIso(
    lastFullSyncAt: lastFullSyncAt,
    lastSyncAt: lastSyncAt,
  );
  if (iso == null) return 'Never';
  final date = DateTime.tryParse(iso);
  if (date == null) return 'Never';

  final n = now ?? DateTime.now();
  final local = date.toLocal();
  final sameDay = local.year == n.year &&
      local.month == n.month &&
      local.day == n.day;

  final time = _formatTime(local);
  if (sameDay) return time;
  return '${_monthShort(local.month)} ${local.day}, $time';
}

String _formatTime(DateTime d) {
  final hour24 = d.hour;
  final minute = d.minute.toString().padLeft(2, '0');
  final isPm = hour24 >= 12;
  var hour12 = hour24 % 12;
  if (hour12 == 0) hour12 = 12;
  final suffix = isPm ? 'PM' : 'AM';
  return '$hour12:$minute $suffix';
}

String _monthShort(int month) {
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  if (month < 1 || month > 12) return '???';
  return names[month - 1];
}
