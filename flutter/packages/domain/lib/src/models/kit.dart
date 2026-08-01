/// Subclass kit identity fields (names, not resolved hashes).
///
/// Mirrors TS `SubclassKitInput` / ability kit fields used by hard evaluators.
class SubclassKit {
  const SubclassKit({
    this.aspects = const [],
    this.fragments = const [],
    this.superAbility,
    this.melee,
    this.grenade,
    this.classAbility,
    this.name,
  });

  final List<String> aspects;
  final List<String> fragments;

  /// Named `superAbility` because `super` is reserved in Dart.
  final String? superAbility;
  final String? melee;
  final String? grenade;
  final String? classAbility;
  final String? name;

  int get aspectCount => aspects.length;
  int get fragmentCount => fragments.length;

  AbilityKit get abilityKit => AbilityKit(
        superAbility: superAbility,
        melee: melee,
        grenade: grenade,
        classAbility: classAbility,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubclassKit &&
        _strListEquals(other.aspects, aspects) &&
        _strListEquals(other.fragments, fragments) &&
        other.superAbility == superAbility &&
        other.melee == melee &&
        other.grenade == grenade &&
        other.classAbility == classAbility &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(aspects),
        Object.hashAll(fragments),
        superAbility,
        melee,
        grenade,
        classAbility,
        name,
      );
}

/// Ability pins / kit fields for exotic ability matching (TS `AbilityKitFields`).
class AbilityKit {
  const AbilityKit({
    this.superAbility,
    this.melee,
    this.grenade,
    this.classAbility,
  });

  final String? superAbility;
  final String? melee;
  final String? grenade;
  final String? classAbility;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AbilityKit &&
        other.superAbility == superAbility &&
        other.melee == melee &&
        other.grenade == grenade &&
        other.classAbility == classAbility;
  }

  @override
  int get hashCode =>
      Object.hash(superAbility, melee, grenade, classAbility);
}

/// Unique exotic hashes by kind for exotic-limit evaluation.
class ExoticComposition {
  const ExoticComposition({
    this.exoticWeaponHashes = const [],
    this.exoticArmorHashes = const [],
  });

  final List<int> exoticWeaponHashes;
  final List<int> exoticArmorHashes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExoticComposition &&
        _intListEquals(other.exoticWeaponHashes, exoticWeaponHashes) &&
        _intListEquals(other.exoticArmorHashes, exoticArmorHashes);
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(exoticWeaponHashes),
        Object.hashAll(exoticArmorHashes),
      );
}

/// Per-piece armor mod energy usage for hard mod-energy checks.
class ModEnergyPiece {
  const ModEnergyPiece({
    required this.slot,
    required this.energyUsed,
    required this.energyCapacity,
  });

  /// Slot label (armor slot wire name or free-form piece id).
  final String slot;
  final int energyUsed;
  final int energyCapacity;

  bool get exceedsCapacity => energyUsed > energyCapacity;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ModEnergyPiece &&
        other.slot == slot &&
        other.energyUsed == energyUsed &&
        other.energyCapacity == energyCapacity;
  }

  @override
  int get hashCode => Object.hash(slot, energyUsed, energyCapacity);
}

/// Input bag for subclass kit hard evaluation (counts + capacity resolution).
class SubclassKitEvalInput {
  const SubclassKitEvalInput({
    required this.aspectCount,
    required this.fragmentCount,
    required this.fragmentCapacity,
    this.maxAspects = 2,
    this.capacityResolved = true,
  });

  final int aspectCount;
  final int fragmentCount;
  final int fragmentCapacity;
  final int maxAspects;

  /// When false, fragment capacity is not hard-enforced (TS `capacityResolved`).
  ///
  /// ## Semantics (DART-003 / TS parity)
  ///
  /// - **true** (default): if `fragmentCount > fragmentCapacity`, emit
  ///   `ILLEGAL_SUBCLASS_KIT`.
  /// - **false**: skip fragment-capacity hard check (caller could not resolve
  ///   aspect capacities from the entity store). Aspect max is still enforced.
  ///
  /// Do not pass `fragmentCapacity: 0` with `capacityResolved: true` unless
  /// zero capacity is known-correct — prefer `capacityResolved: false` when
  /// unknown.
  final bool capacityResolved;
}

/// Destiny allows two aspects on a subclass kit (TS `MAX_SUBCLASS_ASPECTS`).
const int maxSubclassAspects = 2;

bool _strListEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _intListEquals(List<int> a, List<int> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
