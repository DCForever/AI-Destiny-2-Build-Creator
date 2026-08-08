/// Pure score / rank for Catalog weapon roll targets (preferred + avoid).
///
/// Soft display only — never hard-blocks save/equip; soft never auto-applies.
library;

import '../models/roll_target.dart';

/// Optional plug-family expansion: hash → other hashes that count as the same
/// perk family (e.g. base ↔ enhanced). When null/empty, match is hash-only.
typedef PlugFamilyLookup = Set<int> Function(int plugHash);

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
/// [plugsByColumn]: columnKey → plug hash(es) on that instance for the column.
/// Accepts a single equipped hash (`int`) or a set of equipped + reusable plugs.
///
/// **Dual segs N/M** (DBR-IDL-002/005): **one credit per column** with preferred
/// multi-picks. Multi-pick is multi-**accept**: any listed preferred **on this
/// copy** (any socket) matches that ideal slot. M is not inflated by alternatives.
///
/// **Av k**: one hit per avoid column when any listed avoid is on this copy.
///
/// Matching uses column-key resolution with fallbacks, then **whole-copy plug
/// presence** so scores stay correct when socket keys differ across instances
/// (e.g. 525 vs 487 → 0/4 false miss).
RollTargetMatchResult scoreInstanceAgainstTarget(
  WeaponRollTarget target,
  Map<String, Object?> plugsByColumn, {
  PlugFamilyLookup? familyOf,
}) {
  var preferredMatched = 0;
  var preferredScored = 0;
  var avoidHits = 0;
  var avoidScored = 0;
  final preferredByColumn = <String, PreferredColumnState>{};
  final avoidByColumn = <String, AvoidColumnState>{};

  final allPlugs = allPlugsOnInstance(plugsByColumn);

  bool anyPlugMatches(Set<int> instancePlugs, Set<int> acceptable) {
    for (final plug in instancePlugs) {
      if (plugMatchesAcceptable(plug, acceptable, familyOf: familyOf)) {
        return true;
      }
    }
    return false;
  }

  /// Plugs to test for a column: resolved column set, or whole copy if key miss.
  Set<int> plugsForColumn(RollTargetColumn col) {
    final resolved = resolvePlugsForColumnKey(
      plugsByColumn,
      col.columnKey,
      label: col.label,
    );
    // Key miss or empty socket → still match preferred/avoid by presence on copy.
    if (resolved.isEmpty && allPlugs.isNotEmpty) return allPlugs;
    return resolved;
  }

  for (final col in target.columns) {
    final key = col.columnKey;
    final instancePlugs = plugsForColumn(col);

    if (col.preferredPlugHashes.isEmpty) {
      preferredByColumn[key] = PreferredColumnState.unscored;
    } else {
      preferredScored++;
      if (anyPlugMatches(instancePlugs, col.preferredPlugHashes)) {
        preferredMatched++;
        preferredByColumn[key] = PreferredColumnState.matched;
      } else {
        preferredByColumn[key] = PreferredColumnState.miss;
      }
    }

    if (col.avoidPlugHashes.isEmpty) {
      avoidByColumn[key] = AvoidColumnState.unscored;
    } else {
      avoidScored++;
      if (anyPlugMatches(instancePlugs, col.avoidPlugHashes)) {
        avoidHits++;
        avoidByColumn[key] = AvoidColumnState.hit;
      } else {
        avoidByColumn[key] = AvoidColumnState.clear;
      }
    }
  }

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
