import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:drift/drift.dart' show Value;

import 'attachment_use_cases.dart';
import 'clock_ids.dart';
import 'coverage_use_cases.dart';
import 'errors.dart';
import 'hard_gate_ports.dart';
import 'hard_gates.dart';
import 'mappers.dart';

/// Create non-default (or additional) variant.
class CreateVariantCommand {
  const CreateVariantCommand({
    this.id,
    required this.name,
    this.isDefault = false,
    this.exoticWeaponHash,
    this.exoticWeaponName,
    this.artifactHash,
    this.artifactName,
    this.artifactConfig = const [],
    this.notes,
  });

  final String? id;
  final String name;
  final bool isDefault;
  final int? exoticWeaponHash;
  final String? exoticWeaponName;
  final int? artifactHash;
  final String? artifactName;
  final List<int> artifactConfig;
  final String? notes;
}

/// Partial variant update (+ optional full attachment replace).
class UpdateVariantCommand {
  const UpdateVariantCommand({
    this.name,
    this.setExoticWeapon = false,
    this.exoticWeaponHash,
    this.exoticWeaponName,
    this.setArtifact = false,
    this.artifactHash,
    this.artifactName,
    this.artifactConfig,
    this.setNotes = false,
    this.notes,
    this.attachments,
  });

  final String? name;
  final bool setExoticWeapon;
  final int? exoticWeaponHash;
  final String? exoticWeaponName;
  final bool setArtifact;
  final int? artifactHash;
  final String? artifactName;
  final List<int>? artifactConfig;
  final bool setNotes;
  final String? notes;

  /// When non-null, replaces all attachments (after prepare).
  final List<SetAttachmentInput>? attachments;
}

/// Expand live/snapshot attachments into pure [ExpandedSetItem] rows.
///
/// Fashion sets contribute zero combat claims (product parity).
Future<List<ExpandedSetItem>> expandAttachmentsToItems(
  AppDatabase db,
  int userId,
  List<AttachmentRecord> attachments,
) async {
  final out = <ExpandedSetItem>[];

  for (final att in attachments) {
    final set = await getSet(db, userId, att.setId);
    if (set == null) continue;
    final setType = SetType.tryParse(set.type);
    if (setType == null) continue;
    if (setType == SetType.fashion) continue;

    if (att.mode == AttachmentMode.snapshot.wireName &&
        att.snapshotConfigs != null) {
      for (final cfg in att.snapshotConfigs!) {
        final slotWire = cfg['slot'];
        final itemHash = cfg['itemHash'];
        final itemName = cfg['itemName'];
        if (slotWire is! String || itemName is! String) continue;
        final slot = EquipmentSlot.tryParse(slotWire);
        if (slot == null) continue;
        final hash = itemHash is int
            ? itemHash
            : itemHash is num
                ? itemHash.toInt()
                : null;
        if (hash == null) continue;

        List<int>? perks;
        final rawPerks = cfg['selectedPerks'];
        if (rawPerks is List) {
          perks = rawPerks
              .map((e) => e is int ? e : (e as num).toInt())
              .toList();
        }

        out.add(
          ExpandedSetItem(
            slot: slot,
            itemHash: hash,
            itemName: itemName,
            setId: att.setId,
            setType: setType,
            selectedPerks: perks,
            instanceId: cfg['instanceId'] as String?,
          ),
        );
      }
      continue;
    }

    // Live: active set items whose slots map to equipment slots.
    final items = await listActiveSetItems(db, att.setId);
    for (final item in items) {
      final slot = EquipmentSlot.tryParse(item.slot);
      if (slot == null) continue;
      out.add(
        ExpandedSetItem(
          slot: slot,
          itemHash: item.itemHash,
          itemName: item.itemName,
          setId: att.setId,
          setType: setType,
          selectedPerks: item.selectedPerks,
          instanceId: item.instanceId,
        ),
      );
    }
  }

  return out;
}

/// Whether any attachment contributes mod hashes (for default completeness).
Future<bool> variantHasMods(
  AppDatabase db,
  int userId,
  List<AttachmentRecord> attachments,
) async {
  for (final att in attachments) {
    final set = await getSet(db, userId, att.setId);
    if (set == null) continue;
    if (set.type == SetType.mod.wireName) {
      if (att.mode == AttachmentMode.snapshot.wireName) {
        if (att.snapshotConfigs != null && att.snapshotConfigs!.isNotEmpty) {
          return true;
        }
      } else {
        final items = await listActiveSetItems(db, att.setId);
        if (items.isNotEmpty) return true;
      }
    }
    // Armor/live items may carry modHashes.
    if (att.mode == AttachmentMode.snapshot.wireName &&
        att.snapshotConfigs != null) {
      for (final cfg in att.snapshotConfigs!) {
        final mods = cfg['modHashes'];
        if (mods is List && mods.isNotEmpty) return true;
      }
    } else {
      final items = await listActiveSetItems(db, att.setId);
      for (final item in items) {
        if (item.modHashes != null && item.modHashes!.isNotEmpty) return true;
      }
    }
  }
  return false;
}

