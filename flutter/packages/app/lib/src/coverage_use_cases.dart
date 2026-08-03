import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_sandbox_data/destiny2_sandbox_data.dart';

import 'designation_chrome.dart';
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

/// Indexes for soft coverage (set-bonus piece map + weapon elements).
class CoverageIndexes {
  const CoverageIndexes({
    this.setBonusByItemHash = const {},
    this.weaponElementByHash = const {},
  });

  final Map<int, SetBonusRecord> setBonusByItemHash;
  final Map<int, String> weaponElementByHash;

  static const empty = CoverageIndexes();
}

/// Invert set-bonus records with [itemHashes] into per-item lookup.
///
/// Each entry is `(domainRecord, memberItemHashes)`.
Map<int, SetBonusRecord> buildSetBonusByItemHash(
  Iterable<({SetBonusRecord record, List<int> itemHashes})> rows,
) {
  final out = <int, SetBonusRecord>{};
  for (final row in rows) {
    for (final h in row.itemHashes) {
      out[h] = row.record;
    }
  }
  return out;
}

/// Build weapon element map from catalog-like rows (hash + optional element).
Map<int, String> buildWeaponElementByHash(
  Iterable<({int hash, String? element})> weapons,
) {
  final out = <int, String>{};
  for (final w in weapons) {
    final el = w.element?.trim();
    if (el != null && el.isNotEmpty) {
      out[w.hash] = el;
    }
  }
  return out;
}

/// Compose [CoverageIndexes] from optional partial maps / catalog weapons.
CoverageIndexes loadCoverageIndexes({
  Map<int, SetBonusRecord>? setBonusByItemHash,
  Map<int, String>? weaponElementByHash,
  Iterable<({int hash, String? element})>? weapons,
}) {
  final elements = <int, String>{
    ...?weaponElementByHash,
    ...buildWeaponElementByHash(weapons ?? const []),
  };
  return CoverageIndexes(
    setBonusByItemHash: setBonusByItemHash ?? const {},
    weaponElementByHash: elements,
  );
}

/// Element designations implied by verb designations (not already explicit).
///
/// e.g. Verb: Jolt → Element: Arc (DBR-SYN-013 / BR-SYN-009).
List<SynergyTypeDesignation> impliedElementDesignations(
  Iterable<SynergyTypeDesignation> designations,
) {
  final existing = {
    for (final d in designations) d.designationKey,
  };
  final out = <SynergyTypeDesignation>[];
  final seenImplied = <String>{};

  for (final d in designations) {
    if (d.type.wireName != 'verb') continue;
    final sub = d.subType?.trim();
    if (sub == null || sub.isEmpty) continue;
    final element = impliedElementForVerb(sub);
    if (element == null) continue;
    final implied = SynergyTypeDesignation(
      type: const SynergyType('element'),
      subType: element,
    );
    final key = implied.designationKey;
    if (existing.contains(key) || seenImplied.contains(key)) continue;
    seenImplied.add(key);
    out.add(implied);
  }
  return out;
}

/// Explicit designations plus any implied element designations (deduped).
List<SynergyTypeDesignation> expandDesignationsWithImpliedElements(
  Iterable<SynergyTypeDesignation> designations,
) {
  final list = designations.toList();
  final implied = impliedElementDesignations(list);
  if (implied.isEmpty) return list;
  return [...list, ...implied];
}

/// Aggregate links from all library records matching a designation (deduped).
List<SynergyLink> aggregateLinksForDesignation(Iterable<Synergy> matches) {
  final seen = <String>{};
  final links = <SynergyLink>[];
  for (final synergy in matches) {
    for (final link in synergy.links) {
      final key = [
        link.kind.wireName,
        link.itemHash ?? '',
        link.perkHash ?? '',
        link.originTraitHash ?? '',
        link.originTraitName ?? '',
        link.armorSetHash ?? '',
        link.armorSetName ?? '',
        link.bonusPieces ?? '',
        link.bonusName ?? '',
      ].join('|');
      if (seen.contains(key)) continue;
      seen.add(key);
      links.add(link);
    }
  }
  return links;
}

bool _libraryMatchesDesignation(Synergy s, SynergyTypeDesignation d) {
  if (s.type.wireName != d.type.wireName) return false;
  final dSub = d.subType?.trim() ?? '';
  final sSub = s.subType?.trim() ?? '';
  if (dSub.isEmpty) {
    // Type-only designation: any library row of that type.
    return true;
  }
  return sSub == dSub;
}

/// Synthetic designation-scoped synergies for soft coverage (Next shape).
List<Synergy> designationCoverageSynergies({
  required List<SynergyTypeDesignation> effectiveDesignations,
  required List<Synergy> librarySynergies,
}) {
  final out = <Synergy>[];
  for (final d in effectiveDesignations) {
    final key = d.designationKey;
    final matches = [
      for (final s in librarySynergies)
        if (_libraryMatchesDesignation(s, d)) s,
    ];
    out.add(
      Synergy(
        id: key,
        name: formatDesignationChrome(d.type.wireName, d.subType),
        type: d.type,
        subType: d.subType,
        links: aggregateLinksForDesignation(matches),
      ),
    );
  }
  return out;
}

/// Load designated library synergies matching build synergy type designations.
///
/// Expands verb→element implications (DBR-SYN-013) and aggregates multi-library
/// links per designation for soft coverage tiers.
Future<List<Synergy>> loadDesignatedSynergies(
  AppDatabase db,
  int userId,
  List<SynergyTypeDesignationRecord> designations,
) async {
  if (designations.isEmpty) return const [];
  final explicit = [
    for (final d in designations)
      SynergyTypeDesignation(
        type: SynergyType(d.type),
        subType: d.subType,
      ),
  ];
  final effective = expandDesignationsWithImpliedElements(explicit);
  final all = await listSynergies(db, userId);
  final library = [for (final row in all) synergyFromRecord(row)];
  return designationCoverageSynergies(
    effectiveDesignations: effective,
    librarySynergies: library,
  );
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
  CoverageIndexes? indexes,
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

  // Coverage uses the active variant's effective kit (DBR-CMPL-001c).
  final kit = loadEffectiveSubclassKit(
    buildSubclass: build.subclass,
    variantSubclassKit: variant.subclassKit,
    pinnedSuper: build.pinnedSuper,
  );
  final subclassMap = subclassKitToJson(kit);

  final idx = indexes ??
      loadCoverageIndexes(
        setBonusByItemHash: setBonusByItemHash,
        weaponElementByHash: weaponElementByHash,
      );

  final coverage = evaluateCoverage(
    CoverageEvalInput(
      claims: claims,
      synergies: synergies,
      subclass: subclassMap,
      setBonusByItemHash:
          idx.setBonusByItemHash.isEmpty ? null : idx.setBonusByItemHash,
      weaponElementByHash:
          idx.weaponElementByHash.isEmpty ? null : idx.weaponElementByHash,
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
