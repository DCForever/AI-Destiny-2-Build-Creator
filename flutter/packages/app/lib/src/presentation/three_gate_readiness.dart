/// Pure three-gate readiness summary for host UX (DBR-CMPL-001d / BR-VAR-041).
///
/// Gates: (1) compose-complete, (2) required links, (3) equip-ready.
/// Soft required-link misses on non-default never hard-disable Save.
library;

import 'package:destiny2_domain/destiny2_domain.dart';

/// One chip / row in the three-gate readiness summary.
class ThreeGateStatus {
  const ThreeGateStatus({
    required this.composeComplete,
    required this.requiredLinksSatisfied,
    required this.equipReady,
    this.composeMissing = const [],
    this.requiredFailures = const [],
    this.isDefault = true,
  });

  /// Gate 1: full combat loadout + kit bar + artifact (when evaluated).
  final bool composeComplete;

  /// Gate 2: all required links satisfied (equip-ready / applied kit).
  final bool requiredLinksSatisfied;

  /// Gate 3: equip-ready (owned pins; separate equip/export path).
  final bool equipReady;

  final List<String> composeMissing;
  final List<RequiredLinkFailure> requiredFailures;
  final bool isDefault;

  /// Hard-block Save only when default and compose or required fails.
  /// Soft never disables Save on non-default.
  bool get hardBlocksSave {
    if (!isDefault) return false;
    return !composeComplete || !requiredLinksSatisfied;
  }

  /// Soft-warn styling for unsatisfied required links on non-default.
  bool get softRequiredWarn =>
      !isDefault && requiredFailures.isNotEmpty;

  /// Compact chip labels (BR-VAR-041).
  List<String> get chipLabels => [
        composeComplete ? 'Compose ready' : 'Compose incomplete',
        requiredLinksSatisfied
            ? 'Required links ok'
            : (isDefault
                ? 'Required links missing'
                : 'Required links soft'),
        equipReady ? 'Equip ready' : 'Not equip-ready',
      ];
}

/// Evaluate three-gate readiness from pure domain evaluators.
///
/// Does not throw. Callers wire Save disable from [ThreeGateStatus.hardBlocksSave]
/// only — soft coverage / non-default required never disable Save alone.
ThreeGateStatus evaluateThreeGateReadiness({
  required ResolvedVariantEquipment resolved,
  required bool isDefault,
  String? className,
  SubclassKit? subclassKit,
  bool hasMods = false,
  int fragmentCapacity = 0,
  bool capacityResolved = true,
  int? artifactHash,
  List<int> artifactConfig = const [],
  List<Synergy> designatedSynergies = const [],
  InventoryPinIndex inventory = const {},
  MatchEvidenceContext? matchCtx,
  bool requireKitAndArtifact = true,
}) {
  final kitFields = subclassKit != null
      ? SubclassKitFields.fromKit(subclassKit)
      : null;
  final subclassName = kitFields?.name;

  final composeMissing = <String>[];
  var composeComplete = true;
  try {
    assertFullCombatLoadout(
      resolved,
      className: className,
      subclassName: subclassName,
      hasMods: hasMods,
      options: FullCombatLoadoutOptions(
        fragmentCapacity: fragmentCapacity,
        capacityResolved: capacityResolved,
        artifactHash: artifactHash,
        artifactConfig: artifactConfig,
        subclassKit: kitFields,
        requireKitAndArtifact: requireKitAndArtifact,
      ),
    );
  } on ResolveVariantException catch (e) {
    composeComplete = false;
    final missing = e.details?['missing'];
    if (missing is List) {
      composeMissing.addAll(missing.map((e) => e.toString()));
    }
  }

  final kitMap =
      subclassKit != null ? <String, Object?>{
            'aspects': subclassKit.aspects,
            'fragments': subclassKit.fragments,
            if (subclassKit.superAbility != null)
              'super': subclassKit.superAbility,
            if (subclassKit.melee != null) 'melee': subclassKit.melee,
            if (subclassKit.grenade != null) 'grenade': subclassKit.grenade,
          } : null;
  final base = matchCtx ?? const MatchEvidenceContext();
  final ctx = MatchEvidenceContext(
    setBonusByItemHash: base.setBonusByItemHash,
    artifactConfig: artifactConfig,
    kit: kitMap ?? base.kit,
    perkFamilyByHash: base.perkFamilyByHash,
    exoticClassItemHashes: base.exoticClassItemHashes,
  );

  final requiredFailures = collectRequiredLinkFailures(
    synergies: designatedSynergies,
    resolved: resolved,
    inventory: inventory,
    ctx: ctx,
  );
  final requiredOk = requiredFailures.isEmpty;

  final equip = computeEquipReady(resolved, inventory);

  return ThreeGateStatus(
    composeComplete: composeComplete,
    requiredLinksSatisfied: requiredOk,
    equipReady: equip.equipReady,
    composeMissing: composeMissing,
    requiredFailures: requiredFailures,
    isDefault: isDefault,
  );
}
