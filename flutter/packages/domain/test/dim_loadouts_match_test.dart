import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  CachedDimLoadout loadout({
    required String shareId,
    required String name,
    required String exotic,
    String notes = '',
  }) {
    return CachedDimLoadout(
      shareId: shareId,
      name: name,
      classType: 2,
      exotic: CachedDimExotic(
        hash: 1,
        name: exotic,
        description: 'Grants grenade energy.',
      ),
      items: const [],
      subclassPlugs: const [],
      mods: const [],
      artifactPerks: const [],
      notes: notes,
    );
  }

  final twins = [
    loadout(
      shareId: 'share-aaa',
      name: 'Grenade Core A',
      exotic: 'Contraverse Hold',
      notes: 'notes A',
    ),
    loadout(
      shareId: 'share-bbb',
      name: 'Grenade Core B',
      exotic: 'Contraverse Hold',
      notes: 'notes B',
    ),
  ];

  group('parseDimGgShareId', () {
    test('parses dim.gg/<shareId> and dim.gg/<shareId>/…', () {
      expect(parseDimGgShareId('https://dim.gg/share-aaa'), 'share-aaa');
      expect(
        parseDimGgShareId('https://dim.gg/share-bbb/Some-Title'),
        'share-bbb',
      );
      expect(parseDimGgShareId('dim.gg/share-ccc'), 'share-ccc');
      expect(parseDimGgShareId('https://example.com/x'), isNull);
      expect(parseDimGgShareId(null), isNull);
    });
  });

  group('matchCachedDimLoadout', () {
    test('shareId from DIM link wins over shared exotic', () {
      final match = matchCachedDimLoadout(
        loadouts: twins,
        dimLink: 'https://dim.gg/share-bbb/Contraverse-Alt',
        buildName: 'wrong name',
        exoticName: 'Contraverse Hold',
      );
      expect(match.kind, CachedDimLoadoutMatchKind.matched);
      expect(match.loadout!.shareId, 'share-bbb');
      expect(match.loadout!.notes, 'notes B');
    });

    test('exact build name wins when shareId is absent', () {
      final match = matchCachedDimLoadout(
        loadouts: twins,
        dimLink: null,
        buildName: 'Grenade Core A',
        exoticName: 'Contraverse Hold',
      );
      expect(match.kind, CachedDimLoadoutMatchKind.matched);
      expect(match.loadout!.shareId, 'share-aaa');
      expect(match.loadout!.notes, 'notes A');
    });

    test('exotic-only overlap is ambiguous and never picks a row', () {
      final match = matchCachedDimLoadout(
        loadouts: twins,
        dimLink: null,
        buildName: 'Unrelated Card Title',
        exoticName: 'Contraverse Hold',
      );
      expect(match.kind, CachedDimLoadoutMatchKind.ambiguous);
      expect(match.loadout, isNull);
      expect(match.ambiguousCount, 2);
      expect(match.ambiguousLabel, 'ambiguous (2 loadouts)');
    });
  });
}