/// Resolve equipment for a variant using pure claims resolve + ports for exotic slots.
Future<ResolvedVariantEquipment?> resolveUserVariant(
  AppDatabase db,
  int userId,
  String buildId,
  String variantId, {
  HardGatePorts ports = HardGatePorts.defaults,
}) async {
  final build = await getBuild(db, userId, buildId);
  final variant = await getVariant(db, buildId, variantId);
  if (build == null || variant == null) return null;

  final attachments = await listAttachments(db, variantId);
  final expanded = await expandAttachmentsToItems(db, userId, attachments);

  final weapon = effectiveExoticWeapon(
    buildExoticWeaponHash: build.exoticWeaponHash,
    buildExoticWeaponName: build.exoticWeaponName,
    variantExoticWeaponHash: variant.exoticWeaponHash,
    variantExoticWeaponName: variant.exoticWeaponName,
  );
  final weaponSlot =
      await ports.resolveExoticWeaponSlot(weapon.exoticWeaponHash);
  final armorSlot =
      await ports.resolveExoticArmorSlot(build.exoticArmorHash);

  return resolveVariantClaims(
    expandedItems: expanded,
    buildExoticArmorHash: build.exoticArmorHash,
    buildExoticArmorName: build.exoticArmorName,
    buildExoticWeaponHash: build.exoticWeaponHash,
    buildExoticWeaponName: build.exoticWeaponName,
    variantExoticWeaponHash: variant.exoticWeaponHash,
    variantExoticWeaponName: variant.exoticWeaponName,
    exoticWeaponSlot: weaponSlot,
    exoticArmorSlot: armorSlot,
  );
}

/// Product `validateVariantSave` order (hard only; soft coverage excluded).
Future<void> validateVariantSave(
  AppDatabase db,
  int userId,
  String buildId,
  String variantId, {
  HardGatePorts ports = HardGatePorts.defaults,
}) async {
  final build = await getBuild(db, userId, buildId);
  final variant = await getVariant(db, buildId, variantId);
  if (build == null || variant == null) return;

  final attachments = await listAttachments(db, variantId);
  final resolved = await resolveUserVariant(
    db,
    userId,
    buildId,
    variantId,
    ports: ports,
  );
  if (resolved == null) return;

  final hasMods = await variantHasMods(db, userId, attachments);
  // Residual until pkg-variant-subclass-kit: kit bar reads builds.subclass.
  final kit = subclassKitFromJson(build.subclass);
  final domainAtts = attachments.map(attachmentFromRecord).toList();

  final aspects = kit.aspects
      .map((a) => a.trim())
      .where((a) => a.isNotEmpty)
      .toList();
  final capacity = await ports.resolveFragmentCapacity(aspects);
  final capacityResolved =
      aspects.isEmpty || capacity.resolvedCount == aspects.length;

  final designated = variant.isDefault
      ? await loadDesignatedSynergies(db, userId, build.synergyTypes)
      : const <Synergy>[];

  InventoryPinIndex inventory = const {};
  if (variant.isDefault) {
    final invRows = await listInventoryItems(db, userId);
    inventory = buildInventoryPinIndex([
      for (final row in invRows)
        InventoryPinItem(instanceId: row.instanceId, itemHash: row.itemHash),
    ]);
  }

  await assertVariantSaveHardGates(
    VariantSaveGateInput(
      resolved: resolved,
      isDefault: variant.isDefault,
      attachments: domainAtts,
      className: build.className,
      subclassName: kit.name,
      hasMods: hasMods,
      subclassKit: kit,
      fragmentCapacity: capacity.capacity,
      capacityResolved: capacityResolved,
      artifactHash: variant.artifactHash,
      artifactConfig: variant.artifactConfig,
      designatedSynergies: designated,
      inventory: inventory,
    ),
    ports: ports,
  );
}

