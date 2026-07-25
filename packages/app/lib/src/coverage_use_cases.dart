import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';

import 'hard_gate_ports.dart';
import 'mappers.dart';
import 'variant_use_cases.dart';

/// Soft-only coverage query result (never a hard-block envelope).
class CoverageQueryResult {
  const CoverageQueryResult({
    required this.buildId,
    required this.variantId,
    required this.coverage,
    this.claims = const [],
  });

  final String buildId;
  final String variantId;
  final CoverageResult coverage;
  final List<SlotClaim> claims;

  /// Convenience: any designated synergy not fully supported.
  bool get hasSoftMisses => coverage.synergies.any(
        (s) => s.tier != CoverageTier.supported,
      );
}

/// Load designated library synergies matching build synergy type designations.
///
/// Designations are type(+subType) keys; library synergies with matching type
/// contribute evidence links for soft coverage.
Future<List<Synergy>> loadDesignatedSynergies(
  AppDatabase db,
  int userId,
  List<SynergyTypeDesignationRecord> designations,
) async {
  if (designations.isEmpty) return const [];
  final all = await listSynergies(db, userId);
  final keys = {
    for (final d in designations)
      SynergyTypeDesignation(
        type: SynergyType(d.type),
        subType: d.subType,
      ).designationKey,
  };

  final out = <Synergy>[];
  for (final row in all) {
    final domain = synergyFromRecord(row);
    final key = SynergyTypeDesignation(
      type: domain.type,
      subType: domain.subType,
    ).designationKey;
    // Match full designation or type-only when designation has no subtype.
    final typeOnly = domain.type.wireName;
    if (keys.contains(key) || keys.contains(typeOnly)) {
      out.add(domain);
    }
  }
  return out;
}

/// Query soft coverage for a variant. **Never** hard-blocks and never mutates.
///
/// Soft misses/weak tiers are returned for display only. Callers must not use
/// this result to reject save of non-default (or default) variants.
Future<CoverageQueryResult?> queryVariantCoverage(
  AppDatabase db,
  int userId,
  String buildId,
  String variantId, {
  HardGatePorts ports = HardGatePorts.defaults,
  Map<int, SetBonusRecord>? setBonusByItemHash,
  Map<int, String>? weaponElementByHash,
  StatEstimate? statEstimate,
}) async {
  final build = await getBuild(db, userId, buildId);
  final variant = await getVariant(db, buildId, variantId);
  if (build == null || variant == null) return null;

  final resolved = await resolveUserVariant(
    db,
    userId,
    buildId,
    variantId,
    ports: ports,
  );
  if (resolved == null) return null;

  final claims = resolved.equipment.values.toList();
  final synergies = await loadDesignatedSynergies(
    db,
    userId,
    build.synergyTypes,
  );

  final kit = subclassKitFromJson(build.subclass);
  final subclassMap = subclassKitToJson(kit);

  final coverage = evaluateCoverage(
    CoverageEvalInput(
      claims: claims,
      synergies: synergies,
      subclass: subclassMap,
      setBonusByItemHash: setBonusByItemHash,
      weaponElementByHash: weaponElementByHash,
      softStatTargets: softStatTargetsFromJson(build.softStatTargets),
      statEstimate: statEstimate,
    ),
  );

  return CoverageQueryResult(
    buildId: buildId,
    variantId: variantId,
    coverage: coverage,
    claims: claims,
  );
}
