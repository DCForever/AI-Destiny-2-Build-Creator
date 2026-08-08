/// Pure score / rank for Catalog weapon roll targets (preferred + avoid).
///
/// Soft display only — never hard-blocks save/equip; soft never auto-applies.
library;

import '../models/roll_target.dart';

/// Optional plug-family expansion: hash → other hashes that count as the same
/// perk family (e.g. base ↔ enhanced, or multiple manifest plugs with the same
/// display name). When null/empty, match is hash-only.
typedef PlugFamilyLookup = Set<int> Function(int plugHash);

/// Normalize a plug display name for family matching.
///
/// Strips enhanced labels and collapses punctuation so "All-Star",
/// "All Star", and "Enhanced All-Star" share a family key.
String normalizePlugFamilyName(String raw) {
  var s = raw.trim().toLowerCase();
  if (s.isEmpty) return s;
  s = s.replaceAll(RegExp(r'\s*\(enhanced\)\s*$'), '');
  s = s.replaceAll(RegExp(r'^enhanced\s+'), '');
  s = s.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  return s;
}

/// Build [PlugFamilyLookup] grouping plug hashes by normalized display name.
///
/// Destiny often ships multiple item hashes for the same perk (random-roll
/// variants, enhanced tiers). Roll targets store the hash the user tapped;
/// scoring must still match other hashes that share that perk name.
PlugFamilyLookup buildPlugFamilyLookup(Map<int, String> nameByHash) {
  final byNorm = <String, Set<int>>{};
  final familyByHash = <int, Set<int>>{};
  for (final e in nameByHash.entries) {
    if (e.key == 0) continue;
    final norm = normalizePlugFamilyName(e.value);
    if (norm.isEmpty) {
      familyByHash.putIfAbsent(e.key, () => {e.key});
      continue;
    }
    byNorm.putIfAbsent(norm, () => <int>{}).add(e.key);
  }
  for (final members in byNorm.values) {
    final frozen = Set<int>.from(members);
    for (final h in frozen) {
      familyByHash[h] = frozen;
    }
  }
  return (int plugHash) => familyByHash[plugHash] ?? {plugHash};
}

/// Expand [hashes] with every family member known to [familyOf].
Set<int> expandHashesWithFamily(
  Set<int> hashes,
  PlugFamilyLookup familyOf,
) {
  if (hashes.isEmpty) return const {};
  final out = <int>{};
  for (final h in hashes) {
    out.addAll(familyOf(h));
  }
  return out;
}

/// Domain failure for invalid roll targets.
class RollTargetValidationException implements Exception {
  const RollTargetValidationException(
    this.message, {
    this.code = 'ROLL_TARGET_INVALID',
  });

  final String code;
  final String message;

  @override
  String toString() => 'RollTargetValidationException($code: $message)';
}

/// Whether roll targets (ideal/avoid) apply to this weapon (DBR-IDL-009).
///
/// Exotic weapons have fixed perks — no preferred/avoid multi-pick.
bool weaponAllowsRollTargets({required bool isExotic}) => !isExotic;

/// Rejects exotic weapons (DBR-IDL-009).
///
/// Throws [RollTargetValidationException] when [isExotic] is true.
void assertRollTargetsAllowedForWeapon({required bool isExotic}) {
  if (isExotic) {
    throw const RollTargetValidationException(
      'Exotic weapons have fixed perks and cannot have roll targets',
      code: 'ROLL_TARGET_EXOTIC_NOT_ALLOWED',
    );
  }
}

/// Validates preferred ∩ avoid is empty on every column.
///
/// Throws [RollTargetValidationException] when invalid.
///
/// Pass [isExotic] true to enforce DBR-IDL-009 (exotics disallowed).
void validateRollTarget(
  WeaponRollTarget target, {
  bool isExotic = false,
}) {
  assertRollTargetsAllowedForWeapon(isExotic: isExotic);
  for (final col in target.columns) {
    final overlap = col.preferredPlugHashes.intersection(col.avoidPlugHashes);
    if (overlap.isNotEmpty) {
      throw RollTargetValidationException(
        'Column ${col.columnKey} has plugs in both preferred and avoid: '
        '${overlap.join(', ')}',
        code: 'ROLL_TARGET_PREFERRED_AVOID_OVERLAP',
      );
    }
  }
}

/// Whether [instancePlug] matches any of [acceptable], optionally via family.
bool plugMatchesAcceptable(
  int instancePlug,
  Set<int> acceptable, {
  PlugFamilyLookup? familyOf,
}) {
  if (acceptable.isEmpty) return false;
  if (acceptable.contains(instancePlug)) return true;
  if (familyOf == null) return false;
  final family = familyOf(instancePlug);
  for (final h in family) {
    if (acceptable.contains(h)) return true;
  }
  // Also: instance is family member of an acceptable hash.
  for (final want in acceptable) {
    if (familyOf(want).contains(instancePlug)) return true;
  }
  return false;
}

