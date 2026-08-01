import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:test/test.dart';

void main() {
  group('coverageKeyFromLink / linkDedupeKey', () {
    test('weapon and weapon_perk keys', () {
      expect(
        coverageKeyFromLink(kind: 'weapon', itemHash: 1),
        'weapon:1',
      );
      expect(
        coverageKeyFromLink(kind: 'weapon_perk', perkHash: 99),
        'weapon_perk:99',
      );
    });

    test('origin trait hash or name', () {
      expect(
        coverageKeyFromLink(kind: 'origin_trait', originTraitHash: 5),
        'origin_trait:hash:5',
      );
      expect(
        coverageKeyFromLink(
          kind: 'origin_trait',
          originTraitName: 'Cast No Shadows',
        ),
        'origin_trait:name:cast no shadows',
      );
    });

    test('fallback when no coverage key', () {
      expect(
        linkDedupeKey(kind: 'weapon', displayName: 'X'),
        'fallback:weapon:x',
      );
    });
  });

  group('filterOutLinkedWeapons / filterOutLinkedPickerItems', () {
    test('removes weapons already in draft', () {
      final options = [
        const CatalogItem(hash: 1, name: 'Lodestar', isExotic: true),
        const CatalogItem(hash: 2, name: 'Other', isExotic: false),
      ];
      final draft = [
        const SynergyLinkWrite(
          kind: 'weapon',
          displayName: 'Lodestar',
          itemHash: 1,
        ),
      ];
      expect(
        filterOutLinkedWeapons(options, draft).map((o) => o.hash),
        [2],
      );
    });

    test('removes origin traits and perks already linked', () {
      final options = [
        const SynergyPickerHit(
          kind: 'origin_trait',
          name: 'Cast No Shadows',
          originTraitHash: 99,
          originTraitName: 'Cast No Shadows',
        ),
        const SynergyPickerHit(
          kind: 'weapon_perk',
          name: 'Arc Alignment',
          hash: 2174503023,
          perkHash: 2174503023,
        ),
        const SynergyPickerHit(
          kind: 'weapon_perk',
          name: 'Voltshot',
          hash: 1,
          perkHash: 1,
        ),
      ];
      final draft = [
        const SynergyLinkWrite(
          kind: 'origin_trait',
          displayName: 'Cast No Shadows',
          originTraitHash: 99,
          originTraitName: 'Cast No Shadows',
        ),
        const SynergyLinkWrite(
          kind: 'weapon_perk',
          displayName: 'Arc Alignment',
          perkHash: 2174503023,
        ),
      ];
      final remaining = filterOutLinkedPickerItems(options, draft);
      expect(remaining.map((r) => r.name), ['Voltshot']);
    });

    test('restores options when draft cleared', () {
      final options = [
        const SynergyPickerHit(
          kind: 'exotic_armor',
          name: 'Synthoceps',
          hash: 42,
        ),
      ];
      final withLink = filterOutLinkedPickerItems(options, [
        const SynergyLinkWrite(
          kind: 'exotic_armor',
          displayName: 'Synthoceps',
          itemHash: 42,
        ),
      ]);
      expect(withLink, isEmpty);
      expect(filterOutLinkedPickerItems(options, []), hasLength(1));
    });
  });

  group('formatWeaponPerkSourceLabel', () {
    test('exotic intrinsic and trait', () {
      expect(
        formatWeaponPerkSourceLabel(WeaponPerkSource.exotic, 'Intrinsic'),
        'Exotic intrinsic',
      );
      expect(
        formatWeaponPerkSourceLabel(WeaponPerkSource.exotic, 'Trait'),
        'Exotic trait',
      );
      expect(
        formatWeaponPerkSourceLabel(WeaponPerkSource.exotic, null),
        'Exotic trait',
      );
    });

    test('legendary perks', () {
      expect(
        formatWeaponPerkSourceLabel(WeaponPerkSource.legendary, 'Trait'),
        'Legendary perk',
      );
      expect(
        formatWeaponPerkSourceLabel(WeaponPerkSource.legendary, 'Intrinsic'),
        'Legendary intrinsic',
      );
    });

    test('both tiers', () {
      expect(
        formatWeaponPerkSourceLabel(WeaponPerkSource.both, 'Trait'),
        'Legendary & exotic',
      );
    });

    test('null source', () {
      expect(formatWeaponPerkSourceLabel(null, 'Trait'), isNull);
    });
  });

  group('searchCatalogForSynergyLinks', () {
    final catalog = [
      const CatalogItem(
        hash: 10,
        name: 'Lodestar',
        isExotic: true,
        slot: 'Energy',
        ammo: 'Special',
        sourceStore: 'exotic-weapons',
      ),
      const CatalogItem(
        hash: 20,
        name: 'Synthoceps',
        isExotic: true,
        slot: 'Gauntlets',
        classType: 'Titan',
        sourceStore: 'exotic-armor',
      ),
      const CatalogItem(
        hash: 30,
        name: 'Voltshot',
        isExotic: false,
        itemTypeName: 'Perk',
      ),
    ];

    test('weapon kind finds weapons', () {
      final hits = searchCatalogForSynergyLinks(
        catalog: catalog,
        linkKind: 'weapon',
        query: 'lode',
      );
      expect(hits, hasLength(1));
      expect(hits.single.hash, 10);
      final write = pickerHitToLinkWrite(hits.single);
      expect(write.kind, 'weapon');
      expect(write.itemHash, 10);
    });

    test('omit linked after search', () {
      final hits = searchCatalogForSynergyLinks(
        catalog: catalog,
        linkKind: 'weapon',
      );
      final filtered = filterOutLinkedPickerItems(hits, [
        const SynergyLinkWrite(
          kind: 'weapon',
          displayName: 'Lodestar',
          itemHash: 10,
        ),
      ]);
      expect(filtered.any((h) => h.hash == 10), isFalse);
    });

    test('weapon_perk may include source label', () {
      final hits = searchCatalogForSynergyLinks(
        catalog: catalog,
        linkKind: 'weapon_perk',
        query: 'volt',
      );
      expect(hits, isNotEmpty);
      expect(hits.first.kind, 'weapon_perk');
    });
  });
}
