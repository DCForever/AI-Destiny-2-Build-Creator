/// Pure soft-stat nudge suggestions (TS `statNudges.ts`).
///
/// Suggestions only — never auto-applied. Callers must accept via
/// [targetsFromAcceptedNudges].
library;

import '../models/soft_stats.dart';
import '../models/synergy.dart';

/// One soft-stat nudge suggestion.
class StatNudge {
  const StatNudge({
    required this.stat,
    required this.suggested,
    required this.reason,
    this.synergyId,
  });

  final ArmorStatName stat;
  final int suggested;
  final String reason;
  final String? synergyId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StatNudge &&
        other.stat == stat &&
        other.suggested == suggested &&
        other.reason == reason &&
        other.synergyId == synergyId;
  }

  @override
  int get hashCode => Object.hash(stat, suggested, reason, synergyId);
}

const int _defaultSuggested = 100;

/// Synergy type wire (lowercase) → Armor 3.0 stat.
const Map<String, ArmorStatName> synergyTypeToStat = {
  'melee': ArmorStatName.melee,
  'grenade': ArmorStatName.grenade,
  'super': ArmorStatName.superStat,
  'class': ArmorStatName.classStat,
  'ability': ArmorStatName.classStat,
  'weapons': ArmorStatName.weapons,
  'weapon': ArmorStatName.weapons,
  'health': ArmorStatName.health,
  'survivability': ArmorStatName.health,
};

String _designationLabel(SynergyTypeDesignation d) {
  final sub = d.subType?.trim();
  if (sub == null || sub.isEmpty) return d.type.wireName;
  return '${d.type.wireName} ($sub)';
}

/// Suggest soft-stat nudges from designated synergy types (one per stat, first wins).
List<StatNudge> suggestStatNudges(
  List<SynergyTypeDesignation> designations, [
  List<Synergy> matched = const [],
]) {
  // matched retained for TS signature parity; unused.
  // ignore: unused_local_variable
  final _ = matched;
  final byStat = <ArmorStatName, StatNudge>{};
  for (final designation in designations) {
    final key = designation.type.wireName.toLowerCase();
    final stat = synergyTypeToStat[key];
    if (stat == null) continue;
    if (byStat.containsKey(stat)) continue;
    final label = _designationLabel(designation);
    byStat[stat] = StatNudge(
      stat: stat,
      suggested: _defaultSuggested,
      reason:
          'Designated synergy type "$label" (${designation.type.wireName})',
      synergyId: designation.designationKey,
    );
  }
  return byStat.values.toList(growable: false);
}

/// Apply accepted nudges into existing targets (per-stat max). Never auto-called by coverage.
SoftStatTargets targetsFromAcceptedNudges(
  SoftStatTargets existing,
  List<StatNudge> nudges,
) {
  final out = Map<ArmorStatName, int>.from(existing.values);
  for (final nudge in nudges) {
    final prev = out[nudge.stat];
    out[nudge.stat] =
        prev == null ? nudge.suggested : (prev > nudge.suggested ? prev : nudge.suggested);
  }
  return SoftStatTargets(out);
}
