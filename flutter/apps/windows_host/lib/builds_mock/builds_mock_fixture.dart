import 'builds_mock_models.dart';

/// In-repo fake data only — no account paths, tokens, or live inventory.
BuildsMockFixture loadBuildsMockFixture() {
  const sets = <MockArmorSet>[
    MockArmorSet(id: 'set_techsec', name: 'Techsec'),
    MockArmorSet(id: 'set_walk', name: "Walker's Bond"),
    MockArmorSet(id: 'set_aion', name: 'Aion Renewal'),
    MockArmorSet(id: 'set_brazen', name: 'Brazen Gambit'),
  ];

  final builds = <MockBuild>[
    ..._techsecReadyBuilds(),
    _build(
      id: 'b11',
      name: 'Solipsism Strand mismatch',
      subclass: 'Strand',
      exoticArmor: 'Solipsism',
      exoticWeapon: 'Osteo Striga',
      a: 'set_aion',
      b: 'set_brazen',
      exoticSlot: 'class_item',
      why: '2pc Aion + 2pc Brazen around Solipsism class item.',
    ),
    _build(
      id: 'b12',
      name: 'Solipsism Prismatic weave',
      subclass: 'Prismatic',
      exoticArmor: 'Solipsism',
      exoticWeapon: 'Conditional Finality',
      a: 'set_aion',
      b: 'set_techsec',
      exoticSlot: 'class_item',
      why: '2pc Aion + 2pc Techsec; exotic locks class item.',
    ),
    _build(
      id: 'b13',
      name: 'Starfire Solar battery',
      subclass: 'Solar',
      exoticArmor: 'Starfire Protocol',
      exoticWeapon: 'Sunshot',
      a: 'set_brazen',
      b: 'set_walk',
      exoticSlot: 'chest',
      why: '2pc Brazen + 2pc Walker around Starfire chest.',
    ),
    _build(
      id: 'b14',
      name: 'Nezarec Void leech',
      subclass: 'Void',
      exoticArmor: "Nezarec's Sin",
      exoticWeapon: 'Graviton Lance',
      a: 'set_aion',
      b: 'set_walk',
      exoticSlot: 'helmet',
      why: '2pc Aion + 2pc Walker around Nezarec helmet.',
    ),
    _build(
      id: 'b15',
      name: 'Getaway Arc blink',
      subclass: 'Arc',
      exoticArmor: 'Getaway Artist',
      exoticWeapon: 'Riskrunner',
      a: 'set_techsec',
      b: 'set_brazen',
      exoticSlot: 'arms',
      why: '2pc Techsec + 2pc Brazen around Getaway gauntlets.',
    ),
  ];

  const held = <MockHeldCell>[
    MockHeldCell(setId: 'set_techsec', slot: 'helmet', held: 4),
    MockHeldCell(setId: 'set_techsec', slot: 'arms', held: 3),
    MockHeldCell(setId: 'set_techsec', slot: 'chest', held: 2),
    MockHeldCell(setId: 'set_techsec', slot: 'legs', held: 2),
    MockHeldCell(setId: 'set_techsec', slot: 'class_item', held: 1),
    MockHeldCell(setId: 'set_walk', slot: 'helmet', held: 1),
    MockHeldCell(setId: 'set_walk', slot: 'arms', held: 0),
    MockHeldCell(setId: 'set_walk', slot: 'chest', held: 2),
    MockHeldCell(setId: 'set_walk', slot: 'legs', held: 1),
    MockHeldCell(setId: 'set_walk', slot: 'class_item', held: 1),
    MockHeldCell(setId: 'set_aion', slot: 'helmet', held: 2),
    MockHeldCell(setId: 'set_aion', slot: 'arms', held: 2),
    MockHeldCell(setId: 'set_aion', slot: 'chest', held: 1),
    MockHeldCell(setId: 'set_aion', slot: 'legs', held: 3),
    MockHeldCell(setId: 'set_aion', slot: 'class_item', held: 0),
    MockHeldCell(setId: 'set_brazen', slot: 'helmet', held: 1),
    MockHeldCell(setId: 'set_brazen', slot: 'arms', held: 1),
    MockHeldCell(setId: 'set_brazen', slot: 'chest', held: 1),
    MockHeldCell(setId: 'set_brazen', slot: 'legs', held: 1),
    MockHeldCell(setId: 'set_brazen', slot: 'class_item', held: 1),
  ];

  const swaps = <MockSwapProposal>[
    MockSwapProposal(
      id: 'swap1',
      buildId: 'b01',
      buildName: 'Techsec Prismatic core',
      summary: 'Move Techsec legs → Aion legs (frees over-cap stack).',
      changesSplit: false,
    ),
    MockSwapProposal(
      id: 'swap2',
      buildId: 'b13',
      buildName: 'Starfire Solar battery',
      summary: 'Retarget 2pc split: Brazen helmet/legs → arms/legs.',
      changesSplit: true,
    ),
    MockSwapProposal(
      id: 'swap3',
      buildId: 'b05',
      buildName: 'Techsec Void leach',
      summary: 'Swap Walk arms (0 held) → Techsec arms.',
      changesSplit: false,
    ),
  ];

  return BuildsMockFixture(
    sets: sets,
    builds: builds,
    held: held,
    swaps: swaps,
  );
}

