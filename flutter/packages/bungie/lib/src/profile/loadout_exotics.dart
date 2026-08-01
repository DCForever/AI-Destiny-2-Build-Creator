/// Resolve exotic armor/weapon identity for Bungie in-game loadouts
/// (Next `resolveLoadoutExoticsFromInstances` parity — DART-068 / GAP-UI-LOADOUTS-02).

import 'character_loadouts.dart';

/// Catalog index of exotic armor/weapon hashes and display names.
class ExoticCatalogIndex {
  const ExoticCatalogIndex({
    required this.armorHashes,
    required this.weaponHashes,
    required this.armorNames,
    required this.weaponNames,
  });

  final Set<int> armorHashes;
  final Set<int> weaponHashes;
  final Map<int, String> armorNames;
  final Map<int, String> weaponNames;

  static const empty = ExoticCatalogIndex(
    armorHashes: {},
    weaponHashes: {},
    armorNames: {},
    weaponNames: {},
  );
}

/// Build [ExoticCatalogIndex] from simple hash/name rows.
ExoticCatalogIndex buildExoticCatalogIndex({
  required Iterable<({int hash, String name})> exoticArmor,
  required Iterable<({int hash, String name})> exoticWeapons,
}) {
  final armorHashes = <int>{};
  final weaponHashes = <int>{};
  final armorNames = <int, String>{};
  final weaponNames = <int, String>{};
  for (final a in exoticArmor) {
    armorHashes.add(a.hash);
    armorNames[a.hash] = a.name;
  }
  for (final w in exoticWeapons) {
    weaponHashes.add(w.hash);
    weaponNames[w.hash] = w.name;
  }
  return ExoticCatalogIndex(
    armorHashes: armorHashes,
    weaponHashes: weaponHashes,
    armorNames: armorNames,
    weaponNames: weaponNames,
  );
}

/// Resolved exotic pins for one loadout.
class LoadoutExoticResolution {
  const LoadoutExoticResolution({
    this.exoticArmorHash,
    this.exoticWeaponHash,
    this.exoticArmorName,
    this.exoticWeaponName,
  });

  final int? exoticArmorHash;
  final int? exoticWeaponHash;
  final String? exoticArmorName;
  final String? exoticWeaponName;

  static const empty = LoadoutExoticResolution();
}

/// Map loadout item instance IDs → exotic identity using inventory hashes.
/// First exotic armor and first exotic weapon win.
LoadoutExoticResolution resolveLoadoutExoticsFromInstances({
  required Iterable<String> itemInstanceIds,
  required Map<String, int> instanceIdToHash,
  required ExoticCatalogIndex catalog,
}) {
  int? exoticArmorHash;
  int? exoticWeaponHash;

  for (final instanceId in itemInstanceIds) {
    if (instanceId.isEmpty || instanceId == '0') continue;
    final hash = instanceIdToHash[instanceId];
    if (hash == null) continue;

    if (exoticArmorHash == null && catalog.armorHashes.contains(hash)) {
      exoticArmorHash = hash;
    } else if (exoticWeaponHash == null && catalog.weaponHashes.contains(hash)) {
      exoticWeaponHash = hash;
    }

    if (exoticArmorHash != null && exoticWeaponHash != null) break;
  }

  return LoadoutExoticResolution(
    exoticArmorHash: exoticArmorHash,
    exoticWeaponHash: exoticWeaponHash,
    exoticArmorName:
        exoticArmorHash != null ? catalog.armorNames[exoticArmorHash] : null,
    exoticWeaponName:
        exoticWeaponHash != null ? catalog.weaponNames[exoticWeaponHash] : null,
  );
}

/// Build instanceId → itemHash from inventory rows.
Map<String, int> instanceHashMapFromInventory(
  Iterable<({String instanceId, int itemHash})> items,
) {
  final map = <String, int>{};
  for (final item in items) {
    if (item.instanceId.isNotEmpty) {
      map[item.instanceId] = item.itemHash;
    }
  }
  return map;
}

/// Apply exotic resolution onto each loadout via [BungieInGameLoadout.copyWith].
List<BungieInGameLoadout> enrichLoadoutsWithExotics(
  Iterable<BungieInGameLoadout> loadouts, {
  required Map<String, int> instanceIdToHash,
  required ExoticCatalogIndex catalog,
}) {
  return [
    for (final lo in loadouts)
      () {
        final r = resolveLoadoutExoticsFromInstances(
          itemInstanceIds: lo.itemInstanceIds,
          instanceIdToHash: instanceIdToHash,
          catalog: catalog,
        );
        return lo.copyWith(
          exoticArmorHash: r.exoticArmorHash,
          exoticWeaponHash: r.exoticWeaponHash,
          exoticArmorName: r.exoticArmorName,
          exoticWeaponName: r.exoticWeaponName,
        );
      }(),
  ];
}
