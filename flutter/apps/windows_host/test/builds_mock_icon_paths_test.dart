import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_icon_paths.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const catalog = <CatalogItem>[
    CatalogItem(
      hash: 300,
      name: 'Chaos Reach',
      icon: '/common/destiny2_content/icons/super.png',
      itemTypeName: 'super',
      isExotic: false,
      sourceStore: 'abilities',
    ),
    CatalogItem(
      hash: 100,
      name: 'Vesper of Radius',
      icon: '/common/destiny2_content/icons/armor.png',
      isExotic: true,
      sourceStore: 'exotic-armor',
    ),
    CatalogItem(
      hash: 200,
      name: 'Barrow-Dyad',
      icon: '/common/destiny2_content/icons/weapon.png',
      isExotic: true,
      sourceStore: 'exotic-weapons',
    ),
  ];

  const build = MockBuild(
    id: 'b1',
    name: 'Source',
    subclass: 'Stormcaller',
    exoticArmor: 'Vesper of Radius',
    exoticWeapon: 'Barrow-Dyad',
    slots: [],
    loop: '',
    artifact: MockArtifact(name: '—', season: '—'),
    setBonuses: [],
    stats: [],
  );

  test('prefers cached superIconPath then catalog plug hash then name', () {
    const withCached = CachedDimLoadout(
      shareId: 'a',
      name: 'A',
      classType: 2,
      items: [],
      subclassPlugs: [
        CachedDimNamedHash(hash: 1, name: 'Rift'),
        CachedDimNamedHash(hash: 2, name: 'Glide'),
        CachedDimNamedHash(hash: 300, name: 'Chaos Reach'),
      ],
      mods: [],
      artifactPerks: [],
      subclass: CachedDimSubclass(
        hash: 9,
        name: 'Stormcaller',
        superName: 'Chaos Reach',
        superIconPath: '/common/destiny2_content/icons/cached_super.png',
      ),
    );
    final cached = resolveBuildsMockSegmentIcons(
      build: build,
      loadout: withCached,
      catalogItems: catalog,
    );
    expect(cached.superIconPath, '/common/destiny2_content/icons/cached_super.png');

    const withoutCached = CachedDimLoadout(
      shareId: 'b',
      name: 'B',
      classType: 2,
      items: [],
      subclassPlugs: [
        CachedDimNamedHash(hash: 1, name: 'Rift'),
        CachedDimNamedHash(hash: 2, name: 'Glide'),
        CachedDimNamedHash(hash: 300, name: 'Chaos Reach'),
      ],
      mods: [],
      artifactPerks: [],
      subclass: CachedDimSubclass(
        hash: 9,
        name: 'Stormcaller',
        superName: 'Chaos Reach',
      ),
    );
    final fromHash = resolveBuildsMockSegmentIcons(
      build: build,
      loadout: withoutCached,
      catalogItems: catalog,
    );
    expect(fromHash.superIconPath, '/common/destiny2_content/icons/super.png');
    expect(fromHash.exoticArmorIconPath, '/common/destiny2_content/icons/armor.png');
    expect(fromHash.exoticWeaponIconPath, '/common/destiny2_content/icons/weapon.png');
  });

  test('resolveCatalogExoticIconPath prefers store then any exotic', () {
    expect(
      resolveCatalogExoticIconPath(
        name: 'Vesper of Radius',
        catalogItems: catalog,
        armor: true,
      ),
      '/common/destiny2_content/icons/armor.png',
    );
    expect(
      resolveCatalogExoticIconPath(
        name: 'Barrow-Dyad',
        catalogItems: catalog,
        armor: false,
      ),
      '/common/destiny2_content/icons/weapon.png',
    );
    expect(
      resolveCatalogExoticIconPath(
        name: 'Unknown Exotic',
        catalogItems: catalog,
        armor: true,
      ),
      isNull,
    );
  });

  test('resolveSetFilterIconPath matches case-insensitively', () {
    expect(
      resolveSetFilterIconPath(
        setName: 'Techsec',
        iconByLowerName: const {
          'techsec': '/common/destiny2_content/icons/set.png',
        },
      ),
      '/common/destiny2_content/icons/set.png',
    );
    expect(
      resolveSetFilterIconPath(
        setName: 'Missing',
        iconByLowerName: const {},
      ),
      isNull,
    );
  });

  test('omits super path when unresolvable', () {
    final icons = resolveBuildsMockSegmentIcons(
      build: build,
      loadout: const CachedDimLoadout(
        shareId: 'c',
        name: 'C',
        classType: 2,
        items: [],
        subclassPlugs: [],
        mods: [],
        artifactPerks: [],
        subclass: CachedDimSubclass(
          hash: 1,
          name: 'Stormcaller',
          superName: 'Unknown Super',
        ),
      ),
      catalogItems: catalog,
    );
    expect(icons.superIconPath, isNull);
    expect(icons.exoticArmorIconPath, isNotNull);
  });
}
