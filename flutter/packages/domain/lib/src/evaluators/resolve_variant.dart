/// Pure resolveVariant merge / conflict / completeness helpers.
///
/// Mirrors TypeScript `src/lib/builds/resolveVariant.ts` pure surface.
/// No DB load / attachment expansion (callers pass [ExpandedSetItem] lists).
library;

import '../models/equipment.dart';
import '../models/failure_codes.dart';
import '../models/kit.dart';
import '../models/library.dart';
import '../models/resolved_variant.dart';
import '../models/slot_claim.dart';
import 'default_loadout_completeness.dart';

/// Domain failure for resolve asserts / pair validation.
///
/// Codes match product API codes so adapters can map to HTTP later.
class ResolveVariantException implements Exception {
  const ResolveVariantException(
    this.message, {
    required this.code,
    this.details,
  });

  final String code;
  final String message;
  final Map<String, Object?>? details;

  @override
  String toString() => 'ResolveVariantException($code: $message)';
}

/// Effective exotic weapon after build-shared preference (TS `effectiveExoticWeapon`).
class EffectiveExoticWeapon {
  const EffectiveExoticWeapon({
    this.exoticWeaponHash,
    this.exoticWeaponName,
    required this.fromBuild,
  });

  final int? exoticWeaponHash;
  final String? exoticWeaponName;
  final bool fromBuild;
}

/// Prefer build-shared exotic weapon over variant-level pin.
EffectiveExoticWeapon effectiveExoticWeapon({
  int? buildExoticWeaponHash,
  String? buildExoticWeaponName,
  int? variantExoticWeaponHash,
  String? variantExoticWeaponName,
}) {
  if (buildExoticWeaponHash != null) {
    return EffectiveExoticWeapon(
      exoticWeaponHash: buildExoticWeaponHash,
      exoticWeaponName: buildExoticWeaponName,
      fromBuild: true,
    );
  }
  return EffectiveExoticWeapon(
    exoticWeaponHash: variantExoticWeaponHash,
    exoticWeaponName: variantExoticWeaponName,
    fromBuild: false,
  );
}

/// Convenience overload using DART-002 [Build] / [Variant] models.
EffectiveExoticWeapon effectiveExoticWeaponFromRecords(
  Build build,
  Variant variant,
) {
  return effectiveExoticWeapon(
    buildExoticWeaponHash: build.exoticWeaponHash,
    buildExoticWeaponName: build.exoticWeaponName,
    variantExoticWeaponHash: variant.exoticWeaponHash,
    variantExoticWeaponName: variant.exoticWeaponName,
  );
}

/// Convert expanded set items to slot claims (pair → [ClaimSource.pairSet]).
List<SlotClaim> itemsToSlotClaims(List<ExpandedSetItem> items) {
  return [for (final item in items) item.toSlotClaim()];
}

/// Detect slots claimed by more than one [SlotClaim].
List<SlotConflict> detectSlotConflicts(List<SlotClaim> claims) {
  final bySlot = <EquipmentSlot, List<SlotClaim>>{};
  for (final claim in claims) {
    bySlot.putIfAbsent(claim.slot, () => <SlotClaim>[]).add(claim);
  }
  final conflicts = <SlotConflict>[];
  for (final entry in bySlot.entries) {
    if (entry.value.length > 1) {
      conflicts.add(
        SlotConflict(slot: entry.key, claimants: List.unmodifiable(entry.value)),
      );
    }
  }
  return conflicts;
}

/// First-writer equipment map (first claim per slot wins).
Map<EquipmentSlot, SlotClaim> buildEquipmentMap(List<SlotClaim> claims) {
  final equipment = <EquipmentSlot, SlotClaim>{};
  for (final claim in claims) {
    equipment.putIfAbsent(claim.slot, () => claim);
  }
  return equipment;
}

/// Append exotic weapon claim when hash and slot are present.
List<SlotClaim> addExoticWeaponClaim(
  List<SlotClaim> claims, {
  int? exoticWeaponHash,
  String? exoticWeaponName,
  EquipmentSlot? weaponSlot,
  ClaimSource source = ClaimSource.variantExoticWeapon,
}) {
  if (exoticWeaponHash == null || weaponSlot == null) return claims;
  return [
    ...claims,
    SlotClaim(
      slot: weaponSlot,
      itemHash: exoticWeaponHash,
      itemName: exoticWeaponName ?? 'Exotic ($exoticWeaponHash)',
      source: source,
    ),
  ];
}

