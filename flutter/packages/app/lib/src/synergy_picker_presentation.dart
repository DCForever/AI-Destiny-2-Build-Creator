import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';

import 'synergy_use_cases.dart';

/// Weapon-perk host tier for BR-SYN-012 labels (product `WeaponPerkSource`).
enum WeaponPerkSource {
  exotic,
  legendary,
  both,
}

/// Stable coverage key for “is this evidence target already linked?” (BR-SYN-011).
///
/// Product parity: `coverageKeyFromLink` in `src/lib/synergies/coverageKeys.ts`.
String? coverageKeyFromLink({
  required String kind,
  int? itemHash,
  int? perkHash,
  int? originTraitHash,
  String? originTraitName,
  String? armorSetName,
  int? bonusPieces,
  String? bonusName,
}) {
  switch (kind) {
    case 'weapon':
      if (itemHash == null) return null;
      return 'weapon:$itemHash';
    case 'weapon_perk':
      if (perkHash == null) return null;
      return 'weapon_perk:$perkHash';
    case 'origin_trait':
      if (originTraitHash != null) {
        return 'origin_trait:hash:$originTraitHash';
      }
      final name = originTraitName?.trim().toLowerCase() ?? '';
      if (name.isEmpty) return null;
      return 'origin_trait:name:$name';
    case 'armor_set_bonus':
      final set = armorSetName?.trim().toLowerCase() ?? '';
      if (set.isEmpty || bonusPieces == null) return null;
      final bonus = bonusName?.trim().toLowerCase() ?? '';
      return 'armor_set_bonus:$set:$bonusPieces:$bonus';
    case 'exotic_armor':
      if (itemHash == null) return null;
      return 'exotic_armor:$itemHash';
    case 'artifact_perk':
      if (perkHash == null) return null;
      return 'artifact_perk:$perkHash';
    default:
      return null;
  }
}

/// Dedupe key for draft links (coverage key or name fallback).
String linkDedupeKey({
  required String kind,
  required String displayName,
  int? itemHash,
  int? perkHash,
  int? originTraitHash,
  String? originTraitName,
  String? armorSetName,
  int? bonusPieces,
  String? bonusName,
}) {
  final key = coverageKeyFromLink(
    kind: kind,
    itemHash: itemHash,
    perkHash: perkHash,
    originTraitHash: originTraitHash,
    originTraitName: originTraitName,
    armorSetName: armorSetName,
    bonusPieces: bonusPieces,
    bonusName: bonusName,
  );
  if (key != null) return key;
  return 'fallback:$kind:${displayName.trim().toLowerCase()}';
}

String linkDedupeKeyFromWrite(SynergyLinkWrite link) {
  return linkDedupeKey(
    kind: link.kind,
    displayName: link.displayName,
    itemHash: link.itemHash,
    perkHash: link.perkHash,
    originTraitHash: link.originTraitHash,
    originTraitName: link.originTraitName,
    armorSetName: link.armorSetName,
    bonusPieces: link.bonusPieces,
    bonusName: link.bonusName,
  );
}

Set<String> draftLinkKeys(Iterable<SynergyLinkWrite> links) {
  return {for (final l in links) linkDedupeKeyFromWrite(l)};
}

/// Drop weapon catalog hits already on the draft (BR-SYN-011).
List<CatalogItem> filterOutLinkedWeapons(
  List<CatalogItem> options,
  Iterable<SynergyLinkWrite> draftLinks,
) {
  final linked = draftLinkKeys(draftLinks);
  return options
      .where(
        (opt) => !linked.contains(
          linkDedupeKey(
            kind: 'weapon',
            displayName: opt.name,
            itemHash: opt.hash,
          ),
        ),
      )
      .toList();
}

/// Evidence picker row (kind-aware catalog / synthetic hit).
class SynergyPickerHit {
  const SynergyPickerHit({
    required this.kind,
    required this.name,
    this.hash,
    this.perkHash,
    this.parentItemHash,
    this.originTraitName,
    this.originTraitHash,
    this.armorSetName,
    this.bonusPieces,
    this.bonusName,
    this.armorSetHash,
    this.sourceLabel,
    this.subtitle,
  });

  final String kind;
  final String name;
  final int? hash;
  final int? perkHash;
  final int? parentItemHash;
  final String? originTraitName;
  final int? originTraitHash;
  final String? armorSetName;
  final int? bonusPieces;
  final String? bonusName;
  final int? armorSetHash;

