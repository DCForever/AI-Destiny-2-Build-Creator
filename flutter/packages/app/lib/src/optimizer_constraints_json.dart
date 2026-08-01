/// Parse/serialize Armor Set optimizer constraints JSON (product parity).
///
/// Soft metadata only — never auto-applies kits. Used for post-sync eligibility
/// and optional seed on armor capture (DART-067 / BR-OPT-004).
library;

import 'dart:convert';

import 'package:destiny2_domain/destiny2_domain.dart';

/// Persisted on Armor Sets (`sets.optimizer_constraints`).
class ArmorSetOptimizerConstraints {
  const ArmorSetOptimizerConstraints({
    this.lockedExoticItemHash,
    this.requireExotic = false,
    this.setBonusGoals = const [],
    this.statPriorities = const [],
    this.statThresholds,
    this.requireThresholds = false,
    this.includeModEstimates = true,
    this.preferReuse = false,
  });

  final int? lockedExoticItemHash;
  final bool requireExotic;
  final List<SetBonusCoverageGoal> setBonusGoals;
  final List<ArmorStatName> statPriorities;
  final Map<ArmorStatName, int>? statThresholds;
  final bool requireThresholds;
  final bool includeModEstimates;
  final bool preferReuse;

  /// Empty default payload (still counts as constrained when stored).
  factory ArmorSetOptimizerConstraints.empty() =>
      const ArmorSetOptimizerConstraints();
}

/// True when a non-null payload is stored (even partial) — improvement eligibility.
bool hasOptimizerConstraintsPayload(ArmorSetOptimizerConstraints? constraints) {
  return constraints != null;
}

/// Parse stored JSON; null when missing/invalid.
ArmorSetOptimizerConstraints? parseOptimizerConstraints(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final map = Map<String, Object?>.from(decoded);

    int? locked;
    final lockedRaw = map['lockedExoticItemHash'];
    if (lockedRaw is int) {
      locked = lockedRaw > 0 ? lockedRaw : null;
    } else if (lockedRaw is num) {
      final n = lockedRaw.toInt();
      locked = n > 0 ? n : null;
    }

    final goals = <SetBonusCoverageGoal>[];
    final goalsRaw = map['setBonusGoals'];
    if (goalsRaw is List) {
      for (final g in goalsRaw) {
        if (g is! Map) continue;
        final gm = Map<String, Object?>.from(g);
        final key = gm['setBonusKey']?.toString();
        final min = gm['minPieces'];
        if (key == null || key.isEmpty) continue;
        final minPieces = min is int
            ? min
            : min is num
                ? min.toInt()
                : null;
        if (minPieces != 2 && minPieces != 4) continue;
        goals.add(
          SetBonusCoverageGoal(setBonusKey: key, minPieces: minPieces!),
        );
      }
    }

    final priorities = <ArmorStatName>[];
    final priRaw = map['statPriorities'];
    if (priRaw is List) {
      for (final p in priRaw) {
        final name = ArmorStatName.tryParse(p.toString());
        if (name != null) priorities.add(name);
      }
    }

    Map<ArmorStatName, int>? thresholds;
    final thrRaw = map['statThresholds'];
    if (thrRaw is Map) {
      final out = <ArmorStatName, int>{};
      thrRaw.forEach((k, v) {
        final name = ArmorStatName.tryParse(k.toString());
        if (name == null) return;
        final n = v is int
            ? v
            : v is num
                ? v.toInt()
                : int.tryParse(v.toString());
        if (n != null) out[name] = n;
      });
      if (out.isNotEmpty) thresholds = out;
    }

    return ArmorSetOptimizerConstraints(
      lockedExoticItemHash: locked,
      requireExotic: map['requireExotic'] == true,
      setBonusGoals: goals,
      statPriorities: priorities,
      statThresholds: thresholds,
      requireThresholds: map['requireThresholds'] == true,
      includeModEstimates: map['includeModEstimates'] != false,
      preferReuse: map['preferReuse'] == true,
    );
  } catch (_) {
    return null;
  }
}

/// Serialize constraints for Drift storage.
String serializeOptimizerConstraints(ArmorSetOptimizerConstraints c) {
  final map = <String, Object?>{
    'setBonusGoals': [
      for (final g in c.setBonusGoals)
        {'setBonusKey': g.setBonusKey, 'minPieces': g.minPieces},
    ],
    'preferReuse': c.preferReuse,
    'includeModEstimates': c.includeModEstimates,
  };
  if (c.lockedExoticItemHash != null) {
    map['lockedExoticItemHash'] = c.lockedExoticItemHash;
  }
  if (c.requireExotic) map['requireExotic'] = true;
  if (c.statPriorities.isNotEmpty) {
    map['statPriorities'] = [for (final p in c.statPriorities) p.wireName];
  }
  if (c.statThresholds != null && c.statThresholds!.isNotEmpty) {
    map['statThresholds'] = {
      for (final e in c.statThresholds!.entries) e.key.wireName: e.value,
    };
  }
  if (c.requireThresholds) map['requireThresholds'] = true;
  return jsonEncode(map);
}

/// Seed minimal constraints from build identity (product seedConstraintsFromBuild).
ArmorSetOptimizerConstraints seedConstraintsFromBuild({
  int? exoticArmorHash,
  Map<String, int>? softStatTargets,
}) {
  Map<ArmorStatName, int>? thresholds;
  if (softStatTargets != null && softStatTargets.isNotEmpty) {
    final out = <ArmorStatName, int>{};
    softStatTargets.forEach((k, v) {
      final name = ArmorStatName.tryParse(k);
      if (name != null) out[name] = v;
    });
    if (out.isNotEmpty) thresholds = out;
  }
  return ArmorSetOptimizerConstraints(
    lockedExoticItemHash:
        exoticArmorHash != null && exoticArmorHash > 0 ? exoticArmorHash : null,
    statThresholds: thresholds,
    setBonusGoals: const [],
    preferReuse: false,
    includeModEstimates: true,
  );
}
