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
  });

  final String slot;
  final String setId;
  final String pieceName;
  final int heldCopies;
  final bool isExoticSlot;
}

class MockBuild {
  const MockBuild({
    required this.id,
    required this.name,
    required this.subclass,
    required this.exoticArmor,
    required this.exoticWeapon,
    required this.slots,
    this.splitWhy,
    this.creator,
  });

  final String id;
  final String name;
  final String subclass;
  final String exoticArmor;
  final String exoticWeapon;
  final List<MockSlotAssignment> slots;
  final String? splitWhy;
  final String? creator;

  bool get usesSolipsism =>
      exoticArmor.toLowerCase().contains('solipsism') ||
      slots.any((s) => s.pieceName.toLowerCase().contains('solipsism'));

  bool get solipsismNotPrismatic =>
      usesSolipsism && subclass.toLowerCase() != 'prismatic';

  Set<String> get setIds => {for (final s in slots) s.setId};
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