Set<int> _coercePlugSet(Object? raw) {
  if (raw == null) return const {};
  if (raw is int) return raw == 0 ? const {} : {raw};
  if (raw is Set<int>) return raw.where((h) => h != 0).toSet();
  if (raw is Iterable) {
    return {
      for (final e in raw)
        if (e is int && e != 0)
          e
        else if (e is num && e.toInt() != 0)
          e.toInt(),
    };
  }
  final p = int.tryParse('$raw');
  if (p != null && p != 0) return {p};
  return const {};
}

/// Union of every plug on the instance (all columns, equipped + reusables).
Set<int> allPlugsOnInstance(Map<String, Object?> plugsByColumn) {
  final out = <int>{};
  for (final raw in plugsByColumn.values) {
    out.addAll(_coercePlugSet(raw));
  }
  return out;
}

/// Resolve plugs for a target column key, with fallbacks when keys diverge
/// across instances (socket_N vs Label@i) or are missing.
Set<int> resolvePlugsForColumnKey(
  Map<String, Object?> plugsByColumn,
  String columnKey, {
  String? label,
}) {
  // 1) Exact key
  if (plugsByColumn.containsKey(columnKey)) {
    return _coercePlugSet(plugsByColumn[columnKey]);
  }

  // 2) socket_N ↔ *@N / col_N
  final socketM = RegExp(r'^socket_(\d+)$').firstMatch(columnKey);
  if (socketM != null) {
    final n = socketM.group(1)!;
    for (final e in plugsByColumn.entries) {
      if (e.key == 'col_$n' || e.key.endsWith('@$n')) {
        return _coercePlugSet(e.value);
      }
    }
  }

  // 3) Label@N → socket_N / same base@N
  final atM = RegExp(r'^(.*)@(\d+)$').firstMatch(columnKey);
  if (atM != null) {
    final base = atM.group(1)!;
    final n = atM.group(2)!;
    final bySocket = plugsByColumn['socket_$n'];
    if (bySocket != null) return _coercePlugSet(bySocket);
    for (final e in plugsByColumn.entries) {
      if (e.key == 'col_$n') return _coercePlugSet(e.value);
      if (e.key.toLowerCase() == '${base.toLowerCase()}@$n') {
        return _coercePlugSet(e.value);
      }
    }
  }

  // 4) Unique label / kind prefix match
  final candidates = <String>{
    if (label != null && label.trim().isNotEmpty) label.trim().toLowerCase(),
    columnKey.toLowerCase(),
    if (atM != null) atM.group(1)!.toLowerCase(),
  };
  final hits = <MapEntry<String, Object?>>[];
  for (final e in plugsByColumn.entries) {
    final k = e.key.toLowerCase();
    final base = k.contains('@') ? k.split('@').first : k;
    for (final c in candidates) {
      if (c.isEmpty) continue;
      if (k == c || base == c || k.startsWith('$c@') || k.startsWith('l:$c')) {
        hits.add(e);
        break;
      }
    }
  }
  if (hits.length == 1) return _coercePlugSet(hits.first.value);

  // 5) Unresolved — empty (caller may fall back to full instance union)
  return const {};
}