  /// BR-SYN-012 label when known.
  final String? sourceLabel;
  final String? subtitle;
}

/// Drop picker hits already on the draft (BR-SYN-011).
List<SynergyPickerHit> filterOutLinkedPickerItems(
  List<SynergyPickerHit> options,
  Iterable<SynergyLinkWrite> draftLinks,
) {
  final linked = draftLinkKeys(draftLinks);
  return options.where((item) {
    final key = linkDedupeKey(
      kind: item.kind,
      displayName: item.name,
      itemHash: item.hash,
      perkHash: item.perkHash ?? item.hash,
      originTraitHash: item.originTraitHash,
      originTraitName: item.originTraitName,
      armorSetName: item.armorSetName,
      bonusPieces: item.bonusPieces,
      bonusName: item.bonusName,
    );
    return !linked.contains(key);
  }).toList();
}

/// Human label for weapon_perk picker rows (BR-SYN-012).
String? formatWeaponPerkSourceLabel(
  WeaponPerkSource? source, [
  String? plugTypeName,
]) {
  if (source == null) return null;
  final role = (plugTypeName ?? '').trim().toLowerCase();
  final isIntrinsic = role == 'intrinsic';

  if (source == WeaponPerkSource.both) return 'Legendary & exotic';
  if (source == WeaponPerkSource.exotic) {
    return isIntrinsic ? 'Exotic intrinsic' : 'Exotic trait';
  }
  return isIntrinsic ? 'Legendary intrinsic' : 'Legendary perk';
}

/// Infer perk source from catalog exotic flag when full plug store unavailable.
WeaponPerkSource? inferWeaponPerkSource({
  bool? hostIsExotic,
  bool? alsoOnLegendary,
  bool? alsoOnExotic,
}) {
  if (alsoOnLegendary == true && alsoOnExotic == true) {
    return WeaponPerkSource.both;
  }
  if (hostIsExotic == true || alsoOnExotic == true) {
    return WeaponPerkSource.exotic;
  }
  if (hostIsExotic == false || alsoOnLegendary == true) {
    return WeaponPerkSource.legendary;
  }
  return null;
}

bool _matchesQuery(CatalogItem item, String q) {
  if (q.isEmpty) return true;
  final hay =
      '${item.name} ${item.hash} ${item.itemTypeName ?? ''} ${item.description ?? ''}'
          .toLowerCase();
  return hay.contains(q);
}

bool _itemMatchesLinkKind(CatalogItem item, String kindWire) {
  final kind = SynergyLinkKind.tryParse(kindWire);
  if (kind == null) return false;
  final comp = compositionKindFromCatalogItem(item);
  switch (kind) {
    case SynergyLinkKind.weapon:
      return comp == CompositionKind.weapon ||
          comp == CompositionKind.exoticWeapon ||
          (comp == null &&
              (item.ammo != null ||
                  item.slot == 'Kinetic' ||
                  item.slot == 'Energy' ||
                  item.slot == 'Power'));
    case SynergyLinkKind.exoticArmor:
      return comp == CompositionKind.exoticArmor ||
          (item.isExotic &&
              (comp == CompositionKind.armor ||
                  item.slot == 'Helmet' ||
                  item.slot == 'Gauntlets' ||
                  item.slot == 'Chest' ||
                  item.slot == 'Legs' ||
                  item.slot == 'ClassItem'));
    case SynergyLinkKind.weaponPerk:
      return comp == CompositionKind.weaponPerk ||
          (item.itemTypeName?.toLowerCase().contains('perk') ?? false) ||
          // Fallback: allow weapon rows as perk hosts when plug store missing.
          comp == CompositionKind.weapon ||
          comp == CompositionKind.exoticWeapon ||
          comp == CompositionKind.mod;
    case SynergyLinkKind.originTrait:
      return comp == CompositionKind.originTrait ||
          (item.itemTypeName?.toLowerCase().contains('origin') ?? false) ||
          (item.name.toLowerCase().contains('origin'));
    case SynergyLinkKind.armorSetBonus:
      return comp == CompositionKind.armorSetBonus ||
          (item.itemTypeName?.toLowerCase().contains('set bonus') ?? false) ||
          (item.name.toLowerCase().contains('set bonus'));
    case SynergyLinkKind.artifactPerk:
      return comp == CompositionKind.artifactPerk ||
          (item.itemTypeName?.toLowerCase().contains('artifact') ?? false) ||
          (item.name.toLowerCase().contains('artifact'));
  }
}

