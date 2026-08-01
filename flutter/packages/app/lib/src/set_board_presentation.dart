import 'package:destiny2_db/destiny2_db.dart';

/// Named perk chip for set item rows (BR-SET-010 / BR-ROLL-001).
class SetItemPerkDisplay {
  const SetItemPerkDisplay({
    required this.hash,
    required this.name,
  });

  final int hash;
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetItemPerkDisplay && other.hash == hash && other.name == name;

  @override
  int get hashCode => Object.hash(hash, name);
}

/// Linked library synergy badge for a set item.
class SetItemLinkedSynergy {
  const SetItemLinkedSynergy({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

/// Whether an equipment board slot is an armor piece slot.
bool isArmorBoardSlot(String slot) {
  final base = slot.contains(':') ? slot.split(':').first : slot;
  switch (base) {
    case 'helmet':
    case 'arms':
    case 'chest':
    case 'legs':
    case 'class_item':
    case 'exotic_armor':
      return true;
    default:
      return false;
  }
}

/// Occupied single-occupant slots require replace confirm (BR-SLOT-006).
///
/// For mod multi-keys, pass [exactKeyOccupied] only when the exact write key
/// already has an active item.
bool slotNeedsReplaceConfirm({
  required bool slotOccupied,
}) {
  return slotOccupied;
}

/// Extract perk hashes to store on fill from an owned instance projection.
///
/// Prefers trait-classified socket plugs; falls back to trait plug cards;
/// then all equipped plug hashes when no classification is available
/// (wishlist / unenriched residual keeps empty when no plugs).
List<int> selectedPerksFromInstance(CatalogInstanceProjection? instance) {
  if (instance == null) return const [];

  final fromSockets = <int>[];
  final plugs = instance.socketPlugs;
  if (plugs != null) {
    for (final raw in plugs) {
      final kind = raw['columnKind'] as String?;
      final label = (raw['columnLabel'] as String?)?.toLowerCase() ?? '';
      final isTrait = kind == 'trait' || label.contains('trait');
      if (!isTrait) continue;
      final equipped = raw['equippedPlugHash'];
      final hash = equipped is int
          ? equipped
          : equipped is num
              ? equipped.toInt()
              : null;
      if (hash == null || hash == 0) continue;
      if (!fromSockets.contains(hash)) fromSockets.add(hash);
    }
  }
  if (fromSockets.isNotEmpty) return List.unmodifiable(fromSockets);

  final fromCards = <int>[];
  for (final card in instance.plugCards) {
    if (!card.isTrait) continue;
    if (card.hash == 0) continue;
    if (!fromCards.contains(card.hash)) fromCards.add(card.hash);
  }
  if (fromCards.isNotEmpty) return List.unmodifiable(fromCards);

  // Unclassified plugs: store equipped hashes so roll data is not dropped
  // (BR-ROLL-001 full roll). Detail UI still filters traits when classified.
  if (instance.plugHashes.isNotEmpty) {
    return List.unmodifiable(
      instance.plugHashes.where((h) => h != 0).toList(),
    );
  }
  return const [];
}

/// Trait perks for display on set item rows (exclude barrel/mag when classified).
List<SetItemPerkDisplay> traitPerksForDisplay({
  List<int> selectedPerks = const [],
  List<ResolvedPlugCard> plugCards = const [],
  Map<int, String> plugNameByHash = const {},
}) {
  final out = <SetItemPerkDisplay>[];
  final seen = <int>{};

  final traitCards = plugCards.where((c) => c.isTrait).toList();
  if (traitCards.isNotEmpty) {
    for (final card in traitCards) {
      if (!seen.add(card.hash)) continue;
      out.add(SetItemPerkDisplay(hash: card.hash, name: card.displayName));
    }
    return List.unmodifiable(out);
  }

  // When cards are present but none are traits, only show selectedPerks that
  // are not classified as non-trait in plugCards.
  final nonTrait = {
    for (final c in plugCards)
      if (!c.isTrait && c.columnKind != null) c.hash,
  };

  for (final hash in selectedPerks) {
    if (hash == 0 || !seen.add(hash)) continue;
    if (nonTrait.contains(hash)) continue;
    final name = plugNameByHash[hash];
    final cardMatch = plugCards.where((c) => c.hash == hash).toList();
    final display = name ??
        (cardMatch.isNotEmpty ? cardMatch.first.displayName : '#$hash');
    out.add(SetItemPerkDisplay(hash: hash, name: display));
  }
  return List.unmodifiable(out);
}

/// Catalog / inventory meta chips for a filled set item row (BR-SET-010).
List<String> buildSetItemMetaChips({
  bool? isExotic,
  String? element,
  String? ammo,
  String? itemTypeName,
  String? frame,
  String? classType,
  String? tierLabel,
  int? tier,
  String? originTraitName,
  int? power,
  String? location,
  required bool hasInstance,
  bool stale = false,
}) {
  final meta = <String>[];
  if (isExotic == true) meta.add('Exotic');
  if (element != null && element.isNotEmpty) meta.add(element);
  if (ammo != null && ammo.isNotEmpty) meta.add(ammo);
  if (itemTypeName != null && itemTypeName.isNotEmpty) meta.add(itemTypeName);
  if (frame != null && frame.isNotEmpty) meta.add(frame);
  if (classType != null && classType.isNotEmpty) meta.add(classType);
  if (tierLabel != null && tierLabel.isNotEmpty) {
    meta.add(tierLabel);
  } else if (tier != null) {
    meta.add('Tier $tier');
  }
  if (originTraitName != null && originTraitName.isNotEmpty) {
    meta.add(originTraitName);
  }
  if (power != null) meta.add('P$power');
  if (location != null && location.isNotEmpty) meta.add(location);
  meta.add(hasInstance ? 'Instance' : 'Wishlist');
  if (stale) meta.add('Stale');
  return meta;
}

/// Presentation row for one active set item (host-enriched).
class SetItemRowPresentation {
  const SetItemRowPresentation({
    required this.itemId,
    required this.slot,
    required this.itemHash,
    required this.itemName,
    this.instanceId,
    this.icon,
    this.metaChips = const [],
    this.traitPerks = const [],
    this.linkedSynergies = const [],
    this.armorStats,
    this.statsUnknown = false,
  });

  final String itemId;
  final String slot;
  final int itemHash;
  final String itemName;
  final String? instanceId;
  final String? icon;
  final List<String> metaChips;
  final List<SetItemPerkDisplay> traitPerks;
  final List<SetItemLinkedSynergy> linkedSynergies;
  final ArmorBaseStatBoard? armorStats;

  /// True when armor slot has no resolvable rolls (wishlist or missing).
  final bool statsUnknown;

  bool get hasInstance => instanceId != null && instanceId!.isNotEmpty;
}
