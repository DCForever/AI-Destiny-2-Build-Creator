/// Fake-data models for the Builds mock-up screen (no persistence / network).
library;

const List<String> kMockArmorSlots = [
  'helmet',
  'arms',
  'chest',
  'legs',
  'class_item',
];

const Map<String, String> kMockArmorSlotLabels = {
  'helmet': 'Helmet',
  'arms': 'Gauntlets',
  'chest': 'Chest',
  'legs': 'Legs',
  'class_item': 'Class Item',
};

/// Default physical inventory cap (copies of each set piece per slot).
const int kMockDefaultInventoryCap = 2;
const int kMockMinInventoryCap = 1;
const int kMockMaxInventoryCap = 4;

/// Builds required before a set is Ready for re-optimize.
const int kMockReadyBuildCount = 10;

/// Per-slot uses required across those builds.
const int kMockReadySlotUses = 3;

/// EoF armor stats shown on the hybrid loadout card.
enum MockStatId { health, melee, grenade, superAbility, classAbility, weapons }

const List<MockStatId> kMockStatOrder = [
  MockStatId.health,
  MockStatId.melee,
  MockStatId.grenade,
  MockStatId.superAbility,
  MockStatId.classAbility,
  MockStatId.weapons,
];

String mockStatLabel(MockStatId id) {
  switch (id) {
    case MockStatId.health:
      return 'Health';
    case MockStatId.melee:
      return 'Melee';
    case MockStatId.grenade:
      return 'Grenade';
    case MockStatId.superAbility:
      return 'Super';
    case MockStatId.classAbility:
      return 'Class';
    case MockStatId.weapons:
      return 'Weapons';
  }
}

class MockArmorSet {
  const MockArmorSet({required this.id, required this.name});

  final String id;
  final String name;
}

class MockSlotAssignment {
  const MockSlotAssignment({
    required this.slot,
    required this.setId,
    required this.pieceName,
    this.heldCopies = 1,
    this.isExoticSlot = false,
    this.statTotal = 64,
  });

  final String slot;
  final String setId;
  final String pieceName;
  final int heldCopies;
  final bool isExoticSlot;

  /// Sum of the six armor stats on this piece (fake fixture value).
  final int statTotal;
}

class MockSetBonus {
  const MockSetBonus({
    required this.setId,
    required this.setName,
    required this.pieces,
    required this.tier,
    required this.text,
  });

  final String setId;
  final String setName;
  final int pieces;
  final String tier;
  final String text;
}

class MockArtifact {
  const MockArtifact({
    required this.name,
    required this.season,
    this.perks = const [],
  });

  final String name;
  final String season;
  final List<String> perks;
}

class MockStatTotal {
  const MockStatTotal({
    required this.id,
    required this.value,
  });

  final MockStatId id;
  final int value;

  String get label => mockStatLabel(id);
}

class MockBuild {
  const MockBuild({
    required this.id,
    required this.name,
    required this.subclass,
    required this.exoticArmor,
    required this.exoticWeapon,
    required this.slots,
    required this.loop,
    required this.artifact,
    required this.setBonuses,
    required this.stats,
    this.splitWhy,
    this.creator,
    this.dimLink,
    this.exoticWeaponType,
    this.exoticWeaponDamageType,
    this.exoticWeaponSlot,
  });

  final String id;
  final String name;
  final String subclass;
  final String exoticArmor;
  final String exoticWeapon;
  final List<MockSlotAssignment> slots;

  /// One-line build loop / description (hybrid card top).
  final String loop;

  final MockArtifact artifact;
  final List<MockSetBonus> setBonuses;
  final List<MockStatTotal> stats;

  final String? splitWhy;
  final String? creator;

  /// Optional dim.gg share URL (`dim.gg/<shareId>` or `dim.gg/<shareId>/…`).
  final String? dimLink;

  /// DIM `Type` for [exoticWeapon] when known from build data (similar suggest).
  final String? exoticWeaponType;

  /// DIM `Element` for [exoticWeapon] when known from build data.
  final String? exoticWeaponDamageType;

  /// Weapon slot wire name (`primary` / `special` / `heavy`) when known.
  final String? exoticWeaponSlot;

  bool get usesSolipsism =>
      exoticArmor.toLowerCase().contains('solipsism') ||
      slots.any((s) => s.pieceName.toLowerCase().contains('solipsism'));

  bool get solipsismNotPrismatic =>
      usesSolipsism && subclass.toLowerCase() != 'prismatic';

  Set<String> get setIds => {
        for (final s in slots)
          if (!s.isExoticSlot) s.setId,
      };
}

class MockHeldCell {
  const MockHeldCell({
    required this.setId,
    required this.slot,
    required this.held,
  });

  final String setId;
  final String slot;
  final int held;
}

class MockSwapProposal {
  const MockSwapProposal({
    required this.id,
    required this.buildId,
    required this.buildName,
    required this.summary,
    required this.changesSplit,
  });

  final String id;
  final String buildId;
  final String buildName;
  final String summary;
  final bool changesSplit;
}

enum MockSwapDecision { pending, accepted, rejected }

enum MockReadiness { ready, notReady }

/// Browse layout for the Builds main pane (Detail is a separate screen).
enum BuildsMockCardLayout { grid, list }

/// One display-only stat priority row for compact browse cards / list rows.
class BuildsMockStatPriority {
  const BuildsMockStatPriority({
    required this.label,
    this.inferred = false,
  });

  final String label;
  final bool inferred;
}

class MockSetReadiness {
  const MockSetReadiness({
    required this.setId,
    required this.setName,
    required this.buildCount,
    required this.slotUses,
    required this.status,
  });

  final String setId;
  final String setName;
  final int buildCount;
  final Map<String, int> slotUses;
  final MockReadiness status;
}

class BuildsMockFixture {
  const BuildsMockFixture({
    required this.sets,
    required this.builds,
    required this.held,
    required this.swaps,
  });

  final List<MockArmorSet> sets;
  final List<MockBuild> builds;
  final List<MockHeldCell> held;
  final List<MockSwapProposal> swaps;

  MockArmorSet? setById(String id) {
    for (final s in sets) {
      if (s.id == id) return s;
    }
    return null;
  }

  int heldFor({required String setId, required String slot}) {
    for (final h in held) {
      if (h.setId == setId && h.slot == slot) return h.held;
    }
    return 0;
  }
}