/// Append build exotic armor claim when hash and slot are present.
///
/// When [skipIfClassItemClaimed] is true and a class_item claim already exists
/// (class-item intent mode), returns [claims] unchanged.
List<SlotClaim> addExoticArmorClaim(
  List<SlotClaim> claims, {
  int? exoticArmorHash,
  String? exoticArmorName,
  EquipmentSlot? armorSlot,
  bool skipIfClassItemClaimed = false,
}) {
  if (armorSlot == null || exoticArmorHash == null) return claims;
  if (skipIfClassItemClaimed &&
      claims.any((c) => c.slot == EquipmentSlot.classItem)) {
    return claims;
  }
  return [
    ...claims,
    SlotClaim(
      slot: armorSlot,
      itemHash: exoticArmorHash,
      itemName: exoticArmorName ?? 'Exotic ($exoticArmorHash)',
      source: ClaimSource.buildExoticArmor,
    ),
  ];
}

/// Pair set exotic_armor must match build exotic armor (unless intent mode).
void validatePairArmorMatch({
  int? buildExoticArmorHash,
  required List<ExpandedSetItem> pairItems,
  bool intentMode = false,
}) {
  if (buildExoticArmorHash == null) return;
  ExpandedSetItem? pairArmor;
  for (final item in pairItems) {
    if (item.slot == EquipmentSlot.exoticArmor) {
      pairArmor = item;
      break;
    }
  }
  if (pairArmor == null) return;
  if (pairArmor.itemHash == buildExoticArmorHash) return;
  if (intentMode) return;
  throw ResolveVariantException(
    'Pair set exotic armor must match build exotic armor',
    code: DomainFailureCodes.pairArmorMismatch,
    details: {
      'expected': buildExoticArmorHash,
      'actual': pairArmor.itemHash,
    },
  );
}

/// Hard-block when any multi-claim conflicts exist.
void assertNoSlotConflicts(ResolvedVariantEquipment resolved) {
  if (resolved.conflicts.isEmpty) return;
  throw ResolveVariantException(
    'Multiple items claim the same equipment slot',
    code: DomainFailureCodes.slotConflict,
    details: {
      'conflicts': [
        for (final c in resolved.conflicts)
          {
            'slot': c.slot.wireName,
            'claimants': [
              for (final x in c.claimants)
                {
                  'source': x.source.wireName,
                  'setId': x.setId,
                  'itemHash': x.itemHash,
                },
            ],
          },
      ],
    },
  );
}

/// Hard-block when no equipment slots are filled.
void assertVariantNotEmpty(ResolvedVariantEquipment resolved) {
  if (resolved.equipment.isEmpty) {
    throw const ResolveVariantException(
      'Variant must fill at least one equipment slot',
      code: DomainFailureCodes.variantEmpty,
    );
  }
}

/// Required weapon slots for default full combat loadout (DBR-CMPL-001).
const List<EquipmentSlot> requiredWeaponSlots = EquipmentSlot.weaponSlots;

/// Required armor slots for default full combat loadout (DBR-CMPL-001).
const List<EquipmentSlot> requiredArmorSlots = EquipmentSlot.armorSlots;

/// Options for kit bar + artifact fill on default full combat (DBR-CMPL-001*).
class FullCombatLoadoutOptions {
  const FullCombatLoadoutOptions({
    this.maxAspects = maxSubclassAspects,
    this.fragmentCapacity = 0,
    this.capacityResolved = true,
    this.artifactHash,
    this.artifactConfig,
    this.subclassKit,
    this.requireKitAndArtifact = true,
  });

  final int maxAspects;
  final int fragmentCapacity;
  final bool capacityResolved;
  final int? artifactHash;
  final List<int>? artifactConfig;

  /// When set, used for kit-bar gaps instead of [subclassName]-only identity.
  final SubclassKitFields? subclassKit;

  /// When true (default), enforce subclass kit bar + artifact fill.
  /// Set false only for pure equipment-gap unit tests.
  final bool requireKitAndArtifact;
}

