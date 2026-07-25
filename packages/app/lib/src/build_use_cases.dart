import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:drift/drift.dart' show Value;

import 'attachment_use_cases.dart';
import 'clock_ids.dart';
import 'errors.dart';
import 'hard_gate_ports.dart';
import 'hard_gates.dart';
import 'mappers.dart';
import 'variant_use_cases.dart';

/// Build + variants for detail views.
class BuildDetail {
  const BuildDetail({
    required this.build,
    this.variants = const [],
  });

  final BuildRecord build;
  final List<VariantRecord> variants;

  Build get domain => buildFromRecord(build);
}

/// Create build input (identity + optional default variant seed).
class CreateBuildCommand {
  const CreateBuildCommand({
    this.id,
    this.name,
    required this.className,
    this.subclass = const SubclassKit(),
    this.exoticArmorHash,
    this.exoticArmorName,
    this.exoticWeaponHash,
    this.exoticWeaponName,
    this.pinnedSuper,
    this.softStatTargets = const SoftStatTargets(),
    this.tagIds = const [],
    this.synergyTypes = const [],
    this.defaultVariant,
  });

  final String? id;
  final String? name;
  final GuardianClass className;
  final SubclassKit subclass;
  final int? exoticArmorHash;
  final String? exoticArmorName;
  final int? exoticWeaponHash;
  final String? exoticWeaponName;
  final String? pinnedSuper;
  final SoftStatTargets softStatTargets;
  final List<String> tagIds;
  final List<SynergyTypeDesignation> synergyTypes;
  final DefaultVariantSeed? defaultVariant;
}

/// Optional default variant fields on create.
class DefaultVariantSeed {
  const DefaultVariantSeed({
    this.id,
    this.name = 'Default',
    this.exoticWeaponHash,
    this.exoticWeaponName,
    this.artifactHash,
    this.artifactName,
    this.artifactConfig = const [],
    this.notes,
    this.attachments = const [],
  });

  final String? id;
  final String name;
  final int? exoticWeaponHash;
  final String? exoticWeaponName;
  final int? artifactHash;
  final String? artifactName;
  final List<int> artifactConfig;
  final String? notes;
  final List<SetAttachmentInput> attachments;
}

/// Partial build update.
class UpdateBuildCommand {
  const UpdateBuildCommand({
    this.name,
    this.className,
    this.subclass,
    this.setExoticArmor = false,
    this.exoticArmorHash,
    this.exoticArmorName,
    this.setExoticWeapon = false,
    this.exoticWeaponHash,
    this.exoticWeaponName,
    this.setPinnedSuper = false,
    this.pinnedSuper,
    this.softStatTargets,
    this.tagIds,
    this.synergyTypes,
  });

  final String? name;
  final GuardianClass? className;
  final SubclassKit? subclass;
  final bool setExoticArmor;
  final int? exoticArmorHash;
  final String? exoticArmorName;
  final bool setExoticWeapon;
  final int? exoticWeaponHash;
  final String? exoticWeaponName;
  final bool setPinnedSuper;
  final String? pinnedSuper;
  final SoftStatTargets? softStatTargets;
  final List<String>? tagIds;
  final List<SynergyTypeDesignation>? synergyTypes;
}

List<SynergyTypeDesignation> normalizeDesignations(
  List<SynergyTypeDesignation> input,
) {
  final seen = <String>{};
  final out = <SynergyTypeDesignation>[];
  for (final d in input) {
    final typeWire = d.type.wireName.trim();
    if (typeWire.isEmpty) {
      throw UseCaseException(
        UseCaseErrorCode.invalidArgument,
        'Synergy designation type is required',
      );
    }
    final sub = d.subType?.trim();
    final normalized = SynergyTypeDesignation(
      type: SynergyType(typeWire),
      subType: (sub == null || sub.isEmpty) ? null : sub,
    );
    if (seen.add(normalized.designationKey)) {
      out.add(normalized);
    }
  }
  return out;
}

String _resolveCreateName(CreateBuildCommand input) {
  final trimmed = input.name?.trim() ?? '';
  if (trimmed.isNotEmpty) return trimmed;
  final className = input.className.wireName;
  final kitName = input.subclass.name?.trim();
  if (kitName != null && kitName.isNotEmpty) {
    return '$className $kitName';
  }
  return '$className Build';
}

/// List builds for [userId].
Future<List<BuildRecord>> listUserBuilds(AppDatabase db, int userId) {
  return listBuilds(db, userId);
}

/// Get build detail (build + variants) or null.
Future<BuildDetail?> getBuildDetail(
  AppDatabase db,
  int userId,
  String buildId,
) async {
  final build = await getBuild(db, userId, buildId);
  if (build == null) return null;
  final variants = await listVariants(db, buildId);
  return BuildDetail(build: build, variants: variants);
}

