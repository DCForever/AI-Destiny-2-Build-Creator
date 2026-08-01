import '../profile/profile_types.dart';

/// Human-readable inventory sync diagnostics (Next `formatSyncDiagnostics` parity).
///
/// Used by Settings hosts (DART-053 / GAP-INV-04) so raw/parsed/dropped/resolution
/// counts are visible after sync — not only itemCount.
String formatSyncDiagnostics(InventoryParseDiagnostics diagnostics) {
  final lines = <String>[
    'Bungie raw items: ${_fmt(diagnostics.raw.total)}',
    'Parsed from Bungie: ${_fmt(diagnostics.parsed.total)} '
        '(${_fmt(diagnostics.parsed.equipmentTotal)} weapons/armor incl. vault containers, '
        '${diagnostics.parsed.subclassTotal} subclasses)',
    'Dropped: ${_fmt(diagnostics.dropped.total)} '
        '(unknown bucket: ${diagnostics.dropped.unknownBucket}, '
        'missing instance id: ${diagnostics.dropped.missingInstanceId})',
  ];

  final resolution = diagnostics.resolution;
  if (resolution != null) {
    lines.add(
      'Stored after resolution: ${_fmt(resolution.storedTotal)} '
      '(${_fmt(resolution.storedEquipment)} weapons/armor; '
      '${_fmt(resolution.resolvedFromTransfer)} from vault/postmaster, '
      '${_fmt(resolution.droppedNonEquipment)} non-equipment dropped)',
    );
  }

  final unknownBuckets = diagnostics.dropped.unknownBuckets.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  if (unknownBuckets.isNotEmpty) {
    final top = unknownBuckets.take(8).map((e) => '  bucket ${e.key}: ${e.value}').join('\n');
    lines.add('Top unknown buckets:\n$top');
  }

  return lines.join('\n');
}

String _fmt(int n) {
  // Locale-agnostic thousands separators matching common Next toLocaleString output
  // for en-US style counts (optional polish; keeps tests stable).
  final s = n.toString();
  if (s.length <= 3) return s;
  final buf = StringBuffer();
  var i = 0;
  final start = s.length % 3;
  if (start > 0) {
    buf.write(s.substring(0, start));
    if (s.length > start) buf.write(',');
  }
  for (i = start; i < s.length; i += 3) {
    buf.write(s.substring(i, i + 3));
    if (i + 3 < s.length) buf.write(',');
  }
  return buf.toString();
}