/// Create a variant on an existing build.
Future<VariantRecord?> createUserVariant(
  AppDatabase db,
  int userId,
  String buildId,
  CreateVariantCommand input, {
  NowClock now = defaultNow,
  IdGenerator newId = defaultNewId,
}) async {
  final build = await getBuild(db, userId, buildId);
  if (build == null) return null;

  final name = input.name.trim();
  if (name.isEmpty) {
    throw UseCaseException(
      UseCaseErrorCode.invalidArgument,
      'Variant name cannot be empty',
    );
  }

  return createVariantRecord(
    db,
    id: input.id ?? newId(),
    buildId: buildId,
    name: name,
    isDefault: input.isDefault,
    exoticWeaponHash: input.exoticWeaponHash,
    exoticWeaponName: input.exoticWeaponName,
    artifactHash: input.artifactHash,
    artifactName: input.artifactName,
    artifactConfig: input.artifactConfig,
    notes: input.notes,
    now: now(),
  );
}

/// Update variant; equipment-affecting changes re-run hard gates with rollback.
Future<VariantRecord?> updateUserVariant(
  AppDatabase db,
  int userId,
  String buildId,
  String variantId,
  UpdateVariantCommand input, {
  NowClock now = defaultNow,
  HardGatePorts ports = HardGatePorts.defaults,
}) async {
  final build = await getBuild(db, userId, buildId);
  if (build == null) return null;

  final existing = await getVariant(db, buildId, variantId);
  if (existing == null) return null;

  final equipmentAffecting =
      input.attachments != null || input.setExoticWeapon;

  final previousAttachments =
      equipmentAffecting ? await listAttachments(db, variantId) : null;
  final previousSnapshot = equipmentAffecting
      ? (
          name: existing.name,
          exoticWeaponHash: existing.exoticWeaponHash,
          exoticWeaponName: existing.exoticWeaponName,
          artifactHash: existing.artifactHash,
          artifactName: existing.artifactName,
          artifactConfig: existing.artifactConfig,
          notes: existing.notes,
          updatedAt: existing.updatedAt,
        )
      : null;

  final ts = now();
  String? nextName;
  if (input.name != null) {
    final trimmed = input.name!.trim();
    if (trimmed.isEmpty) {
      throw UseCaseException(
        UseCaseErrorCode.invalidArgument,
        'Variant name cannot be empty',
      );
    }
    nextName = trimmed;
  }

  await updateVariantRecord(
    db,
    buildId,
    variantId,
    name: nextName,
    exoticWeaponHash: input.setExoticWeapon
        ? Value(input.exoticWeaponHash)
        : const Value.absent(),
    exoticWeaponName: input.setExoticWeapon
        ? Value(input.exoticWeaponName)
        : const Value.absent(),
    artifactHash:
        input.setArtifact ? Value(input.artifactHash) : const Value.absent(),
    artifactName:
        input.setArtifact ? Value(input.artifactName) : const Value.absent(),
    artifactConfig: input.artifactConfig,
    notes: input.setNotes ? Value(input.notes) : const Value.absent(),
    now: ts,
  );

  if (input.attachments != null) {
    await prepareAttachments(
      db,
      userId,
      variantId,
      input.attachments!,
      now: () => ts,
    );
  }

  if (equipmentAffecting &&
      previousAttachments != null &&
      previousSnapshot != null) {
    try {
      await validateVariantSave(
        db,
        userId,
        buildId,
        variantId,
        ports: ports,
      );
    } catch (e) {
      // R1: restore prior variant + attachments.
      await updateVariantRecord(
        db,
        buildId,
        variantId,
        name: previousSnapshot.name,
        exoticWeaponHash: Value(previousSnapshot.exoticWeaponHash),
        exoticWeaponName: Value(previousSnapshot.exoticWeaponName),
        artifactHash: Value(previousSnapshot.artifactHash),
        artifactName: Value(previousSnapshot.artifactName),
        artifactConfig: previousSnapshot.artifactConfig,
        notes: Value(previousSnapshot.notes),
        now: previousSnapshot.updatedAt,
      );
      await replaceAttachments(
        db,
        variantId,
        previousAttachments
            .map(
              (a) => AttachmentWrite(
                id: a.id,
                setId: a.setId,
                mode: a.mode,
                snapshotConfigs: a.snapshotConfigs,
              ),
            )
            .toList(),
        previousAttachments.isNotEmpty
            ? previousAttachments.first.attachedAt
            : previousSnapshot.updatedAt,
      );
      rethrow;
    }
  }

  return getVariant(db, buildId, variantId);
}

/// Delete a variant owned via [buildId] / user scope.
Future<bool> deleteUserVariant(
  AppDatabase db,
  int userId,
  String buildId,
  String variantId,
) async {
  final build = await getBuild(db, userId, buildId);
  if (build == null) return false;
  return deleteVariantRecord(db, buildId, variantId);
}

/// Domain map helpers.
List<Variant> mapVariantsDomain(List<VariantRecord> rows) =>
    rows.map(variantFromRecord).toList();
