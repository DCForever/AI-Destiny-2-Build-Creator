import '../normalize.dart';
import '../raw/raw_types.dart';
import '../types/records.dart';
import '../types/services.dart';

class BaseProjection {
  const BaseProjection({
    required this.hash,
    required this.name,
    required this.searchName,
    this.icon,
  });

  final Hash hash;
  final String name;
  final String searchName;
  final String? icon;
}

BaseProjection projectBase(RawInventoryItem item) {
  final dp = item.displayProperties;
  return BaseProjection(
    hash: item.hash,
    name: dp.name,
    searchName: normalizeName(dp.name),
    icon: dp.icon,
  );
}

bool isUsable(RawInventoryItem item) {
  return !item.redacted && item.displayProperties.name.trim().isNotEmpty;
}

List<RawInventoryItem> iterItems(RawTable table) {
  final result = <RawInventoryItem>[];
  for (final v in table.values) {
    final item = RawInventoryItem.tryParse(v);
    if (item != null && isUsable(item)) result.add(item);
  }
  return result;
}

Object? getRaw(RawTable table, int hash) {
  return table[hash.toString()] ?? table['$hash'];
}

DestinyClassName? toClassName(int? classType) {
  if (classType == null || classType == 3) return null;
  switch (classType) {
    case 0:
      return DestinyClassName.titan;
    case 1:
      return DestinyClassName.hunter;
    case 2:
      return DestinyClassName.warlock;
    default:
      return null;
  }
}

ArmorSlotName? toArmorSlot(String slotName) {
  switch (slotName) {
    case 'Helmet':
      return ArmorSlotName.helmet;
    case 'Gauntlets':
      return ArmorSlotName.gauntlets;
    case 'Chest Armor':
      return ArmorSlotName.chest;
    case 'Leg Armor':
      return ArmorSlotName.legs;
    case 'Class Armor':
      return ArmorSlotName.classItem;
    default:
      return null;
  }
}

WeaponSlotName? toWeaponSlot(String slotName) {
  switch (slotName) {
    case 'Kinetic Weapons':
      return WeaponSlotName.kinetic;
    case 'Energy Weapons':
      return WeaponSlotName.energy;
    case 'Power Weapons':
      return WeaponSlotName.power;
    default:
      return null;
  }
}

AmmoTypeName? toAmmoType(int? n) {
  switch (n) {
    case 1:
      return AmmoTypeName.primary;
    case 2:
      return AmmoTypeName.special;
    case 3:
      return AmmoTypeName.heavy;
    default:
      return null;
  }
}

ElementName? toElementName(String name) {
  return ElementName.tryParse(name);
}

ElementName deriveElement(String typeName, String categoryId) {
  for (final el in [
    ElementName.arc,
    ElementName.solar,
    ElementName.voidElement,
    ElementName.stasis,
    ElementName.strand,
    ElementName.prismatic,
  ]) {
    if (typeName.startsWith(el.label)) return el;
  }
  final cat = categoryId.toLowerCase();
  if (cat.contains('.arc.') || cat.endsWith('.arc')) return ElementName.arc;
  if (cat.contains('.solar.') || cat.endsWith('.solar')) {
    return ElementName.solar;
  }
  if (cat.contains('.void.') || cat.endsWith('.void')) {
    return ElementName.voidElement;
  }
  if (cat.contains('.stasis.') || cat.endsWith('.stasis')) {
    return ElementName.stasis;
  }
  if (cat.contains('.strand.') || cat.endsWith('.strand')) {
    return ElementName.strand;
  }
  if (cat.contains('.prismatic.') || cat.endsWith('.prismatic')) {
    return ElementName.prismatic;
  }
  return ElementName.kinetic;
}

RawInventoryItem? findSocketPlug(
  RawInventoryItem item,
  RawTable itemTable,
  bool Function(RawInventoryItem plug) test,
) {
  for (final socket in item.socketEntries) {
    final h = socket.singleInitialItemHash;
    if (h == null || h == 0) continue;
    final plug = RawInventoryItem.tryParse(getRaw(itemTable, h));
    if (plug != null && test(plug)) return plug;
  }
  return null;
}

List<Hash> plugSetHashes(int? plugSetHash, RawTable plugSets) {
  if (plugSetHash == null || plugSetHash == 0) return const [];
  final ps = RawPlugSet.tryParse(getRaw(plugSets, plugSetHash));
  if (ps == null) return const [];
  return ps.reusablePlugItems.map((e) => e.plugItemHash).toList();
}

({List<Hash> curated, List<Hash> randomized}) socketPlugHashes(
  RawSocketEntry socket,
  RawTable plugSets,
) {
  final curated = <Hash>[];
  if (socket.reusablePlugSetHash != null) {
    curated.addAll(plugSetHashes(socket.reusablePlugSetHash, plugSets));
  } else if (socket.singleInitialItemHash != null) {
    curated.add(socket.singleInitialItemHash!);
  }
  final randomized = plugSetHashes(socket.randomizedPlugSetHash, plugSets);
  return (
    curated: curated.toSet().toList(),
    randomized: randomized.toSet().toList(),
  );
}

bool isOriginSocket(RawSocketEntry socket, RawTable itemTable) {
  final h = socket.singleInitialItemHash;
  if (h == null) return false;
  final plug = RawInventoryItem.tryParse(getRaw(itemTable, h));
  final cat = plug?.plug?['plugCategoryIdentifier'] as String? ?? '';
  return cat.contains('origins');
}

final _excludedCatPatterns = <RegExp>[
  RegExp(r'intrinsics'),
  RegExp(r'origins'),
  RegExp(r'masterwork'),
  RegExp(r'shader'),
  RegExp(r'^enhancements\.'),
];

bool isExcludedPerkSocket(RawSocketEntry socket, RawTable itemTable) {
  final h = socket.singleInitialItemHash;
  if (h == null) {
    return socket.randomizedPlugSetHash == null &&
        socket.reusablePlugSetHash == null;
  }
  final plug = RawInventoryItem.tryParse(getRaw(itemTable, h));
  final cat = plug?.plug?['plugCategoryIdentifier'] as String? ?? '';
  if (_excludedCatPatterns.any((p) => p.hasMatch(cat))) return true;
  if (cat == 'frames' && plug?.itemTypeDisplayName == 'Intrinsic') return true;
  return false;
}

List<int> getPerkSocketIndexes(RawInventoryItem item, int categoryHash) {
  for (final cat in item.socketCategories) {
    if (cat.socketCategoryHash == categoryHash) return cat.socketIndexes;
  }
  return const [];
}

bool isWeaponFrameName(String name) {
  const suffix = ' Frame';
  final trimmed = name.trim();
  if (trimmed.contains(': ')) return false;
  return trimmed.length > suffix.length && trimmed.endsWith(suffix);
}

bool isLegendaryWeaponFramePlug(RawInventoryItem plug) {
  final name = plug.displayProperties.name;
  if (!isWeaponFrameName(name)) return false;
  final cat = plug.plug?['plugCategoryIdentifier'] as String? ?? '';
  if (cat.contains('intrinsics')) return true;
  return cat == 'frames' && plug.itemTypeDisplayName == 'Intrinsic';
}
