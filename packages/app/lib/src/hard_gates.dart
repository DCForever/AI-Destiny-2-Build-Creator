import 'package:destiny2_domain/destiny2_domain.dart';

import 'errors.dart';
import 'hard_gate_ports.dart';

void _throwHard(ConstraintEvaluation eval) {
  if (!eval.isHardBlocked) return;
  final first = eval.hardBlocks.first;
  final code = UseCaseErrorCode.fromDomainCode(first.code) ??
      UseCaseErrorCode.invalidArgument;
  throw UseCaseException(
    code,
    eval.hardBlocks.map((b) => b.message).join('; '),
    details: {
      'hardBlocks': [
        for (final b in eval.hardBlocks)
          {'code': b.code, 'message': b.message},
      ],
      if (eval.softWarnings.isNotEmpty)
        'softWarnings': [
          for (final w in eval.softWarnings)
            {'code': w.code, 'message': w.message},
        ],
    },
  );
}

void _throwResolve(ResolveVariantException e) {
  final code =
      UseCaseErrorCode.fromDomainCode(e.code) ?? UseCaseErrorCode.invalidArgument;
  throw UseCaseException(
    code,
    e.message,
    details: e.details ?? const {},
  );
}

/// Hard gates for build identity create/update (product createUserBuild order).
///
/// Order: synergy required → subclass kit → exotic ability match.
/// Soft warnings from exotic ability never auto-apply and alone do not block
/// unless hard blocks are present (pure evaluator semantics).
Future<void> assertBuildIdentityHardGates({
  required List<SynergyTypeDesignation> synergyTypes,
  required SubclassKit subclass,
  int? exoticArmorHash,
  String? exoticArmorName,
  String? pinnedSuper,
  HardGatePorts ports = HardGatePorts.defaults,
}) async {
  _throwHard(evaluateSynergyRequirement(synergyTypes));

  final aspects = subclass.aspects
      .map((a) => a.trim())
      .where((a) => a.isNotEmpty)
      .toList();
  final fragments = subclass.fragments
      .map((f) => f.trim())
      .where((f) => f.isNotEmpty)
      .toList();
  final capacity = await ports.resolveFragmentCapacity(aspects);
  final capacityResolved =
      aspects.isEmpty || capacity.resolvedCount == aspects.length;

  _throwHard(
    evaluateSubclassKit(
      SubclassKitEvalInput(
        aspectCount: aspects.length,
        fragmentCount: fragments.length,
        fragmentCapacity: capacity.capacity,
        capacityResolved: capacityResolved,
      ),
    ),
  );

  final required = ports.lookupAbilityRequirements(
    hash: exoticArmorHash,
    name: exoticArmorName,
  );
  if (required == null) return;

  _throwHard(
    evaluateExoticAbilityMatch(
      required: required,
      kit: subclass.abilityKit,
      pinnedSuper: pinnedSuper,
    ),
  );
}

/// Input for equipment hard gates after pure resolve.
class VariantSaveGateInput {
  const VariantSaveGateInput({
    required this.resolved,
    required this.isDefault,
    required this.attachments,
    this.className,
    this.subclassName,
    this.hasMods = false,
  });

  final ResolvedVariantEquipment resolved;
  final bool isDefault;
  final List<Attachment> attachments;
  final String? className;
  final String? subclassName;
  final bool hasMods;
}

/// Hard gates for variant equipment save (product validateVariantSave order).
///
/// Order: slot conflicts → exotic limits → mod energy → default completeness.
/// Soft coverage is intentionally **not** evaluated here.
Future<void> assertVariantSaveHardGates(
  VariantSaveGateInput input, {
  HardGatePorts ports = HardGatePorts.defaults,
}) async {
  try {
    assertNoSlotConflicts(input.resolved);
  } on ResolveVariantException catch (e) {
    _throwResolve(e);
  }

  final claims = input.resolved.equipment.values.toList();
  final composition = await ports.classifyExoticComposition(claims);
  _throwHard(evaluateExoticLimits(composition));

  final pieces = await ports.resolveModEnergyPieces(
    attachments: input.attachments,
    equipment: input.resolved.equipment,
  );
  if (pieces.isNotEmpty) {
    _throwHard(evaluateModEnergy(pieces));
  }

  if (input.isDefault) {
    try {
      assertFullCombatLoadout(
        input.resolved,
        className: input.className,
        subclassName: input.subclassName,
        hasMods: input.hasMods,
      );
    } on ResolveVariantException catch (e) {
      _throwResolve(e);
    }
  }
}
