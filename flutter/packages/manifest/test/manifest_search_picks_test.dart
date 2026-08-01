import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:test/test.dart';

void main() {
  final items = [
    const CatalogItem(
      hash: 100,
      name: 'Synthoceps',
      isExotic: true,
      slot: 'Gauntlets',
      classType: 'Titan',
      sourceStore: 'exotic-armor',
    ),
    const CatalogItem(
      hash: 200,
      name: 'Celestial Nighthawk',
      isExotic: true,
      slot: 'Helmet',
      classType: 'Hunter',
      sourceStore: 'exotic-armor',
    ),
    const CatalogItem(
      hash: 300,
      name: 'Golden Gun',
      isExotic: false,
      slot: 'super',
      itemTypeName: 'super',
      classType: 'Hunter',
      sourceStore: 'abilities',
    ),
    const CatalogItem(
      hash: 400,
      name: 'Flow State',
      isExotic: false,
      sourceStore: 'aspects',
      classType: 'Hunter',
      element: 'Arc',
    ),
    const CatalogItem(
      hash: 500,
      name: 'Spark of Beacons',
      isExotic: false,
      sourceStore: 'fragments',
      element: 'Arc',
    ),
  ];

  test('exotic armor search by name', () {
    final picks = searchManifestPicks(
      items: items,
      kind: ManifestPickKind.exoticArmor,
      query: 'synth',
    );
    expect(picks, hasLength(1));
    expect(picks.single.name, 'Synthoceps');
    expect(picks.single.hash, 100);
  });

  test('super ability search', () {
    final picks = searchManifestPicks(
      items: items,
      kind: ManifestPickKind.superAbility,
      query: 'golden',
    );
    expect(picks.single.name, 'Golden Gun');
  });

  test('class filter on exotic armor', () {
    final picks = searchManifestPicks(
      items: items,
      kind: ManifestPickKind.exoticArmor,
      classType: 'Hunter',
    );
    expect(picks.map((p) => p.name), ['Celestial Nighthawk']);
  });

  test('aspects and fragments', () {
    expect(
      searchManifestPicks(items: items, kind: ManifestPickKind.aspect)
          .single
          .name,
      'Flow State',
    );
    expect(
      searchManifestPicks(items: items, kind: ManifestPickKind.fragment)
          .single
          .name,
      'Spark of Beacons',
    );
  });
}