/// Default variant must be a full combat loadout (weapons + armor + identity +
/// mods + kit bar + artifact when [FullCombatLoadoutOptions.requireKitAndArtifact]).
///
/// [className] / [subclassName] are optional strings so incomplete drafts can
/// omit identity without requiring a full [Build] row.
void assertFullCombatLoadout(
  ResolvedVariantEquipment resolved, {
  String? className,
  String? subclassName,
  bool hasMods = false,
  FullCombatLoadoutOptions? options,
}) {
  final opts = options ?? const FullCombatLoadoutOptions();
  final missing = <String>[];
  for (final slot in requiredWeaponSlots) {
    if (!resolved.equipment.containsKey(slot)) missing.add(slot.wireName);
  }
  for (final slot in requiredArmorSlots) {
    if (!resolved.equipment.containsKey(slot)) missing.add(slot.wireName);
  }
  if (className == null || className.isEmpty) missing.add('className');

  final kitFields = opts.subclassKit ??
      (subclassName != null && subclassName.isNotEmpty
          ? SubclassKitFields(name: subclassName)
          : null);
  if (kitFields == null || !_nonEmptyName(kitFields.name)) {
    if (!missing.contains('subclass')) missing.add('subclass');
  }
  if (!hasMods) missing.add('mods');

  if (opts.requireKitAndArtifact) {
    for (final gap in collectSubclassKitCompleteGaps(
      kitFields,
      maxAspects: opts.maxAspects,
      fragmentCapacity: opts.fragmentCapacity,
      capacityResolved: opts.capacityResolved,
    )) {
      if (!missing.contains(gap)) missing.add(gap);
    }
    for (final gap in collectArtifactCompleteGaps(
      artifactHash: opts.artifactHash,
      artifactConfig: opts.artifactConfig,
    )) {
      if (!missing.contains(gap)) missing.add(gap);
    }
  }

  if (missing.isNotEmpty) {
    throw ResolveVariantException(
      'Default variant must be a full combat loadout',
      code: DomainFailureCodes.defaultVariantIncomplete,
      details: {'missing': missing},
    );
  }
}

bool _nonEmptyName(String? value) =>
    value != null && value.trim().isNotEmpty;

/// Completeness policy: default → full combat; non-default → non-empty only.
///
/// DBR-CMPL-001 / DBR-CMPL-002.
void assertVariantCompleteness(
  ResolvedVariantEquipment resolved, {
  required bool isDefault,
  String? className,
  String? subclassName,
  bool hasMods = false,
  FullCombatLoadoutOptions? options,
}) {
  assertVariantNotEmpty(resolved);
  if (isDefault) {
    assertFullCombatLoadout(
      resolved,
      className: className,
      subclassName: subclassName,
      hasMods: hasMods,
      options: options,
    );
  }
}

/// Pure claims-only resolve (TS `resolveVariantEquipment` without DB load).
///
/// [expandedItems] must already be loaded from attachments (live/snapshot).
/// Fashion sets should be filtered out by the caller before calling.
ResolvedVariantEquipment resolveVariantClaims({
  required List<ExpandedSetItem> expandedItems,
  int? buildExoticArmorHash,
  String? buildExoticArmorName,
  int? buildExoticWeaponHash,
  String? buildExoticWeaponName,
  int? variantExoticWeaponHash,
  String? variantExoticWeaponName,
  EquipmentSlot? exoticWeaponSlot,
  EquipmentSlot? exoticArmorSlot,
}) {
  final intentMode = exoticArmorSlot == EquipmentSlot.classItem;
  final pairItems = [
    for (final i in expandedItems)
      if (i.setType == SetType.pair) i,
  ];
  validatePairArmorMatch(
    buildExoticArmorHash: buildExoticArmorHash,
    pairItems: pairItems,
    intentMode: intentMode,
  );

  var claims = itemsToSlotClaims(expandedItems);
  final weapon = effectiveExoticWeapon(
    buildExoticWeaponHash: buildExoticWeaponHash,
    buildExoticWeaponName: buildExoticWeaponName,
    variantExoticWeaponHash: variantExoticWeaponHash,
    variantExoticWeaponName: variantExoticWeaponName,
  );
  claims = addExoticWeaponClaim(
    claims,
    exoticWeaponHash: weapon.exoticWeaponHash,
    exoticWeaponName: weapon.exoticWeaponName,
    weaponSlot: exoticWeaponSlot,
  );
  claims = addExoticArmorClaim(
    claims,
    exoticArmorHash: buildExoticArmorHash,
    exoticArmorName: buildExoticArmorName,
    armorSlot: exoticArmorSlot,
    skipIfClassItemClaimed: intentMode,
  );

  final conflicts = detectSlotConflicts(claims);
  return ResolvedVariantEquipment(
    equipment: buildEquipmentMap(claims),
    conflicts: conflicts,
  );
}

/// Convenience using [Build] / [Variant] exotic fields.
ResolvedVariantEquipment resolveVariantClaimsFromRecords({
  required List<ExpandedSetItem> expandedItems,
  required Build build,
  required Variant variant,
  EquipmentSlot? exoticWeaponSlot,
  EquipmentSlot? exoticArmorSlot,
}) {
  return resolveVariantClaims(
    expandedItems: expandedItems,
    buildExoticArmorHash: build.exoticArmorHash,
    buildExoticArmorName: build.exoticArmorName,
    buildExoticWeaponHash: build.exoticWeaponHash,
    buildExoticWeaponName: build.exoticWeaponName,
    variantExoticWeaponHash: variant.exoticWeaponHash,
    variantExoticWeaponName: variant.exoticWeaponName,
    exoticWeaponSlot: exoticWeaponSlot,
    exoticArmorSlot: exoticArmorSlot,
  );
}
