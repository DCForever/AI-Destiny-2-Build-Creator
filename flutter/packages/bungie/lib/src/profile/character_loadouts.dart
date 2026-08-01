import 'profile_types.dart';

/// Bungie CDN origin for relative Destiny content paths.
const String kBungieCdnOrigin = 'https://www.bungie.net';

/// Components for characters (200) + character loadouts (206) — same as product/DIM.
const String kCharacterLoadoutsProfileComponents = '200,206';

/// One raw loadout slot item from component 206.
class RawLoadoutSlotItem {
  const RawLoadoutSlotItem({
    required this.itemInstanceId,
    this.plugItemHashes = const [],
  });

  final String itemInstanceId;
  final List<int> plugItemHashes;
}

/// One raw loadout slot before presentation resolve.
class RawLoadoutSlot {
  const RawLoadoutSlot({
    required this.colorHash,
    required this.iconHash,
    required this.nameHash,
    this.items = const [],
  });

  final int colorHash;
  final int iconHash;
  final int nameHash;
  final List<RawLoadoutSlotItem> items;
}

/// Resolved presentation paths for icon/color/name hashes.
class LoadoutPresentationTables {
  const LoadoutPresentationTables({
    this.icons = const {},
    this.colors = const {},
    this.names = const {},
  });

  /// hash → iconImagePath
  final Map<String, String> icons;

  /// hash → colorImagePath
  final Map<String, String> colors;

  /// hash → display name
  final Map<String, String> names;
}

/// One Bungie in-game loadout slot (product `BungieInGameLoadout`).
class BungieInGameLoadout {
  const BungieInGameLoadout({
    required this.id,
    required this.characterId,
    required this.className,
    required this.characterLight,
    required this.index,
    required this.name,
    required this.iconHash,
    required this.colorHash,
    required this.nameHash,
    this.iconPath,
    this.colorPath,
    this.iconUrl,
    this.colorUrl,
    this.itemInstanceIds = const [],
    this.empty = true,
    this.exoticArmorHash,
    this.exoticWeaponHash,
    this.exoticArmorName,
    this.exoticWeaponName,
  });

  /// Stable id: `characterId:index`
  final String id;
  final String characterId;

  /// Titan | Hunter | Warlock
  final String className;
  final int characterLight;
  final int index;
  final String name;
  final int iconHash;
  final int colorHash;
  final int nameHash;
  final String? iconPath;
  final String? colorPath;
  final String? iconUrl;
  final String? colorUrl;
  final List<String> itemInstanceIds;
  final bool empty;
  final int? exoticArmorHash;
  final int? exoticWeaponHash;
  final String? exoticArmorName;
  final String? exoticWeaponName;

