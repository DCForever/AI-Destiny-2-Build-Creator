/// User-authored weapon roll targets (Catalog ideal + anti-ideal).
///
/// Distinct from equip-ready **wishlist** (DBR-ROLL-* desired roll without pin).
/// Soft display scores only — never hard-blocks save/equip.
library;

/// One socket/trait column on a named roll target.
class RollTargetColumn {
  const RollTargetColumn({
    required this.columnKey,
    this.label,
    this.preferredPlugHashes = const {},
    this.avoidPlugHashes = const {},
  });

  /// Stable key (socket index string or category key).
  final String columnKey;
  final String? label;

  /// Multi-pick ideal plugs; empty → column not scored for preferred.
  final Set<int> preferredPlugHashes;

  /// Multi-pick anti-ideal plugs; empty → column not scored for avoid.
  final Set<int> avoidPlugHashes;

  /// Preferred and avoid must be disjoint.
  bool get hasPreferredAvoidOverlap =>
      preferredPlugHashes.intersection(avoidPlugHashes).isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RollTargetColumn &&
        other.columnKey == columnKey &&
        other.label == label &&
        _setEq(other.preferredPlugHashes, preferredPlugHashes) &&
        _setEq(other.avoidPlugHashes, avoidPlugHashes);
  }

  @override
  int get hashCode => Object.hash(
        columnKey,
        label,
        Object.hashAllUnordered(preferredPlugHashes),
        Object.hashAllUnordered(avoidPlugHashes),
      );
}

/// Named preferred + avoid profile for one weapon identity.
class WeaponRollTarget {
  const WeaponRollTarget({
    required this.id,
    required this.userId,
    required this.weaponKey,
    required this.name,
    this.columns = const [],
    this.updatedAtMs,
  });

  final String id;
  final String userId;

  /// MVP: definition hash as string (or family key later).
  final String weaponKey;
  final String name;
  final List<RollTargetColumn> columns;
  final int? updatedAtMs;

  bool get hasPreferredAvoidOverlap =>
      columns.any((c) => c.hasPreferredAvoidOverlap);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WeaponRollTarget) return false;
    if (other.id != id ||
        other.userId != userId ||
        other.weaponKey != weaponKey ||
        other.name != name ||
        other.updatedAtMs != updatedAtMs) {
      return false;
    }
    if (other.columns.length != columns.length) return false;
    for (var i = 0; i < columns.length; i++) {
      if (other.columns[i] != columns[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        weaponKey,
        name,
        updatedAtMs,
        Object.hashAll(columns),
      );
}

/// Preferred column outcome for UI.
enum PreferredColumnState {
  matched,
  miss,
  unscored,
}

/// Avoid column outcome for UI.
enum AvoidColumnState {
  hit,
  clear,
  unscored,
}

/// Pure score of one instance against a [WeaponRollTarget].
class RollTargetMatchResult {
  const RollTargetMatchResult({
    required this.preferredMatched,
    required this.preferredScored,
    required this.avoidHits,
    required this.avoidScored,
    this.preferredByColumn = const {},
    this.avoidByColumn = const {},
  });

  final int preferredMatched;
  final int preferredScored;
  final int avoidHits;
  final int avoidScored;
  final Map<String, PreferredColumnState> preferredByColumn;
  final Map<String, AvoidColumnState> avoidByColumn;

  double get preferredRatio =>
      preferredScored == 0 ? 0.0 : preferredMatched / preferredScored;

  double get avoidRatio =>
      avoidScored == 0 ? 0.0 : avoidHits / avoidScored;

  bool get isPerfectPreferred =>
      preferredScored > 0 && preferredMatched == preferredScored;

  bool get isCleanAvoid => avoidHits == 0;

  bool get hasAnyScoreDimension => preferredScored > 0 || avoidScored > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RollTargetMatchResult &&
        other.preferredMatched == preferredMatched &&
        other.preferredScored == preferredScored &&
        other.avoidHits == avoidHits &&
        other.avoidScored == avoidScored;
  }

  @override
  int get hashCode => Object.hash(
        preferredMatched,
        preferredScored,
        avoidHits,
        avoidScored,
      );
}

/// Owned instance row input for ranking (pure DTO).
class RollTargetInstanceInput {
  const RollTargetInstanceInput({
    required this.instanceId,
    required this.plugsByColumn,
    this.power,
    this.gearTier,
  });

  final String instanceId;

  /// columnKey → selected plug hash on that instance.
  final Map<String, int> plugsByColumn;
  final int? power;
  final int? gearTier;
}

/// Ranked owned instance with match result.
class RankedRollTargetInstance {
  const RankedRollTargetInstance({
    required this.instance,
    required this.match,
  });

  final RollTargetInstanceInput instance;
  final RollTargetMatchResult match;
}

bool _setEq(Set<int> a, Set<int> b) {
  if (a.length != b.length) return false;
  for (final v in a) {
    if (!b.contains(v)) return false;
  }
  return true;
}
