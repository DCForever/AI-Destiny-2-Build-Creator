import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_sandbox_data/destiny2_sandbox_data.dart' as sandbox;

/// Resolved fragment capacity for subclass kit hard evaluation.
class FragmentCapacityResult {
  const FragmentCapacityResult({
    required this.capacity,
    required this.resolvedCount,
  });

  final int capacity;
  final int resolvedCount;
}

/// Lookup fragment capacity for aspect names (manifest-backed in hosts).
typedef FragmentCapacityResolver = Future<FragmentCapacityResult> Function(
  List<String> aspectNames,
);

/// Exotic ability requirements for a build exotic armor pin.
typedef AbilityRequirementsLookup = AbilityKit? Function({
  int? hash,
  String? name,
});

/// Classify exotic weapon/armor hashes among equipment claims.
typedef ExoticCompositionClassifier = Future<ExoticComposition> Function(
  List<SlotClaim> claims,
);

/// Build mod-energy piece rows for hard evaluation (empty → skip check).
typedef ModEnergyPiecesResolver = Future<List<ModEnergyPiece>> Function({
  required List<Attachment> attachments,
  required Map<EquipmentSlot, SlotClaim> equipment,
});

/// Resolve equipment slot for an exotic weapon hash (null → skip pin claim).
typedef ExoticWeaponSlotResolver = Future<EquipmentSlot?> Function(
  int? weaponHash,
);

/// Resolve equipment slot for an exotic armor hash (null → skip pin claim).
typedef ExoticArmorSlotResolver = Future<EquipmentSlot?> Function(
  int? armorHash,
);

/// Injectable ports for hard gates that need entity/sandbox data.
class HardGatePorts {
  const HardGatePorts({
    this.resolveFragmentCapacity = defaultFragmentCapacity,
    this.lookupAbilityRequirements = defaultAbilityRequirements,
    this.classifyExoticComposition = defaultExoticComposition,
    this.resolveModEnergyPieces = defaultModEnergyPieces,
    this.resolveExoticWeaponSlot = defaultExoticWeaponSlot,
    this.resolveExoticArmorSlot = defaultExoticArmorSlot,
  });

  final FragmentCapacityResolver resolveFragmentCapacity;
  final AbilityRequirementsLookup lookupAbilityRequirements;
  final ExoticCompositionClassifier classifyExoticComposition;
  final ModEnergyPiecesResolver resolveModEnergyPieces;
  final ExoticWeaponSlotResolver resolveExoticWeaponSlot;
  final ExoticArmorSlotResolver resolveExoticArmorSlot;

  static const defaults = HardGatePorts();
}

/// Default: no entity store → capacity 0, resolvedCount 0 (capacityResolved false when aspects present).
Future<FragmentCapacityResult> defaultFragmentCapacity(
  List<String> aspectNames,
) async {
  return const FragmentCapacityResult(capacity: 0, resolvedCount: 0);
}

/// Default: curated sandbox table (may be empty until product expands it).
AbilityKit? defaultAbilityRequirements({int? hash, String? name}) {
  final fields = sandbox.lookupExoticAbilityRequirements(
    hash: hash,
    name: name,
  );
  if (fields == null || fields.isEmpty) return null;
  return AbilityKit(
    superAbility: fields.superAbility,
    melee: fields.melee,
    grenade: fields.grenade,
    classAbility: fields.classAbility,
  );
}

/// Default: claim source + exotic_* slots (optional hash sets via custom port).
Future<ExoticComposition> defaultExoticComposition(
  List<SlotClaim> claims,
) async {
  final weapons = <int>[];
  final armor = <int>[];
  for (final claim in claims) {
    final isWeapon = claim.slot == EquipmentSlot.exoticWeapon ||
        claim.source == ClaimSource.variantExoticWeapon;
    final isArmor = claim.slot == EquipmentSlot.exoticArmor ||
        claim.source == ClaimSource.buildExoticArmor;
    if (isWeapon) weapons.add(claim.itemHash);
    if (isArmor) armor.add(claim.itemHash);
  }
  return ExoticComposition(
    exoticWeaponHashes: weapons,
    exoticArmorHashes: armor,
  );
}

/// Default: no mod cost table → empty pieces (mod energy check skipped).
Future<List<ModEnergyPiece>> defaultModEnergyPieces({
  required List<Attachment> attachments,
  required Map<EquipmentSlot, SlotClaim> equipment,
}) async {
  return const [];
}

/// Default: no slot known without entity cache.
Future<EquipmentSlot?> defaultExoticWeaponSlot(int? weaponHash) async => null;

/// Default: no slot known without entity cache.
Future<EquipmentSlot?> defaultExoticArmorSlot(int? armorHash) async => null;

/// Test helper: fixed capacity fully resolved for all aspects.
FragmentCapacityResolver fixedFragmentCapacity(int capacity) {
  return (aspectNames) async => FragmentCapacityResult(
        capacity: capacity,
        resolvedCount: aspectNames.length,
      );
}

/// Test helper: exotic composition from explicit hash membership sets.
ExoticCompositionClassifier exoticCompositionFromHashSets({
  Set<int> exoticWeapons = const {},
  Set<int> exoticArmor = const {},
}) {
  return (claims) async {
    final weapons = <int>[];
    final armor = <int>[];
    for (final claim in claims) {
      final isWeapon = exoticWeapons.contains(claim.itemHash) ||
          claim.slot == EquipmentSlot.exoticWeapon ||
          claim.source == ClaimSource.variantExoticWeapon;
      final isArmor = exoticArmor.contains(claim.itemHash) ||
          claim.slot == EquipmentSlot.exoticArmor ||
          claim.source == ClaimSource.buildExoticArmor;
      if (isWeapon) weapons.add(claim.itemHash);
      if (isArmor) armor.add(claim.itemHash);
    }
    return ExoticComposition(
      exoticWeaponHashes: weapons,
      exoticArmorHashes: armor,
    );
  };
}