/// Create build with hard identity gates; optional default attachments re-validated.
Future<BuildDetail> createUserBuild(
  AppDatabase db,
  int userId,
  CreateBuildCommand input, {
  NowClock now = defaultNow,
  IdGenerator newId = defaultNewId,
  HardGatePorts ports = HardGatePorts.defaults,
}) async {
  final synergyTypes = normalizeDesignations(input.synergyTypes);
  await assertBuildIdentityHardGates(
    synergyTypes: synergyTypes,
    subclass: input.subclass,
    exoticArmorHash: input.exoticArmorHash,
    exoticArmorName: input.exoticArmorName,
    pinnedSuper: input.pinnedSuper,
    ports: ports,
  );

  final name = _resolveCreateName(input);
  final buildId = input.id ?? newId();
  final seed = input.defaultVariant ?? const DefaultVariantSeed();
  final variantId = seed.id ?? newId();
  final ts = now();

  final exoticArmorHash = input.exoticArmorHash;
  final exoticArmorName = exoticArmorHash == null
      ? null
      : (input.exoticArmorName ?? 'Exotic ($exoticArmorHash)');
  final exoticWeaponHash = input.exoticWeaponHash;
  final exoticWeaponName = exoticWeaponHash == null
      ? null
      : (input.exoticWeaponName ?? 'Exotic ($exoticWeaponHash)');

  await createBuildRecord(
    db,
    userId,
    id: buildId,
    name: name,
    className: input.className.wireName,
    subclass: subclassKitToJson(input.subclass),
    exoticArmorHash: exoticArmorHash,
    exoticArmorName: exoticArmorName,
    exoticWeaponHash: exoticWeaponHash,
    exoticWeaponName: exoticWeaponName,
    pinnedSuper: input.pinnedSuper,
    softStatTargets: softStatTargetsToJson(input.softStatTargets),
    tagIds: input.tagIds,
    synergyTypes: designationsToRecords(synergyTypes),
    now: ts,
  );

  await createVariantRecord(
    db,
    id: variantId,
    buildId: buildId,
    name: seed.name.trim().isEmpty ? 'Default' : seed.name.trim(),
    isDefault: true,
    exoticWeaponHash: seed.exoticWeaponHash,
    exoticWeaponName: seed.exoticWeaponName,
    artifactHash: seed.artifactHash,
    artifactName: seed.artifactName,
    artifactConfig: seed.artifactConfig,
    notes: seed.notes,
    now: ts,
  );

  if (seed.attachments.isNotEmpty) {
    try {
      await prepareAttachments(
        db,
        userId,
        variantId,
        seed.attachments,
        now: () => ts,
      );
      await validateVariantSave(
        db,
        userId,
        buildId,
        variantId,
        ports: ports,
      );
    } catch (e) {
      // R2: failed hard validation must not leave illegal default variant.
      await deleteBuildRecord(db, userId, buildId);
      rethrow;
    }
  }

  return (await getBuildDetail(db, userId, buildId))!;
}

/// Update build identity fields with hard gates.
Future<BuildDetail?> updateUserBuild(
  AppDatabase db,
  int userId,
  String buildId,
  UpdateBuildCommand input, {
  NowClock now = defaultNow,
  HardGatePorts ports = HardGatePorts.defaults,
}) async {
  final existing = await getBuild(db, userId, buildId);
  if (existing == null) return null;

  final nextSynergy = input.synergyTypes != null
      ? normalizeDesignations(input.synergyTypes!)
      : designationsFromRecords(existing.synergyTypes);
  final nextSubclass = input.subclass ?? subclassKitFromJson(existing.subclass);
  final nextExoticHash = input.setExoticArmor
      ? input.exoticArmorHash
      : existing.exoticArmorHash;
  final nextExoticName = input.setExoticArmor
      ? input.exoticArmorName
      : existing.exoticArmorName;
  final nextPinned =
      input.setPinnedSuper ? input.pinnedSuper : existing.pinnedSuper;

  // Re-run identity gates when identity-affecting fields change or always for safety.
  await assertBuildIdentityHardGates(
    synergyTypes: nextSynergy,
    subclass: nextSubclass,
    exoticArmorHash: nextExoticHash,
    exoticArmorName: nextExoticName,
    pinnedSuper: nextPinned,
    ports: ports,
  );

  String? nextName;
  if (input.name != null) {
    final trimmed = input.name!.trim();
    if (trimmed.isEmpty) {
      throw UseCaseException(
        UseCaseErrorCode.invalidArgument,
        'Build name cannot be empty',
      );
    }
    nextName = trimmed;
  }

  final ts = now();
  await updateBuildRecord(
    db,
    userId,
    buildId,
    name: nextName,
    className: input.className?.wireName,
    subclass: input.subclass != null ? subclassKitToJson(input.subclass!) : null,
    exoticArmorHash:
        input.setExoticArmor ? Value(input.exoticArmorHash) : const Value.absent(),
    exoticArmorName:
        input.setExoticArmor ? Value(input.exoticArmorName) : const Value.absent(),
    exoticWeaponHash: input.setExoticWeapon
        ? Value(input.exoticWeaponHash)
        : const Value.absent(),
    exoticWeaponName: input.setExoticWeapon
        ? Value(input.exoticWeaponName)
        : const Value.absent(),
    pinnedSuper:
        input.setPinnedSuper ? Value(input.pinnedSuper) : const Value.absent(),
    softStatTargets: input.softStatTargets != null
        ? softStatTargetsToJson(input.softStatTargets!)
        : null,
    tagIds: input.tagIds,
    synergyTypes: input.synergyTypes != null
        ? designationsToRecords(nextSynergy)
        : null,
    now: ts,
  );

  return getBuildDetail(db, userId, buildId);
}

/// Delete build owned by [userId].
Future<bool> deleteUserBuild(AppDatabase db, int userId, String buildId) {
  return deleteBuildRecord(db, userId, buildId);
}
