/// Default-variant required synergy links (DBR-SYN-007–010a, BR-VAR-050).
///
/// Satisfaction: equip-ready pins only for gear claims; wishlist does not count.
/// Non-gear applied-kit kinds (currently [SynergyLinkKind.artifactPerk] among the
/// six product kinds) use applied kit/config on the variant.
///
/// Mirrors TypeScript `src/lib/builds/assertRequiredLinks.ts`.
library;

import '../models/equipment.dart';
import '../models/failure_codes.dart';
import '../models/resolved_variant.dart';
import '../models/slot_claim.dart';
import '../models/synergy.dart';
import 'equip_ready.dart';
import 'resolve_variant.dart';
import 'soft_coverage.dart';

/// Link kinds satisfied by applied kit/config, not gear pins.
///
/// Among the current six [SynergyLinkKind] values only [artifactPerk] is
/// applied-kit; aspect/fragment/super/melee/grenade kinds land with
/// pkg-synergy-kinds-v1.
const Set<SynergyLinkKind> appliedKitLinkKinds = {
  SynergyLinkKind.artifactPerk,
};

/// One unsatisfied required link (product error details shape).
class RequiredLinkFailure {
  const RequiredLinkFailure({
    required this.synergyId,
    required this.synergyName,
    required this.linkId,
    required this.kind,
    required this.displayName,
    required this.reason,
  });

  final String synergyId;
  final String synergyName;
  final String linkId;
  final String kind;
  final String displayName;

  /// `unmatched` or `wishlist_or_stale`.
  final String reason;

  Map<String, Object?> toJson() => {
        'synergyId': synergyId,
        'synergyName': synergyName,
        'linkId': linkId,
        'kind': kind,
        'displayName': displayName,
        'reason': reason,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RequiredLinkFailure &&
        other.synergyId == synergyId &&
        other.synergyName == synergyName &&
        other.linkId == linkId &&
        other.kind == kind &&
        other.displayName == displayName &&
        other.reason == reason;
  }

  @override
  int get hashCode => Object.hash(
        synergyId,
        synergyName,
        linkId,
        kind,
        displayName,
        reason,
      );
}

/// Result of [isRequiredLinkSatisfied].
class RequiredLinkSatisfaction {
  const RequiredLinkSatisfaction.ok()
      : ok = true,
        reason = null;

  const RequiredLinkSatisfaction.fail(this.reason) : ok = false;

  final bool ok;
  final String? reason;
}

bool _claimIsEquipReady(SlotClaim claim, InventoryPinIndex inventory) {
  final instanceId = claim.instanceId;
  if (instanceId == null || instanceId.isEmpty) return false;
  final owned = inventory[instanceId];
  if (owned == null) return false;
  return owned == claim.itemHash;
}

/// Claims that are equip-ready (non-stale owned pins) on combat slots.
List<SlotClaim> equipReadyClaims(
  ResolvedVariantEquipment resolved,
  InventoryPinIndex inventory,
) {
  final out = <SlotClaim>[];
  for (final slot in EquipmentSlot.combatSlots) {
    final claim = resolved.equipment[slot];
    if (claim == null) continue;
    if (_claimIsEquipReady(claim, inventory)) out.add(claim);
  }
  return out;
}

/// Whether a required link is satisfied under DBR-SYN-010a.
///
/// Gear kinds use equip-ready claims only; wishlist-only identity never satisfies.
RequiredLinkSatisfaction isRequiredLinkSatisfied(
  SynergyLink link, {
  required List<SlotClaim> readyClaims,
  required List<SlotClaim> allClaims,
  MatchEvidenceContext? ctx,
}) {
  final context = ctx ?? const MatchEvidenceContext();

  if (appliedKitLinkKinds.contains(link.kind)) {
    final ok = matchEvidenceLink(link, allClaims, context);
    return ok
        ? const RequiredLinkSatisfaction.ok()
        : const RequiredLinkSatisfaction.fail('unmatched');
  }

  // Soft evidence can match wishlist; required must use equip-ready only.
  final softMatch = matchEvidenceLink(link, allClaims, context);
  if (!softMatch) {
    return const RequiredLinkSatisfaction.fail('unmatched');
  }
  final readyMatch = matchEvidenceLink(link, readyClaims, context);
  if (!readyMatch) {
    return const RequiredLinkSatisfaction.fail('wishlist_or_stale');
  }
  return const RequiredLinkSatisfaction.ok();
}

/// Collect unsatisfied required links (does not throw).
List<RequiredLinkFailure> collectRequiredLinkFailures({
  required List<Synergy> synergies,
  required ResolvedVariantEquipment resolved,
  required InventoryPinIndex inventory,
  MatchEvidenceContext? ctx,
}) {
  final allClaims = resolved.equipment.values.toList();
  final readyClaims = equipReadyClaims(resolved, inventory);
  final context = ctx ?? const MatchEvidenceContext();

  final failures = <RequiredLinkFailure>[];
  for (final synergy in synergies) {
    for (final link in synergy.links) {
      if (!link.required) continue;
      final result = isRequiredLinkSatisfied(
        link,
        readyClaims: readyClaims,
        allClaims: allClaims,
        ctx: context,
      );
      if (result.ok) continue;
      failures.add(
        RequiredLinkFailure(
          synergyId: synergy.id,
          synergyName: synergy.name,
          linkId: link.id,
          kind: link.kind.wireName,
          displayName: link.displayName,
          reason: result.reason ?? 'unmatched',
        ),
      );
    }
  }
  return failures;
}

/// Hard-block when any required links are unsatisfied.
void assertRequiredLinksSatisfied({
  required List<Synergy> synergies,
  required ResolvedVariantEquipment resolved,
  required InventoryPinIndex inventory,
  MatchEvidenceContext? ctx,
}) {
  final unsatisfied = collectRequiredLinkFailures(
    synergies: synergies,
    resolved: resolved,
    inventory: inventory,
    ctx: ctx,
  );
  if (unsatisfied.isEmpty) return;
  throw ResolveVariantException(
    'Default variant required synergy links need equip-ready pins',
    code: DomainFailureCodes.requiredLinkUnsatisfied,
    details: {
      'unsatisfied': [for (final f in unsatisfied) f.toJson()],
    },
  );
}
