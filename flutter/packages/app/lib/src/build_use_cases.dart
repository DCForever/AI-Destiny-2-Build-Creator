import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:drift/drift.dart' show Value;

import 'attachment_use_cases.dart';
import 'clock_ids.dart';
import 'errors.dart';
import 'hard_gate_ports.dart';
import 'hard_gates.dart';
import 'identity_change.dart';
import 'mappers.dart';
import 'variant_use_cases.dart';

/// Build + variants for detail views.
class BuildDetail {
  const BuildDetail({
    required this.build,
    this.variants = const [],
    this.forkedFromId,
  });

  final BuildRecord build;
  final List<VariantRecord> variants;

  /// Set when this detail is the result of an identity Fork (DBR-ID-008).
  final String? forkedFromId;

  Build get domain => buildFromRecord(build);

  BuildDetail copyWith({
    BuildRecord? build,
    List<VariantRecord>? variants,
    String? forkedFromId,
  }) {
    return BuildDetail(
      build: build ?? this.build,
      variants: variants ?? this.variants,
      forkedFromId: forkedFromId ?? this.forkedFromId,
    );
  }
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
    this.subclassKit,
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

  /// When null, create seeds kit pieces from [CreateBuildCommand.subclass].
  final SubclassKit? subclassKit;
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
    this.identityAction,
    this.existingExoticArmorSlot,
    this.nextExoticArmorSlot,
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

  /// Required when identity fields change (DBR-ID-008 / DART-064).
  final IdentityAction? identityAction;

  /// Optional catalog slots for class-item exotic non-identity swap.
  final String? existingExoticArmorSlot;
  final String? nextExoticArmorSlot;
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

  // Build owns tree only; kit pieces seed the default variant (DBR-SUB-001/003).
  final treeOnly = subclassTreeOnly(input.subclass.name);
  final defaultKitPieces = variantKitPiecesOnly(
    seed.subclassKit ?? input.subclass,
  );

