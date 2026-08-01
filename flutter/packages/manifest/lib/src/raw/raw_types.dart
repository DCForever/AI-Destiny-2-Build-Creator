// Minimal structural views over raw Bungie JSON maps.

class RawDisplayProperties {
  RawDisplayProperties(this.name, this.description, this.icon);

  final String name;
  final String description;
  final String? icon;

  static RawDisplayProperties? from(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    return RawDisplayProperties(
      m['name'] as String? ?? '',
      m['description'] as String? ?? '',
      m['icon'] as String?,
    );
  }
}

class RawPlugEntry {
  RawPlugEntry(this.plugItemHash);
  final int plugItemHash;
}

class RawSocketEntry {
  RawSocketEntry({
    this.socketTypeHash,
    this.singleInitialItemHash,
    this.reusablePlugSetHash,
    this.randomizedPlugSetHash,
  });

  final int? socketTypeHash;
  final int? singleInitialItemHash;
  final int? reusablePlugSetHash;
  final int? randomizedPlugSetHash;

  static RawSocketEntry? from(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    return RawSocketEntry(
      socketTypeHash: (m['socketTypeHash'] as num?)?.toInt(),
      singleInitialItemHash: (m['singleInitialItemHash'] as num?)?.toInt(),
      reusablePlugSetHash: (m['reusablePlugSetHash'] as num?)?.toInt(),
      randomizedPlugSetHash: (m['randomizedPlugSetHash'] as num?)?.toInt(),
    );
  }
}

class RawSocketCategory {
  RawSocketCategory(this.socketCategoryHash, this.socketIndexes);

  final int socketCategoryHash;
  final List<int> socketIndexes;

  static RawSocketCategory? from(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final indexes = (m['socketIndexes'] as List? ?? const [])
        .map((e) => (e as num).toInt())
        .toList();
    return RawSocketCategory(
      (m['socketCategoryHash'] as num?)?.toInt() ?? 0,
      indexes,
    );
  }
}

class RawInvestmentStat {
  RawInvestmentStat({
    required this.statTypeHash,
    required this.value,
    this.isConditionallyActive = false,
  });

  final int statTypeHash;
  final int value;
  final bool isConditionallyActive;

  static RawInvestmentStat? from(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    return RawInvestmentStat(
      statTypeHash: (m['statTypeHash'] as num?)?.toInt() ?? 0,
      value: (m['value'] as num?)?.toInt() ?? 0,
      isConditionallyActive: m['isConditionallyActive'] as bool? ?? false,
    );
  }
}

class RawInventoryItem {
  RawInventoryItem(this.raw);

  final Map<String, dynamic> raw;

  int get hash => (raw['hash'] as num?)?.toInt() ?? 0;

  RawDisplayProperties get displayProperties =>
      RawDisplayProperties.from(raw['displayProperties']) ??
      RawDisplayProperties('', '', null);

  int? get itemType => (raw['itemType'] as num?)?.toInt();
  String? get itemTypeDisplayName => raw['itemTypeDisplayName'] as String?;
  String? get flavorText => raw['flavorText'] as String?;
  int? get classType => (raw['classType'] as num?)?.toInt();
  int? get defaultDamageTypeHash =>
      (raw['defaultDamageTypeHash'] as num?)?.toInt();
  bool get redacted => raw['redacted'] as bool? ?? false;

  Map<String, dynamic>? get inventory {
    final v = raw['inventory'];
    return v is Map ? Map<String, dynamic>.from(v) : null;
  }

  Map<String, dynamic>? get equippingBlock {
    final v = raw['equippingBlock'];
    return v is Map ? Map<String, dynamic>.from(v) : null;
  }

  Map<String, dynamic>? get plug {
    final v = raw['plug'];
    return v is Map ? Map<String, dynamic>.from(v) : null;
  }

  Map<String, dynamic>? get sockets {
    final v = raw['sockets'];
    return v is Map ? Map<String, dynamic>.from(v) : null;
  }

  List<RawInvestmentStat> get investmentStats {
    final list = raw['investmentStats'];
    if (list is! List) return const [];
    return list
        .map(RawInvestmentStat.from)
        .whereType<RawInvestmentStat>()
        .toList();
  }

  List<Map<String, dynamic>> get perks {
    final list = raw['perks'];
    if (list is! List) return const [];
    final out = <Map<String, dynamic>>[];
    for (final e in list) {
      if (e is Map) out.add(Map<String, dynamic>.from(e));
    }
    return out;
  }

  List<Map<String, dynamic>> get tooltipNotifications {
    final list = raw['tooltipNotifications'];
    if (list is! List) return const [];
    final out = <Map<String, dynamic>>[];
    for (final e in list) {
      if (e is Map) out.add(Map<String, dynamic>.from(e));
    }
    return out;
  }

  List<RawSocketEntry> get socketEntries {
    final sockets = this.sockets;
    final list = sockets?['socketEntries'];
    if (list is! List) return const [];
    return list.map(RawSocketEntry.from).whereType<RawSocketEntry>().toList();
  }

  List<RawSocketCategory> get socketCategories {
    final sockets = this.sockets;
    final list = sockets?['socketCategories'];
    if (list is! List) return const [];
    return list
        .map(RawSocketCategory.from)
        .whereType<RawSocketCategory>()
        .toList();
  }

  static RawInventoryItem? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    if (m['hash'] is! num) return null;
    if (m['displayProperties'] is! Map) return null;
    return RawInventoryItem(m);
  }
}

class RawPlugSet {
  RawPlugSet(this.reusablePlugItems);
  final List<RawPlugEntry> reusablePlugItems;

  static RawPlugSet? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final list = m['reusablePlugItems'];
    final items = <RawPlugEntry>[];
    if (list is List) {
      for (final e in list) {
        if (e is Map && e['plugItemHash'] is num) {
          items.add(RawPlugEntry((e['plugItemHash'] as num).toInt()));
        }
      }
    }
    return RawPlugSet(items);
  }
}

class RawSandboxPerk {
  RawSandboxPerk(this.hash, this.displayProperties);
  final int hash;
  final RawDisplayProperties displayProperties;

  static RawSandboxPerk? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final dp = RawDisplayProperties.from(m['displayProperties']);
    if (dp == null) return null;
    return RawSandboxPerk((m['hash'] as num?)?.toInt() ?? 0, dp);
  }
}

class RawDamageType {
  RawDamageType(this.hash, this.displayProperties);
  final int hash;
  final RawDisplayProperties displayProperties;

  static RawDamageType? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final dp = RawDisplayProperties.from(m['displayProperties']);
    if (dp == null) return null;
    return RawDamageType((m['hash'] as num?)?.toInt() ?? 0, dp);
  }
}

class RawEquipmentSlot {
  RawEquipmentSlot(this.hash, this.displayProperties);
  final int hash;
  final RawDisplayProperties displayProperties;

  static RawEquipmentSlot? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final dp = RawDisplayProperties.from(m['displayProperties']);
    if (dp == null) return null;
    return RawEquipmentSlot((m['hash'] as num?)?.toInt() ?? 0, dp);
  }
}

class RawStatDef {
  RawStatDef(this.hash, this.displayProperties);
  final int hash;
  final RawDisplayProperties displayProperties;

  static RawStatDef? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final dp = RawDisplayProperties.from(m['displayProperties']);
    if (dp == null) return null;
    return RawStatDef((m['hash'] as num?)?.toInt() ?? 0, dp);
  }
}
