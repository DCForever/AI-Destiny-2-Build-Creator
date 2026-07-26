import 'package:destiny2_db/destiny2_db.dart';
import 'package:test/test.dart';

void main() {
  test('buildResolvedPlugCards prefers names and marks traits', () {
    final cards = buildResolvedPlugCards(
      socketPlugs: const [
        {
          'socketIndex': 0,
          'equippedPlugHash': 10,
          'columnKind': 'barrel',
          'columnLabel': 'Barrel',
        },
        {
          'socketIndex': 1,
          'equippedPlugHash': 20,
          'columnKind': 'trait',
          'columnLabel': 'Trait',
        },
      ],
      plugNameByHash: const {20: 'Kill Clip'},
    );
    expect(cards, hasLength(2));
    expect(cards[0].displayName, contains('#10'));
    expect(cards[0].resolved, isFalse);
    expect(cards[1].displayName, 'Kill Clip');
    expect(cards[1].resolved, isTrue);
    expect(cards[1].isTrait, isTrue);
  });

  test('buildArmorBaseStatBoard from statValues', () {
    final board = buildArmorBaseStatBoard(const {
      'Health': 20,
      'Melee': 10,
      'Grenade': 10,
      'Super': 10,
      'Class': 10,
      'Weapons': 10,
    });
    expect(board, isNotNull);
    expect(board!.total, 70);
    expect(board.stats['Health'], 20);
    expect(board.incomplete, isFalse);
  });

  test('projectInstancesForHash includes cards and armor board', () {
    const row = InventoryItemRecord(
      instanceId: 'i1',
      itemHash: 50,
      bucket: 'Helmet',
      location: 'vault',
      power: 1800,
      plugHashes: [7],
      statValues: {'Health': 12, 'Melee': 8},
      socketPlugs: [
        {
          'socketIndex': 0,
          'equippedPlugHash': 7,
          'columnKind': 'trait',
          'columnLabel': 'Trait',
        },
      ],
      syncedAt: '2026-07-25T00:00:00.000Z',
    );
    final proj = projectInstancesForHash(
      [row],
      50,
      plugNameByHash: const {7: 'Font of Wisdom'},
      treatAsArmor: true,
    ).single;
    expect(proj.plugCards.single.displayName, 'Font of Wisdom');
    expect(proj.armorStats, isNotNull);
    expect(proj.armorStats!.stats['Health'], 12);
  });
}