/// Search catalog items for evidence picker by [linkKind] and free-text [query].
List<SynergyPickerHit> searchCatalogForSynergyLinks({
  required List<CatalogItem> catalog,
  required String linkKind,
  String query = '',
  int limit = 40,
}) {
  final q = query.trim().toLowerCase();
  final hits = <SynergyPickerHit>[];
  for (final item in catalog) {
    if (!_itemMatchesLinkKind(item, linkKind)) continue;
    if (!_matchesQuery(item, q)) continue;
    hits.add(catalogItemToPickerHit(item, linkKind));
    if (hits.length >= limit) break;
  }
  return hits;
}

/// Map a catalog row to a picker hit for [linkKind].
SynergyPickerHit catalogItemToPickerHit(CatalogItem item, String linkKind) {
  String? sourceLabel;
  if (linkKind == SynergyLinkKind.weaponPerk.wireName) {
    final source = inferWeaponPerkSource(hostIsExotic: item.isExotic);
    sourceLabel = formatWeaponPerkSourceLabel(source, item.itemTypeName);
  }
  return SynergyPickerHit(
    kind: linkKind,
    name: item.name,
    hash: item.hash,
    perkHash: linkKind == SynergyLinkKind.weaponPerk.wireName ||
            linkKind == SynergyLinkKind.artifactPerk.wireName
        ? item.hash
        : null,
    originTraitName:
        linkKind == SynergyLinkKind.originTrait.wireName ? item.name : null,
    originTraitHash:
        linkKind == SynergyLinkKind.originTrait.wireName ? item.hash : null,
    armorSetName:
        linkKind == SynergyLinkKind.armorSetBonus.wireName ? item.name : null,
    bonusPieces:
        linkKind == SynergyLinkKind.armorSetBonus.wireName ? 2 : null,
    sourceLabel: sourceLabel,
    subtitle: [
      if (item.itemTypeName != null && item.itemTypeName!.isNotEmpty)
        item.itemTypeName!,
      if (item.element != null && item.element!.isNotEmpty) item.element!,
      if (sourceLabel != null) sourceLabel,
      '#${item.hash}',
    ].join(' · '),
  );
}

/// Build a [SynergyLinkWrite] from a picker hit.
SynergyLinkWrite pickerHitToLinkWrite(SynergyPickerHit hit) {
  final kind = SynergyLinkKind.tryParse(hit.kind);
  switch (kind) {
    case SynergyLinkKind.weapon:
    case SynergyLinkKind.exoticArmor:
      return SynergyLinkWrite(
        kind: hit.kind,
        displayName: hit.name,
        itemHash: hit.hash,
      );
    case SynergyLinkKind.weaponPerk:
    case SynergyLinkKind.artifactPerk:
      return SynergyLinkWrite(
        kind: hit.kind,
        displayName: hit.name,
        perkHash: hit.perkHash ?? hit.hash,
        parentItemHash: hit.parentItemHash,
      );
    case SynergyLinkKind.originTrait:
      return SynergyLinkWrite(
        kind: hit.kind,
        displayName: hit.name,
        originTraitName: hit.originTraitName ?? hit.name,
        originTraitHash: hit.originTraitHash ?? hit.hash,
      );
    case SynergyLinkKind.armorSetBonus:
      return SynergyLinkWrite(
        kind: hit.kind,
        displayName: hit.name,
        armorSetName: hit.armorSetName ?? hit.name,
        bonusPieces: hit.bonusPieces ?? 2,
        bonusName: hit.bonusName,
        armorSetHash: hit.armorSetHash ?? hit.hash,
      );
    case null:
      return SynergyLinkWrite(
        kind: hit.kind,
        displayName: hit.name,
        itemHash: hit.hash,
      );
  }
}

/// Whether [candidate] is already covered by draft links (BR-SYN-011).
bool isLinkAlreadyDrafted(
  SynergyLinkWrite candidate,
  Iterable<SynergyLinkWrite> draftLinks,
) {
  final key = linkDedupeKeyFromWrite(candidate);
  return draftLinkKeys(draftLinks).contains(key);
}
