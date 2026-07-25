import 'inventory_buckets.dart';
import 'profile_types.dart';

/// Armor 3.0 stat hash → display name (product parseArmorStats).
const Map<int, String> kArmorStatHashToName = {
  392767087: 'Health',
  4244567218: 'Melee',
  1735777505: 'Grenade',
  144602215: 'Super',
  1943323491: 'Class',
  2996146975: 'Weapons',
};

/// Parse GetProfile Response into raw inventory items + diagnostics.
FullInventoryParseResult parseFullInventoryResponse(
  Object? response,
  DestinyMembership membership,
) {
  if (response is! Map) {
    throw const FormatException('Unexpected inventory response shape');
  }
  final res = _asStringKeyedMap(response);
  final socketsMap = _extractSocketsMap(res['itemComponents']);
  final statsMap = _extractStatsMap(res['itemComponents']);
  final instancesMap = _extractInstancesMap(res['itemComponents']);
  final reusablePlugsMap = _extractReusablePlugsMap(res['itemComponents']);
  final items = <RawInventoryItem>[];
  final diagnostics = InventoryParseDiagnostics(
    membership: membership,
    raw: InventoryRawCounts(),
    parsed: InventoryParsedCounts(),
    dropped: InventoryDroppedCounts(),
  );

  final vaultItems = _extractItemList(res['profileInventory']);
  diagnostics.raw.vault = vaultItems.length;
  for (final raw in vaultItems) {
    _recordAttempt(
      _parseItemAttempt(
        raw,
        'vault',
        null,
        socketsMap,
        instancesMap,
        statsMap,
        reusablePlugsMap,
      ),
      diagnostics,
      items,
    );
  }

  final charInventories = _extractCharacterItemSections(res['characterInventories']);
  for (final entry in charInventories.entries) {
    diagnostics.raw.characterInventories[entry.key] = entry.value.length;
    diagnostics.raw.characterInventoriesTotal += entry.value.length;
    for (final raw in entry.value) {
      _recordAttempt(
        _parseItemAttempt(
          raw,
          'character',
          entry.key,
          socketsMap,
          instancesMap,
          statsMap,
          reusablePlugsMap,
        ),
        diagnostics,
        items,
      );
    }
  }

  final charEquipment = _extractCharacterItemSections(res['characterEquipment']);
  for (final entry in charEquipment.entries) {
    diagnostics.raw.characterEquipment[entry.key] = entry.value.length;
    diagnostics.raw.characterEquipmentTotal += entry.value.length;
    for (final raw in entry.value) {
      _recordAttempt(
        _parseItemAttempt(
          raw,
          'equipped',
          entry.key,
          socketsMap,
          instancesMap,
          statsMap,
          reusablePlugsMap,
        ),
        diagnostics,
        items,
      );
    }
  }

  diagnostics.raw.total = diagnostics.raw.vault +
      diagnostics.raw.characterInventoriesTotal +
      diagnostics.raw.characterEquipmentTotal;

  return FullInventoryParseResult(items: items, diagnostics: diagnostics);
}

/// Sort memberships so primary (if known) is first.
List<DestinyMembership> parseMembershipsResponse(Object? response) {
  if (response is! Map) {
    throw const FormatException('Unexpected memberships response shape');
  }
  final res = _asStringKeyedMap(response);
  final primaryId = res['primaryMembershipId'] is String
      ? res['primaryMembershipId'] as String
      : null;
  final rawList = res['destinyMemberships'];
  final list = rawList is List ? rawList : const <Object?>[];
  final memberships = list.map(_parseMembership).toList();
  if (primaryId != null) {
    memberships.sort((a, b) {
      if (a.membershipId == primaryId) return -1;
      if (b.membershipId == primaryId) return 1;
      return 0;
    });
  }
  return memberships;
}

