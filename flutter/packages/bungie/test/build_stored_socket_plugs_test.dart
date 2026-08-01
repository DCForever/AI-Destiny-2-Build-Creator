import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:test/test.dart';

void main() {
  group('buildStoredSocketPlugs', () {
    test('emits columnKind/columnLabel and merges reusable hashes', () {
      final stored = buildStoredSocketPlugs(
        socketCapture: const [
          RawSocketCapture(
            socketIndex: 0,
            equippedPlugHash: 101,
            reusablePlugHashes: [102, 101],
          ),
          RawSocketCapture(
            socketIndex: 1,
            equippedPlugHash: 201,
            reusablePlugHashes: [202],
          ),
          RawSocketCapture(
            socketIndex: 2,
            equippedPlugHash: 301,
            reusablePlugHashes: [],
          ),
          RawSocketCapture(
            socketIndex: 9,
            equippedPlugHash: 901,
            reusablePlugHashes: [],
          ),
        ],
        plugCategoryByHash: const {
          101: 'barrels.rifle',
          201: 'magazines.ar',
          301: 'traits.weapon',
          901: 'shader',
        },
        weaponPerkSocketIndexes: const [0, 1, 2, 3],
      );

      expect(stored, hasLength(3));
      expect(stored[0].columnKind, SocketColumnKind.barrel);
      expect(stored[0].columnLabel, 'Barrel');
      expect(stored[0].reusablePlugHashes, containsAll([101, 102]));
      expect(stored[1].columnKind, SocketColumnKind.magazine);
      expect(stored[2].columnKind, SocketColumnKind.trait);
      expect(stored[2].columnLabel, 'Trait 1');
      // Shader excluded
      expect(stored.any((p) => p.equippedPlugHash == 901), isFalse);

      final json = stored[0].toJsonMap();
      expect(json['columnKind'], 'barrel');
      expect(json['columnLabel'], 'Barrel');
      expect(json['socketIndex'], 0);
    });

    test('buildWeaponSocketContextFromItemDefs supplies indexes + categories',
        () {
      final table = <String, dynamic>{
        '1000': {
          'hash': 1000,
          'sockets': {
            'socketCategories': [
              {
                'socketCategoryHash': kWeaponPerksCategoryHash,
                'socketIndexes': [0, 1, 2],
              },
            ],
          },
        },
        '101': {
          'hash': 101,
          'itemTypeDisplayName': 'Barrel',
          'plug': {'plugCategoryIdentifier': 'barrels.rifle'},
        },
        '201': {
          'hash': 201,
          'itemTypeDisplayName': 'Magazine',
          'plug': {'plugCategoryIdentifier': 'magazines.ar'},
        },
      };

      final ctx = buildWeaponSocketContextFromItemDefs(table, 1000, [101, 201]);
      expect(ctx.weaponPerkSocketIndexes, [0, 1, 2]);
      expect(ctx.plugCategoryByHash[101], 'barrels.rifle');
      expect(ctx.plugItemTypeByHash[201], 'Magazine');

      final stored = buildStoredSocketPlugs(
        socketCapture: const [
          RawSocketCapture(socketIndex: 0, equippedPlugHash: 101),
          RawSocketCapture(socketIndex: 1, equippedPlugHash: 201),
        ],
        plugCategoryByHash: ctx.plugCategoryByHash,
        plugItemTypeByHash: ctx.plugItemTypeByHash,
        weaponPerkSocketIndexes: ctx.weaponPerkSocketIndexes,
      );
      expect(stored.map((p) => p.columnLabel).toList(), ['Barrel', 'Magazine']);
    });

    test('deriveCaptureStatus', () {
      expect(deriveCaptureStatus(null), PerkCaptureStatus.pending);
      expect(deriveCaptureStatus(const []), PerkCaptureStatus.unavailable);
      expect(
        deriveCaptureStatus(const [
          StoredSocketPlug(
            socketIndex: 0,
            equippedPlugHash: 1,
            reusablePlugHashes: [1],
            columnKind: SocketColumnKind.barrel,
            columnLabel: 'Barrel',
          ),
        ]),
        PerkCaptureStatus.complete,
      );
    });
  });
}