/// Score one instance's plugs against a roll target.
///
/// **Identity:** preferred/avoid entries are **manifest plug item hashes**.
/// Column keys (`socket_N`) select which sockets on the copy are scored.
///
/// **Roll-quality dual segs** (what the chips show):
/// - Look at every plug **on this copy** in sockets that have preferred and/or
///   avoid multi-picks (equipped + reusables).
/// - **N/M** = how many of those plugs are **ideal** / how many plugs are on
///   those sockets (e.g. 3/6 = three good of six perks on Trait 1+2).
/// - **Av k** = how many of those plugs are **avoid**.
///
/// Neutral plugs (no preference) count in M but not in N or Av.
/// Example: Duty Bound 525 with 3 ideal + 3 avoid on the two trait columns →
/// `3/6` and `Av 3`; 487 with 3 ideal + 1 avoid among 4 plugs → `3/4` `Av 1`.
RollTargetMatchResult scoreInstanceAgainstTarget(
  WeaponRollTarget target,
  Map<String, Object?> plugsByColumn, {
  PlugFamilyLookup? familyOf,
}) {
  final preferredByColumn = <String, PreferredColumnState>{};
  final avoidByColumn = <String, AvoidColumnState>{};

  final allPreferred = <int>{
    for (final c in target.columns) ...c.preferredPlugHashes,
  };
  final allAvoid = <int>{
    for (final c in target.columns) ...c.avoidPlugHashes,
  };
  final hasAvoidInTarget = allAvoid.isNotEmpty;
  final hasPreferredInTarget = allPreferred.isNotEmpty;

  // Plugs on this copy that sit in scored sockets (preferred and/or avoid set).
  final scoredPlugs = <int>{};
  for (final col in target.columns) {
    final key = col.columnKey;
    final hasPref = col.preferredPlugHashes.isNotEmpty;
    final hasAv = col.avoidPlugHashes.isNotEmpty;
    if (!hasPref && !hasAv) {
      preferredByColumn[key] = PreferredColumnState.unscored;
      avoidByColumn[key] = AvoidColumnState.unscored;
      continue;
    }

    var plugs = resolvePlugsForColumnKey(
      plugsByColumn,
      col.columnKey,
      label: col.label,
    );
    // Key miss: fall back to whole-copy plugs so we still classify by hash.
    if (plugs.isEmpty) {
      plugs = allPlugsOnInstance(plugsByColumn);
    }
    scoredPlugs.addAll(plugs);

    // Per-column state for UI (any ideal/avoid on this socket's plugs).
    if (hasPref) {
      final hit = plugs.any(
        (h) => plugMatchesAcceptable(
          h,
          col.preferredPlugHashes,
          familyOf: familyOf,
        ),
      );
      preferredByColumn[key] =
          hit ? PreferredColumnState.matched : PreferredColumnState.miss;
    } else {
      preferredByColumn[key] = PreferredColumnState.unscored;
    }
    if (hasAv) {
      final hit = plugs.any(
        (h) => plugMatchesAcceptable(
          h,
          col.avoidPlugHashes,
          familyOf: familyOf,
        ),
      );
      avoidByColumn[key] =
          hit ? AvoidColumnState.hit : AvoidColumnState.clear;
    } else {
      avoidByColumn[key] = AvoidColumnState.unscored;
    }
  }

  // If every scored socket failed to resolve, use full copy as last resort.
  final plugsToClassify = scoredPlugs.isNotEmpty
      ? scoredPlugs
      : allPlugsOnInstance(plugsByColumn);

  var good = 0;
  var bad = 0;
  for (final h in plugsToClassify) {
    final isGood = plugMatchesAcceptable(
      h,
      allPreferred,
      familyOf: familyOf,
    );
    final isBad = plugMatchesAcceptable(
      h,
      allAvoid,
      familyOf: familyOf,
    );
    // Prefer avoid if a hash somehow appears in both (invalid target).
    if (isBad) {
      bad++;
    } else if (isGood) {
      good++;
    }
  }

  final preferredMatched = good;
  // M = perks on the scored sockets for this copy (varies by instance).
  final preferredScored =
      hasPreferredInTarget || hasAvoidInTarget ? plugsToClassify.length : 0;
  final avoidHits = bad;
  // Enable Av segment whenever the target defines avoids (show Av 0 when clean).
  final avoidScored = hasAvoidInTarget ? 1 : 0;

  return RollTargetMatchResult(
    preferredMatched: preferredMatched,
    preferredScored: preferredScored,
    avoidHits: avoidHits,
    avoidScored: avoidScored,
    preferredByColumn: preferredByColumn,
    avoidByColumn: avoidByColumn,
  );
}

/// Rank owned instances: preferredRatio desc, avoidHits asc, power desc, tier desc.
List<RankedRollTargetInstance> rankOwnedAgainstTarget(
  WeaponRollTarget target,
  List<RollTargetInstanceInput> instances, {
  PlugFamilyLookup? familyOf,
}) {
  final ranked = <RankedRollTargetInstance>[
    for (final inst in instances)
      RankedRollTargetInstance(
        instance: inst,
        match: scoreInstanceAgainstTarget(
          target,
          inst.plugsByColumn,
          familyOf: familyOf,
        ),
      ),
  ];

  ranked.sort((a, b) {
    final pr = b.match.preferredRatio.compareTo(a.match.preferredRatio);
    if (pr != 0) return pr;
    final av = a.match.avoidHits.compareTo(b.match.avoidHits);
    if (av != 0) return av;
    final powerA = a.instance.power ?? -1;
    final powerB = b.instance.power ?? -1;
    final pw = powerB.compareTo(powerA);
    if (pw != 0) return pw;
    final tierA = a.instance.gearTier ?? -1;
    final tierB = b.instance.gearTier ?? -1;
    final tr = tierB.compareTo(tierA);
    if (tr != 0) return tr;
    return a.instance.instanceId.compareTo(b.instance.instanceId);
  });

  return ranked;
}
