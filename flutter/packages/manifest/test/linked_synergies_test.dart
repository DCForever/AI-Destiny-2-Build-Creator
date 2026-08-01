import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:test/test.dart';

void main() {
  final synergies = [
    const CatalogSynergyMembership(
      id: 's1',
      name: 'Solar DPS',
      links: [
        CatalogSynergyLinkRef(kind: 'weapon', itemHash: 10),
        CatalogSynergyLinkRef(kind: 'weapon_perk', perkHash: 99),
      ],
    ),
    const CatalogSynergyMembership(
      id: 's2',
      name: 'Void Shell',
      links: [
        CatalogSynergyLinkRef(kind: 'exotic_armor', itemHash: 20),
        CatalogSynergyLinkRef(kind: 'weapon', itemHash: 10),
      ],
    ),
  ];

  test('buildLinkedSynergyIdsByItemHash unions itemHash links', () {
    final map = buildLinkedSynergyIdsByItemHash(synergies);
    expect(map[10], containsAll(['s1', 's2']));
    expect(map[20], ['s2']);
    expect(map.containsKey(99), isFalse); // perk not expanded
  });

  test('annotateCatalogWithLinkedSynergies sets ids for filter', () {
    final items = [
      const CatalogItem(hash: 10, name: 'Gun', isExotic: false),
      const CatalogItem(hash: 20, name: 'Armor', isExotic: true),
      const CatalogItem(hash: 30, name: 'Other', isExotic: false),
    ];
    final map = buildLinkedSynergyIdsByItemHash(synergies);
    final annotated = annotateCatalogWithLinkedSynergies(items, map);

    expect(annotated[0].linkedSynergyIds, containsAll(['s1', 's2']));
    expect(annotated[1].linkedSynergyIds, ['s2']);
    expect(annotated[2].linkedSynergyIds, isEmpty);

    final filtered = filterCatalogClient(
      annotated,
      CatalogClientFilters(
        synergies: FacetFilter(include: ['s1']),
      ),
    );
    expect(filtered.map((i) => i.hash).toList(), [10]);
  });

  test('linkedSynergyBadgesForItem resolves names', () {
    final item = const CatalogItem(
      hash: 10,
      name: 'Gun',
      isExotic: false,
      linkedSynergyIds: ['s1', 's2'],
    );
    final badges = linkedSynergyBadgesForItem(
      item,
      buildSynergyNameById(synergies),
    );
    expect(badges.map((b) => b.name).toList(), ['Solar DPS', 'Void Shell']);
  });
}
