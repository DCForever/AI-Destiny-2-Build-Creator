// Drift schema classes SetItem/Synergy/SynergyLink collide with domain models.
import 'package:destiny2_db/destiny2_db.dart' hide SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';

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
