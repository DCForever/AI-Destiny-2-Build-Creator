import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:test/test.dart';

void main() {
  final items = <CatalogItem>[
    const CatalogItem(
      hash: 1,
      name: 'Fatebringer',
      slot: 'Kinetic',
      ammo: 'Primary',
      isExotic: false,
      sourceStore: 'weapons',
    ),
    const CatalogItem(
      hash: 2,
      name: 'Gjallarhorn',
      slot: 'Power',
      ammo: 'Heavy',
      isExotic: true,
      sourceStore: 'exotic-weapons',
    ),
    const CatalogItem(
      hash: 3,
      name: 'Cuirass',
      slot: 'Chest',
      classType: 'Titan',
      isExotic: true,
      sourceStore: 'exotic-armor',
    ),
    const CatalogItem(
      hash: 4,
      name: 'Legacy Chest',
      slot: 'Chest',
      classType: 'Hunter',
      isExotic: false,
      sourceStore: 'legendary-armor',
    ),
    const CatalogItem(
      hash: 5,
      name: 'Well of Radiance',
      itemTypeName: 'Ability',
      isExotic: false,
      sourceStore: 'abilities',
    ),
    const CatalogItem(
      hash: 6,
      name: 'Charged with Light',
      itemTypeName: 'Mod',
      isExotic: false,
      sourceStore: 'mods',
    ),
  ];

  test('weapons mode keeps only weapon stores', () {
    final out = itemsForBrowseMode(items, CatalogBrowseMode.weapons);
    expect(out.map((i) => i.hash).toList(), [1, 2]);
  });

  test('armor mode keeps only armor stores', () {
    final out = itemsForBrowseMode(items, CatalogBrowseMode.armor);
    expect(out.map((i) => i.hash).toList(), [3, 4]);
  });

  test('universal mode keeps mixed kinds', () {
    final out = itemsForBrowseMode(items, CatalogBrowseMode.universal);
    expect(out.length, items.length);
  });

  test('slot/archetype helpers are kind-appropriate', () {
    expect(catalogSlotsForMode(CatalogBrowseMode.weapons), catalogWeaponSlots);
    expect(catalogSlotsForMode(CatalogBrowseMode.armor), catalogArmorSlots);
    expect(catalogShowsAmmoFacet(CatalogBrowseMode.weapons), isTrue);
    expect(catalogShowsAmmoFacet(CatalogBrowseMode.armor), isFalse);
    expect(catalogShowsClassFacet(CatalogBrowseMode.armor), isTrue);
    expect(catalogShowsClassFacet(CatalogBrowseMode.weapons), isFalse);
  });
}
