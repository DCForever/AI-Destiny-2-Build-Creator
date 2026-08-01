import 'catalog_item.dart';

/// Minimal synergy link shape for catalog annotate (product SynergyCatalogLink).
class CatalogSynergyLinkRef {
  const CatalogSynergyLinkRef({
    required this.kind,
    this.itemHash,
    this.perkHash,
    this.originTraitHash,
    this.originTraitName,
    this.armorSetHash,
    this.armorSetName,
  });

  final String kind;
  final int? itemHash;
  final int? perkHash;
  final int? originTraitHash;
  final String? originTraitName;
  final int? armorSetHash;
  final String? armorSetName;
}

/// Library synergy id + display name + links for membership annotate.
class CatalogSynergyMembership {
  const CatalogSynergyMembership({
    required this.id,
    required this.name,
    this.links = const [],
  });

  final String id;
  final String name;
  final List<CatalogSynergyLinkRef> links;
}

/// Build itemHash → synergy ids from weapon / exotic_armor links.
///
/// Deep perk/origin/set-bonus → item expansion requires entity indexes and is
/// intentionally out of scope for primary filter annotate (PROC-06 residual).
Map<int, List<String>> buildLinkedSynergyIdsByItemHash(
  Iterable<CatalogSynergyMembership> synergies,
) {
  final map = <int, List<String>>{};
  for (final syn in synergies) {
    for (final link in syn.links) {
      final kind = link.kind;
      if (kind != 'weapon' && kind != 'exotic_armor') continue;
      final hash = link.itemHash;
      if (hash == null) continue;
      final list = map.putIfAbsent(hash, () => <String>[]);
      if (!list.contains(syn.id)) list.add(syn.id);
    }
  }
  return map;
}

/// Build synergy id → display name lookup.
Map<String, String> buildSynergyNameById(
  Iterable<CatalogSynergyMembership> synergies,
) {
  return {for (final s in synergies) s.id: s.name};
}

/// Annotate [items] with [linkedByHash] (itemHash → synergy ids).
///
/// Unlisted hashes keep prior [CatalogItem.linkedSynergyIds] only when
/// [replaceExisting] is false; default replaces so stale ids clear.
List<CatalogItem> annotateCatalogWithLinkedSynergies(
  List<CatalogItem> items,
  Map<int, List<String>> linkedByHash, {
  bool replaceExisting = true,
}) {
  if (linkedByHash.isEmpty && replaceExisting) {
    return [
      for (final item in items)
        item.linkedSynergyIds.isEmpty
            ? item
            : item.copyWith(linkedSynergyIds: const []),
    ];
  }
  return [
    for (final item in items)
      () {
        final ids = linkedByHash[item.hash];
        if (ids == null || ids.isEmpty) {
          if (replaceExisting && item.linkedSynergyIds.isNotEmpty) {
            return item.copyWith(linkedSynergyIds: const []);
          }
          return item;
        }
        final next = List<String>.unmodifiable(ids);
        if (_listEq(item.linkedSynergyIds, next)) return item;
        return item.copyWith(linkedSynergyIds: next);
      }(),
  ];
}

/// Linked synergy badge DTOs for a catalog item (id + name).
class LinkedSynergyBadge {
  const LinkedSynergyBadge({required this.id, required this.name});

  final String id;
  final String name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LinkedSynergyBadge && other.id == id && other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, name);
}

/// Resolve badges for [item] from membership annotate + name map.
List<LinkedSynergyBadge> linkedSynergyBadgesForItem(
  CatalogItem item,
  Map<String, String> nameById,
) {
  final out = <LinkedSynergyBadge>[];
  for (final id in item.linkedSynergyIds) {
    out.add(LinkedSynergyBadge(id: id, name: nameById[id] ?? id));
  }
  return out;
}

bool _listEq(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
