import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_derived_name.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const loadout = CachedDimLoadout(
    shareId: 'syn-name',
    name: 'Equipped 10/19/2026, 7:00:38 AM',
    classType: 2,
    items: [],
    subclassPlugs: [
      CachedDimNamedHash(hash: 1, name: 'Healing Rift'),
      CachedDimNamedHash(hash: 2, name: 'Burst Glide'),
      CachedDimNamedHash(hash: 3, name: 'Needlestorm'),
      CachedDimNamedHash(hash: 4, name: 'Arcane Needle'),
      CachedDimNamedHash(hash: 5, name: 'Threadling Grenade'),
    ],
    mods: [],
    artifactPerks: [],
    subclass: CachedDimSubclass(
      hash: 9,
      name: 'Strand',
      superName: 'Needlestorm',
    ),
  );

  const build = MockBuild(
    id: 'b1',
    name: 'Equipped 10/19/2026, 7:00:38 AM',
    subclass: 'Strand',
    exoticArmor: 'Swarmers',
    exoticWeapon: 'Barrow-Dyad',
    slots: [],
    loop: 'loop',
    artifact: MockArtifact(name: 'Example', season: 'S'),
    setBonuses: [],
    stats: [],
  );

  test('segment order Class · Element · Super · Exotic Armor · Exotic Weapon', () {
    final name = deriveBuildsMockName(build: build, loadout: loadout);
    expect(
      name.text,
      'Warlock · Strand · Needlestorm · Swarmers · Barrow-Dyad',
    );
    expect(name.sourceName, 'Equipped 10/19/2026, 7:00:38 AM');
  });

  test('omits missing segments and never writes None', () {
    const sparse = MockBuild(
      id: 'b2',
      name: 'Sparse',
      subclass: 'None',
      exoticArmor: '',
      exoticWeapon: '—',
      slots: [],
      loop: '',
      artifact: MockArtifact(name: '—', season: '—'),
      setBonuses: [],
      stats: [],
    );
    final name = deriveBuildsMockName(
      build: sparse,
      loadout: const CachedDimLoadout(
        shareId: 's',
        name: 'Sparse',
        classType: 0,
        items: [],
        subclassPlugs: [],
        mods: [],
        artifactPerks: [],
      ),
    );
    expect(name.text, 'Titan');
    expect(name.text.toLowerCase().contains('none'), isFalse);
    expect(name.exoticArmor, isNull);
    expect(name.exoticWeapon, isNull);
    expect(name.elementLabel, isNull);
    expect(name.superLabel, isNull);
  });

  test('duplicate derived names get · 2 suffix within class', () {
    final first = deriveBuildsMockName(
      build: build,
      loadout: loadout,
      duplicateIndexWithinClass: 1,
    );
    final second = deriveBuildsMockName(
      build: build,
      loadout: loadout,
      duplicateIndexWithinClass: 2,
    );
    expect(first.text.endsWith(' · 2'), isFalse);
    expect(second.text.endsWith(' · 2'), isTrue);
  });

  test('super omitted when subclass data has none', () {
    final name = deriveBuildsMockName(
      build: build,
      loadout: const CachedDimLoadout(
        shareId: 's2',
        name: 'No super',
        classType: 2,
        items: [],
        subclassPlugs: [],
        mods: [],
        artifactPerks: [],
        subclass: CachedDimSubclass(hash: 1, name: 'Strand'),
      ),
    );
    expect(name.superLabel, isNull);
    expect(name.text, 'Warlock · Strand · Swarmers · Barrow-Dyad');
  });

  test('combineBuildsMockSetBonuses merges 2pc+4pc into one box', () {
    final combined = combineBuildsMockSetBonuses(const [
      MockSetBonus(
        setId: 'a',
        setName: "Apostate's Blade",
        pieces: 2,
        tier: '2pc',
        text: '2pc: Example 2-piece set bonus text.',
      ),
      MockSetBonus(
        setId: 'a',
        setName: "Apostate's Blade",
        pieces: 4,
        tier: '4pc',
        text: '4pc: Example 4-piece set bonus text.',
      ),
      MockSetBonus(
        setId: 'b',
        setName: 'Other',
        pieces: 2,
        tier: '2pc',
        text: 'Other 2pc text',
      ),
    ]);
    expect(combined, hasLength(2));
    final four = combined.singleWhere((b) => b.setId == 'a');
    expect(four.tier, '4pc');
    expect(four.text, contains('2pc:'));
    expect(four.text, contains('4pc:'));
    expect(combined.singleWhere((b) => b.setId == 'b').tier, '2pc');
  });
}
