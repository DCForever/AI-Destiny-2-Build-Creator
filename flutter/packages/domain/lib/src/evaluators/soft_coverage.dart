/// Pure soft coverage evaluators (TS `coverage.ts`).
///
/// Soft guidance only — results are [CoverageResult], never [HardBlock]s.
/// Soft guidance never auto-applies kit/pin/target mutations.
library;

import '../models/coverage.dart';
import '../models/equipment.dart';
import '../models/set_bonus.dart';
import '../models/slot_claim.dart';
import '../models/soft_stats.dart';
import '../models/synergy.dart';
import 'stat_estimate.dart';

/// Input for [evaluateCoverage] (pure; no IO).
class CoverageEvalInput {
  const CoverageEvalInput({
    required this.claims,
    required this.synergies,
    this.subclassElement,
    this.subclass,
    this.setBonusByItemHash,
    this.weaponElementByHash,
    this.softStatTargets = const SoftStatTargets(),
    this.statEstimate,
  });

  final List<SlotClaim> claims;
  final List<Synergy> synergies;

  /// Preferred already-resolved subclass element (e.g. `Arc`, `Solar`).
  final String? subclassElement;

  /// Optional TS-like record for element heuristic when [subclassElement] is null.
  final Map<String, Object?>? subclass;

  /// itemHash → set bonus record.
  final Map<int, SetBonusRecord>? setBonusByItemHash;

  /// itemHash → element name for weapons.
  final Map<int, String>? weaponElementByHash;

  final SoftStatTargets softStatTargets;
  final StatEstimate? statEstimate;
}

/// Map matched count / total evidence links → soft tier (TS `tierForMatches`).
CoverageTier tierForMatches(int matched, int total) {
  if (total == 0 || matched == 0) return CoverageTier.missing;
  if (matched >= total) return CoverageTier.supported;
  return CoverageTier.weak;
}

/// Optional match context (TS `MatchEvidenceContext`).
///
/// [setBonusByItemHash] and [artifactConfig] power armor-set / artifact_perk
/// matches. [perkFamilyByHash] enables base/enhanced perk family (DBR-SYN-014a).
/// [exoticClassItemHashes] enables class-item exotic_armor perk config (DBR-ID-011).
class MatchEvidenceContext {
  const MatchEvidenceContext({
    this.setBonusByItemHash,
    this.artifactConfig,
    this.kit,
    this.perkFamilyByHash,
    this.exoticClassItemHashes,
  });

  final Map<int, SetBonusRecord>? setBonusByItemHash;
  final List<int>? artifactConfig;

  /// Kit name fields for future applied-kit kinds (aspect/fragment/…); unused
  /// until pkg-synergy-kinds-v1 expands [SynergyLinkKind].
  final Map<String, Object?>? kit;
  final Map<int, Set<int>>? perkFamilyByHash;
  final Set<int>? exoticClassItemHashes;
}

bool _selectedPerksIncludeFamily(
  List<int>? selected,
  int targetHash,
  Map<int, Set<int>>? familyByHash,
) {
  final perks = selected ?? const <int>[];
  if (perks.contains(targetHash)) return true;
  final family = familyByHash?[targetHash];
  if (family == null) return false;
  for (final p in perks) {
    if (family.contains(p)) return true;
  }
  return false;
}

MatchEvidenceContext _asMatchCtx(Object? setBonusByItemHashOrCtx) {
  if (setBonusByItemHashOrCtx is MatchEvidenceContext) {
    return setBonusByItemHashOrCtx;
  }
  if (setBonusByItemHashOrCtx is Map<int, SetBonusRecord>) {
    return MatchEvidenceContext(setBonusByItemHash: setBonusByItemHashOrCtx);
  }
  return const MatchEvidenceContext();
}

