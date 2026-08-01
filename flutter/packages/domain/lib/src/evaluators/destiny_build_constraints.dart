/// Pure hard-block evaluators for builds / variants (UI + tests).
///
/// Port of TypeScript `src/lib/builds/destinyBuildConstraints.ts`.
/// No IO: callers pass already-resolved composition, capacities, and ability fields.
library;

import '../models/constraints.dart';
import '../models/failure_codes.dart';
import '../models/kit.dart';

/// DBR-CMP-007 / DAC-DST-001: at most one exotic weapon and one exotic armor.
ConstraintEvaluation evaluateExoticLimits(ExoticComposition composition) {
  final hardBlocks = <HardBlock>[];
  final weapons = _uniquePositive(composition.exoticWeaponHashes);
  final armor = _uniquePositive(composition.exoticArmorHashes);

  if (weapons.length > 1) {
    hardBlocks.add(
      HardBlock(
        code: DomainFailureCodes.tooManyExotics,
        message:
            'At most one exotic weapon can be equipped (found ${weapons.length})',
      ),
    );
  }
  if (armor.length > 1) {
    hardBlocks.add(
      HardBlock(
        code: DomainFailureCodes.tooManyExotics,
        message:
            'At most one exotic armor piece can be equipped (found ${armor.length})',
      ),
    );
  }

  return ConstraintEvaluation(hardBlocks: hardBlocks);
}

/// DBR-SYN-003: ≥1 designated synergy type.
///
/// Only the **length** of [synergyTypes] matters; element shape is not inspected.
ConstraintEvaluation evaluateSynergyRequirement(
  Iterable<Object?> synergyTypes,
) {
  if (synergyTypes.isEmpty) {
    return const ConstraintEvaluation(
      hardBlocks: [
        HardBlock(
          code: DomainFailureCodes.noSynergy,
          message: 'Build must designate at least one synergy type',
        ),
      ],
    );
  }
  return ConstraintEvaluation.empty;
}

/// DBR-SUB-004 / DAC-DST-003: aspect count + fragment capacity.
///
/// ## capacityResolved semantics
///
/// - Defaults to **true** when omitted (via [SubclassKitEvalInput.capacityResolved]
///   or the named parameter default).
/// - When **true**, `fragmentCount > fragmentCapacity` is a hard block
///   (`ILLEGAL_SUBCLASS_KIT`).
/// - When **false** (caller could not resolve aspect capacities from the entity
///   store), the fragment-capacity hard check is **skipped**. Aspect max is
///   still enforced.
///
/// Callers that invent `fragmentCapacity: 0` with `capacityResolved: true`
/// will hard-block any positive fragment count — prefer `capacityResolved: false`
/// when capacities are unknown.
ConstraintEvaluation evaluateSubclassKit(SubclassKitEvalInput input) {
  final hardBlocks = <HardBlock>[];
  final maxAspects = input.maxAspects;

  if (input.aspectCount > maxAspects) {
    hardBlocks.add(
      HardBlock(
        code: DomainFailureCodes.illegalSubclassKit,
        message:
            'At most $maxAspects aspects allowed (selected ${input.aspectCount})',
      ),
    );
  }

  // TS: capacityResolved = input.capacityResolved !== false  (default true)
  final capacityResolved = input.capacityResolved;
  if (capacityResolved && input.fragmentCount > input.fragmentCapacity) {
    hardBlocks.add(
      HardBlock(
        code: DomainFailureCodes.illegalSubclassKit,
        message:
            'Too many fragments (${input.fragmentCount}/${input.fragmentCapacity} from aspects)',
      ),
    );
  }

  return ConstraintEvaluation(hardBlocks: hardBlocks);
}

/// Convenience overload matching the TS field-bag call shape.
ConstraintEvaluation evaluateSubclassKitFields({
  required int aspectCount,
  required int fragmentCount,
  required int fragmentCapacity,
  int maxAspects = maxSubclassAspects,
  bool capacityResolved = true,
}) {
  return evaluateSubclassKit(
    SubclassKitEvalInput(
      aspectCount: aspectCount,
      fragmentCount: fragmentCount,
      fragmentCapacity: fragmentCapacity,
      maxAspects: maxAspects,
      capacityResolved: capacityResolved,
    ),
  );
}

