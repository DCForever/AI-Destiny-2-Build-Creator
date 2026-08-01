// Compact entity records projected from raw Bungie tables (MVP stores).
// Port of `src/lib/manifest/types/records.ts` (subset used by DART-017).

typedef Hash = int;

enum DestinyClassName {
  titan('Titan'),
  hunter('Hunter'),
  warlock('Warlock');

  const DestinyClassName(this.label);
  final String label;

  static DestinyClassName? tryParse(String? value) {
    if (value == null) return null;
    for (final v in values) {
      if (v.label == value || v.name.toLowerCase() == value.toLowerCase()) {
        return v;
      }
    }
    return null;
  }
}

enum ElementName {
  kinetic('Kinetic'),
  arc('Arc'),
  solar('Solar'),
  voidElement('Void'),
  stasis('Stasis'),
  strand('Strand'),
  prismatic('Prismatic');

  const ElementName(this.label);
  final String label;

  static ElementName? tryParse(String? value) {
    if (value == null) return null;
    for (final v in values) {
      if (v.label == value) return v;
    }
    return null;
  }
}

enum WeaponSlotName {
  kinetic('Kinetic'),
  energy('Energy'),
  power('Power');

  const WeaponSlotName(this.label);
  final String label;

  static WeaponSlotName? tryParse(String? value) {
    if (value == null) return null;
    for (final v in values) {
      if (v.label == value) return v;
    }
    return null;
  }
}

enum AmmoTypeName {
  primary('Primary'),
  special('Special'),
  heavy('Heavy');

  const AmmoTypeName(this.label);
  final String label;

  static AmmoTypeName? tryParse(String? value) {
    if (value == null) return null;
    for (final v in values) {
      if (v.label == value) return v;
    }
    return null;
  }
}

enum ArmorSlotName {
  helmet('Helmet'),
  gauntlets('Gauntlets'),
  chest('Chest'),
  legs('Legs'),
  classItem('ClassItem');

  const ArmorSlotName(this.label);
  final String label;

  static ArmorSlotName? tryParse(String? value) {
    if (value == null) return null;
    for (final v in values) {
      if (v.label == value) return v;
    }
    return null;
  }
}

enum AbilityKind {
  superAbility('super'),
  grenade('grenade'),
  melee('melee'),
  classAbility('classAbility'),
  movement('movement');

  const AbilityKind(this.json);
  final String json;

  static AbilityKind? tryParse(String? value) {
    if (value == null) return null;
    for (final v in values) {
      if (v.json == value) return v;
    }
    return null;
  }
}

enum ModSlotCategory {
  helmet('helmet'),
  arms('arms'),
  chest('chest'),
  legs('legs'),
  classItem('classItem'),
  general('general'),
  tuning('tuning');

  const ModSlotCategory(this.json);
  final String json;

  static ModSlotCategory? tryParse(String? value) {
    if (value == null) return null;
    for (final v in values) {
      if (v.json == value) return v;
    }
    return null;
  }
}

class NamedDescription {
  const NamedDescription({required this.name, required this.description});

