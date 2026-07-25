/// Pure DIM loadout JSON builders + equipReady-gated jsonOnly envelope.
///
/// Mirrors TypeScript `src/lib/dim/buildVariantDimLoadout.ts` and the pure
/// portion of dim-export `jsonOnly` (assert equip-ready → build loadout).
/// No network, no dim.gg share, no DB mod collection.
library;

import '../models/dim_loadout.dart';
import '../models/equipment.dart';
import '../models/pin.dart';
import '../models/slot_claim.dart';
import '../models/soft_stats.dart';
import 'equip_ready.dart';

/// Input for [buildVariantDimLoadout].
class VariantDimLoadoutInput {
  const VariantDimLoadoutInput({
    required this.buildName,
    required this.className,
    this.variantName,
    this.subclass,
    this.softStatTargets,
    this.equipment = const {},
    this.artifact,
    this.fashion,
    this.modHashes = const [],
  });

  final String buildName;
  final GuardianClass className;
  final String? variantName;
  final DimSubclassNote? subclass;
  final SoftStatTargets? softStatTargets;

  /// Applied combat claims (partial map OK).
  final Map<EquipmentSlot, SlotClaim> equipment;
  final DimArtifact? artifact;
  final DimFashion? fashion;
  final List<int> modHashes;
}

String? _subclassNote(DimSubclassNote? subclass) {
  if (subclass == null) return null;
  final name = subclass.name;
  final superName = subclass.superName;
  if ((name == null || name.isEmpty) &&
      (superName == null || superName.isEmpty)) {
    return null;
  }
  final parts = <String>[
    if (name != null && name.isNotEmpty) name,
    if (superName != null && superName.isNotEmpty) superName,
  ];
  return 'Subclass: ${parts.join(' / ')}';
}

String? _artifactNote(DimArtifact? artifact) {
  if (artifact == null) return null;
  final config = artifact.config.isNotEmpty
      ? ' unlocks=[${artifact.config.join(',')}]'
      : '';
  return 'Artifact: ${artifact.name} (${artifact.hash})$config';
}

List<DimStatConstraint> _softStatConstraints(SoftStatTargets? targets) {
  if (targets == null || targets.isEmpty) return const [];
  final out = <DimStatConstraint>[];
  for (final e in targets.values.entries) {
    final statHash = DimStatHashes.forArmorStat(e.key);
    if (statHash == null) continue;
    out.add(DimStatConstraint(statHash: statHash, minStat: e.value));
  }
  out.sort((a, b) => (b.minStat ?? 0).compareTo(a.minStat ?? 0));
  return out;
}

List<DimLoadoutItem> _buildEquipped(Map<EquipmentSlot, SlotClaim> equipment) {
  final items = <DimLoadoutItem>[];
  for (final slot in EquipmentSlot.combatSlots) {
    final claim = equipment[slot];
    if (claim == null) continue;
    Map<int, int>? overrides;
    final perks = claim.selectedPerks;
    if (perks != null && perks.isNotEmpty) {
      overrides = {
        for (var i = 0; i < perks.length; i++) i: perks[i],
      };
    }
    final instanceId = claim.instanceId;
    items.add(
      DimLoadoutItem(
        hash: claim.itemHash,
        id: (instanceId != null && instanceId.isNotEmpty) ? instanceId : null,
        socketOverrides: overrides,
      ),
    );
  }
  return items;
}

List<DimLoadoutItem> _buildUnequipped(DimFashion? fashion) {
  if (fashion == null || fashion.pieces.isEmpty) return const [];
  return [
    for (final piece in fashion.pieces) DimLoadoutItem(hash: piece.itemHash),
  ];
}

String? _buildNotes(VariantDimLoadoutInput input) {
  final parts = <String>[
    if (_subclassNote(input.subclass) case final s?) s,
    if (_artifactNote(input.artifact) case final a?) a,
  ];
  if (parts.isEmpty) return null;
  final joined = parts.join('\n');
  if (joined.length <= 1024) return joined;
  return joined.substring(0, 1024);
}

DimLoadoutParameters _buildParameters(VariantDimLoadoutInput input) {
  final constraints = _softStatConstraints(input.softStatTargets);
  int? exoticArmorHash;
  for (final slot in EquipmentSlot.combatSlots) {
    final claim = input.equipment[slot];
    if (claim?.source == ClaimSource.buildExoticArmor) {
      exoticArmorHash = claim!.itemHash;
      break;
    }
  }

  return DimLoadoutParameters(
    autoStatMods: true,
    includeRuntimeStatBenefits: true,
    mods: input.modHashes.isNotEmpty ? List<int>.from(input.modHashes) : null,
    statConstraints: constraints.isNotEmpty ? constraints : null,
    exoticArmorHash: exoticArmorHash,
  );
}

/// Map resolved variant (+ mods/soft stats) into a DIM Sync loadout.
///
/// [id] is injectable for deterministic goldens; hosts should pass a UUID.
DimLoadout buildVariantDimLoadout(
  VariantDimLoadoutInput input, {
  String? id,
}) {
  final rawName = input.variantName != null && input.variantName!.isNotEmpty
      ? '${input.buildName} — ${input.variantName}'
      : input.buildName;
  final name =
      rawName.length <= 120 ? rawName : rawName.substring(0, 120);

  return DimLoadout(
    id: id ?? 'dim-loadout-id',
    name: name,
    notes: _buildNotes(input),
    classType: DimClassType.fromGuardianClass(input.className),
    equipped: _buildEquipped(input.equipment),
    unequipped: _buildUnequipped(input.fashion),
    parameters: _buildParameters(input),
  );
}

/// Assert equip-ready then return the product jsonOnly envelope.
///
/// Shape: `{ "loadout": { ... DimLoadout toJson ... } }`.
/// Throws [EquipReadyException] with code `NOT_EQUIP_READY` when not ready.
Map<String, Object?> buildJsonOnlyDimExport({
  required EquipReadyResult readiness,
  required VariantDimLoadoutInput input,
  String? loadoutId,
}) {
  assertEquipReady(readiness);
  final loadout = buildVariantDimLoadout(input, id: loadoutId);
  return {'loadout': loadout.toJson()};
}