/// Whether an evidence link is satisfied by current claims (soft match only).
///
/// Third argument may be a [Map] of set bonuses (legacy) or [MatchEvidenceContext].
bool matchEvidenceLink(
  SynergyLink link,
  List<SlotClaim> claims, [
  Object? setBonusByItemHashOrCtx,
]) {
  final ctx = _asMatchCtx(setBonusByItemHashOrCtx);
  final setBonusByItemHash = ctx.setBonusByItemHash;

  switch (link.kind) {
    case SynergyLinkKind.weapon:
      return link.itemHash != null &&
          claims.any((c) => c.itemHash == link.itemHash);
    case SynergyLinkKind.weaponPerk:
      return link.perkHash != null &&
          claims.any(
            (c) => _selectedPerksIncludeFamily(
              c.selectedPerks,
              link.perkHash!,
              ctx.perkFamilyByHash,
            ),
          );
    case SynergyLinkKind.originTrait:
      final originHash = link.originTraitHash;
      if (originHash != null) {
        return claims.any(
          (c) => _selectedPerksIncludeFamily(
            c.selectedPerks,
            originHash,
            ctx.perkFamilyByHash,
          ),
        );
      }
      return false;
    case SynergyLinkKind.armorSetBonus:
      final needed = link.bonusPieces ?? 2;
      final map = setBonusByItemHash;
      if (link.armorSetHash != null && map != null) {
        var count = 0;
        for (final claim in claims) {
          if (!EquipmentSlot.armorSlots.contains(claim.slot)) continue;
          final bonus = map[claim.itemHash];
          if (bonus?.hash == link.armorSetHash) count += 1;
        }
        return count >= needed;
      }
      if (link.armorSetName != null && link.armorSetName!.isNotEmpty) {
        if (map == null) return false;
        var count = 0;
        for (final claim in claims) {
          if (!EquipmentSlot.armorSlots.contains(claim.slot)) continue;
          final bonus = map[claim.itemHash];
          if (bonus?.name == link.armorSetName) count += 1;
        }
        return count >= needed;
      }
      return false;
    case SynergyLinkKind.exoticArmor:
      // DBR-ID-011: classic = item hash; exotic class items = perk config only.
      final knownClassItem = link.itemHash != null &&
          ctx.exoticClassItemHashes != null &&
          ctx.exoticClassItemHashes!.contains(link.itemHash);

      if (knownClassItem) {
        if (link.perkHash == null) return false;
        return claims.any(
          (c) =>
              c.slot == EquipmentSlot.classItem &&
              _selectedPerksIncludeFamily(
                c.selectedPerks,
                link.perkHash!,
                ctx.perkFamilyByHash,
              ),
        );
      }

      if (link.itemHash != null) {
        final byItem = claims.any(
          (c) =>
              EquipmentSlot.armorSlots.contains(c.slot) &&
              c.itemHash == link.itemHash,
        );
        if (byItem) return true;
        // Soft legacy: any-slot itemHash match (pre-class-item indexes).
        if (claims.any((c) => c.itemHash == link.itemHash)) return true;
      }

      if (link.perkHash != null) {
        return claims.any(
          (c) =>
              c.slot == EquipmentSlot.classItem &&
              _selectedPerksIncludeFamily(
                c.selectedPerks,
                link.perkHash!,
                ctx.perkFamilyByHash,
              ),
        );
      }
      return false;
    case SynergyLinkKind.artifactPerk:
      final hash = link.perkHash ?? link.itemHash;
      if (hash == null) return false;
      // Prefer applied artifact config when provided (product parity).
      final config = ctx.artifactConfig;
      if (config != null) {
        return config.contains(hash);
      }
      // Fallback: selectedPerks on claims (soft path without variant context).
      return claims.any(
        (c) => (c.selectedPerks ?? const []).contains(hash),
      );
  }
}

LinkMatchSummary _linkSummary(SynergyLink link) {
  return LinkMatchSummary(
    kind: link.kind.wireName,
    displayName: link.displayName,
    id: link.id,
  );
}

String? _hintForTier(CoverageTier tier, String name) {
  if (tier == CoverageTier.supported) return null;
  if (tier == CoverageTier.weak) {
    return 'Add remaining links to fully support $name.';
  }
  return 'No evidence links matched for $name.';
}

String? _resolveSubclassElement(CoverageEvalInput input) {
  final explicit = input.subclassElement?.trim();
  if (explicit != null && explicit.isNotEmpty) return explicit;

  final subclass = input.subclass;
  if (subclass == null) return null;
  final el = subclass['element'];
  if (el is String && el.trim().isNotEmpty) return el.trim();

  final text = subclass.toString().toLowerCase();
  for (final name in const [
    'solar',
    'arc',
    'void',
    'stasis',
    'strand',
    'prismatic',
  ]) {
    if (text.contains(name)) {
      return '${name[0].toUpperCase()}${name.substring(1)}';
    }
  }
  return null;
}

