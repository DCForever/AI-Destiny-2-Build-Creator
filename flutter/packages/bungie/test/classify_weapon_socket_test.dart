import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:test/test.dart';

void main() {
  group('classifyWeaponSocket', () {
    const weaponPerkSocketIndexes = [0, 1, 2, 3];

    test('labels barrel, magazine, and trait columns from plug categories', () {
      final categories = <int, String>{
        101: 'barrels.rifle',
        201: 'magazines.ar',
        301: 'traits.weapon',
        302: 'traits.weapon',
      };

      expect(
        classifyWeaponSocket(
          socketIndex: 0,
          equippedPlugHash: 101,
          plugCategoryByHash: categories,
          weaponPerkSocketIndexes: weaponPerkSocketIndexes,
        ),
        isA<SocketClassifyResult>()
            .having((r) => r.columnKind, 'kind', SocketColumnKind.barrel)
            .having((r) => r.columnLabel, 'label', 'Barrel')
            .having((r) => r.includeInGrid, 'include', isTrue),
      );

      expect(
        classifyWeaponSocket(
          socketIndex: 1,
          equippedPlugHash: 201,
          plugCategoryByHash: categories,
          weaponPerkSocketIndexes: weaponPerkSocketIndexes,
        ).columnKind,
        SocketColumnKind.magazine,
      );

      expect(
        classifyWeaponSocket(
          socketIndex: 2,
          equippedPlugHash: 301,
          plugCategoryByHash: categories,
          weaponPerkSocketIndexes: weaponPerkSocketIndexes,
        ),
        isA<SocketClassifyResult>()
            .having((r) => r.columnKind, 'kind', SocketColumnKind.trait)
            .having((r) => r.columnLabel, 'label', 'Trait 1')
            .having((r) => r.includeInGrid, 'include', isTrue),
      );

      expect(
        classifyWeaponSocket(
          socketIndex: 3,
          equippedPlugHash: 302,
          plugCategoryByHash: categories,
          weaponPerkSocketIndexes: weaponPerkSocketIndexes,
        ).columnLabel,
        'Trait 2',
      );
    });

    test(
        'excludes sockets outside weapon-perk indexes without a known column kind',
        () {
      final categories = <int, String>{901: 'traits.weapon'};
      expect(
        classifyWeaponSocket(
          socketIndex: 9,
          equippedPlugHash: 901,
          plugCategoryByHash: categories,
          weaponPerkSocketIndexes: weaponPerkSocketIndexes,
        ).includeInGrid,
        isFalse,
      );
    });

    test('labels true intrinsics as Intrinsic (not bare frames category)', () {
      expect(
        classifyWeaponSocket(
          socketIndex: 0,
          equippedPlugHash: 401,
          plugCategoryByHash: const {401: 'intrinsics'},
          weaponPerkSocketIndexes: weaponPerkSocketIndexes,
        ).columnLabel,
        'Intrinsic',
      );
    });

    test('treats Enhanced Trait plugs under frames category as traits', () {
      expect(
        classifyWeaponSocket(
          socketIndex: 3,
          equippedPlugHash: 402,
          plugCategoryByHash: const {402: 'frames'},
          plugItemTypeByHash: const {402: 'Enhanced Trait'},
          weaponPerkSocketIndexes: weaponPerkSocketIndexes,
        ),
        isA<SocketClassifyResult>()
            .having((r) => r.columnKind, 'kind', SocketColumnKind.trait)
            .having((r) => r.includeInGrid, 'include', isTrue),
      );
    });

    test('includes masterwork before generic enhancements exclusion', () {
      expect(
        classifyWeaponSocket(
          socketIndex: 8,
          equippedPlugHash: 601,
          plugCategoryByHash: const {601: 'enhancements.weapon.masterwork'},
          weaponPerkSocketIndexes: weaponPerkSocketIndexes,
        ),
        isA<SocketClassifyResult>()
            .having((r) => r.columnKind, 'kind', SocketColumnKind.masterwork)
            .having((r) => r.columnLabel, 'label', 'Masterwork')
            .having((r) => r.includeInGrid, 'include', isTrue),
      );
    });

    test('excludes gear-tier enhancement sockets', () {
      expect(
        classifyWeaponSocket(
          socketIndex: 12,
          equippedPlugHash: 701,
          plugCategoryByHash: const {701: 'enhancements.tuning'},
          weaponPerkSocketIndexes: weaponPerkSocketIndexes,
        ).includeInGrid,
        isFalse,
      );
    });

    test('excludes shader and ornament sockets', () {
      expect(
        classifyWeaponSocket(
          socketIndex: 9,
          equippedPlugHash: 901,
          plugCategoryByHash: const {901: 'shader'},
          weaponPerkSocketIndexes: weaponPerkSocketIndexes,
        ).includeInGrid,
        isFalse,
      );
    });

    test('maps intrinsic, origin, masterwork, and catalyst sockets', () {
      final categories = <int, String>{
        401: 'intrinsics',
        501: 'origins',
        601: 'masterwork',
        701: 'catalyst',
      };

      expect(
        classifyWeaponSocket(
          socketIndex: 4,
          equippedPlugHash: 401,
          plugCategoryByHash: categories,
          weaponPerkSocketIndexes: weaponPerkSocketIndexes,
        ).columnKind,
        SocketColumnKind.intrinsic,
      );
      expect(
        classifyWeaponSocket(
          socketIndex: 5,
          equippedPlugHash: 501,
          plugCategoryByHash: categories,
          weaponPerkSocketIndexes: weaponPerkSocketIndexes,
        ).columnKind,
        SocketColumnKind.origin,
      );
      expect(
        classifyWeaponSocket(
          socketIndex: 6,
          equippedPlugHash: 601,
          plugCategoryByHash: categories,
          weaponPerkSocketIndexes: weaponPerkSocketIndexes,
        ).columnKind,
        SocketColumnKind.masterwork,
      );
      expect(
        classifyWeaponSocket(
          socketIndex: 7,
          equippedPlugHash: 701,
          plugCategoryByHash: categories,
          weaponPerkSocketIndexes: weaponPerkSocketIndexes,
        ).columnKind,
        SocketColumnKind.catalyst,
      );
    });

    test('detects enhanced plug variants', () {
      // Name Enhanced OR category enhancements.v2 / enhanced; plain trait false.
      expect(isEnhancedPlug('Zen Moment', 'enhancements.v2'), isTrue);
      expect(isEnhancedPlug('Zen Moment Enhanced', 'traits.weapon'), isTrue);
      expect(isEnhancedPlug('Zen Moment', 'traits.weapon'), isFalse);
      expect(isEnhancedPlug('Rapid Hit', ''), isFalse);
      expect(isEnhancedPlug('Rapid Hit', 'enhancements.v2_general'), isTrue);
      expect(isEnhancedPlug(null, 'enhanced.trait'), isTrue);
      // Avoid over-broad enhancements.* (armor masterwork is not weapon enhance).
      expect(
        isEnhancedPlug('Masterwork', 'enhancements.weapon.masterwork'),
        isFalse,
      );
    });
  });
}
