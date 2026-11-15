import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:test/test.dart';

void main() {
  const ctx = WriteClientContext(accessToken: 'test-token', membershipType: 3);
  const target = 'char-1';
  const helmetBucket = 3448274439;
  const armsBucket = 3551918588;

  List<ApplyInventoryItem> onTarget(List<ApplyToCharacterItem> items) => [
        for (final item in items)
          ApplyInventoryItem(
            instanceId: item.instanceId,
            itemHash: item.itemHash,
            location: 'character',
            bucketHash: helmetBucket,
            characterId: target,
          ),
      ];

  test('equip-only: bulk equipItems with progress waiting→applying→done',
      () async {
    final bulkCalls = <List<String>>[];
    final phases = <String>[];
    final client = createMockWriteClient(
      equipItems: (c, a) async {
        bulkCalls.add(List<String>.from(a.itemIds));
        return [
          for (final id in a.itemIds)
            EquipItemResultEntry(
              instanceId: id,
              equipStatus: kPlatformErrorSuccess,
              errorStatus: 'Success',
            ),
        ];
      },
    );

    const items = [
      ApplyToCharacterItem(
        id: 'helmet',
        label: 'Helmet A',
        itemHash: 1,
        instanceId: 'i1',
        slot: 'helmet',
      ),
      ApplyToCharacterItem(
        id: 'arms',
        label: 'Arms B',
        itemHash: 2,
        instanceId: 'i2',
        slot: 'arms',
      ),
    ];

    final result = await applyToCharacter(
      writeClient: client,
      ctx: ctx,
      characterId: target,
      items: items,
      inventory: onTarget(items),
      onProgress: (p) {
        for (final item in p.items) {
          phases.add('${item.id}:${item.state.name}');
        }
        phases.add('---${p.applyingLine}');
      },
    );

    expect(bulkCalls, [
      ['i1', 'i2'],
    ]);
    expect(result.appliedCount, 2);
    expect(result.failedCount, 0);
    expect(result.summary, '2 applied, 0 failed');
    expect(result.running, isFalse);
    expect(
      result.items.map((i) => i.state).toList(),
      [ApplyItemState.done, ApplyItemState.done],
    );
    expect(phases.any((p) => p.contains('helmet:applying')), isTrue);
  });

  test('vault item: transfer then bulk equip after dry-run confirm', () async {
    final transfers = <TransferItemArgs>[];
    final bulk = <List<String>>[];
    final client = createMockWriteClient(
      transferItem: (c, a) async => transfers.add(a),
      equipItems: (c, a) async {
        bulk.add(List<String>.from(a.itemIds));
        return [
          for (final id in a.itemIds)
            EquipItemResultEntry(
              instanceId: id,
              equipStatus: kPlatformErrorSuccess,
            ),
        ];
      },
    );

    final result = await applyToCharacter(
      writeClient: client,
      ctx: ctx,
      characterId: target,
      items: const [
        ApplyToCharacterItem(
          id: 'helmet',
          label: 'Helmet A',
          itemHash: 1,
          instanceId: 'vault-1',
        ),
      ],
      inventory: const [
        ApplyInventoryItem(
          instanceId: 'vault-1',
          itemHash: 1,
          location: 'vault',
          bucketHash: helmetBucket,
        ),
      ],
      confirmMoves: (moves) async {
        expect(moves, hasLength(1));
        expect(moves.single.fromLabel, 'Vault');
        expect(moves.single.toLabel, 'Character');
        return true;
      },
    );

    expect(transfers, hasLength(1));
    expect(transfers.single.transferToVault, isFalse);
    expect(transfers.single.characterId, target);
    expect(bulk, [
      ['vault-1'],
    ]);
    expect(result.appliedCount, 1);
  });

  test('other-char item: vault-hop with source characterId on to-vault',
      () async {
    final transfers = <TransferItemArgs>[];
    final client = createMockWriteClient(
      transferItem: (c, a) async => transfers.add(a),
    );

    await applyToCharacter(
      writeClient: client,
      ctx: ctx,
      characterId: target,
      items: const [
        ApplyToCharacterItem(
          id: 'arms',
          label: 'Arms B',
          itemHash: 2,
          instanceId: 'other-1',
        ),
      ],
      inventory: const [
        ApplyInventoryItem(
          instanceId: 'other-1',
          itemHash: 2,
          location: 'character',
          bucketHash: armsBucket,
          characterId: 'char-other',
        ),
      ],
      confirmMoves: (_) async => true,
    );

    expect(transfers, hasLength(2));
    expect(transfers[0].transferToVault, isTrue);
    expect(transfers[0].characterId, 'char-other');
    expect(transfers[1].transferToVault, isFalse);
    expect(transfers[1].characterId, target);
  });

  test('equipped-on-other-char: dequip replacement then vault-hop', () async {
    final equips = <EquipItemArgs>[];
    final transfers = <TransferItemArgs>[];
    final client = createMockWriteClient(
      equipItem: (c, a) async => equips.add(a),
      transferItem: (c, a) async => transfers.add(a),
    );

    await applyToCharacter(
      writeClient: client,
      ctx: ctx,
      characterId: target,
      items: const [
        ApplyToCharacterItem(
          id: 'helmet',
          label: 'Exotic Helm',
          itemHash: 99,
          instanceId: 'eq-other',
        ),
      ],
      inventory: const [
        ApplyInventoryItem(
          instanceId: 'eq-other',
          itemHash: 99,
          location: 'equipped',
          bucketHash: helmetBucket,
          characterId: 'char-other',
          isExotic: true,
        ),
        ApplyInventoryItem(
          instanceId: 'replacement',
          itemHash: 11,
          location: 'character',
          bucketHash: helmetBucket,
          characterId: 'char-other',
        ),
      ],
      confirmMoves: (moves) async {
        expect(moves.first.kind, ApplyMoveKind.dequipOnOther);
        return true;
      },
    );

    expect(equips, hasLength(1));
    expect(equips.single.instanceId, 'replacement');
    expect(equips.single.characterId, 'char-other');
    expect(transfers, hasLength(2));
  });

  test('exotic ordering: non-exotics before exotics in EquipItems', () async {
    List<String>? order;
    final client = createMockWriteClient(
      equipItems: (c, a) async {
        order = List<String>.from(a.itemIds);
        return [
          for (final id in a.itemIds)
            EquipItemResultEntry(
              instanceId: id,
              equipStatus: kPlatformErrorSuccess,
            ),
        ];
      },
    );

    await applyToCharacter(
      writeClient: client,
      ctx: ctx,
      characterId: target,
      items: const [
        ApplyToCharacterItem(
          id: 'exotic',
          label: 'Exotic',
          itemHash: 9,
          instanceId: 'ex',
        ),
        ApplyToCharacterItem(
          id: 'leg',
          label: 'Legendary',
          itemHash: 8,
          instanceId: 'leg',
        ),
      ],
      inventory: const [
        ApplyInventoryItem(
          instanceId: 'ex',
          itemHash: 9,
          location: 'character',
          bucketHash: helmetBucket,
          characterId: target,
          isExotic: true,
        ),
        ApplyInventoryItem(
          instanceId: 'leg',
          itemHash: 8,
          location: 'character',
          bucketHash: armsBucket,
          characterId: target,
        ),
      ],
    );

    expect(order, ['leg', 'ex']);
  });

  test('partial bulk failure surfaces ErrorStatus text', () async {
    final client = createMockWriteClient(
      equipItems: (c, a) async => [
            EquipItemResultEntry(
              instanceId: 'ok',
              equipStatus: kPlatformErrorSuccess,
              errorStatus: 'Success',
            ),
            EquipItemResultEntry(
              instanceId: 'bad',
              equipStatus: kDestinyItemNotFound,
              errorStatus: 'DestinyItemNotFound',
            ),
          ],
    );

    final result = await applyToCharacter(
      writeClient: client,
      ctx: ctx,
      characterId: target,
      items: const [
        ApplyToCharacterItem(
          id: 'a',
          label: 'A',
          itemHash: 1,
          instanceId: 'ok',
        ),
        ApplyToCharacterItem(
          id: 'b',
          label: 'B',
          itemHash: 2,
          instanceId: 'bad',
        ),
      ],
      inventory: onTarget(const [
        ApplyToCharacterItem(
          id: 'a',
          label: 'A',
          itemHash: 1,
          instanceId: 'ok',
        ),
        ApplyToCharacterItem(
          id: 'b',
          label: 'B',
          itemHash: 2,
          instanceId: 'bad',
        ),
      ]),
    );

    expect(result.appliedCount, 1);
    expect(result.failedCount, 1);
    expect(result.items[1].reason, 'DestinyItemNotFound');
  });

  test('in-activity stop uses clear message and skips further equips', () async {
    final client = createMockWriteClient(
      equipItems: (c, a) async => [
            EquipItemResultEntry(
              instanceId: 'a',
              equipStatus: kDestinyCannotPerformActionAtThisLocation,
              errorStatus: 'DestinyCannotPerformActionAtThisLocation',
            ),
            EquipItemResultEntry(
              instanceId: 'b',
              equipStatus: kPlatformErrorSuccess,
            ),
          ],
    );

    final result = await applyToCharacter(
      writeClient: client,
      ctx: ctx,
      characterId: target,
      items: const [
        ApplyToCharacterItem(
          id: 'a',
          label: 'A',
          itemHash: 1,
          instanceId: 'a',
        ),
        ApplyToCharacterItem(
          id: 'b',
          label: 'B',
          itemHash: 2,
          instanceId: 'b',
        ),
      ],
      inventory: onTarget(const [
        ApplyToCharacterItem(
          id: 'a',
          label: 'A',
          itemHash: 1,
          instanceId: 'a',
        ),
        ApplyToCharacterItem(
          id: 'b',
          label: 'B',
          itemHash: 2,
          instanceId: 'b',
        ),
      ]),
    );

    expect(result.items[0].reason, kInActivityEquipMessage);
    expect(result.items[1].state, ApplyItemState.failed);
    expect(result.items[1].reason, kInActivityEquipMessage);
  });

  test('full bucket refuses with No room on character (no transfer)', () async {
    var transferCalls = 0;
    var equipCalls = 0;
    final client = createMockWriteClient(
      transferItem: (c, a) async => transferCalls += 1,
      equipItems: (c, a) async {
        equipCalls += 1;
        return const [];
      },
    );

    final inventory = <ApplyInventoryItem>[
      const ApplyInventoryItem(
        instanceId: 'vault-full',
        itemHash: 1,
        location: 'vault',
        bucketHash: helmetBucket,
      ),
      for (var i = 0; i < 10; i++)
        ApplyInventoryItem(
          instanceId: 'fill-$i',
          itemHash: 100 + i,
          location: i == 0 ? 'equipped' : 'character',
          bucketHash: helmetBucket,
          characterId: target,
        ),
    ];

    final result = await applyToCharacter(
      writeClient: client,
      ctx: ctx,
      characterId: target,
      items: const [
        ApplyToCharacterItem(
          id: 'helmet',
          label: 'Helmet',
          itemHash: 1,
          instanceId: 'vault-full',
        ),
      ],
      inventory: inventory,
      confirmMoves: (_) async => true,
    );

    expect(transferCalls, 0);
    expect(equipCalls, 0);
    expect(result.items.single.reason, kNoRoomOnCharacterMessage);
  });

  test('500-with-envelope error surfaces ErrorStatus on item row', () async {
    final client = createMockWriteClient(
      transferItem: (c, a) async {
        throw const BungiePlatformException(
          'Bungie API error: Item Not Found',
          errorCode: kDestinyItemNotFound,
          errorStatus: 'DestinyItemNotFound',
          statusCode: 500,
        );
      },
    );

    final result = await applyToCharacter(
      writeClient: client,
      ctx: ctx,
      characterId: target,
      items: const [
        ApplyToCharacterItem(
          id: 'helmet',
          label: 'Helmet',
          itemHash: 1,
          instanceId: 'vault-1',
        ),
      ],
      inventory: const [
        ApplyInventoryItem(
          instanceId: 'vault-1',
          itemHash: 1,
          location: 'vault',
          bucketHash: helmetBucket,
        ),
      ],
      confirmMoves: (_) async => true,
    );

    expect(result.items.single.state, ApplyItemState.failed);
    expect(result.items.single.reason, 'DestinyItemNotFound');
  });

  test('Cancel on dry-run makes zero write calls', () async {
    var writes = 0;
    final client = createMockWriteClient(
      transferItem: (c, a) async => writes += 1,
      equipItem: (c, a) async => writes += 1,
      equipItems: (c, a) async {
        writes += 1;
        return const [];
      },
    );

    final result = await applyToCharacter(
      writeClient: client,
      ctx: ctx,
      characterId: target,
      items: const [
        ApplyToCharacterItem(
          id: 'helmet',
          label: 'Helmet',
          itemHash: 1,
          instanceId: 'vault-1',
        ),
      ],
      inventory: const [
        ApplyInventoryItem(
          instanceId: 'vault-1',
          itemHash: 1,
          location: 'vault',
          bucketHash: helmetBucket,
        ),
      ],
      confirmMoves: (_) async => false,
    );

    expect(writes, 0);
    expect(result.summary, 'Cancelled — 0 applied');
    expect(result.items.single.state, ApplyItemState.cancelled);
  });

  test('never invokes dismantle/delete on the write client', () async {
    final client = _RecordingWriteClient();
    await applyToCharacter(
      writeClient: client,
      ctx: ctx,
      characterId: target,
      items: const [
        ApplyToCharacterItem(
          id: 'a',
          label: 'Item A',
          itemHash: 1,
          instanceId: 'i1',
        ),
      ],
      inventory: const [
        ApplyInventoryItem(
          instanceId: 'i1',
          itemHash: 1,
          location: 'character',
          bucketHash: helmetBucket,
          characterId: target,
        ),
      ],
    );
    expect(client.equipItemsCalls, 1);
    expect(client.equipCalls, 0);
    expect(client.transferCalls, 0);
    expect(client.dismantleCalls, 0);
    expect(client.deleteCalls, 0);
  });
}

