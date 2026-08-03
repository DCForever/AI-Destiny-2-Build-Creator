import 'package:destiny2_domain/destiny2_domain.dart';

import 'errors.dart';
import 'hard_gate_ports.dart';
import 'mappers.dart';

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
    this.subclassKit,
    this.fragmentCapacity = 0,
    this.capacityResolved = true,
    this.artifactHash,
    this.artifactConfig = const [],
    this.designatedSynergies = const [],
    this.inventory = const {},
    this.matchCtx,
  });

  final ResolvedVariantEquipment resolved;
  final bool isDefault;
  final List<Attachment> attachments;
  final String? className;
  final String? subclassName;
  final bool hasMods;

  /// Build (or effective) subclass kit for gate-1 kit bar + required kit match.
  final SubclassKit? subclassKit;
  final int fragmentCapacity;
  final bool capacityResolved;
  final int? artifactHash;
  final List<int> artifactConfig;

  /// Designated library synergies for gate-2 required links (default only).
  final List<Synergy> designatedSynergies;

  /// Inventory pin index for equip-ready required-link satisfaction.
  final InventoryPinIndex inventory;

  /// Optional perk family / class-item / set-bonus match indexes.
  final MatchEvidenceContext? matchCtx;
}

/// Hard gates for variant equipment save (product validateVariantSave order).
///
/// Order: slot conflicts → exotic limits → mod energy → default completeness
/// (gate 1) → required links (gate 2, default only). Soft coverage is
/// intentionally **not** evaluated here and never hard-blocks non-default.
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
    final kitFields = input.subclassKit != null
        ? SubclassKitFields.fromKit(input.subclassKit!)
        : (input.subclassName != null && input.subclassName!.isNotEmpty
            ? SubclassKitFields(name: input.subclassName)
            : null);
    try {
      assertFullCombatLoadout(
        input.resolved,
        className: input.className,
        subclassName: input.subclassName,
        hasMods: input.hasMods,
        options: FullCombatLoadoutOptions(
          fragmentCapacity: input.fragmentCapacity,
          capacityResolved: input.capacityResolved,
          artifactHash: input.artifactHash,
          artifactConfig: input.artifactConfig,
          subclassKit: kitFields,
        ),
      );
    } on ResolveVariantException catch (e) {
      _throwResolve(e);
    }

    // Gate 2: required synergy links → equip-ready pins / applied kit
    // (DBR-SYN-010a). Non-default skips hard required entirely.
    final kitMap = input.subclassKit != null
        ? subclassKitToJson(input.subclassKit!)
        : null;
    final baseCtx = input.matchCtx ?? const MatchEvidenceContext();
    final ctx = MatchEvidenceContext(
      setBonusByItemHash: baseCtx.setBonusByItemHash,
      artifactConfig: input.artifactConfig,
      kit: kitMap ?? baseCtx.kit,
      perkFamilyByHash: baseCtx.perkFamilyByHash,
      exoticClassItemHashes: baseCtx.exoticClassItemHashes,
    );
    try {
      assertRequiredLinksSatisfied(
        synergies: input.designatedSynergies,
        resolved: input.resolved,
        inventory: input.inventory,
        ctx: ctx,
      );
    } on ResolveVariantException catch (e) {
      _throwResolve(e);
    }
  }
}
