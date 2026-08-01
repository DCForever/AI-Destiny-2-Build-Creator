/// Armor 3.0 stat names (TS `ArmorStatName`).
enum ArmorStatName {
  health('Health'),
  melee('Melee'),
  grenade('Grenade'),
  superStat('Super'),
  classStat('Class'),
  weapons('Weapons');

  const ArmorStatName(this.wireName);
  final String wireName;

  static const List<ArmorStatName> all = ArmorStatName.values;

  static ArmorStatName? tryParse(String wire) {
    for (final v in ArmorStatName.values) {
      if (v.wireName == wire) return v;
    }
    return null;
  }
}

/// Soft stat targets on a build (partial map). Soft guidance only — never hard block.
class SoftStatTargets {
  const SoftStatTargets([this.values = const {}]);

  final Map<ArmorStatName, int> values;

  int? operator [](ArmorStatName stat) => values[stat];

  bool get isEmpty => values.isEmpty;

  SoftStatTargets copyWithValue(ArmorStatName stat, int? target) {
    final next = Map<ArmorStatName, int>.from(values);
    if (target == null) {
      next.remove(stat);
    } else {
      next[stat] = target;
    }
    return SoftStatTargets(next);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SoftStatTargets) return false;
    if (other.values.length != values.length) return false;
    for (final e in values.entries) {
      if (other.values[e.key] != e.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(
        values.entries.map((e) => Object.hash(e.key, e.value)),
      );
}

/// Estimated loadout stats with completeness flag (TS `StatEstimate`).
class StatEstimate {
  const StatEstimate({
    this.values = const {},
    this.incomplete = false,
  });

  final Map<ArmorStatName, int> values;
  final bool incomplete;

  int? operator [](ArmorStatName stat) => values[stat];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StatEstimate) return false;
    if (other.incomplete != incomplete) return false;
    if (other.values.length != values.length) return false;
    for (final e in values.entries) {
      if (other.values[e.key] != e.value) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(incomplete, Object.hashAll(values.entries));
}

/// Soft stat miss row (never a [HardBlock]).
class SoftStatWarningRow {
  const SoftStatWarningRow({
    required this.stat,
    required this.target,
    required this.estimate,
    required this.hint,
  });

  final ArmorStatName stat;
  final int target;
  final int estimate;
  final String hint;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SoftStatWarningRow &&
        other.stat == stat &&
        other.target == target &&
        other.estimate == estimate &&
        other.hint == hint;
  }

  @override
  int get hashCode => Object.hash(stat, target, estimate, hint);
}
