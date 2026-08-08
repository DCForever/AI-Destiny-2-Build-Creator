import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  group('isBareHashLabel', () {
    test('detects empty and pure-digit labels', () {
      expect(isBareHashLabel(null), isTrue);
      expect(isBareHashLabel(''), isTrue);
      expect(isBareHashLabel('  '), isTrue);
      expect(isBareHashLabel('12345'), isTrue);
      expect(isBareHashLabel('Sunshot'), isFalse);
      expect(isBareHashLabel('Unknown (99)'), isFalse);
    });
  });

  group('entityLabelParts / primaryEntityLabel', () {
    test('uses name as primary and hash as footer', () {
      final p = entityLabelParts(name: 'Sunshot', hash: 42, kind: EntityLabelKind.item);
      expect(p.primary, 'Sunshot');
      expect(p.footer, '#42');
      expect(p.unknown, isFalse);
    });

    test('never uses bare hash as primary (DBR-UI-006)', () {
      expect(
        primaryEntityLabel('999', hash: 999, kind: EntityLabelKind.item),
        'Unknown item',
      );
      expect(
        entityLabelParts(name: '999', hash: 999, kind: EntityLabelKind.item),
        const EntityLabelParts(
          primary: 'Unknown item',
          footer: '#999',
          unknown: true,
        ),
      );
    });

    test('unknown without hash uses kind placeholder', () {
      final p = entityLabelParts(name: null, kind: EntityLabelKind.plug);
      expect(p.primary, 'Unknown plug');
      expect(p.footer, isNull);
      expect(p.unknown, isTrue);
    });

    test('entityHashFooter formats positive hashes only', () {
      expect(entityHashFooter(10), '#10');
      expect(entityHashFooter(null), isNull);
      expect(entityHashFooter(0), isNull);
      expect(entityHashFooter(-1), isNull);
    });
  });

  group('resolveEntityPresentation from maps', () {
    const maps = EntityPresentationMaps(
      nameByHash: {
        100: 'Fatebringer',
        300: 'Firefly',
        999: '999', // bare hash string — must not become primary
      },
      iconByHash: {
        100: '/fate.png',
        300: '/firefly.png',
      },
      descriptionByHash: {
        100: 'Hand Cannon · Adaptive Frame',
        300: 'Precision kills cause the target to explode.',
      },
      kindByHash: {
        100: 'Weapon',
        300: 'Weapon perk',
      },
      metaLinesByHash: {
        100: ['Kinetic', 'Primary'],
        300: ['Trait'],
      },
    );

    test('resolves name/icon/description/kind/meta when present', () {
      final p = resolveEntityPresentation(100, maps: maps);
      expect(p.hash, 100);
      expect(p.name, 'Fatebringer');
      expect(p.iconPath, '/fate.png');
      expect(p.description, 'Hand Cannon · Adaptive Frame');
      expect(p.hasDescription, isTrue);
      expect(p.kind, 'Weapon');
      expect(p.metaLines, ['Kinetic', 'Primary']);
      expect(p.nameUnknown, isFalse);
      expect(p.hashFooter, '#100');
    });

    test('resolves perk presentation from maps', () {
      final p = resolveEntityPresentation(
        300,
        maps: maps,
        labelKind: EntityLabelKind.plug,
      );
      expect(p.name, 'Firefly');
      expect(p.kind, 'Weapon perk');
      expect(p.description, contains('explode'));
      expect(p.metaLines, ['Trait']);
    });

    test('empty description is honest when map omits text', () {
      final p = resolveEntityPresentation(
        100,
        maps: const EntityPresentationMaps(
          nameByHash: {100: 'Fatebringer'},
          iconByHash: {100: '/fate.png'},
        ),
      );
      expect(p.name, 'Fatebringer');
      expect(p.iconPath, '/fate.png');
      expect(p.description, isEmpty);
      expect(p.hasDescription, isFalse);
    });

    test('never invents description or name for missing hash', () {
      final p = resolveEntityPresentation(404, maps: maps);
      expect(p.hash, 404);
      expect(p.name, 'Unknown item');
      expect(p.nameUnknown, isTrue);
      expect(p.iconPath, isNull);
      expect(p.description, isEmpty);
      expect(p.hasDescription, isFalse);
      expect(p.kind, isNull);
      expect(p.metaLines, isEmpty);
      expect(p.hashFooter, '#404');
    });

    test('bare hash name map entry is not primary label', () {
      final p = resolveEntityPresentation(999, maps: maps);
      expect(p.name, 'Unknown item');
      expect(p.nameUnknown, isTrue);
      expect(p.hashFooter, '#999');
    });

    test('plug unknown placeholder when maps empty', () {
      final p = resolveEntityPresentation(
        1,
        maps: EntityPresentationMaps.empty,
        labelKind: EntityLabelKind.plug,
      );
      expect(p.name, 'Unknown plug');
      expect(p.description, isEmpty);
    });

    test('whitespace-only description treated as empty', () {
      final p = resolveEntityPresentation(
        5,
        maps: const EntityPresentationMaps(
          nameByHash: {5: 'Mod'},
          descriptionByHash: {5: '   '},
        ),
      );
      expect(p.description, isEmpty);
      expect(p.hasDescription, isFalse);
    });

    test('meta lines drop blanks; do not invent extras', () {
      final p = resolveEntityPresentation(
        7,
        maps: const EntityPresentationMaps(
          nameByHash: {7: 'X'},
          metaLinesByHash: {
            7: ['Solar', '  ', 'Heavy'],
          },
        ),
      );
      expect(p.metaLines, ['Solar', 'Heavy']);
    });
  });

  group('resolveEntityPresentationFields', () {
    test('maps CatalogItem-shaped fields without inventing text', () {
      final p = resolveEntityPresentationFields(
        hash: 101,
        name: 'Sunshot',
        iconPath: '/sun.png',
        description: 'Targets explode and Scorch nearby foes.',
        kind: 'Exotic weapon',
        metaLines: const ['Solar', 'Energy'],
      );
      expect(p.name, 'Sunshot');
      expect(p.description, contains('Scorch'));
      expect(p.metaLines, ['Solar', 'Energy']);
    });

    test('null description stays empty (honest)', () {
      final p = resolveEntityPresentationFields(
        hash: 1,
        name: 'Item',
        description: null,
      );
      expect(p.description, isEmpty);
      expect(p.hasDescription, isFalse);
    });
  });

  group('resolveEntityPresentations batch', () {
    test('returns entry for every hash including misses', () {
      const maps = EntityPresentationMaps(
        nameByHash: {1: 'A', 2: 'B'},
        descriptionByHash: {1: 'desc-a'},
      );
      final batch = resolveEntityPresentations([1, 2, 3], maps: maps);
      expect(batch.keys, containsAll([1, 2, 3]));
      expect(batch[1]!.name, 'A');
      expect(batch[1]!.hasDescription, isTrue);
      expect(batch[2]!.description, isEmpty);
      expect(batch[3]!.name, 'Unknown item');
      expect(batch[3]!.nameUnknown, isTrue);
    });
  });
}
