/// Pure DIM Sync loadout document shapes and constants.
///
/// Mirrors TypeScript `src/lib/dim/dimLoadout.ts` types + hash tables.
/// No network / dim.gg share logic.
library;

import 'equipment.dart';
import 'soft_stats.dart';

/// DIM / Destiny classType integers.
abstract final class DimClassType {
  static const int titan = 0;
  static const int hunter = 1;
  static const int warlock = 2;

  /// Wire name Titan/Hunter/Warlock → DIM classType.
  static int fromGuardianClass(GuardianClass className) {
    switch (className) {
      case GuardianClass.titan:
        return titan;
      case GuardianClass.hunter:
        return hunter;
      case GuardianClass.warlock:
        return warlock;
    }
  }
}

/// Armor 3.0 stat definition hashes used by DIM loadout parameters.
abstract final class DimStatHashes {
  static const int weapons = 2996146975;
  static const int health = 392767087;
  static const int classStat = 1943323491;
  static const int grenade = 1735777505;
  static const int superStat = 144602215;
  static const int melee = 4244567218;

  static int? forArmorStat(ArmorStatName stat) {
    switch (stat) {
      case ArmorStatName.weapons:
        return weapons;
      case ArmorStatName.health:
        return health;
      case ArmorStatName.classStat:
        return classStat;
      case ArmorStatName.grenade:
        return grenade;
      case ArmorStatName.superStat:
        return superStat;
      case ArmorStatName.melee:
        return melee;
    }
  }
}

/// One equipped/unequipped item in a DIM loadout.
class DimLoadoutItem {
  const DimLoadoutItem({
    required this.hash,
    this.id,
    this.amount,
    this.socketOverrides,
  });

  final String? id;
  final int hash;
  final int? amount;

  /// Socket index → plug hash (selected perks).
  final Map<int, int>? socketOverrides;

  Map<String, Object?> toJson() {
    final map = <String, Object?>{'hash': hash};
    if (id != null) map['id'] = id;
    if (amount != null) map['amount'] = amount;
    if (socketOverrides != null && socketOverrides!.isNotEmpty) {
      // JSON object keys are strings (matches JSON.stringify of TS number keys).
      map['socketOverrides'] = {
        for (final e in socketOverrides!.entries) '${e.key}': e.value,
      };
    }
    return map;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DimLoadoutItem) return false;
    if (other.id != id || other.hash != hash || other.amount != amount) {
      return false;
    }
    return _intMapEquals(other.socketOverrides, socketOverrides);
  }

  @override
  int get hashCode => Object.hash(
        id,
        hash,
        amount,
        Object.hashAll(
          (socketOverrides?.entries ?? const <MapEntry<int, int>>[])
              .map((e) => Object.hash(e.key, e.value)),
        ),
      );
}

/// DIM loadout optimizer stat constraint.
class DimStatConstraint {
  const DimStatConstraint({
    required this.statHash,
    this.minStat,
    this.maxStat,
  });

  final int statHash;
  final int? minStat;
  final int? maxStat;

  Map<String, Object?> toJson() {
    final map = <String, Object?>{'statHash': statHash};
    if (minStat != null) map['minStat'] = minStat;
    if (maxStat != null) map['maxStat'] = maxStat;
    return map;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DimStatConstraint &&
        other.statHash == statHash &&
        other.minStat == minStat &&
        other.maxStat == maxStat;
  }

  @override
  int get hashCode => Object.hash(statHash, minStat, maxStat);
}

/// DIM loadout parameters block.
class DimLoadoutParameters {
  const DimLoadoutParameters({
    this.statConstraints,
    this.mods,
    this.exoticArmorHash,
    this.autoStatMods,
    this.includeRuntimeStatBenefits,
  });

  final List<DimStatConstraint>? statConstraints;
  final List<int>? mods;
  final int? exoticArmorHash;
  final bool? autoStatMods;
  final bool? includeRuntimeStatBenefits;