/// Resolve transfer-container bucket hashes via [lookup] (itemHash → equip bucket).
({
  List<RawInventoryItem> items,
  int resolvedFromTransfer,
  int droppedNonEquipment,
}) resolveTransferContainerBuckets(
  List<RawInventoryItem> items,
  Map<int, int> lookup,
) {
  var resolvedFromTransfer = 0;
  var droppedNonEquipment = 0;
  final resolved = <RawInventoryItem>[];

  for (final item in items) {
    if (!needsEquipmentBucketResolution(item.bucketHash)) {
      resolved.add(item);
      continue;
    }
    final equipmentBucket = lookup[item.itemHash];
    if (equipmentBucket == null || !isEquipmentBucketHash(equipmentBucket)) {
      droppedNonEquipment += 1;
      continue;
    }
    resolvedFromTransfer += 1;
    resolved.add(item.copyWith(bucketHash: equipmentBucket));
  }

  return (
    items: resolved,
    resolvedFromTransfer: resolvedFromTransfer,
    droppedNonEquipment: droppedNonEquipment,
  );
}

DestinyMembership _parseMembership(Object? raw) {
  if (raw is! Map) {
    throw const FormatException('Invalid membership entry');
  }
  final m = _asStringKeyedMap(raw);
  final displayName = '${m['bungieGlobalDisplayName'] ?? m['displayName'] ?? ''}';
  return DestinyMembership(
    membershipType: _asInt(m['membershipType']) ?? 0,
    membershipId: '${m['membershipId'] ?? ''}',
    displayName: displayName,
  );
}

class _ParseAttempt {
  const _ParseAttempt({
    required this.item,
    required this.dropReason,
    this.bucketHash,
  });

  final RawInventoryItem? item;
  final String? dropReason;
  final int? bucketHash;
}

void _recordAttempt(
  _ParseAttempt attempt,
  InventoryParseDiagnostics diagnostics,
  List<RawInventoryItem> items,
) {
  final item = attempt.item;
  if (item != null) {
    items.add(item);
    diagnostics.parsed.total += 1;
    diagnostics.parsed.byLocation[item.location] =
        (diagnostics.parsed.byLocation[item.location] ?? 0) + 1;
    final bucketLabel = parseBucketLabel(item.bucketHash);
    diagnostics.parsed.byBucket[bucketLabel] =
        (diagnostics.parsed.byBucket[bucketLabel] ?? 0) + 1;
    if (item.bucketHash == kSubclassBucketHash) {
      diagnostics.parsed.subclassTotal += 1;
    } else {
      diagnostics.parsed.equipmentTotal += 1;
    }
    return;
  }

  diagnostics.dropped.total += 1;
  switch (attempt.dropReason) {
    case 'invalid_shape':
      diagnostics.dropped.invalidShape += 1;
    case 'missing_instance_id':
      diagnostics.dropped.missingInstanceId += 1;
    case 'unknown_bucket':
      diagnostics.dropped.unknownBucket += 1;
      if (attempt.bucketHash != null) {
        final key = '${attempt.bucketHash}';
        diagnostics.dropped.unknownBuckets[key] =
            (diagnostics.dropped.unknownBuckets[key] ?? 0) + 1;
      }
  }
}

_ParseAttempt _parseItemAttempt(
  Object? raw,
  InventoryLocation location,
  String? characterId,
  Map<String, List<Object?>> socketsMap,
  Map<String, Map<String, Object?>> instancesMap,
  Map<String, List<_StatEntry>> statsMap,
  Map<String, Map<int, List<int>>> reusablePlugsMap,
) {
  if (raw is! Map) {
    return const _ParseAttempt(item: null, dropReason: 'invalid_shape');
  }
  final item = _asStringKeyedMap(raw);
  final bucketHash = _asInt(item['bucketHash']) ?? 0;
  if (!isParsableInventoryBucket(bucketHash)) {
    return _ParseAttempt(
      item: null,
      dropReason: 'unknown_bucket',
      bucketHash: bucketHash,
    );
  }

  final instanceId = item['itemInstanceId'] is String
      ? item['itemInstanceId'] as String
      : null;
  if (instanceId == null || instanceId.isEmpty) {
    return _ParseAttempt(
      item: null,
      dropReason: 'missing_instance_id',
      bucketHash: bucketHash,
    );
  }

  final instance = instancesMap[instanceId];
  final power = _parseItemPower(instance);
  final isMasterwork = _parseIsMasterwork(instance);
  final isCrafted = _parseIsCrafted(instance);
  final sockets = socketsMap[instanceId] ?? const [];
  final plugHashes = _parsePlugHashes(sockets);
  final isArmor = isArmorBucketHash(bucketHash);
  final isWeapon = isWeaponBucketHash(bucketHash);
  final isTransfer = kTransferContainerBuckets.contains(bucketHash);
  final statEntries = statsMap[instanceId];
  final statValues = isArmor
      ? _parseArmorStatValues(statEntries)
      : isWeapon || isTransfer
          ? _parseArmorStatValues(statEntries)
          : null;
  final gearTier =
      isArmor || isTransfer ? _parseGearTier(instance) : null;
  final socketCapture = isWeapon || isTransfer
      ? _parseSocketCapture(instanceId, sockets, reusablePlugsMap)
      : null;

  return _ParseAttempt(
    item: RawInventoryItem(
      instanceId: instanceId,
      itemHash: _asInt(item['itemHash']) ?? 0,
      bucketHash: bucketHash,
      location: location,
      characterId: characterId,
      power: power,
      plugHashes: plugHashes,
      isMasterwork: isMasterwork,
      isCrafted: isCrafted,
      statValues: statValues,
      gearTier: gearTier,
      socketCapture: socketCapture,
    ),
    dropReason: null,
  );
}

