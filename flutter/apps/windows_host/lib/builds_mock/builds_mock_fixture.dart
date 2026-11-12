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
      loop:
          'Solipsism class item without Prismatic — flagged; 2pc Aion / 2pc Brazen.',
      artifact: _defaultArtifact,
      stats: _statsForSeed(11),
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
      loop:
          'Solipsism class item + Prismatic weave · 2pc Aion / 2pc Techsec around exotic.',
      artifact: _defaultArtifact,
      stats: const [
        MockStatTotal(id: MockStatId.health, value: 70),
        MockStatTotal(id: MockStatId.melee, value: 55),
        MockStatTotal(id: MockStatId.grenade, value: 80),
        MockStatTotal(id: MockStatId.superAbility, value: 90),
        MockStatTotal(id: MockStatId.classAbility, value: 100),
        MockStatTotal(id: MockStatId.weapons, value: 40),
      ],
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
      loop:
          'Starfire grenade battery · 2pc Brazen / 2pc Walker around chest exotic.',
      artifact: _defaultArtifact,
      stats: const [
        MockStatTotal(id: MockStatId.health, value: 60),
        MockStatTotal(id: MockStatId.melee, value: 30),
        MockStatTotal(id: MockStatId.grenade, value: 100),
        MockStatTotal(id: MockStatId.superAbility, value: 70),
        MockStatTotal(id: MockStatId.classAbility, value: 85),
        MockStatTotal(id: MockStatId.weapons, value: 50),
      ],
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
      loop: 'Void ability leech via Nezarec · 2pc Aion / 2pc Walker.',
      artifact: _defaultArtifact,
      stats: _statsForSeed(14),
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
      loop: 'Getaway Arc soul · 2pc Techsec / 2pc Brazen around gauntlets.',
      artifact: _defaultArtifact,
      stats: _statsForSeed(15),
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

const MockArtifact _defaultArtifact = MockArtifact(
  name: 'Heretical Path',
  season: 'Episode: Heresy',
  perks: [
    'Grenade energy on kills',
    'Melee refund on Transcend',
    'Weapon reload on ability',
  ],
);

const Map<String, String> _kSetBonusText = {
  'set_techsec': '+10 Mobility / Weapons handling on ability hit',
  'set_walk': 'Class ability energy on kills',
  'set_aion': 'Ability energy on orb pickup',
  'set_brazen': 'Solar ability damage after grenade',
};

List<MockBuild> _techsecReadyBuilds() {
  // Ten builds; Techsec pair slots rotate so every slot is used ≥3 times.
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
  final seed = int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
  final slots = <MockSlotAssignment>[
    for (final slot in techsecSlots)
      MockSlotAssignment(
        slot: slot,
        setId: 'set_techsec',
        pieceName: 'Techsec ${kMockArmorSlotLabels[slot]}',
        statTotal: _pieceTotal(seed, slot),
      ),
    for (final slot in otherSlots)
      MockSlotAssignment(
        slot: slot,
        setId: otherSet,
        pieceName: '${_setShort(otherSet)} ${kMockArmorSlotLabels[slot]}',
        statTotal: _pieceTotal(seed, slot),
      ),
    MockSlotAssignment(
      slot: exoticSlot,
      setId: 'exotic',
      pieceName: exoticArmor,
      isExoticSlot: true,
      statTotal: _pieceTotal(seed, exoticSlot) + 4,
    ),
  ]..sort(
      (x, y) =>
          kMockArmorSlots.indexOf(x.slot) - kMockArmorSlots.indexOf(y.slot),
    );

  final why =
      '2pc Techsec (${techsecSlots.map((s) => kMockArmorSlotLabels[s]).join('+')}) '
      '+ 2pc ${_setShort(otherSet)} around ${kMockArmorSlotLabels[exoticSlot]} exotic.';

  return MockBuild(
    id: id,
    name: name,
    subclass: subclass,
    exoticArmor: exoticArmor,
    exoticWeapon: exoticWeapon,
    slots: slots,
    splitWhy: why,
    loop: id == 'b01'
        ? 'Osmiomancy grenade regen → melee/grenade spill into Transcendence → clear + ability uptime.'
        : why,
    artifact: _defaultArtifact,
    setBonuses: [
      _bonus('set_techsec', pieces: 2),
      _bonus(otherSet, pieces: 2),
    ],
    stats: id == 'b01'
        ? const [
            MockStatTotal(id: MockStatId.health, value: 78),
            MockStatTotal(id: MockStatId.melee, value: 42),
            MockStatTotal(id: MockStatId.grenade, value: 100),
            MockStatTotal(id: MockStatId.superAbility, value: 56),
            MockStatTotal(id: MockStatId.classAbility, value: 88),
            MockStatTotal(id: MockStatId.weapons, value: 34),
          ]
        : _statsForSeed(seed),
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
  required String loop,
  required MockArtifact artifact,
  required List<MockStatTotal> stats,
}) {
  final nonExotic = [
    for (final slot in kMockArmorSlots)
      if (slot != exoticSlot) slot,
  ];
  final seed = int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
  final slots = <MockSlotAssignment>[
    for (var i = 0; i < nonExotic.length; i++)
      MockSlotAssignment(
        slot: nonExotic[i],
        setId: i < 2 ? a : b,
        pieceName:
            '${_setShort(i < 2 ? a : b)} ${kMockArmorSlotLabels[nonExotic[i]]}',
        statTotal: _pieceTotal(seed, nonExotic[i]),
      ),
    MockSlotAssignment(
      slot: exoticSlot,
      setId: 'exotic',
      pieceName: exoticArmor,
      isExoticSlot: true,
      statTotal: _pieceTotal(seed, exoticSlot) + 4,
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
    splitWhy: why,
    loop: loop,
    artifact: artifact,
    setBonuses: [
      _bonus(a, pieces: 2),
      _bonus(b, pieces: 2),
    ],
    stats: stats,
    creator: 'mock',
  );
}

MockSetBonus _bonus(String setId, {required int pieces}) {
  return MockSetBonus(
    setId: setId,
    setName: _setFull(setId),
    pieces: pieces,
    tier: '${pieces}pc',
    text: _kSetBonusText[setId] ?? 'Mock set bonus',
  );
}

List<MockStatTotal> _statsForSeed(int seed) {
  final base = 40 + (seed * 7) % 40;
  return [
    MockStatTotal(id: MockStatId.health, value: 50 + (base % 40)),
    MockStatTotal(id: MockStatId.melee, value: 30 + ((base + 11) % 50)),
    MockStatTotal(id: MockStatId.grenade, value: 60 + ((base + 3) % 41)),
    MockStatTotal(id: MockStatId.superAbility, value: 40 + ((base + 17) % 50)),
    MockStatTotal(id: MockStatId.classAbility, value: 55 + ((base + 5) % 45)),
    MockStatTotal(id: MockStatId.weapons, value: 25 + ((base + 23) % 50)),
  ];
}

int _pieceTotal(int seed, String slot) {
  final idx = kMockArmorSlots.indexOf(slot);
  return 62 + ((seed + idx * 3) % 12);
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

String _setFull(String id) {
  switch (id) {
    case 'set_techsec':
      return 'Techsec';
    case 'set_walk':
      return "Walker's Bond";
    case 'set_aion':
      return 'Aion Renewal';
    case 'set_brazen':
      return 'Brazen Gambit';
    default:
      return id;
  }
}
