/// Pure soft-stat target normalize/merge helpers (TS `softStatTargets.ts` core).
///
/// Soft guidance only — never a hard block. No UI draft helpers (out of scope).
library;

import '../models/soft_stats.dart';

/// Armor 3.0 soft-stat ceiling (TS `STAT_MAX`).
const int armorStatMax = 200;

/// Domain validation failure for soft-stat target payloads.
///
/// Code matches product `INVALID_ITEM` so adapters can map to HTTP later.
class SoftStatTargetsException implements Exception {
  const SoftStatTargetsException(this.message, {this.code = 'INVALID_ITEM'});

  final String code;
  final String message;

  @override
  String toString() => 'SoftStatTargetsException($code: $message)';
}

/// Normalize a partial map of wire-name or [ArmorStatName] keys into [SoftStatTargets].
///
/// Accepts [SoftStatTargets] or `Map` with [ArmorStatName] keys or string wire names.
/// Throws [SoftStatTargetsException] on unknown keys or out-of-range values.
SoftStatTargets normalizeSoftStatTargets(Object input) {
  final Map<String, Object?> raw;
  if (input is SoftStatTargets) {
    return SoftStatTargets(
      Map<ArmorStatName, int>.from(input.values),
    );
  }
  if (input is Map<ArmorStatName, int>) {
    raw = {
      for (final e in input.entries) e.key.wireName: e.value,
    };
  } else if (input is Map) {
    raw = {
      for (final e in input.entries) e.key.toString(): e.value,
    };
  } else {
    throw const SoftStatTargetsException(
      'softStatTargets must be an object map',
    );
  }

  final out = <ArmorStatName, int>{};
  for (final name in ArmorStatName.all) {
    if (!raw.containsKey(name.wireName)) continue;
    final value = raw[name.wireName];
    if (value == null) continue;
    if (value is! int) {
      throw SoftStatTargetsException(
        'softStatTargets.${name.wireName} must be an integer',
      );
    }
    if (value < 1 || value > armorStatMax) {
      throw SoftStatTargetsException(
        'softStatTargets.${name.wireName} must be between 1 and $armorStatMax',
      );
    }
    out[name] = value;
  }

  for (final key in raw.keys) {
    if (ArmorStatName.tryParse(key) == null) {
      throw SoftStatTargetsException('Unknown soft stat "$key"');
    }
  }

  return SoftStatTargets(out);
}

/// Merge [incoming] into [existing] taking the per-stat max (never lowers).
SoftStatTargets mergeSoftStatTargets(
  SoftStatTargets existing,
  SoftStatTargets incoming,
) {
  final out = Map<ArmorStatName, int>.from(existing.values);
  for (final name in ArmorStatName.all) {
    final next = incoming[name];
    if (next == null) continue;
    final prev = out[name];
    out[name] = prev == null ? next : (prev > next ? prev : next);
  }
  return SoftStatTargets(out);
}
