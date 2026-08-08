/// User-authored weapon roll targets (Catalog ideal + anti-ideal).
///
/// Distinct from equip-ready **wishlist** (DBR-ROLL-* desired roll without pin).
/// Soft display scores only — never hard-blocks save/equip.
///
/// **Identity (manifest SSoT):**
/// - **Plugs** (preferred/avoid) are Destiny inventory item **hashes**
///   (`DestinyInventoryItemDefinition` for the plug).
/// - **Columns** are weapon **socket indexes** from the item definition /
///   instance capture (`socket_N`), never free-form UI labels as the key.
library;

/// One socket column on a named roll target.
class RollTargetColumn {
  const RollTargetColumn({
    required this.columnKey,
    this.label,
    this.preferredPlugHashes = const {},
    this.avoidPlugHashes = const {},
  });

  /// Stable socket key: `socket_{socketIndex}` from Bungie item sockets.
  ///
  /// Display names (Barrel, Trait 1) live in [label] only — do not use labels
  /// as the key (they are not unique across weapons / can drift).
  final String columnKey;

  /// Optional UI label (Barrel, Trait 1) — not used for identity matching.
  final String? label;

  /// Multi-pick ideal plugs — **manifest plug item hashes**.
  /// Empty → column not scored for preferred.
  final Set<int> preferredPlugHashes;

  /// Multi-pick anti-ideal plugs — **manifest plug item hashes**.
  /// Empty → column not scored for avoid.
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

  /// True when every preferred multi-pick **column** has a hit on this copy.
  ///
  /// Independent of plug-level N/M (e.g. 3 ideals among 6 plugs still perfect
  /// if all three preferred sockets are satisfied). Green dual-seg tint uses
  /// this, not N==M.
  bool get isPerfectPreferred {
    final scored = preferredByColumn.values
        .where((s) => s != PreferredColumnState.unscored);
    if (scored.isEmpty) {
      // No preferred columns (avoid-only or empty target).
      return false;
    }
    return scored.every((s) => s == PreferredColumnState.matched);
  }

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

  /// columnKey → plug hash(es) on that instance for scoring.
  ///
  /// Values may be a single equipped [int] or a [Set]/[Iterable] of equipped +
  /// reusable plugs (plug-level multi-pick preferred/avoid).
  final Map<String, Object?> plugsByColumn;
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
