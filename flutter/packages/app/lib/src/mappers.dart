// Drift schema classes SetItem/Synergy/SynergyLink collide with domain models.
import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';

/// Parse subclass JSON object from build row into [SubclassKit].
SubclassKit subclassKitFromJson(Object? raw) {
  if (raw is! Map) return const SubclassKit();
  final m = Map<String, Object?>.from(
    raw.map((k, v) => MapEntry(k.toString(), v)),
  );

  List<String> strList(Object? v) {
    if (v is! List) return const [];
    return v
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  String? str(Object? v) {
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  // Product JSON uses `super` key; Dart model uses superAbility.
  return SubclassKit(
    aspects: strList(m['aspects']),
    fragments: strList(m['fragments']),
    superAbility: str(m['super']) ?? str(m['superAbility']),
    melee: str(m['melee']),
    grenade: str(m['grenade']),
    classAbility: str(m['classAbility']),
    name: str(m['name']),
  );
}

/// Serialize [SubclassKit] to product-shaped JSON map.
Map<String, Object?> subclassKitToJson(SubclassKit kit) {
  return {
    'aspects': kit.aspects,
    'fragments': kit.fragments,
    if (kit.superAbility != null) 'super': kit.superAbility,
    if (kit.melee != null) 'melee': kit.melee,
    if (kit.grenade != null) 'grenade': kit.grenade,
    if (kit.classAbility != null) 'classAbility': kit.classAbility,
    if (kit.name != null) 'name': kit.name,
  };
}

/// Soft stat targets JSON map for persistence (Armor 3.0 wire names).
Map<String, Object?> softStatTargetsToJson(SoftStatTargets targets) {
  return {
    for (final e in targets.values.entries) e.key.wireName: e.value,
  };
}

/// Best-effort soft targets from stored JSON (unknown keys ignored for domain map).
SoftStatTargets softStatTargetsFromJson(Map<String, Object?> raw) {
  if (raw.isEmpty) return const SoftStatTargets();
  try {
    return normalizeSoftStatTargets(raw);
  } on SoftStatTargetsException {
    // Persistence may hold legacy/partial maps; domain map keeps valid keys only.
    final out = <ArmorStatName, int>{};
    for (final e in raw.entries) {
      final name = ArmorStatName.tryParse(e.key);
      if (name == null) continue;
      final v = e.value;
      if (v is int && v >= 1 && v <= armorStatMax) out[name] = v;
    }
    return SoftStatTargets(out);
  }
}

/// Designation records → domain designations.
List<SynergyTypeDesignation> designationsFromRecords(
  List<SynergyTypeDesignationRecord> rows,
) {
  return [
    for (final r in rows)
      SynergyTypeDesignation(
        type: SynergyType(r.type),
        subType: r.subType,
      ),
  ];
}

/// Domain designations → persistence records.
List<SynergyTypeDesignationRecord> designationsToRecords(
  List<SynergyTypeDesignation> rows,
) {
  return [
    for (final d in rows)
      SynergyTypeDesignationRecord(
        type: d.type.wireName,
        subType: d.subType,
      ),
  ];
}

/// Map persistence [BuildRecord] → pure domain [Build].
Build buildFromRecord(BuildRecord r) {
  final cls = GuardianClass.tryParse(r.className) ?? GuardianClass.hunter;
  return Build(
    id: r.id,
    name: r.name,
    className: cls,
    subclass: subclassKitFromJson(r.subclass),
    exoticArmorHash: r.exoticArmorHash,
    exoticArmorName: r.exoticArmorName,
    exoticWeaponHash: r.exoticWeaponHash,
    exoticWeaponName: r.exoticWeaponName,
    pinnedSuper: r.pinnedSuper,
    softStatTargets: softStatTargetsFromJson(r.softStatTargets),
    synergyTypes: designationsFromRecords(r.synergyTypes),
    tagIds: r.tagIds,
  );
}

/// Map persistence [VariantRecord] → pure domain [Variant].
Variant variantFromRecord(VariantRecord r) {
  return Variant(
    id: r.id,
    buildId: r.buildId,
    name: r.name,
    isDefault: r.isDefault,
    exoticWeaponHash: r.exoticWeaponHash,
    exoticWeaponName: r.exoticWeaponName,
    artifactHash: r.artifactHash,
    artifactName: r.artifactName,
    artifactConfig: r.artifactConfig,
    notes: r.notes,
  );
}

/// Map persistence [SetRecord] → pure domain [GearSet].
GearSet gearSetFromRecord(SetRecord r) {
  final type = SetType.tryParse(r.type);
  if (type == null) {
    throw ArgumentError.value(r.type, 'type', 'Unknown set type wire');
  }
  return GearSet(
    id: r.id,
    name: r.name,
    type: type,
    tagIds: r.tagIds,
    linkedModSetId: r.linkedModSetId,
  );
}

/// Map [SetItemRecord] → pure domain [SetItem] (active or soft-removed).
SetItem setItemFromRecord(SetItemRecord r) {
  return SetItem(
    id: r.id,
    setId: r.setId,
    slot: r.slot,
    itemHash: r.itemHash,
    itemName: r.itemName,
    instanceId: r.instanceId,
    selectedPerks: r.selectedPerks,
    masterworkHash: r.masterworkHash,
    modHashes: r.modHashes,
    stale: false,
  );
}

/// Map [SynergyWithLinks] → pure domain [Synergy].
Synergy synergyFromRecord(SynergyWithLinks row) {
  final kindLinks = <SynergyLink>[];
  for (final l in row.links) {
    final kind = SynergyLinkKind.tryParse(l.kind);
    if (kind == null) {
      // Skip unknown legacy kinds rather than crash domain construction.
      continue;
    }
    kindLinks.add(
      SynergyLink(
        id: l.id,
        synergyId: l.synergyId,
        kind: kind,
        displayName: l.displayName,
        itemHash: l.itemHash,
        perkHash: l.perkHash,
        parentItemHash: l.parentItemHash,
        originTraitName: l.originTraitName,
        originTraitHash: l.originTraitHash,
        armorSetName: l.armorSetName,
        bonusPieces: l.bonusPieces,
        bonusName: l.bonusName,
        armorSetHash: l.armorSetHash,
        required: l.required,
      ),
    );
  }
  return Synergy(
    id: row.id,
    name: row.name,
    type: SynergyType(row.type),
    subType: row.subType,
    description: row.description,
    links: kindLinks,
  );
}

/// Map [AttachmentRecord] → pure domain [Attachment].
Attachment attachmentFromRecord(AttachmentRecord r) {
  final mode = r.mode == AttachmentMode.snapshot.wireName
      ? AttachmentMode.snapshot
      : AttachmentMode.live;
  List<SnapshotConfig>? snapshots;
  final raw = r.snapshotConfigs;
  if (raw != null) {
    snapshots = raw.map(_snapshotFromMap).whereType<SnapshotConfig>().toList();
  }
  return Attachment(
    id: r.id,
    variantId: r.variantId,
    setId: r.setId,
    mode: mode,
    snapshotConfigs: snapshots,
  );
}

SnapshotConfig? _snapshotFromMap(Map<String, Object?> m) {
  final slot = m['slot'];
  final itemHash = m['itemHash'];
  final itemName = m['itemName'];
  if (slot is! String || itemName is! String) return null;
  final hash = itemHash is int
      ? itemHash
      : itemHash is num
          ? itemHash.toInt()
          : null;
  if (hash == null) return null;

  List<int>? asIntList(Object? v) {
    if (v == null) return null;
    if (v is! List) return null;
    return v.map((e) => e is int ? e : (e as num).toInt()).toList();
  }

  return SnapshotConfig(
    slot: slot,
    itemHash: hash,
    itemName: itemName,
    selectedPerks: asIntList(m['selectedPerks']),
    masterworkHash: m['masterworkHash'] is num
        ? (m['masterworkHash'] as num).toInt()
        : null,
    modHashes: asIntList(m['modHashes']),
    instanceId: m['instanceId'] as String?,
  );
}

/// Serialize domain-ish snapshot maps for Drift replaceAttachments.
List<Map<String, Object?>> snapshotConfigsToMaps(List<SnapshotConfig> configs) {
  return configs
      .map(
        (c) => <String, Object?>{
          'slot': c.slot,
          'itemHash': c.itemHash,
          'itemName': c.itemName,
          if (c.selectedPerks != null) 'selectedPerks': c.selectedPerks,
          if (c.masterworkHash != null) 'masterworkHash': c.masterworkHash,
          if (c.modHashes != null) 'modHashes': c.modHashes,
          if (c.instanceId != null) 'instanceId': c.instanceId,
        },
      )
      .toList();
}

/// Active set item → snapshot config map (product attachmentService shape).
Map<String, Object?> setItemRecordToSnapshotMap(SetItemRecord item) {
  return {
    'slot': item.slot,
    'itemHash': item.itemHash,
    'itemName': item.itemName,
    'selectedPerks': item.selectedPerks,
    if (item.masterworkHash != null) 'masterworkHash': item.masterworkHash,
    if (item.modHashes != null) 'modHashes': item.modHashes,
    if (item.instanceId != null) 'instanceId': item.instanceId,
  };
}