  Map<String, Object?> toJson() {
    final map = <String, Object?>{};
    if (statConstraints != null && statConstraints!.isNotEmpty) {
      map['statConstraints'] = [
        for (final c in statConstraints!) c.toJson(),
      ];
    }
    if (mods != null && mods!.isNotEmpty) {
      map['mods'] = List<int>.from(mods!);
    }
    if (exoticArmorHash != null) map['exoticArmorHash'] = exoticArmorHash;
    if (autoStatMods != null) map['autoStatMods'] = autoStatMods;
    if (includeRuntimeStatBenefits != null) {
      map['includeRuntimeStatBenefits'] = includeRuntimeStatBenefits;
    }
    return map;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DimLoadoutParameters) return false;
    if (other.exoticArmorHash != exoticArmorHash ||
        other.autoStatMods != autoStatMods ||
        other.includeRuntimeStatBenefits != includeRuntimeStatBenefits) {
      return false;
    }
    if (!_intListEquals(other.mods, mods)) return false;
    if (!_constraintListEquals(other.statConstraints, statConstraints)) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        exoticArmorHash,
        autoStatMods,
        includeRuntimeStatBenefits,
        Object.hashAll(mods ?? const []),
        Object.hashAll(statConstraints ?? const []),
      );
}

/// Full DIM Sync loadout document.
class DimLoadout {
  const DimLoadout({
    required this.id,
    required this.name,
    required this.classType,
    required this.equipped,
    required this.unequipped,
    this.notes,
    this.parameters,
  });

  final String id;
  final String name;
  final String? notes;
  final int classType;
  final List<DimLoadoutItem> equipped;
  final List<DimLoadoutItem> unequipped;
  final DimLoadoutParameters? parameters;

  Map<String, Object?> toJson() {
    final map = <String, Object?>{
      'id': id,
      'name': name,
      'classType': classType,
      'equipped': [for (final i in equipped) i.toJson()],
      'unequipped': [for (final i in unequipped) i.toJson()],
    };
    if (notes != null) map['notes'] = notes;
    if (parameters != null) map['parameters'] = parameters!.toJson();
    return map;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DimLoadout) return false;
    if (other.id != id ||
        other.name != name ||
        other.notes != notes ||
        other.classType != classType ||
        other.parameters != parameters) {
      return false;
    }
    if (other.equipped.length != equipped.length) return false;
    for (var i = 0; i < equipped.length; i++) {
      if (other.equipped[i] != equipped[i]) return false;
    }
    if (other.unequipped.length != unequipped.length) return false;
    for (var i = 0; i < unequipped.length; i++) {
      if (other.unequipped[i] != unequipped[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        notes,
        classType,
        parameters,
        Object.hashAll(equipped),
        Object.hashAll(unequipped),
      );
}

/// Optional subclass fields used only for loadout notes.
class DimSubclassNote {
  const DimSubclassNote({this.name, this.superName});

  final String? name;

  /// TS field name is `super` (reserved in Dart).
  final String? superName;
}

/// Resolved seasonal artifact for DIM notes.
class DimArtifact {
  const DimArtifact({
    required this.hash,
    required this.name,
    this.config = const [],
  });

  final int hash;
  final String name;
  final List<int> config;
}

/// One fashion ornament / cosmetic piece.
class DimFashionPiece {
  const DimFashionPiece({
    required this.itemHash,
    required this.itemName,
  });

  final int itemHash;
  final String itemName;
}

/// Resolved fashion set for unequipped DIM items.
class DimFashion {
  const DimFashion({
    required this.setId,
    this.pieces = const [],
  });

  final String setId;

  /// Fashion pieces in export order (values of TS `fashion.slots`).
  final List<DimFashionPiece> pieces;
}

bool _intMapEquals(Map<int, int>? a, Map<int, int>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (b[e.key] != e.value) return false;
  }
  return true;
}

bool _intListEquals(List<int>? a, List<int>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _constraintListEquals(
  List<DimStatConstraint>? a,
  List<DimStatConstraint>? b,
) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