  final String name;
  final String description;

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
      };

  factory NamedDescription.fromJson(Map<String, dynamic> json) {
    return NamedDescription(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class WeaponPerkColumn {
  const WeaponPerkColumn({
    required this.column,
    required this.curated,
    required this.randomized,
  });

  final int column;
  final List<Hash> curated;
  final List<Hash> randomized;

  Map<String, dynamic> toJson() => {
        'column': column,
        'curated': curated,
        'randomized': randomized,
      };

  factory WeaponPerkColumn.fromJson(Map<String, dynamic> json) {
    return WeaponPerkColumn(
      column: json['column'] as int? ?? 0,
      curated: _intList(json['curated']),
      randomized: _intList(json['randomized']),
    );
  }
}

List<int> _intList(Object? value) {
  if (value is! List) return const [];
  return value.map((e) => (e as num).toInt()).toList();
}

abstract class EntityRecordBase {
  Hash get hash;
  String get name;
  String get searchName;
  String? get icon;
}

class ExoticArmorRecord implements EntityRecordBase {
  const ExoticArmorRecord({
    required this.hash,
    required this.name,
    required this.searchName,
    this.icon,
    required this.classType,
    required this.slot,
    required this.intrinsic,
    this.archetype,
    this.flavorText = '',
  });

  @override
  final Hash hash;
  @override
  final String name;
  @override
  final String searchName;
  @override
  final String? icon;
  final DestinyClassName classType;
  final ArmorSlotName slot;
  final NamedDescription intrinsic;
  final String? archetype;
  final String flavorText;

  Map<String, dynamic> toJson() => {
        'hash': hash,
        'name': name,
        'searchName': searchName,
        'icon': icon,
        'classType': classType.label,
        'slot': slot.label,
        'intrinsic': intrinsic.toJson(),
        'archetype': archetype,
        'flavorText': flavorText,
      };

  factory ExoticArmorRecord.fromJson(Map<String, dynamic> json) {
    return ExoticArmorRecord(
      hash: (json['hash'] as num).toInt(),
      name: json['name'] as String? ?? '',
      searchName: json['searchName'] as String? ?? '',
      icon: json['icon'] as String?,
      classType: DestinyClassName.tryParse(json['classType'] as String?) ??
          DestinyClassName.hunter,
      slot: ArmorSlotName.tryParse(json['slot'] as String?) ??
          ArmorSlotName.helmet,
      intrinsic: NamedDescription.fromJson(
        Map<String, dynamic>.from(json['intrinsic'] as Map? ?? const {}),
      ),
      archetype: json['archetype'] as String?,
      flavorText: json['flavorText'] as String? ?? '',
    );
  }
}

/// Exotic weapon entity row (store `exotic-weapons`, DART-062).
class ExoticWeaponRecord implements EntityRecordBase {
  const ExoticWeaponRecord({
    required this.hash,
    required this.name,
    required this.searchName,
    this.icon,
    required this.slot,
    required this.element,
    required this.ammo,
    required this.frame,
    required this.intrinsic,
    this.catalyst,
    this.flavorText = '',
    this.perkColumns = const [],
    this.itemTypeName = '',
  });

  @override
  final Hash hash;
  @override
  final String name;
  @override
  final String searchName;
  @override
  final String? icon;
  final WeaponSlotName slot;
  final ElementName element;
  final AmmoTypeName ammo;
  final String frame;
  final NamedDescription intrinsic;
  final NamedDescription? catalyst;
  final String flavorText;
  final List<WeaponPerkColumn> perkColumns;
  final String itemTypeName;

  Map<String, dynamic> toJson() => {
        'hash': hash,
        'name': name,
        'searchName': searchName,
        'icon': icon,
        'slot': slot.label,
        'element': element.label,
        'ammo': ammo.label,
        'frame': frame,
        'intrinsic': intrinsic.toJson(),
        'catalyst': catalyst?.toJson(),
        'flavorText': flavorText,
        'perkColumns': perkColumns.map((c) => c.toJson()).toList(),
        'itemTypeName': itemTypeName,
      };

  factory ExoticWeaponRecord.fromJson(Map<String, dynamic> json) {
    final cols = (json['perkColumns'] as List? ?? const [])
        .map(
          (e) => WeaponPerkColumn.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
    NamedDescription? catalyst;
    final rawCat = json['catalyst'];
    if (rawCat is Map) {
      catalyst = NamedDescription.fromJson(Map<String, dynamic>.from(rawCat));
    }
    return ExoticWeaponRecord(
      hash: (json['hash'] as num).toInt(),
      name: json['name'] as String? ?? '',
      searchName: json['searchName'] as String? ?? '',
      icon: json['icon'] as String?,
      slot: WeaponSlotName.tryParse(json['slot'] as String?) ??
          WeaponSlotName.kinetic,
      element: ElementName.tryParse(json['element'] as String?) ??
          ElementName.kinetic,
      ammo: AmmoTypeName.tryParse(json['ammo'] as String?) ??
          AmmoTypeName.primary,
      frame: json['frame'] as String? ?? '',
      intrinsic: NamedDescription.fromJson(
        Map<String, dynamic>.from(json['intrinsic'] as Map? ?? const {}),
      ),
      catalyst: catalyst,
      flavorText: json['flavorText'] as String? ?? '',
      perkColumns: cols,
      itemTypeName: json['itemTypeName'] as String? ?? '',
    );
  }
}

/// Legendary armor entity row (store `legendary-armor`, DART-062).
class LegendaryArmorRecord implements EntityRecordBase {
  const LegendaryArmorRecord({
    required this.hash,
    required this.name,
    required this.searchName,
    this.icon,
    required this.classType,
    required this.slot,
    this.archetype,
  });

  @override
  final Hash hash;
  @override
  final String name;
  @override
  final String searchName;
  @override
  final String? icon;
  final DestinyClassName classType;
  final ArmorSlotName slot;
  final String? archetype;

  Map<String, dynamic> toJson() => {
        'hash': hash,
        'name': name,
        'searchName': searchName,
        'icon': icon,
        'classType': classType.label,
        'slot': slot.label,
        'archetype': archetype,
      };

  factory LegendaryArmorRecord.fromJson(Map<String, dynamic> json) {
    return LegendaryArmorRecord(
      hash: (json['hash'] as num).toInt(),
      name: json['name'] as String? ?? '',
      searchName: json['searchName'] as String? ?? '',
      icon: json['icon'] as String?,
      classType: DestinyClassName.tryParse(json['classType'] as String?) ??
          DestinyClassName.hunter,
      slot: ArmorSlotName.tryParse(json['slot'] as String?) ??
          ArmorSlotName.helmet,
      archetype: json['archetype'] as String?,
    );
  }
}

class WeaponRecord implements EntityRecordBase {
  const WeaponRecord({
    required this.hash,
    required this.name,
    required this.searchName,
    this.icon,
    required this.slot,
    required this.element,
    required this.ammo,
    required this.frame,
    required this.itemTypeName,
    this.originTraitHashes = const [],
    this.perkColumns = const [],
  });

  @override
  final Hash hash;
  @override
  final String name;
  @override
  final String searchName;
  @override
  final String? icon;
  final WeaponSlotName slot;
  final ElementName element;
  final AmmoTypeName ammo;
  final String frame;
  final String itemTypeName;
  final List<Hash> originTraitHashes;
  final List<WeaponPerkColumn> perkColumns;

  Map<String, dynamic> toJson() => {
        'hash': hash,
        'name': name,
        'searchName': searchName,
        'icon': icon,
        'slot': slot.label,
        'element': element.label,
        'ammo': ammo.label,
        'frame': frame,
        'itemTypeName': itemTypeName,
        'originTraitHashes': originTraitHashes,
        'perkColumns': perkColumns.map((c) => c.toJson()).toList(),
      };

  factory WeaponRecord.fromJson(Map<String, dynamic> json) {
    final cols = (json['perkColumns'] as List? ?? const [])
        .map((e) => WeaponPerkColumn.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return WeaponRecord(
      hash: (json['hash'] as num).toInt(),
      name: json['name'] as String? ?? '',
      searchName: json['searchName'] as String? ?? '',
      icon: json['icon'] as String?,
      slot: WeaponSlotName.tryParse(json['slot'] as String?) ??
          WeaponSlotName.kinetic,
      element: ElementName.tryParse(json['element'] as String?) ??
          ElementName.kinetic,
      ammo: AmmoTypeName.tryParse(json['ammo'] as String?) ??
          AmmoTypeName.primary,
      frame: json['frame'] as String? ?? '',
      itemTypeName: json['itemTypeName'] as String? ?? '',
      originTraitHashes: _intList(json['originTraitHashes']),
      perkColumns: cols,
    );
  }
}

class AspectRecord implements EntityRecordBase {
  const AspectRecord({
    required this.hash,
    required this.name,
    required this.searchName,
    this.icon,
    required this.description,
    this.classType,
    required this.element,
    required this.fragmentCapacity,
  });

  @override
  final Hash hash;
  @override
  final String name;
  @override
  final String searchName;
  @override
  final String? icon;
  final String description;
  final DestinyClassName? classType;
  final ElementName element;
  final int fragmentCapacity;

  Map<String, dynamic> toJson() => {
        'hash': hash,
        'name': name,
        'searchName': searchName,
        'icon': icon,
        'description': description,
        'classType': classType?.label,
        'element': element.label,
        'fragmentCapacity': fragmentCapacity,
      };

  factory AspectRecord.fromJson(Map<String, dynamic> json) {
    return AspectRecord(
      hash: (json['hash'] as num).toInt(),
      name: json['name'] as String? ?? '',
      searchName: json['searchName'] as String? ?? '',
      icon: json['icon'] as String?,
      description: json['description'] as String? ?? '',
      classType: DestinyClassName.tryParse(json['classType'] as String?),
      element: ElementName.tryParse(json['element'] as String?) ??
          ElementName.kinetic,
      fragmentCapacity: (json['fragmentCapacity'] as num?)?.toInt() ?? 0,
    );
  }
}

class FragmentRecord implements EntityRecordBase {
  const FragmentRecord({
    required this.hash,
    required this.name,
    required this.searchName,
    this.icon,
    required this.description,
    required this.element,
    this.statModifiers = const {},
  });

  @override
  final Hash hash;
  @override
  final String name;
  @override
  final String searchName;
  @override
  final String? icon;
  final String description;
  final ElementName element;
  final Map<String, int> statModifiers;

  Map<String, dynamic> toJson() => {
        'hash': hash,
        'name': name,
        'searchName': searchName,
        'icon': icon,
        'description': description,
        'element': element.label,
        'statModifiers': statModifiers,
      };

  factory FragmentRecord.fromJson(Map<String, dynamic> json) {
    final mods = <String, int>{};
    final raw = json['statModifiers'];
    if (raw is Map) {
      for (final e in raw.entries) {
        mods[e.key.toString()] = (e.value as num).toInt();
      }
    }
    return FragmentRecord(
      hash: (json['hash'] as num).toInt(),
      name: json['name'] as String? ?? '',
      searchName: json['searchName'] as String? ?? '',
      icon: json['icon'] as String?,
      description: json['description'] as String? ?? '',
      element: ElementName.tryParse(json['element'] as String?) ??
          ElementName.kinetic,
      statModifiers: mods,
    );
  }
}

class AbilityRecord implements EntityRecordBase {
  const AbilityRecord({
    required this.hash,
    required this.name,
    required this.searchName,
    this.icon,
    required this.description,
    required this.kind,
    this.classType,
    required this.element,
    this.subclassAffinities = const [],
    this.verbs = const [],
  });

  @override
  final Hash hash;
  @override
  final String name;
  @override
  final String searchName;
  @override
  final String? icon;
  final String description;
  final AbilityKind kind;
  final DestinyClassName? classType;
  final ElementName element;
  final List<String> subclassAffinities;
  final List<String> verbs;

  Map<String, dynamic> toJson() => {
        'hash': hash,
        'name': name,
        'searchName': searchName,
        'icon': icon,
        'description': description,
        'kind': kind.json,
        'classType': classType?.label,
        'element': element.label,
        'subclassAffinities': subclassAffinities,
        'verbs': verbs,
      };

  factory AbilityRecord.fromJson(Map<String, dynamic> json) {
    return AbilityRecord(
      hash: (json['hash'] as num).toInt(),
      name: json['name'] as String? ?? '',
      searchName: json['searchName'] as String? ?? '',
      icon: json['icon'] as String?,
      description: json['description'] as String? ?? '',
      kind: AbilityKind.tryParse(json['kind'] as String?) ?? AbilityKind.superAbility,
      classType: DestinyClassName.tryParse(json['classType'] as String?),
      element: ElementName.tryParse(json['element'] as String?) ??
          ElementName.kinetic,
      subclassAffinities: (json['subclassAffinities'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      verbs:
          (json['verbs'] as List? ?? const []).map((e) => e.toString()).toList(),
    );
  }
}

class ModRecord implements EntityRecordBase {
  const ModRecord({
    required this.hash,
    required this.name,
    required this.searchName,
    this.icon,
    required this.description,
    required this.slotCategory,
    this.energyCost,
    this.statModifiers = const {},
  });

  @override
  final Hash hash;
  @override
  final String name;
  @override
  final String searchName;
  @override
  final String? icon;
  final String description;
  final ModSlotCategory slotCategory;
  final int? energyCost;
  final Map<String, int> statModifiers;

  Map<String, dynamic> toJson() => {
        'hash': hash,
        'name': name,
        'searchName': searchName,
        'icon': icon,
        'description': description,
        'slotCategory': slotCategory.json,
        'energyCost': energyCost,
        'statModifiers': statModifiers,
      };

  factory ModRecord.fromJson(Map<String, dynamic> json) {
    final mods = <String, int>{};
    final raw = json['statModifiers'];
    if (raw is Map) {
      for (final e in raw.entries) {
        mods[e.key.toString()] = (e.value as num).toInt();
      }
    }
    return ModRecord(
      hash: (json['hash'] as num).toInt(),
      name: json['name'] as String? ?? '',
      searchName: json['searchName'] as String? ?? '',
      icon: json['icon'] as String?,
      description: json['description'] as String? ?? '',
      slotCategory: ModSlotCategory.tryParse(json['slotCategory'] as String?) ??
          ModSlotCategory.general,
      energyCost: (json['energyCost'] as num?)?.toInt(),
      statModifiers: mods,
    );
  }
}
