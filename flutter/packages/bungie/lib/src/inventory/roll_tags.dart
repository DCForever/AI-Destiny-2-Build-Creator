import 'package:destiny2_sandbox_data/destiny2_sandbox_data.dart';

/// Wire values for inventory `rollTags` (product `RollTag` union).
abstract final class RollTags {
  static const crafted = 'Crafted';
  static const championBarrier = 'ChampionBarrier';
  static const championOverload = 'ChampionOverload';
  static const championUnstoppable = 'ChampionUnstoppable';
  static const meleeBuildCandidate = 'MeleeBuildCandidate';
  static const orbitBuild = 'OrbitBuild';
}

/// Legendary weapon metadata needed for frame-based champion tags.
///
/// Subset of product `WeaponRecord` (`frame` + `itemTypeName`).
class RollTagWeaponMeta {
  const RollTagWeaponMeta({
    required this.frame,
    required this.itemTypeName,
  });

  final String frame;
  final String itemTypeName;
}

class ComputeRollTagsOptions {
  const ComputeRollTagsOptions({this.isCrafted = false});

  final bool isCrafted;
}

final _perkChampionPatterns = <({RegExp pattern, String tag})>[
  (pattern: RegExp(r'\banti-?barrier\b', caseSensitive: false), tag: RollTags.championBarrier),
  (pattern: RegExp(r'\bbarrier\b', caseSensitive: false), tag: RollTags.championBarrier),
  (pattern: RegExp(r'\boverload\b', caseSensitive: false), tag: RollTags.championOverload),
  (pattern: RegExp(r'\bunstoppable\b', caseSensitive: false), tag: RollTags.championUnstoppable),
];

String? _championTagForType(ChampionType type) {
  switch (type) {
    case ChampionType.barrier:
      return RollTags.championBarrier;
    case ChampionType.overload:
      return RollTags.championOverload;
    case ChampionType.unstoppable:
      return RollTags.championUnstoppable;
  }
}

List<String> _perkNamesFromHashes(
  List<int> plugHashes,
  Map<int, String> perkNameMap,
) {
  final names = <String>[];
  for (final hash in plugHashes) {
    final name = perkNameMap[hash];
    if (name != null && name.isNotEmpty) names.add(name);
  }
  return names;
}

bool _hasPerk(List<String> names, String target) {
  final needle = target.toLowerCase();
  return names.any((name) => name.toLowerCase().contains(needle));
}

String? _championTagFromPerks(List<String> names) {
  for (final entry in _perkChampionPatterns) {
    if (names.any((name) => entry.pattern.hasMatch(name))) {
      return entry.tag;
    }
  }
  return null;
}

/// Rule-based roll tag assignment from plug hashes and optional weapon metadata.
///
/// Port of product `computeRollTags` in `src/lib/inventory/rollTags.ts`.
/// Tags are computed at sync time and stored on inventory rows.
/// Soft metadata only — never auto-applies build edits.
List<String> computeRollTags(
  List<int> plugHashes,
  Map<int, String> perkNameMap, {
  RollTagWeaponMeta? weapon,
  ComputeRollTagsOptions? options,
  bool? isCrafted,
}) {
  final crafted = isCrafted ?? options?.isCrafted ?? false;
  final tags = <String>{};
  final perkNames = _perkNamesFromHashes(plugHashes, perkNameMap);

  if (crafted) {
    tags.add(RollTags.crafted);
  }

  if (weapon != null) {
    final intrinsic = getChampionCounterForFrame(
      weapon.frame,
      weapon.itemTypeName,
    );
    if (intrinsic != null) {
      final tag = _championTagForType(intrinsic);
      if (tag != null) tags.add(tag);
    }
  }

  final perkChampion = _championTagFromPerks(perkNames);
  if (perkChampion != null) {
    tags.add(perkChampion);
  }

  if (weapon?.itemTypeName == 'Hand Cannon' &&
      _hasPerk(perkNames, 'Pugilist') &&
      _hasPerk(perkNames, 'Swashbuckler')) {
    tags.add(RollTags.meleeBuildCandidate);
  }

  if (_hasPerk(perkNames, 'Demolitionist') &&
      _hasPerk(perkNames, 'Adrenaline Junkie')) {
    tags.add(RollTags.orbitBuild);
  }

  return tags.toList(growable: false);
}