/// Evaluate soft coverage for a variant composition.
///
/// Returns [CoverageResult] only. Never emits hard blocks or mutates inputs.
CoverageResult evaluateCoverage(CoverageEvalInput input) {
  final claims = input.claims;
  final synergies = input.synergies;
  final setBonusByItemHash = input.setBonusByItemHash;
  final softStatTargets = input.softStatTargets;
  final statEstimate = input.statEstimate;

  final synergyRows = <SynergyCoverageRow>[];
  for (final synergy in synergies) {
    final matchedLinks = <LinkMatchSummary>[];
    final unmatchedLinks = <LinkMatchSummary>[];
    for (final link in synergy.links) {
      if (matchEvidenceLink(link, claims, setBonusByItemHash)) {
        matchedLinks.add(_linkSummary(link));
      } else {
        unmatchedLinks.add(_linkSummary(link));
      }
    }
    final tier = tierForMatches(matchedLinks.length, synergy.links.length);
    synergyRows.add(
      SynergyCoverageRow(
        synergyId: synergy.id,
        name: synergy.name,
        tier: tier,
        matchedLinks: matchedLinks,
        unmatchedLinks: unmatchedLinks,
        hint: _hintForTier(tier, synergy.name),
      ),
    );
  }

  final setBonuses = <SetBonusSoftRow>[];
  if (setBonusByItemHash != null) {
    final bySet = <int, ({SetBonusRecord record, int count})>{};
    for (final claim in claims) {
      if (!EquipmentSlot.armorSlots.contains(claim.slot)) continue;
      final record = setBonusByItemHash[claim.itemHash];
      if (record == null) continue;
      final prev = bySet[record.hash];
      bySet[record.hash] = (
        record: record,
        count: (prev?.count ?? 0) + 1,
      );
    }
    for (final entry in bySet.values) {
      final record = entry.record;
      final count = entry.count;
      final activeBonuses = record.perks
          .where((p) => count >= p.requiredCount)
          .map((p) => '${p.requiredCount}pc')
          .toList(growable: false);
      final maxRequired = record.perks.isEmpty
          ? 0
          : record.perks
              .map((p) => p.requiredCount)
              .reduce((a, b) => a > b ? a : b);
      SetBonusSoftStatus status = SetBonusSoftStatus.inactive;
      if (activeBonuses.isNotEmpty) {
        status = SetBonusSoftStatus.active;
      } else if (count > 0 && count < maxRequired) {
        status = SetBonusSoftStatus.partial;
      }

      final supportedSynergyIds = synergies
          .where(
            (s) => s.links.any(
              (l) =>
                  l.kind == SynergyLinkKind.armorSetBonus &&
                  (l.armorSetHash == record.hash ||
                      l.armorSetName == record.name),
            ),
          )
          .map((s) => s.id)
          .toList(growable: false);

      String? hint;
      if (status == SetBonusSoftStatus.partial) {
        hint = 'Need more pieces of ${record.name} for the next bonus.';
      } else if (status == SetBonusSoftStatus.inactive) {
        hint = 'No set bonus active for ${record.name}.';
      }

      setBonuses.add(
        SetBonusSoftRow(
          setName: record.name,
          armorSetHash: record.hash,
          pieceCount: count,
          status: status,
          activeBonuses: activeBonuses,
          supportedSynergyIds: supportedSynergyIds,
          hint: hint,
        ),
      );
    }
  }

  final elementMismatches = <ElementSoftMismatch>[];
  final subEl = _resolveSubclassElement(input);
  final weaponElementByHash = input.weaponElementByHash;
  if (subEl != null &&
      subEl.toLowerCase() != 'prismatic' &&
      weaponElementByHash != null) {
    for (final claim in claims) {
      if (!EquipmentSlot.weaponSlots.contains(claim.slot)) continue;
      final weaponEl = weaponElementByHash[claim.itemHash];
      if (weaponEl == null || weaponEl.toLowerCase() == 'kinetic') continue;
      if (weaponEl.toLowerCase() != subEl.toLowerCase()) {
        elementMismatches.add(
          ElementSoftMismatch(
            slot: claim.slot,
            weaponElement: weaponEl,
            subclassElement: subEl,
            hint:
                '${claim.slot.wireName} is $weaponEl; subclass is $subEl.',
          ),
        );
      }
    }
  }

  final softStats = statEstimate != null
      ? softStatWarnings(softStatTargets, statEstimate)
      : const <SoftStatWarningRow>[];

  return CoverageResult(
    synergies: synergyRows,
    setBonuses: setBonuses,
    elementMismatches: elementMismatches,
    targets: softStatTargets,
    statEstimate: statEstimate,
    softStats: softStats,
  );
}