  await createBuildRecord(
    db,
    userId,
    id: buildId,
    name: name,
    className: input.className.wireName,
    subclass: subclassTreeToJson(treeOnly.name),
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
    subclassKit: subclassKitPiecesToJson(defaultKitPieces),
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

/// Update build identity fields with hard gates + DBR-ID-008 Confirm/Fork.
Future<BuildDetail?> updateUserBuild(
  AppDatabase db,
  int userId,
  String buildId,
  UpdateBuildCommand input, {
  NowClock now = defaultNow,
  IdGenerator newId = defaultNewId,
  HardGatePorts ports = HardGatePorts.defaults,
}) async {
  final existing = await getBuild(db, userId, buildId);
  if (existing == null) return null;

  final nextSynergy = input.synergyTypes != null
      ? normalizeDesignations(input.synergyTypes!)
      : designationsFromRecords(existing.synergyTypes);
  final existingSubclass = subclassKitFromJson(existing.subclass);
  final nextSubclass = input.subclass ?? existingSubclass;
  final nextExoticHash = input.setExoticArmor
      ? input.exoticArmorHash
      : existing.exoticArmorHash;
  final nextExoticName = input.setExoticArmor
      ? input.exoticArmorName
      : existing.exoticArmorName;
  final nextWeaponHash = input.setExoticWeapon
      ? input.exoticWeaponHash
      : existing.exoticWeaponHash;
  final nextWeaponName = input.setExoticWeapon
      ? input.exoticWeaponName
      : existing.exoticWeaponName;
  final nextPinned =
      input.setPinnedSuper ? input.pinnedSuper : existing.pinnedSuper;

  final changedIdentity = detectIdentityFieldChanges(
    existingSynergyTypes: designationsFromRecords(existing.synergyTypes),
    nextSynergyTypes: input.synergyTypes != null ? nextSynergy : null,
    existingExoticArmorHash: existing.exoticArmorHash,
    nextExoticArmorHash: nextExoticHash,
    setExoticArmor: input.setExoticArmor,
    existingExoticArmorSlot: input.existingExoticArmorSlot,
    nextExoticArmorSlot: input.nextExoticArmorSlot,
    existingExoticWeaponHash: existing.exoticWeaponHash,
    nextExoticWeaponHash: nextWeaponHash,
    setExoticWeapon: input.setExoticWeapon,
    existingPinnedSuper: existing.pinnedSuper,
    nextPinnedSuper: nextPinned,
    setPinnedSuper: input.setPinnedSuper,
    existingSubclass: existingSubclass,
    nextSubclass: input.subclass,
  );

  if (changedIdentity.isNotEmpty) {
    if (input.identityAction == null) {
      throw UseCaseException(
        UseCaseErrorCode.identityConfirmRequired,
        'Confirm in-place or fork to apply identity changes',
        details: {'identityFields': changedIdentity},
      );
    }
    if (input.identityAction == IdentityAction.fork) {
      return _forkBuildWithIdentity(
        db,
        userId,
        existing,
        input,
        nextSynergy: nextSynergy,
        nextSubclass: nextSubclass,
        nextExoticHash: nextExoticHash,
        nextExoticName: nextExoticName,
        nextWeaponHash: nextWeaponHash,
        nextWeaponName: nextWeaponName,
        nextPinned: nextPinned,
        now: now,
        newId: newId,
        ports: ports,
      );
    }
    // confirm — fall through to in-place update
  }

  // Identity path: tree name + pins. Kit composition is variant-owned.
  // Hard gates still use next tree name with empty pieces for synergy/count
  // when kit is not part of this write; exotic ability uses effective kit
  // only when tree/pin changes with existing variant kit on create path.
  final treeForGates = subclassTreeOnly(nextSubclass.name);
  await assertBuildIdentityHardGates(
    synergyTypes: nextSynergy,
    subclass: treeForGates,
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
    // Tree-only writes going forward (legacy full-blob still readable).
    subclass: input.subclass != null
        ? subclassTreeToJson(input.subclass!.name)
        : null,
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

Future<BuildDetail> _forkBuildWithIdentity(
  AppDatabase db,
  int userId,
  BuildRecord existing,
  UpdateBuildCommand input, {
  required List<SynergyTypeDesignation> nextSynergy,
  required SubclassKit nextSubclass,
  required int? nextExoticHash,
  required String? nextExoticName,
  required int? nextWeaponHash,
  required String? nextWeaponName,
  required String? nextPinned,
  required NowClock now,
  required IdGenerator newId,
  required HardGatePorts ports,
}) async {
  await assertBuildIdentityHardGates(
    synergyTypes: nextSynergy,
    subclass: nextSubclass,
    exoticArmorHash: nextExoticHash,
    exoticArmorName: nextExoticName,
    pinnedSuper: nextPinned,
    ports: ports,
  );

  final className = input.className?.wireName ?? existing.className;
  var name = input.name?.trim();
  if (name == null || name.isEmpty) name = existing.name;
  // Product: on name collision append " (fork)" (includes source build name).
  final library = await listBuilds(db, userId);
  if (library.any((b) => b.className == className && b.name == name)) {
    name = '$name (fork)';
  }

  final tagIds = input.tagIds ?? existing.tagIds;
  final ts = now();
  final forkedId = newId();

  await createBuildRecord(
    db,
    userId,
    id: forkedId,
    name: name,
    className: className,
    subclass: subclassTreeToJson(nextSubclass.name),
    exoticArmorHash: nextExoticHash,
    exoticArmorName: nextExoticHash == null
        ? null
        : (nextExoticName ?? existing.exoticArmorName),
    exoticWeaponHash: nextWeaponHash,
    exoticWeaponName: nextWeaponHash == null
        ? null
        : (nextWeaponName ?? existing.exoticWeaponName),
    pinnedSuper: nextPinned,
    softStatTargets: existing.softStatTargets,
    tagIds: tagIds,
    synergyTypes: designationsToRecords(nextSynergy),
    now: ts,
  );

  final variants = await listVariants(db, existing.id);
  for (final variant in variants) {
    final newVariantId = newId();
    // Fork clones each variant's subclass_kit (independent kits under new tree).
    final kitJson = variant.subclassKit ??
        subclassKitPiecesToJson(
          variantKitPiecesOnly(subclassKitFromJson(existing.subclass)),
        );
    await createVariantRecord(
      db,
      id: newVariantId,
      buildId: forkedId,
      name: variant.name,
      isDefault: variant.isDefault,
      exoticWeaponHash: variant.exoticWeaponHash,
      exoticWeaponName: variant.exoticWeaponName,
      artifactHash: variant.artifactHash,
      artifactName: variant.artifactName,
      artifactConfig: variant.artifactConfig,
      subclassKit: kitJson,
      notes: variant.notes,
      now: ts,
    );

    final sourceAttachments = await listAttachments(db, variant.id);
    if (sourceAttachments.isEmpty) continue;

    final prepared = <AttachmentWrite>[];
    for (final attachment in sourceAttachments) {
      if (attachment.snapshotConfigs != null &&
          attachment.snapshotConfigs!.isNotEmpty) {
        prepared.add(
          AttachmentWrite(
            setId: attachment.setId,
            mode: AttachmentMode.snapshot.wireName,
            snapshotConfigs: attachment.snapshotConfigs,
          ),
        );
        continue;
      }
      final items = await listActiveSetItems(db, attachment.setId);
      prepared.add(
        AttachmentWrite(
          setId: attachment.setId,
          mode: AttachmentMode.snapshot.wireName,
          snapshotConfigs: [
            for (final item in items) setItemRecordToSnapshotMap(item),
          ],
        ),
      );
    }
    if (prepared.isNotEmpty) {
      await replaceAttachments(db, newVariantId, prepared, ts);
    }
  }

  final detail = await getBuildDetail(db, userId, forkedId);
  if (detail == null) {
    throw UseCaseException(
      UseCaseErrorCode.notFound,
      'Forked build not found',
    );
  }
  return detail.copyWith(forkedFromId: existing.id);
}

/// Delete build owned by [userId].
Future<bool> deleteUserBuild(AppDatabase db, int userId, String buildId) {
  return deleteBuildRecord(db, userId, buildId);
}
