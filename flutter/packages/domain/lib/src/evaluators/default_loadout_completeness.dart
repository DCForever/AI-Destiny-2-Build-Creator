/// Default variant composition completeness (DBR-CMPL-001, DBR-SUB-006–007, DBR-ART-003a).
///
/// Equipment slots are checked separately in [assertFullCombatLoadout]; this covers
/// subclass kit bar + artifact fill.
library;

import '../models/kit.dart';

/// Subclass kit fields for completeness checks (names, not resolved hashes).
///
/// Mirrors TS `SubclassKitFields` / product JSON (`super` key as [superAbility]).
class SubclassKitFields {
  const SubclassKitFields({
    this.name,
    this.superAbility,
    this.melee,
    this.grenade,
    this.classAbility,
    this.movement,
    this.aspects,
    this.fragments,
  });

  final String? name;
  final String? superAbility;
  final String? melee;
  final String? grenade;
  final String? classAbility;
  final String? movement;
  final List<String>? aspects;
  final List<String>? fragments;

  /// Build from domain [SubclassKit].
  factory SubclassKitFields.fromKit(SubclassKit kit) {
    return SubclassKitFields(
      name: kit.name,
      superAbility: kit.superAbility,
      melee: kit.melee,
      grenade: kit.grenade,
      classAbility: kit.classAbility,
      aspects: kit.aspects,
      fragments: kit.fragments,
    );
  }
}

bool _nonEmpty(String? value) =>
    value != null && value.trim().isNotEmpty;

List<String> _cleanList(List<String>? values) {
  if (values == null) return const [];
  return [
    for (final v in values)
      if (v.trim().isNotEmpty) v.trim(),
  ];
}

/// Gaps for default-complete subclass kit (DBR-SUB-006).
///
/// Class ability / movement are not required (DBR-SUB-007).
List<String> collectSubclassKitCompleteGaps(
  SubclassKitFields? kit, {
  int maxAspects = maxSubclassAspects,
  int fragmentCapacity = 0,
  bool capacityResolved = true,
}) {
  final missing = <String>[];
  if (kit == null) {
    missing.add('subclass');
    return missing;
  }
  if (!_nonEmpty(kit.name)) missing.add('subclass');

  if (!_nonEmpty(kit.superAbility)) missing.add('super');
  if (!_nonEmpty(kit.melee)) missing.add('melee');
  if (!_nonEmpty(kit.grenade)) missing.add('grenade');

  final aspects = _cleanList(kit.aspects);
  if (aspects.length < maxAspects) {
    missing.add('aspects');
  }

  final fragments = _cleanList(kit.fragments);

  if (capacityResolved) {
    // With aspects filled, capacity should be known and fragments must fill it.
    if (aspects.length >= maxAspects) {
      if (fragmentCapacity > 0 && fragments.length < fragmentCapacity) {
        missing.add('fragments');
      }
    }
  } else if (aspects.length >= maxAspects && fragments.isEmpty) {
    // Capacity unknown: require some fragments when aspects are filled.
    missing.add('fragments');
  }

  return missing;
}

/// Gaps for default artifact fill (DBR-ART-003a / DBR-CMPL-001a).
///
/// Selection alone is not enough — config must be non-empty.
List<String> collectArtifactCompleteGaps({
  int? artifactHash,
  List<int>? artifactConfig,
}) {
  final missing = <String>[];
  if (artifactHash == null) {
    missing.add('artifact');
    return missing;
  }
  final config = artifactConfig ?? const <int>[];
  if (config.isEmpty) {
    missing.add('artifactConfig');
  }
  return missing;
}

/// Whether subclass kit bar is composition-complete.
bool isSubclassKitCompositionComplete(
  SubclassKitFields? kit, {
  int maxAspects = maxSubclassAspects,
  int fragmentCapacity = 0,
  bool capacityResolved = true,
}) {
  return collectSubclassKitCompleteGaps(
    kit,
    maxAspects: maxAspects,
    fragmentCapacity: fragmentCapacity,
    capacityResolved: capacityResolved,
  ).isEmpty;
}

/// Whether artifact hash + non-empty config are present.
bool isArtifactCompositionComplete({
  int? artifactHash,
  List<int>? artifactConfig,
}) {
  return collectArtifactCompleteGaps(
    artifactHash: artifactHash,
    artifactConfig: artifactConfig,
  ).isEmpty;
}