List<Object?> _extractItemList(Object? section) {
  if (section is! Map) return const [];
  final s = _asStringKeyedMap(section);
  final data = s['data'];
  if (data is! Map) return const [];
  final d = _asStringKeyedMap(data);
  final items = d['items'];
  return items is List ? List<Object?>.from(items) : const [];
}

Map<String, List<Object?>> _extractCharacterItemSections(Object? section) {
  if (section is! Map) return {};
  final s = _asStringKeyedMap(section);
  final data = s['data'];
  if (data is! Map) return {};
  final result = <String, List<Object?>>{};
  for (final entry in _asStringKeyedMap(data).entries) {
    if (entry.value is! Map) continue;
    final e = _asStringKeyedMap(entry.value as Map);
    final items = e['items'];
    result[entry.key] =
        items is List ? List<Object?>.from(items) : const <Object?>[];
  }
  return result;
}

Map<String, Map<String, Object?>> _extractInstancesMap(Object? itemComponents) {
  if (itemComponents is! Map) return {};
  final ic = _asStringKeyedMap(itemComponents);
  final instances = ic['instances'];
  if (instances is! Map) return {};
  final inst = _asStringKeyedMap(instances);
  final data = inst['data'];
  if (data is! Map) return {};
  final result = <String, Map<String, Object?>>{};
  for (final entry in _asStringKeyedMap(data).entries) {
    if (entry.value is Map) {
      result[entry.key] = _asStringKeyedMap(entry.value as Map);
    }
  }
  return result;
}

Map<String, List<Object?>> _extractSocketsMap(Object? itemComponents) {
  if (itemComponents is! Map) return {};
  final ic = _asStringKeyedMap(itemComponents);
  final sockets = ic['sockets'];
  if (sockets is! Map) return {};
  final s = _asStringKeyedMap(sockets);
  final data = s['data'];
  if (data is! Map) return {};
  final result = <String, List<Object?>>{};
  for (final entry in _asStringKeyedMap(data).entries) {
    if (entry.value is! Map) continue;
    final e = _asStringKeyedMap(entry.value as Map);
    final list = e['sockets'];
    result[entry.key] =
        list is List ? List<Object?>.from(list) : const <Object?>[];
  }
  return result;
}

class _StatEntry {
  const _StatEntry(this.statHash, this.value);
  final int statHash;
  final int value;
}

Map<String, List<_StatEntry>> _extractStatsMap(Object? itemComponents) {
  if (itemComponents is! Map) return {};
  final ic = _asStringKeyedMap(itemComponents);
  final stats = ic['stats'];
  if (stats is! Map) return {};
  final s = _asStringKeyedMap(stats);
  final data = s['data'];
  if (data is! Map) return {};
  final result = <String, List<_StatEntry>>{};
  for (final entry in _asStringKeyedMap(data).entries) {
    if (entry.value is! Map) continue;
    final e = _asStringKeyedMap(entry.value as Map);
    final rawStats = e['stats'];
    final rows = rawStats is List
        ? rawStats
        : rawStats is Map
            ? rawStats.values.toList()
            : const <Object?>[];
    final parsed = <_StatEntry>[];
    for (final row in rows) {
      if (row is! Map) continue;
      final r = _asStringKeyedMap(row);
      final hash = _asInt(r['statHash']);
      final value = _asInt(r['value']);
      if (hash != null && value != null) {
        parsed.add(_StatEntry(hash, value));
      }
    }
    if (parsed.isNotEmpty) result[entry.key] = parsed;
  }
  return result;
}

