import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:test/test.dart';

void main() {
  test('hitActions: weapons get set+synergy; aspects get neither set nor synergy',
      () {
    expect(hitActions(CompositionKind.weapon), (set: true, synergy: true));
    expect(hitActions(CompositionKind.exoticArmor), (set: true, synergy: true));
    expect(hitActions(CompositionKind.mod), (set: true, synergy: false));
    expect(hitActions(CompositionKind.aspect), (set: false, synergy: false));
    expect(hitActions(CompositionKind.fragment), (set: false, synergy: false));
  });

  test('compositionKindFromCatalogItem uses sourceStore', () {
    expect(
      compositionKindFromCatalogItem(
        const CatalogItem(
          hash: 1,
          name: 'W',
          isExotic: false,
          sourceStore: 'weapons',
        ),
      ),
      CompositionKind.weapon,
    );
    expect(
      compositionKindFromCatalogItem(
        const CatalogItem(
          hash: 2,
          name: 'G',
          isExotic: true,
          sourceStore: 'exotic-weapons',
        ),
      ),
      CompositionKind.exoticWeapon,
    );
    expect(
      compositionKindFromCatalogItem(
        const CatalogItem(
          hash: 3,
          name: 'A',
          isExotic: true,
          sourceStore: 'exotic-armor',
        ),
      ),
      CompositionKind.exoticArmor,
    );
  });

  test('set and synergy link wires for common kinds', () {
    expect(setTypeWireForKind(CompositionKind.weapon), 'weapon');
    expect(setTypeWireForKind(CompositionKind.exoticArmor), 'armor');
    expect(setTypeWireForKind(CompositionKind.aspect), isNull);
    expect(synergyLinkKindWireForKind(CompositionKind.weapon), 'weapon');
    expect(
      synergyLinkKindWireForKind(CompositionKind.exoticArmor),
      'exotic_armor',
    );
  });
}
