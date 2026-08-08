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

/// Score one instance's plugs against a roll target.
///
/// [plugsByColumn]: columnKey → selected plug hash.
/// Columns with empty preferred are unscored for preferred; empty avoid
/// unscored for avoid.
RollTargetMatchResult scoreInstanceAgainstTarget(
  WeaponRollTarget target,
  Map<String, int> plugsByColumn, {
  PlugFamilyLookup? familyOf,
}) {
  var preferredMatched = 0;
  var preferredScored = 0;
  var avoidHits = 0;
  var avoidScored = 0;
  final preferredByColumn = <String, PreferredColumnState>{};
  final avoidByColumn = <String, AvoidColumnState>{};

  for (final col in target.columns) {
    final key = col.columnKey;
    final plug = plugsByColumn[key];

    if (col.preferredPlugHashes.isEmpty) {
      preferredByColumn[key] = PreferredColumnState.unscored;
    } else {
      preferredScored++;
      if (plug != null &&
          plugMatchesAcceptable(
            plug,
            col.preferredPlugHashes,
            familyOf: familyOf,
          )) {
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
      if (plug != null &&
          plugMatchesAcceptable(
            plug,
            col.avoidPlugHashes,
            familyOf: familyOf,
          )) {
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