  BungieInGameLoadout copyWith({
    int? exoticArmorHash,
    int? exoticWeaponHash,
    String? exoticArmorName,
    String? exoticWeaponName,
  }) {
    return BungieInGameLoadout(
      id: id,
      characterId: characterId,
      className: className,
      characterLight: characterLight,
      index: index,
      name: name,
      iconHash: iconHash,
      colorHash: colorHash,
      nameHash: nameHash,
      iconPath: iconPath,
      colorPath: colorPath,
      iconUrl: iconUrl,
      colorUrl: colorUrl,
      itemInstanceIds: itemInstanceIds,
      empty: empty,
      exoticArmorHash: exoticArmorHash ?? this.exoticArmorHash,
      exoticWeaponHash: exoticWeaponHash ?? this.exoticWeaponHash,
      exoticArmorName: exoticArmorName ?? this.exoticArmorName,
      exoticWeaponName: exoticWeaponName ?? this.exoticWeaponName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BungieInGameLoadout && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// True when the slot has no equipped instances (empty preset).
bool isEmptyLoadoutItems(List<RawLoadoutSlotItem> items) {
  if (items.isEmpty) return true;
  return items.every(
    (i) =>
        i.itemInstanceId.isEmpty ||
        i.itemInstanceId == '0',
  );
}

/// Build absolute Bungie CDN URL from a relative path (or null).
String? bungieContentUrl(String? relativePath) {
  if (relativePath == null || relativePath.isEmpty) return null;
  final path =
      relativePath.startsWith('/') ? relativePath : '/$relativePath';
  return '$kBungieCdnOrigin$path';
}

/// Resolved name + icon/color paths/URLs for a loadout slot.
class ResolvedLoadoutPresentation {
  const ResolvedLoadoutPresentation({
    required this.name,
    this.iconPath,
    this.colorPath,
    this.iconUrl,
    this.colorUrl,
  });

  final String name;
  final String? iconPath;
  final String? colorPath;
  final String? iconUrl;
  final String? colorUrl;
}

/// Map icon/color/name hashes through presentation tables (DIM-style).
ResolvedLoadoutPresentation resolveLoadoutPresentation({
  required int iconHash,
  required int colorHash,
  required int nameHash,
  required LoadoutPresentationTables tables,
  required String fallbackName,
}) {
  final iconPath = tables.icons[iconHash.toString()];
  final colorPath = tables.colors[colorHash.toString()];
  final resolvedName = tables.names[nameHash.toString()];
  final name = (resolvedName != null && resolvedName.trim().isNotEmpty)
      ? resolvedName.trim()
      : fallbackName;
  final icon = (iconPath != null && iconPath.isNotEmpty) ? iconPath : null;
  final color = (colorPath != null && colorPath.isNotEmpty) ? colorPath : null;
  return ResolvedLoadoutPresentation(
    name: name,
    iconPath: icon,
    colorPath: color,
    iconUrl: bungieContentUrl(icon),
    colorUrl: bungieContentUrl(color),
  );
}

/// Extract presentation paths from raw definition tables (hash-keyed).
LoadoutPresentationTables presentationTablesFromRaw({
  required Map<String, Object?> icons,
  required Map<String, Object?> colors,
  required Map<String, Object?> names,
}) {
  final outIcons = <String, String>{};
  final outColors = <String, String>{};
  final outNames = <String, String>{};

  for (final e in icons.entries) {
    final d = _asStringKeyedMap(e.value);
    final path = d?['iconImagePath'];
    if (path is String && path.isNotEmpty) {
      outIcons[e.key] = path;
    }
  }
  for (final e in colors.entries) {
    final d = _asStringKeyedMap(e.value);
    final path = d?['colorImagePath'];
    if (path is String && path.isNotEmpty) {
      outColors[e.key] = path;
    }
  }
  for (final e in names.entries) {
    final d = _asStringKeyedMap(e.value);
    final name = d?['name'];
    if (name is String && name.isNotEmpty) {
      outNames[e.key] = name;
    }
  }
  return LoadoutPresentationTables(
    icons: outIcons,
    colors: outColors,
    names: outNames,
  );
}

/// Parse GetProfile Response.characterLoadouts (component 206).
///
/// Shape: `{ characterLoadouts: { data: { [characterId]: { loadouts: [...] } } } }`
/// Optionally also accepts the `data` map alone if [response] is already that map
/// wrapped under `characterLoadouts`.
List<BungieInGameLoadout> parseCharacterLoadoutsResponse(
  Object? response,
  List<CharacterSummary> characters, {
  LoadoutPresentationTables tables = const LoadoutPresentationTables(),
}) {
  final res = _asStringKeyedMap(response);
  if (res == null) return const [];

  final section = _asStringKeyedMap(res['characterLoadouts']);
  final dataRaw = section?['data'];
  final data = _asStringKeyedMap(dataRaw);
  if (data == null) return const [];

  final byId = {for (final c in characters) c.characterId: c};
  final out = <BungieInGameLoadout>[];

  for (final entry in data.entries) {
    final characterId = entry.key;
    final char = byId[characterId];
    if (char == null) continue;

    final cl = _asStringKeyedMap(entry.value);
    final loadoutsRaw = cl?['loadouts'];
    final list = loadoutsRaw is List ? loadoutsRaw : const [];

    for (var index = 0; index < list.length; index++) {
      final slot = parseRawLoadoutSlot(list[index]);
      if (slot == null) continue;
      final empty = isEmptyLoadoutItems(slot.items);
      final presentation = resolveLoadoutPresentation(
        iconHash: slot.iconHash,
        colorHash: slot.colorHash,
        nameHash: slot.nameHash,
        tables: tables,
        fallbackName: 'Loadout ${index + 1}',
      );
      final itemInstanceIds = slot.items
          .map((i) => i.itemInstanceId)
          .where((id) => id.isNotEmpty && id != '0')
          .toList(growable: false);

      out.add(
        BungieInGameLoadout(
          id: '$characterId:$index',
          characterId: characterId,
          className: char.classType,
          characterLight: char.light,
          index: index,
          name: presentation.name,
          iconHash: slot.iconHash,
          colorHash: slot.colorHash,
          nameHash: slot.nameHash,
          iconPath: presentation.iconPath,
          colorPath: presentation.colorPath,
          iconUrl: presentation.iconUrl,
          colorUrl: presentation.colorUrl,
          itemInstanceIds: itemInstanceIds,
          empty: empty,
        ),
      );
    }
  }

  const classOrder = {'Titan': 0, 'Hunter': 1, 'Warlock': 2};
  out.sort((a, b) {
    final ca = classOrder[a.className] ?? 9;
    final cb = classOrder[b.className] ?? 9;
    if (ca != cb) return ca.compareTo(cb);
    final idCmp = a.characterId.compareTo(b.characterId);
    if (idCmp != 0) return idCmp;
    return a.index.compareTo(b.index);
  });
  return out;
}

/// Parse one raw loadout slot object from component 206.
RawLoadoutSlot? parseRawLoadoutSlot(Object? raw) {
  final o = _asStringKeyedMap(raw);
  if (o == null) return null;
  final itemsRaw = o['items'];
  final itemsList = itemsRaw is List ? itemsRaw : const [];
  final items = <RawLoadoutSlotItem>[];
  for (final item in itemsList) {
    final i = _asStringKeyedMap(item);
    if (i == null) continue;
    final plugsRaw = i['plugItemHashes'];
    final plugs = <int>[];
    if (plugsRaw is List) {
      for (final n in plugsRaw) {
        if (n is num) plugs.add(n.toInt());
      }
    }
    items.add(
      RawLoadoutSlotItem(
        itemInstanceId: '${i['itemInstanceId'] ?? '0'}',
        plugItemHashes: plugs,
      ),
    );
  }
  return RawLoadoutSlot(
    colorHash: _asInt(o['colorHash']),
    iconHash: _asInt(o['iconHash']),
    nameHash: _asInt(o['nameHash']),
    items: items,
  );
}

/// Filter in-game loadouts by class and empty visibility (product defaults).
List<BungieInGameLoadout> filterInGameLoadouts(
  List<BungieInGameLoadout> loadouts, {
  String? classFilter,
  bool hideEmpty = true,
}) {
  return loadouts
      .where((lo) {
        if (hideEmpty && lo.empty) return false;
        if (classFilter != null &&
            classFilter.isNotEmpty &&
            lo.className != classFilter) {
          return false;
        }
        return true;
      })
      .toList(growable: false);
}

int _asInt(Object? v) {
  if (v is num) return v.toInt();
  return 0;
}

Map<String, Object?>? _asStringKeyedMap(Object? raw) {
  if (raw is! Map) return null;
  final out = <String, Object?>{};
  for (final e in raw.entries) {
    out[e.key.toString()] = e.value;
  }
  return out;
}