Map<String, Map<int, List<int>>> _extractReusablePlugsMap(Object? itemComponents) {
  if (itemComponents is! Map) return {};
  final ic = _asStringKeyedMap(itemComponents);
  final reusable = ic['reusablePlugs'];
  if (reusable is! Map) return {};
  final r = _asStringKeyedMap(reusable);
  final data = r['data'];
  if (data is! Map) return {};
  final result = <String, Map<int, List<int>>>{};
  for (final entry in _asStringKeyedMap(data).entries) {
    if (entry.value is! Map) continue;
    final e = _asStringKeyedMap(entry.value as Map);
    final plugs = e['plugs'];
    if (plugs is! Map) continue;
    final bySocket = <int, List<int>>{};
    for (final plugEntry in _asStringKeyedMap(plugs).entries) {
      final socketIndex = int.tryParse(plugEntry.key);
      if (socketIndex == null || plugEntry.value is! List) continue;
      final hashes = <int>[];
      for (final plug in plugEntry.value as List) {
        if (plug is! Map) continue;
        final p = _asStringKeyedMap(plug);
        if (p['canInsert'] == false || p['enabled'] == false) continue;
        final hash = _asInt(p['plugItemHash']);
        if (hash != null) hashes.add(hash);
      }
      if (hashes.isNotEmpty) bySocket[socketIndex] = hashes;
    }
    if (bySocket.isNotEmpty) result[entry.key] = bySocket;
  }
  return result;
}

int _parseItemPower(Map<String, Object?>? instance) {
  if (instance == null) return 0;
  final primaryStat = instance['primaryStat'];
  if (primaryStat is! Map) return 0;
  return _asInt(_asStringKeyedMap(primaryStat)['value']) ?? 0;
}

bool _parseIsMasterwork(Map<String, Object?>? instance) {
  if (instance == null) return false;
  if (instance['isMasterwork'] == true) return true;
  final quality = instance['quality'];
  if (quality is! Map) return false;
  final tiers = _asStringKeyedMap(quality)['versions'];
  return tiers is List && tiers.isNotEmpty;
}

bool _parseIsCrafted(Map<String, Object?>? instance) {
  if (instance == null) return false;
  return instance['isCrafted'] == true;
}

int? _parseGearTier(Map<String, Object?>? instance) {
  if (instance == null) return null;
  return _asInt(instance['gearTier']);
}

List<int> _parsePlugHashes(List<Object?> sockets) {
  final result = <int>[];
  for (final sock in sockets) {
    if (sock is! Map) continue;
    final s = _asStringKeyedMap(sock);
    if (s['isEnabled'] == false) continue;
    final hash = _asInt(s['plugHash']);
    if (hash != null) result.add(hash);
  }
  return result;
}

Map<String, Object?>? _parseArmorStatValues(List<_StatEntry>? stats) {
  if (stats == null || stats.isEmpty) return null;
  final result = <String, Object?>{};
  for (final entry in stats) {
    final name = kArmorStatHashToName[entry.statHash];
    if (name != null) result[name] = entry.value;
  }
  return result.isEmpty ? null : result;
}

List<RawSocketCapture>? _parseSocketCapture(
  String instanceId,
  List<Object?> sockets,
  Map<String, Map<int, List<int>>> reusablePlugsMap,
) {
  final instanceReusable = reusablePlugsMap[instanceId] ?? const {};
  final result = <RawSocketCapture>[];
  for (var socketIndex = 0; socketIndex < sockets.length; socketIndex++) {
    final sock = sockets[socketIndex];
    if (sock is! Map) continue;
    final s = _asStringKeyedMap(sock);
    if (s['isEnabled'] == false) continue;
    final plugHash = _asInt(s['plugHash']);
    if (plugHash == null) continue;
    result.add(
      RawSocketCapture(
        socketIndex: socketIndex,
        equippedPlugHash: plugHash,
        reusablePlugHashes: instanceReusable[socketIndex] ?? const [],
      ),
    );
  }
  return result.isEmpty ? null : result;
}

Map<String, Object?> _asStringKeyedMap(Map<dynamic, dynamic> map) {
  return {
    for (final entry in map.entries) entry.key.toString(): entry.value,
  };
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}