List<MockBuild> _techsecReadyBuilds() {
  // Ten builds; Techsec pair slots rotate so every slot is used ≥3 times.
  // exoticSlot must match the exotic armor piece.
  final specs = <(String, String, String, String, String, String, List<String>)>[
    (
      'b01',
      'Techsec Prismatic core',
      'Prismatic',
      'Osmiomancy Gloves',
      'Osteo Striga',
      'arms',
      ['helmet', 'chest'],
    ),
    (
      'b02',
      'Techsec Solar grenade',
      'Solar',
      'Starfire Protocol',
      'Sunshot',
      'chest',
      ['legs', 'class_item'],
    ),
    (
      'b03',
      'Techsec Arc blink',
      'Arc',
      'Getaway Artist',
      'Riskrunner',
      'arms',
      ['helmet', 'legs'],
    ),
    (
      'b04',
      'Techsec Strand tangle',
      'Strand',
      'Swarmers',
      'Dead Messenger',
      'legs',
      ['arms', 'chest'],
    ),
    (
      'b05',
      'Techsec Void leach',
      'Void',
      "Nezarec's Sin",
      'Graviton Lance',
      'helmet',
      ['legs', 'class_item'],
    ),
    (
      'b06',
      'Techsec Prismatic sink',
      'Prismatic',
      'Secant Filaments',
      'Conditional Finality',
      'legs',
      ['helmet', 'chest'],
    ),
    (
      'b07',
      'Techsec Solar boots',
      'Solar',
      'Boots of the Assembler',
      'Polaris Lance',
      'legs',
      ['arms', 'class_item'],
    ),
    (
      'b08',
      'Techsec Arc crown',
      'Arc',
      'Fallen Sunstar',
      'Trinity Ghoul',
      'helmet',
      ['arms', 'class_item'],
    ),
    (
      'b09',
      'Techsec Strand grip',
      'Strand',
      'Nothing Manacles',
      'Edge of Intent',
      'arms',
      ['helmet', 'legs'],
    ),
    (
      'b10',
      'Techsec Void hood',
      'Void',
      "Verity's Brow",
      'Vexcalibur',
      'helmet',
      ['chest', 'class_item'],
    ),
  ];
  return [
    for (final s in specs)
      _buildWithTechsecPair(
        id: s.$1,
        name: s.$2,
        subclass: s.$3,
        exoticArmor: s.$4,
        exoticWeapon: s.$5,
        exoticSlot: s.$6,
        techsecSlots: s.$7,
      ),
  ];
}

MockBuild _buildWithTechsecPair({
  required String id,
  required String name,
  required String subclass,
  required String exoticArmor,
  required String exoticWeapon,
  required String exoticSlot,
  required List<String> techsecSlots,
}) {
  final otherSlots = [
    for (final slot in kMockArmorSlots)
      if (slot != exoticSlot && !techsecSlots.contains(slot)) slot,
  ];
  final otherSet = id.hashCode.isEven ? 'set_aion' : 'set_brazen';
  final slots = <MockSlotAssignment>[
    for (final slot in techsecSlots)
      MockSlotAssignment(
        slot: slot,
        setId: 'set_techsec',
        pieceName: 'Techsec ${kMockArmorSlotLabels[slot]}',
      ),
    for (final slot in otherSlots)
      MockSlotAssignment(
        slot: slot,
        setId: otherSet,
        pieceName: '${_setShort(otherSet)} ${kMockArmorSlotLabels[slot]}',
      ),
    MockSlotAssignment(
      slot: exoticSlot,
      setId: 'exotic',
      pieceName: exoticArmor,
      isExoticSlot: true,
    ),
  ]..sort(
      (x, y) =>
          kMockArmorSlots.indexOf(x.slot) - kMockArmorSlots.indexOf(y.slot),
    );

  return MockBuild(
    id: id,
    name: name,
    subclass: subclass,
    exoticArmor: exoticArmor,
    exoticWeapon: exoticWeapon,
    slots: slots,
    splitWhy:
        '2pc Techsec (${techsecSlots.map((s) => kMockArmorSlotLabels[s]).join('+')}) '
        '+ 2pc ${_setShort(otherSet)} around ${kMockArmorSlotLabels[exoticSlot]} exotic.',
    creator: 'mock',
  );
}

MockBuild _build({
  required String id,
  required String name,
  required String subclass,
  required String exoticArmor,
  required String exoticWeapon,
  required String a,
  required String b,
  required String exoticSlot,
  required String why,
}) {
  final nonExotic = [
    for (final slot in kMockArmorSlots)
      if (slot != exoticSlot) slot,
  ];
  // First two non-exotic → set A, last two → set B (2pc+2pc).
  final slots = <MockSlotAssignment>[
    for (var i = 0; i < nonExotic.length; i++)
      MockSlotAssignment(
        slot: nonExotic[i],
        setId: i < 2 ? a : b,
        pieceName: '${_setShort(i < 2 ? a : b)} ${kMockArmorSlotLabels[nonExotic[i]]}',
      ),
    MockSlotAssignment(
      slot: exoticSlot,
      setId: 'exotic',
      pieceName: exoticArmor,
      isExoticSlot: true,
    ),
  ]..sort((x, y) => kMockArmorSlots.indexOf(x.slot) - kMockArmorSlots.indexOf(y.slot));

  return MockBuild(
    id: id,
    name: name,
    subclass: subclass,
    exoticArmor: exoticArmor,
    exoticWeapon: exoticWeapon,
    slots: slots,
    splitWhy: why,
    creator: 'mock',
  );
}

String _setShort(String id) {
  switch (id) {
    case 'set_techsec':
      return 'Techsec';
    case 'set_walk':
      return 'Walker';
    case 'set_aion':
      return 'Aion';
    case 'set_brazen':
      return 'Brazen';
    default:
      return id;
  }
}
