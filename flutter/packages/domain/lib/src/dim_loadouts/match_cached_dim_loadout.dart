import 'cached_dim_loadout.dart';

/// Result of binding a UI build card to one compiled DIM loadout.
///
/// Never returns an exotic-only guess — that path is [ambiguous] or [none].
enum CachedDimLoadoutMatchKind { matched, ambiguous, none }

/// Outcome of [matchCachedDimLoadout].
class CachedDimLoadoutMatch {
  const CachedDimLoadoutMatch._({
    required this.kind,
    this.loadout,
    this.ambiguousCount = 0,
  });

  factory CachedDimLoadoutMatch.matched(CachedDimLoadout loadout) {
    return CachedDimLoadoutMatch._(
      kind: CachedDimLoadoutMatchKind.matched,
      loadout: loadout,
    );
  }

  factory CachedDimLoadoutMatch.ambiguous(int count) {
    return CachedDimLoadoutMatch._(
      kind: CachedDimLoadoutMatchKind.ambiguous,
      ambiguousCount: count,
    );
  }

  factory CachedDimLoadoutMatch.none() {
    return const CachedDimLoadoutMatch._(kind: CachedDimLoadoutMatchKind.none);
  }

  final CachedDimLoadoutMatchKind kind;
  final CachedDimLoadout? loadout;
  final int ambiguousCount;

  /// UI copy when [kind] is [CachedDimLoadoutMatchKind.ambiguous].
  String get ambiguousLabel => 'ambiguous ($ambiguousCount loadouts)';
}

/// Parse `dim.gg/<shareId>` or `dim.gg/<shareId>/…` (optional scheme).
///
/// Returns null when the host is not dim.gg or the path has no share segment.
String? parseDimGgShareId(String? link) {
  if (link == null) return null;
  final trimmed = link.trim();
  if (trimmed.isEmpty) return null;

  var candidate = trimmed;
  if (!candidate.contains('://')) {
    candidate = 'https://$candidate';
  }
  final uri = Uri.tryParse(candidate);
  if (uri == null) return null;
  final host = uri.host.toLowerCase();
  if (host != 'dim.gg' && host != 'www.dim.gg') return null;
  final segments =
      uri.pathSegments.where((part) => part.isNotEmpty).toList(growable: false);
  if (segments.isEmpty) return null;
  final shareId = segments.first.trim();
  return shareId.isEmpty ? null : shareId;
}

/// Bind a card to a compiled loadout: shareId first, then exact name.
///
/// Exotic-only overlap never selects a row — returns [CachedDimLoadoutMatch.ambiguous]
/// with the exotic hit count (or [none] when there are no exotic hits either).
CachedDimLoadoutMatch matchCachedDimLoadout({
  required List<CachedDimLoadout> loadouts,
  String? dimLink,
  String? buildName,
  String? exoticName,
}) {
  final shareId = parseDimGgShareId(dimLink);
  if (shareId != null) {
    for (final row in loadouts) {
      if (row.shareId == shareId) {
        return CachedDimLoadoutMatch.matched(row);
      }
    }
  }

  final name = buildName?.trim() ?? '';
  if (name.isNotEmpty) {
    final byName = <CachedDimLoadout>[
      for (final row in loadouts)
        if (row.name == name) row,
    ];
    if (byName.length == 1) {
      return CachedDimLoadoutMatch.matched(byName.first);
    }
    if (byName.length > 1) {
      return CachedDimLoadoutMatch.ambiguous(byName.length);
    }
  }

  final exotic = exoticName?.trim() ?? '';
  if (exotic.isEmpty) return CachedDimLoadoutMatch.none();
  final exoticNeedle = exotic.toLowerCase();
  var exoticHits = 0;
  for (final row in loadouts) {
    final rowExotic = row.exotic?.name.trim().toLowerCase() ?? '';
    if (rowExotic == exoticNeedle) exoticHits++;
  }
  if (exoticHits >= 1) {
    return CachedDimLoadoutMatch.ambiguous(exoticHits);
  }
  return CachedDimLoadoutMatch.none();
}
