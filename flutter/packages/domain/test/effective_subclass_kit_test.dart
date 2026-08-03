import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  group('subclassTreeNameEqual', () {
    test('trims and ignores kit pieces', () {
      expect(subclassTreeNameEqual(' Arcstrider ', 'Arcstrider'), isTrue);
      expect(subclassTreeNameEqual('Arcstrider', 'Gunslinger'), isFalse);
      expect(subclassTreeNameEqual(null, ''), isTrue);
    });
  });

  group('mergeEffectiveSubclassKit', () {
    test('two variants under one tree keep independent pieces', () {
      const tree = 'Arcstrider';
      const kitA = SubclassKit(
        aspects: ['Flow State', 'Tempest Strike'],
        fragments: ['Spark of Focus'],
        superAbility: 'Storm\'s Edge',
        melee: 'Combination Blow',
        grenade: 'Skip Grenade',
      );
      const kitB = SubclassKit(
        aspects: ['Flow State'],
        fragments: ['Spark of Momentum', 'Spark of Resistance'],
        superAbility: 'Arc Staff',
        melee: 'Disorienting Blow',
        grenade: 'Flux Grenade',
      );

      final effectiveA = mergeEffectiveSubclassKit(
        variantKit: kitA,
        treeName: tree,
      );
      final effectiveB = mergeEffectiveSubclassKit(
        variantKit: kitB,
        treeName: tree,
      );

      expect(effectiveA.name, tree);
      expect(effectiveB.name, tree);
      expect(effectiveA.aspects, kitA.aspects);
      expect(effectiveB.aspects, kitB.aspects);
      expect(effectiveA.superAbility, "Storm's Edge");
      expect(effectiveB.superAbility, 'Arc Staff');
      expect(effectiveA, isNot(effectiveB));
    });

    test('build-pinned Super overrides variant Super', () {
      final effective = mergeEffectiveSubclassKit(
        variantKit: const SubclassKit(
          superAbility: 'Arc Staff',
          melee: 'Combination Blow',
        ),
        treeName: 'Arcstrider',
        pinnedSuper: 'Storm\'s Edge',
      );
      expect(effective.superAbility, "Storm's Edge");
      expect(effective.melee, 'Combination Blow');
      expect(effective.name, 'Arcstrider');
    });

    test('empty pin leaves variant Super', () {
      final effective = mergeEffectiveSubclassKit(
        variantKit: const SubclassKit(superAbility: 'Arc Staff'),
        treeName: 'Arcstrider',
        pinnedSuper: '  ',
      );
      expect(effective.superAbility, 'Arc Staff');
    });

    test('does not invent exotic ability pins', () {
      // Soft exotic pin guidance never mutates the kit in merge.
      final effective = mergeEffectiveSubclassKit(
        variantKit: const SubclassKit(aspects: ['Flow State']),
        treeName: 'Arcstrider',
      );
      expect(effective.melee, isNull);
      expect(effective.grenade, isNull);
      expect(effective.classAbility, isNull);
      expect(effective.superAbility, isNull);
    });
  });

  group('variantKitPiecesOnly / subclassTreeOnly', () {
    test('strips tree from pieces and pieces from tree', () {
      const full = SubclassKit(
        name: 'Gunslinger',
        aspects: ['Knock \'Em Down'],
        superAbility: 'Golden Gun',
      );
      final pieces = variantKitPiecesOnly(full);
      expect(pieces.name, isNull);
      expect(pieces.aspects, ['Knock \'Em Down']);
      expect(pieces.superAbility, 'Golden Gun');

      final tree = subclassTreeOnly(full.name);
      expect(tree.name, 'Gunslinger');
      expect(subclassKitPiecesEmpty(tree), isTrue);
    });
  });
}