/// Fake write client that also exposes dismantle/delete counters for the
/// safety assertion (those methods are NOT on [BungieWriteClient]).
class _RecordingWriteClient implements BungieWriteClient {
  int equipCalls = 0;
  int equipItemsCalls = 0;
  int transferCalls = 0;
  int dismantleCalls = 0;
  int deleteCalls = 0;

  @override
  Future<void> equipItem(WriteClientContext ctx, EquipItemArgs args) async {
    equipCalls += 1;
  }

  @override
  Future<List<EquipItemResultEntry>> equipItems(
    WriteClientContext ctx,
    EquipItemsArgs args,
  ) async {
    equipItemsCalls += 1;
    return [
      for (final id in args.itemIds)
        EquipItemResultEntry(
          instanceId: id,
          equipStatus: kPlatformErrorSuccess,
        ),
    ];
  }

  @override
  Future<void> transferItem(
    WriteClientContext ctx,
    TransferItemArgs args,
  ) async {
    transferCalls += 1;
  }

  @override
  Future<void> applyArtifactConfig(
    WriteClientContext ctx,
    ApplyArtifactArgs args,
  ) async {}

  @override
  Future<void> applyFashionSlot(
    WriteClientContext ctx,
    ApplyFashionArgs args,
  ) async {}

  Future<void> dismantleItem() async => dismantleCalls += 1;
  Future<void> deleteItem() async => deleteCalls += 1;
}