/// DBR-MOD-001–002 / DAC-DST-002: piece energy must not exceed capacity.
ConstraintEvaluation evaluateModEnergy(List<ModEnergyPiece> pieces) {
  final hardBlocks = <HardBlock>[];
  for (final piece in pieces) {
    if (piece.energyUsed > piece.energyCapacity) {
      hardBlocks.add(
        HardBlock(
          code: DomainFailureCodes.modEnergyExceeded,
          message:
              '${piece.slot}: mods use ${piece.energyUsed} energy (capacity ${piece.energyCapacity})',
        ),
      );
    }
  }
  return ConstraintEvaluation(hardBlocks: hardBlocks);
}

/// DBR-SUB-005 / DAC-DST-004: exotic-required abilities must match kit
/// (and pinned Super when the requirement is a Super).
///
/// Soft warning [DomainFailureCodes.exoticAbilityPinProposed] is emitted only
/// when there is at least one requirement **and** at least one hard mismatch.
/// Soft warnings never auto-apply kit/pin mutations.
ConstraintEvaluation evaluateExoticAbilityMatch({
  required AbilityKit required,
  required AbilityKit kit,
  String? pinnedSuper,
}) {
  final hardBlocks = <HardBlock>[];
  final softWarnings = <SoftWarning>[];

  final checks = <_AbilityCheck>[
    _AbilityCheck(
      key: _AbilityKey.superAbility,
      label: 'Super',
      kitValue: kit.superAbility,
      pinValue: pinnedSuper,
    ),
    _AbilityCheck(
      key: _AbilityKey.melee,
      label: 'melee',
      kitValue: kit.melee,
    ),
    _AbilityCheck(
      key: _AbilityKey.grenade,
      label: 'grenade',
      kitValue: kit.grenade,
    ),
    _AbilityCheck(
      key: _AbilityKey.classAbility,
      label: 'class ability',
      kitValue: kit.classAbility,
    ),
  ];

  var hasRequirement = false;
  for (final check in checks) {
    final needed = _requiredFor(required, check.key)?.trim();
    if (needed == null || needed.isEmpty) continue;
    hasRequirement = true;
    final String effective;
    if (check.key == _AbilityKey.superAbility) {
      final pin = check.pinValue?.trim() ?? '';
      final kitVal = check.kitValue?.trim() ?? '';
      effective = pin.isNotEmpty ? pin : kitVal;
    } else {
      effective = check.kitValue?.trim() ?? '';
    }
    if (!_namesMatch(effective, needed)) {
      hardBlocks.add(
        HardBlock(
          code: DomainFailureCodes.exoticAbilityMismatch,
          message:
              'Exotic requires ${check.label} "$needed" (kit has "${effective.isEmpty ? "none" : effective}")',
        ),
      );
    }
  }

  if (hasRequirement && hardBlocks.isNotEmpty) {
    softWarnings.add(
      const SoftWarning(
        code: DomainFailureCodes.exoticAbilityPinProposed,
        message:
            "Confirm ability pins to match this exotic's requirements",
      ),
    );
  }

  return ConstraintEvaluation(
    hardBlocks: hardBlocks,
    softWarnings: softWarnings,
  );
}

/// Flatten multiple evaluation envelopes into one (TS `mergeConstraintEvaluations`).
ConstraintEvaluation mergeConstraintEvaluations(
  Iterable<ConstraintEvaluation> parts,
) {
  final hardBlocks = <HardBlock>[];
  final softWarnings = <SoftWarning>[];
  for (final part in parts) {
    hardBlocks.addAll(part.hardBlocks);
    softWarnings.addAll(part.softWarnings);
  }
  return ConstraintEvaluation(
    hardBlocks: hardBlocks,
    softWarnings: softWarnings,
  );
}

// --- private helpers ---

List<int> _uniquePositive(List<int> hashes) {
  final seen = <int>{};
  final out = <int>[];
  for (final h in hashes) {
    if (h > 0 && seen.add(h)) {
      out.add(h);
    }
  }
  return out;
}

bool _namesMatch(String a, String b) {
  return a.trim().toLowerCase() == b.trim().toLowerCase();
}

enum _AbilityKey { superAbility, melee, grenade, classAbility }

class _AbilityCheck {
  const _AbilityCheck({
    required this.key,
    required this.label,
    required this.kitValue,
    this.pinValue,
  });

  final _AbilityKey key;
  final String label;
  final String? kitValue;
  final String? pinValue;
}

String? _requiredFor(AbilityKit required, _AbilityKey key) {
  switch (key) {
    case _AbilityKey.superAbility:
      return required.superAbility;
    case _AbilityKey.melee:
      return required.melee;
    case _AbilityKey.grenade:
      return required.grenade;
    case _AbilityKey.classAbility:
      return required.classAbility;
  }
}
