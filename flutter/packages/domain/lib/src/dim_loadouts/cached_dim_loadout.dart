/// Compiled DIM loadout cache models (inbound read path).
///
/// Distinct from [DimLoadout] export DTOs under `models/dim_loadout.dart`.
/// These types describe `{StorageRoot}/dim_loadouts/dim-loadouts.json`.
library;

/// One named plug / mod / perk row from the compiled cache.
class CachedDimNamedHash {
  const CachedDimNamedHash({
    required this.hash,
    required this.name,
    this.description = '',
  });

  final int hash;
  final String name;
  final String description;
}

/// Named item with optional tier / type labels.
class CachedDimItem {
  const CachedDimItem({
    required this.hash,
    required this.name,
    required this.itemType,
    required this.tier,
  });

  final int hash;
  final String name;
  final String itemType;
  final String tier;
}

/// Optional exotic armor/weapon summary on a cached loadout.
class CachedDimExotic {
  const CachedDimExotic({
    required this.hash,
    required this.name,
    required this.description,
  });

  final int hash;
  final String name;
  final String description;
}

/// Optional subclass summary.
///
/// [superName] / [superIconPath] are additive optional fields from the
/// compiled cache when present. Older catalogs omit them.
class CachedDimSubclass {
  const CachedDimSubclass({
    required this.hash,
    required this.name,
    this.superName,
    this.superIconPath,
  });

  final int hash;

  /// Element / subclass display name (e.g. Strand).
  final String name;

  /// Super ability display name when the compiler included it.
  final String? superName;

  /// Relative Bungie icon path for the Super when present.
  final String? superIconPath;
}

/// One DIM optimizer constraint row (order = priority).
class CachedDimStatConstraint {
  const CachedDimStatConstraint({
    required this.statHash,
    required this.name,
    this.minTier,
    this.maxTier,
    this.minStat,
    this.maxStat,
  });

  final int statHash;
  final String name;
  final int? minTier;
  final int? maxTier;
  final int? minStat;
  final int? maxStat;
}

/// One loadout inside the compiled `dim-loadouts.json` catalog.
class CachedDimLoadout {
  const CachedDimLoadout({
    required this.shareId,
    required this.name,
    required this.classType,
    required this.items,
    required this.subclassPlugs,
    required this.mods,
    required this.artifactPerks,
    this.subclass,
    this.exotic,
    this.artifactSeason,
    this.statConstraints,
    this.notes,
  });

  final String shareId;
  final String name;
  final int classType;
  final CachedDimSubclass? subclass;
  final CachedDimExotic? exotic;
  final List<CachedDimItem> items;
  final List<CachedDimNamedHash> subclassPlugs;
  final List<CachedDimNamedHash> mods;
  final int? artifactSeason;
  final List<CachedDimNamedHash> artifactPerks;
  final List<CachedDimStatConstraint>? statConstraints;
  final String? notes;
}

/// Root catalog object for schemaVersion 1.
class CachedDimLoadoutCatalog {
  const CachedDimLoadoutCatalog({
    required this.schemaVersion,
    required this.generatedAtPt,
    required this.manifestVersion,
    required this.loadouts,
  });

  final int schemaVersion;
  final String generatedAtPt;
  final String manifestVersion;
  final List<CachedDimLoadout> loadouts;
}
