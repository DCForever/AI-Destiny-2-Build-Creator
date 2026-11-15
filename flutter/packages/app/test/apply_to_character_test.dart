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

  test('vault item: transfer then bulk equip immediately', () async {
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

  test(
    'full bucket at plan time: evicts unequipped non-plan item then moves target',
    () async {
      // CHANGED: previously refused with kNoRoomOnCharacterMessage and made
      // zero transfers. Now makes room (DIM-style) then moves the pin.
      final transfers = <TransferItemArgs>[];
      final client = createMockWriteClient(
        transferItem: (c, a) async => transfers.add(a),
        equipItems: (c, a) async => [
              for (final id in a.itemIds)
                EquipItemResultEntry(
                  instanceId: id,
                  equipStatus: kPlatformErrorSuccess,
                ),
            ],
      );

      final inventory = <ApplyInventoryItem>[
        const ApplyInventoryItem(
          instanceId: 'vault-full',
          itemHash: 1,
          location: 'vault',
          bucketHash: helmetBucket,
          name: 'Lustrous Boots',
        ),
        const ApplyInventoryItem(
          instanceId: 'fill-0',
          itemHash: 100,
          location: 'equipped',
          bucketHash: helmetBucket,
          characterId: target,
          power: 200,
          name: 'Equipped Helm',
        ),
        for (var i = 1; i < 10; i++)
          ApplyInventoryItem(
            instanceId: 'fill-$i',
            itemHash: 100 + i,
            location: 'character',
            bucketHash: helmetBucket,
            characterId: target,
            power: 100 + i,
            name: 'Junk Helm $i',
            isExotic: i == 9,
          ),
      ];

      final result = await applyToCharacter(
        writeClient: client,
        ctx: ctx,
        characterId: target,
        items: const [
          ApplyToCharacterItem(
            id: 'helmet',
            label: 'Lustrous Boots',
            itemHash: 1,
            instanceId: 'vault-full',
            slot: 'helmet',
          ),
        ],
        inventory: inventory,
      );

      // Eviction prefers non-exotic + lowest power among unequipped → fill-1.
      expect(transfers, hasLength(2));
      expect(transfers[0].instanceId, 'fill-1');
      expect(transfers[0].transferToVault, isTrue);
      expect(transfers[0].characterId, target);
      expect(transfers[1].instanceId, 'vault-full');
      expect(transfers[1].transferToVault, isFalse);
      expect(result.appliedCount, 1);
      expect(
        result.items.any(
          (r) =>
              r.id.startsWith(kApplyMakeRoomRowIdPrefix) &&
              r.label == kMakeRoomMovedToVaultMessage('Junk Helm 1'),
        ),
        isTrue,
      );
    },
  );

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
    );

    expect(result.items.single.state, ApplyItemState.failed);
    expect(result.items.single.reason, 'DestinyItemNotFound');
  });

  test('zero planned moves makes zero TransferItem calls', () async {
    var transferCalls = 0;
    var equipItemsCalls = 0;
    final client = createMockWriteClient(
      transferItem: (c, a) async => transferCalls += 1,
      equipItems: (c, a) async {
        equipItemsCalls += 1;
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
          label: 'Helmet',
          itemHash: 1,
          instanceId: 'on-target',
        ),
      ],
      inventory: const [
        ApplyInventoryItem(
          instanceId: 'on-target',
          itemHash: 1,
          location: 'character',
          bucketHash: helmetBucket,
          characterId: target,
        ),
      ],
    );

    expect(transferCalls, 0);
    expect(equipItemsCalls, 1);
    expect(result.appliedCount, 1);
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

  test(
    'two pins into one free slot: first proceeds, second makes room',
    () async {
      // CHANGED: previously the second pin was refused with
      // kNoRoomOnCharacterMessage. Make-room now frees a slot for the second.
      final transfers = <TransferItemArgs>[];
      List<String>? equipOrder;
      final client = createMockWriteClient(
        transferItem: (c, a) async => transfers.add(a),
        equipItems: (c, a) async {
          equipOrder = List<String>.from(a.itemIds);
          return [
            for (final id in a.itemIds)
              EquipItemResultEntry(
                instanceId: id,
                equipStatus: kPlatformErrorSuccess,
              ),
          ];
        },
      );

      final inventory = <ApplyInventoryItem>[
        const ApplyInventoryItem(
          instanceId: 'vault-a',
          itemHash: 1,
          location: 'vault',
          bucketHash: helmetBucket,
        ),
        const ApplyInventoryItem(
          instanceId: 'vault-b',
          itemHash: 2,
          location: 'vault',
          bucketHash: helmetBucket,
        ),
        for (var i = 0; i < 9; i++)
          ApplyInventoryItem(
            instanceId: 'fill-$i',
            itemHash: 200 + i,
            location: i == 0 ? 'equipped' : 'character',
            bucketHash: helmetBucket,
            characterId: target,
            power: 50 + i,
            name: 'Fill $i',
          ),
      ];

      final result = await applyToCharacter(
        writeClient: client,
        ctx: ctx,
        characterId: target,
        items: const [
          ApplyToCharacterItem(
            id: 'a',
            label: 'A',
            itemHash: 1,
            instanceId: 'vault-a',
          ),
          ApplyToCharacterItem(
            id: 'b',
            label: 'B',
            itemHash: 2,
            instanceId: 'vault-b',
          ),
        ],
        inventory: inventory,
      );

      expect(transfers, hasLength(3));
      expect(transfers[0].instanceId, 'vault-a');
      expect(transfers[1].instanceId, 'fill-1');
      expect(transfers[1].transferToVault, isTrue);
      expect(transfers[2].instanceId, 'vault-b');
      expect(equipOrder, ['vault-a', 'vault-b']);
      expect(result.appliedCount, 2);
      expect(result.failedCount, 0);
    },
  );

  test(
    'to-vault hop then 1642 with no evictee: stranded vault message (R1/R2b)',
    () async {
      // RESTORED (PR55): after a successful hop to vault, make-room failure
      // must still say the item is in the vault — not generic still-full.
      var hop = 0;
      final client = createMockWriteClient(
        transferItem: (c, a) async {
          hop += 1;
          if (hop == 1) {
            expect(a.transferToVault, isTrue);
            return;
          }
          throw const BungiePlatformException(
            'Bungie API error: No room',
            errorCode: kDestinyNoRoomInDestination,
            errorStatus: 'DestinyNoRoomInDestination',
          );
        },
      );

      final result = await applyToCharacter(
        writeClient: client,
        ctx: ctx,
        characterId: target,
        items: const [
          ApplyToCharacterItem(
            id: 'arms',
            label: 'Synthoceps',
            itemHash: 2,
            instanceId: 'other-1',
            slot: 'arms',
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
      );

      expect(hop, 2);
      expect(result.items.first.state, ApplyItemState.failed);
      expect(result.items.first.reason, kMovedToVaultStuckMessage);
    },
  );

  test(
    'full bucket, vault room, nothing evictable: No room on character, 0 transfers (R2a)',
    () async {
      var transferCalls = 0;
      final client = createMockWriteClient(
        transferItem: (c, a) async => transferCalls += 1,
        equipItems: (c, a) async => const [],
      );

      final inventory = <ApplyInventoryItem>[
        const ApplyInventoryItem(
          instanceId: 'vault-1',
          itemHash: 1,
          location: 'vault',
          bucketHash: helmetBucket,
        ),
        // 10 slots: all equipped or locked / non-transferable → no evictee.
        const ApplyInventoryItem(
          instanceId: 'eq',
          itemHash: 10,
          location: 'equipped',
          bucketHash: helmetBucket,
          characterId: target,
        ),
        for (var i = 0; i < 9; i++)
          ApplyInventoryItem(
            instanceId: 'locked-$i',
            itemHash: 100 + i,
            location: 'character',
            bucketHash: helmetBucket,
            characterId: target,
            isLocked: true,
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
            instanceId: 'vault-1',
          ),
        ],
        inventory: inventory,
      );

      expect(transferCalls, 0);
      expect(result.items.single.reason, kNoRoomOnCharacterMessage);
    },
  );

  test('hash mismatch refuses before any TransferItem', () async {
    var transferCalls = 0;
    var equipCalls = 0;
    final client = createMockWriteClient(
      transferItem: (c, a) async => transferCalls += 1,
      equipItems: (c, a) async {
        equipCalls += 1;
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
          itemHash: 111,
          instanceId: 'vault-1',
        ),
      ],
      inventory: const [
        ApplyInventoryItem(
          instanceId: 'vault-1',
          itemHash: 999,
          location: 'vault',
          bucketHash: helmetBucket,
        ),
      ],
    );

    expect(transferCalls, 0);
    expect(equipCalls, 0);
    expect(result.items.single.reason, kItemHashMismatchMessage);
  });

  test('exotic weapon (isExotic) is equipped after legendary weapon', () async {
    const kineticBucket = 1498876634;
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
          id: 'exotic-gun',
          label: 'Exotic Gun',
          itemHash: 9001,
          instanceId: 'exo-w',
        ),
        ApplyToCharacterItem(
          id: 'leg-gun',
          label: 'Legendary Gun',
          itemHash: 9002,
          instanceId: 'leg-w',
        ),
      ],
      inventory: const [
        ApplyInventoryItem(
          instanceId: 'exo-w',
          itemHash: 9001,
          location: 'character',
          bucketHash: kineticBucket,
          characterId: target,
          isExotic: true,
        ),
        ApplyInventoryItem(
          instanceId: 'leg-w',
          itemHash: 9002,
          location: 'character',
          bucketHash: kineticBucket,
          characterId: target,
        ),
      ],
    );

    expect(order, ['leg-w', 'exo-w']);
  });

  test('full vault refuses other-char pull with No room in vault', () async {
    var transferCalls = 0;
    final client = createMockWriteClient(
      transferItem: (c, a) async => transferCalls += 1,
    );

    final inventory = <ApplyInventoryItem>[
      const ApplyInventoryItem(
        instanceId: 'other-1',
        itemHash: 2,
        location: 'character',
        bucketHash: armsBucket,
        characterId: 'char-other',
      ),
      for (var i = 0; i < kApplyVaultCapacity; i++)
        ApplyInventoryItem(
          instanceId: 'vault-fill-$i',
          itemHash: 300 + i,
          location: 'vault',
          bucketHash: helmetBucket,
        ),
    ];

    final result = await applyToCharacter(
      writeClient: client,
      ctx: ctx,
      characterId: target,
      items: const [
        ApplyToCharacterItem(
          id: 'arms',
          label: 'Arms',
          itemHash: 2,
          instanceId: 'other-1',
        ),
      ],
      inventory: inventory,
    );

    expect(transferCalls, 0);
    expect(result.items.single.reason, kNoRoomInVaultMessage);
  });

  test('generic Exception never surfaces error.toString() on apply row',
      () async {
    final client = createMockWriteClient(
      transferItem: (c, a) async {
        throw Exception('secret-token-should-not-leak');
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
    );

    expect(result.items.single.reason, kGenericApplyFailureMessage);
    expect(result.items.single.reason, isNot(contains('secret-token')));
  });

  test('BungieHttpException maps to fixed HTTP failure text', () async {
    final client = createMockWriteClient(
      transferItem: (c, a) async {
        throw const BungieHttpException(
          'raw body',
          statusCode: 503,
          bodySnippet: 'upstream boom',
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
    );

    expect(result.items.single.reason, bungieHttpFailureMessage(503));
    expect(result.items.single.reason, isNot(contains('upstream')));
  });

  test('TransferItem 1642 at run time: make-room then retry succeeds', () async {
    final transfers = <TransferItemArgs>[];
    var vaultPullAttempts = 0;
    final client = createMockWriteClient(
      transferItem: (c, a) async {
        transfers.add(a);
        if (!a.transferToVault && a.instanceId == 'vault-1') {
          vaultPullAttempts += 1;
          if (vaultPullAttempts == 1) {
            throw const BungiePlatformException(
              'Bungie API error: No room',
              errorCode: kDestinyNoRoomInDestination,
              errorStatus: 'DestinyNoRoomInDestination',
            );
          }
        }
      },
      equipItems: (c, a) async => [
            for (final id in a.itemIds)
              EquipItemResultEntry(
                instanceId: id,
                equipStatus: kPlatformErrorSuccess,
              ),
          ],
    );

    // 9 on character → planner thinks there is room; runtime 1642 triggers
    // make-room against an unequipped filler.
    final inventory = <ApplyInventoryItem>[
      const ApplyInventoryItem(
        instanceId: 'vault-1',
        itemHash: 1,
        location: 'vault',
        bucketHash: helmetBucket,
        name: 'Lustrous Boots',
      ),
      const ApplyInventoryItem(
        instanceId: 'eq',
        itemHash: 10,
        location: 'equipped',
        bucketHash: helmetBucket,
        characterId: target,
        power: 200,
        name: 'Equipped',
      ),
      for (var i = 0; i < 8; i++)
        ApplyInventoryItem(
          instanceId: 'fill-$i',
          itemHash: 50 + i,
          location: 'character',
          bucketHash: helmetBucket,
          characterId: target,
          power: 10 + i,
          name: 'Filler $i',
        ),
    ];

    final result = await applyToCharacter(
      writeClient: client,
      ctx: ctx,
      characterId: target,
      items: const [
        ApplyToCharacterItem(
          id: 'boots',
          label: 'Lustrous Boots',
          itemHash: 1,
          instanceId: 'vault-1',
          slot: 'legs',
        ),
      ],
      inventory: inventory,
    );

    expect(transfers.map((t) => t.instanceId).toList(), [
      'vault-1',
      'fill-0',
      'vault-1',
    ]);
    expect(transfers[1].transferToVault, isTrue);
    expect(result.appliedCount, 1);
    expect(
      result.items.any(
        (r) => r.label == kMakeRoomMovedToVaultMessage('Filler 0'),
      ),
      isTrue,
    );
  });

  test('still full after 2 make-room attempts: fixed-text failure, no further writes',
      () async {
    final transfers = <TransferItemArgs>[];
    final client = createMockWriteClient(
      transferItem: (c, a) async {
        transfers.add(a);
        if (!a.transferToVault && a.instanceId == 'vault-1') {
          throw const BungiePlatformException(
            'Bungie API error: No room',
            errorCode: kDestinyNoRoomInDestination,
            errorStatus: 'DestinyNoRoomInDestination',
          );
        }
      },
      equipItems: (c, a) async => const [],
    );

    final inventory = <ApplyInventoryItem>[
      const ApplyInventoryItem(
        instanceId: 'vault-1',
        itemHash: 1,
        location: 'vault',
        bucketHash: helmetBucket,
        name: 'Target',
      ),
      const ApplyInventoryItem(
        instanceId: 'eq',
        itemHash: 10,
        location: 'equipped',
        bucketHash: helmetBucket,
        characterId: target,
        power: 200,
      ),
      for (var i = 0; i < 8; i++)
        ApplyInventoryItem(
          instanceId: 'fill-$i',
          itemHash: 50 + i,
          location: 'character',
          bucketHash: helmetBucket,
          characterId: target,
          power: i,
          name: 'Filler $i',
        ),
    ];

    final result = await applyToCharacter(
      writeClient: client,
      ctx: ctx,
      characterId: target,
      items: const [
        ApplyToCharacterItem(
          id: 'helmet',
          label: 'Target Helm',
          itemHash: 1,
          instanceId: 'vault-1',
          slot: 'helmet',
        ),
      ],
      inventory: inventory,
    );

    // Initial pull + 2 evictions + 2 retries = 5 transfers; then stop.
    expect(transfers, hasLength(5));
    expect(
      transfers.where((t) => t.transferToVault).map((t) => t.instanceId),
      ['fill-0', 'fill-1'],
    );
    expect(result.items.first.state, ApplyItemState.failed);
    expect(
      result.items.first.reason,
      kMakeRoomStillFullMessage('Target Helm'),
    );
    expect(result.items.first.reason, isNot(contains('DestinyNoRoom')));
  });

  test('never evicts equipped items or plan items; vault full refuses clearly',
      () async {
    var transferCalls = 0;
    final client = createMockWriteClient(
      transferItem: (c, a) async => transferCalls += 1,
    );

    final inventory = <ApplyInventoryItem>[
      const ApplyInventoryItem(
        instanceId: 'vault-target',
        itemHash: 1,
        location: 'vault',
        bucketHash: helmetBucket,
      ),
      // Only equipped + a plan peer occupy the bucket → no eligible evictee.
      const ApplyInventoryItem(
        instanceId: 'equipped-only',
        itemHash: 10,
        location: 'equipped',
        bucketHash: helmetBucket,
        characterId: target,
      ),
      for (var i = 0; i < 8; i++)
        ApplyInventoryItem(
          instanceId: 'fill-$i',
          itemHash: 100 + i,
          location: 'character',
          bucketHash: helmetBucket,
          characterId: target,
        ),
      // Second plan item sitting on character — must not be chosen as evictee.
      const ApplyInventoryItem(
        instanceId: 'plan-peer',
        itemHash: 2,
        location: 'character',
        bucketHash: helmetBucket,
        characterId: target,
      ),
      for (var i = 0; i < kApplyVaultCapacity; i++)
        ApplyInventoryItem(
          instanceId: 'vault-fill-$i',
          itemHash: 9000 + i,
          location: 'vault',
          bucketHash: armsBucket,
        ),
    ];

    final result = await applyToCharacter(
      writeClient: client,
      ctx: ctx,
      characterId: target,
      items: const [
        ApplyToCharacterItem(
          id: 'a',
          label: 'A',
          itemHash: 1,
          instanceId: 'vault-target',
        ),
        ApplyToCharacterItem(
          id: 'b',
          label: 'B',
          itemHash: 2,
          instanceId: 'plan-peer',
        ),
      ],
      inventory: inventory,
    );

    expect(transferCalls, 0);
    expect(result.items[0].state, ApplyItemState.failed);
    expect(result.items[0].reason, kNoRoomInVaultMessage);
  });

  test('never evicts equipped or plan items when making room', () async {
    final transfers = <TransferItemArgs>[];
    final client = createMockWriteClient(
      transferItem: (c, a) async => transfers.add(a),
      equipItems: (c, a) async => [
            for (final id in a.itemIds)
              EquipItemResultEntry(
                instanceId: id,
                equipStatus: kPlatformErrorSuccess,
              ),
          ],
    );

    final inventory = <ApplyInventoryItem>[
      const ApplyInventoryItem(
        instanceId: 'vault-1',
        itemHash: 1,
        location: 'vault',
        bucketHash: helmetBucket,
      ),
      const ApplyInventoryItem(
        instanceId: 'equipped',
        itemHash: 10,
        location: 'equipped',
        bucketHash: helmetBucket,
        characterId: target,
        power: 1,
        name: 'Equipped Low Power',
      ),
      const ApplyInventoryItem(
        instanceId: 'plan-peer',
        itemHash: 2,
        location: 'character',
        bucketHash: helmetBucket,
        characterId: target,
        power: 1,
        name: 'Plan Peer',
      ),
      for (var i = 0; i < 8; i++)
        ApplyInventoryItem(
          instanceId: 'fill-$i',
          itemHash: 50 + i,
          location: 'character',
          bucketHash: helmetBucket,
          characterId: target,
          power: 100 + i,
          name: 'Filler $i',
        ),
    ];

    await applyToCharacter(
      writeClient: client,
      ctx: ctx,
      characterId: target,
      items: const [
        ApplyToCharacterItem(
          id: 'a',
          label: 'A',
          itemHash: 1,
          instanceId: 'vault-1',
        ),
        ApplyToCharacterItem(
          id: 'b',
          label: 'B',
          itemHash: 2,
          instanceId: 'plan-peer',
        ),
      ],
      inventory: inventory,
    );

    final evicted = transfers.where((t) => t.transferToVault).toList();
    expect(evicted, isNotEmpty);
    for (final e in evicted) {
      expect(e.instanceId, isNot(anyOf('equipped', 'plan-peer', 'vault-1')));
    }
  });

  test('labels: exotic weapon/armor annotated; never primary alone', () async {
    final client = createMockWriteClient(
      equipItems: (c, a) async => [
            for (final id in a.itemIds)
              EquipItemResultEntry(
                instanceId: id,
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
          id: 'exo-w',
          label: 'primary',
          itemHash: 9001,
          instanceId: 'exo-w',
          slot: 'primary',
          isExotic: true,
        ),
        ApplyToCharacterItem(
          id: 'exo-a',
          label: 'Briarbinds',
          itemHash: 9002,
          instanceId: 'exo-a',
          slot: 'arms',
          isExotic: true,
        ),
        ApplyToCharacterItem(
          id: 'named-w',
          label: 'Barrow-Dyad',
          itemHash: 9003,
          instanceId: 'named-w',
          slot: 'primary',
          isExotic: true,
        ),
      ],
      inventory: const [
        ApplyInventoryItem(
          instanceId: 'exo-w',
          itemHash: 9001,
          location: 'character',
          bucketHash: 1498876634,
          characterId: target,
          isExotic: true,
        ),
        ApplyInventoryItem(
          instanceId: 'exo-a',
          itemHash: 9002,
          location: 'character',
          bucketHash: armsBucket,
          characterId: target,
          isExotic: true,
        ),
        ApplyInventoryItem(
          instanceId: 'named-w',
          itemHash: 9003,
          location: 'character',
          bucketHash: 1498876634,
          characterId: target,
          isExotic: true,
        ),
      ],
    );

    expect(result.items[0].label, isNot('primary'));
    expect(result.items[0].label, isNot(contains('None')));
    // Slot-key fallback when name is unknown: readable exotic kind.
    expect(result.items[0].label, 'Exotic weapon');
    expect(result.items[1].label, 'Briarbinds (Exotic armor)');
    expect(result.items[2].label, 'Barrow-Dyad (Exotic weapon)');
  });

  test(
    'planned make-room counts toward 2-attempt limit (R3): at most 2 evictions',
    () async {
      final transfers = <TransferItemArgs>[];
      final client = createMockWriteClient(
        transferItem: (c, a) async {
          transfers.add(a);
          if (!a.transferToVault && a.instanceId == 'vault-1') {
            throw const BungiePlatformException(
              'Bungie API error: No room',
              errorCode: kDestinyNoRoomInDestination,
              errorStatus: 'DestinyNoRoomInDestination',
            );
          }
        },
        equipItems: (c, a) async => const [],
      );

      // Full bucket → planner schedules 1 eviction (counts as attempt 1).
      // Runtime 1642 allows one more eviction (attempt 2), then stops.
      final inventory = <ApplyInventoryItem>[
        const ApplyInventoryItem(
          instanceId: 'vault-1',
          itemHash: 1,
          location: 'vault',
          bucketHash: helmetBucket,
          name: 'Target',
        ),
        const ApplyInventoryItem(
          instanceId: 'eq',
          itemHash: 10,
          location: 'equipped',
          bucketHash: helmetBucket,
          characterId: target,
          power: 200,
        ),
        for (var i = 0; i < 9; i++)
          ApplyInventoryItem(
            instanceId: 'fill-$i',
            itemHash: 50 + i,
            location: 'character',
            bucketHash: helmetBucket,
            characterId: target,
            power: i,
            name: 'Filler $i',
          ),
      ];

      final result = await applyToCharacter(
        writeClient: client,
        ctx: ctx,
        characterId: target,
        items: const [
          ApplyToCharacterItem(
            id: 'helmet',
            label: 'Target Helm',
            itemHash: 1,
            instanceId: 'vault-1',
            slot: 'helmet',
          ),
        ],
        inventory: inventory,
      );

      final evictions =
          transfers.where((t) => t.transferToVault).map((t) => t.instanceId);
      expect(evictions.length, 2);
      expect(evictions, ['fill-0', 'fill-1']);
      expect(result.items.first.state, ApplyItemState.failed);
      expect(
        result.items.first.reason,
        kMakeRoomStillFullMessage('Target Helm'),
      );
    },
  );

  test('TransferItem 1637 at run time: make-room then retry succeeds', () async {
    final transfers = <TransferItemArgs>[];
    var vaultPullAttempts = 0;
    final client = createMockWriteClient(
      transferItem: (c, a) async {
        transfers.add(a);
        if (!a.transferToVault && a.instanceId == 'vault-1') {
          vaultPullAttempts += 1;
          if (vaultPullAttempts == 1) {
            throw const BungiePlatformException(
              'Bungie API error: Inventory full',
              errorCode: kDestinyInventoryFull,
              errorStatus: 'DestinyInventoryFull',
            );
          }
        }
      },
      equipItems: (c, a) async => [
            for (final id in a.itemIds)
              EquipItemResultEntry(
                instanceId: id,
                equipStatus: kPlatformErrorSuccess,
              ),
          ],
    );

    final inventory = <ApplyInventoryItem>[
      const ApplyInventoryItem(
        instanceId: 'vault-1',
        itemHash: 1,
        location: 'vault',
        bucketHash: helmetBucket,
        name: 'Lustrous Boots',
      ),
      const ApplyInventoryItem(
        instanceId: 'eq',
        itemHash: 10,
        location: 'equipped',
        bucketHash: helmetBucket,
        characterId: target,
        power: 200,
      ),
      for (var i = 0; i < 8; i++)
        ApplyInventoryItem(
          instanceId: 'fill-$i',
          itemHash: 50 + i,
          location: 'character',
          bucketHash: helmetBucket,
          characterId: target,
          power: 10 + i,
          name: 'Filler $i',
        ),
    ];

    final result = await applyToCharacter(
      writeClient: client,
      ctx: ctx,
      characterId: target,
      items: const [
        ApplyToCharacterItem(
          id: 'boots',
          label: 'Lustrous Boots',
          itemHash: 1,
          instanceId: 'vault-1',
          slot: 'legs',
        ),
      ],
      inventory: inventory,
    );

    expect(transfers.map((t) => t.instanceId).toList(), [
      'vault-1',
      'fill-0',
      'vault-1',
    ]);
    expect(result.appliedCount, 1);
  });

  test('never evicts an item on another character in the same bucket', () async {
    final transfers = <TransferItemArgs>[];
    final client = createMockWriteClient(
      transferItem: (c, a) async => transfers.add(a),
      equipItems: (c, a) async => [
            for (final id in a.itemIds)
              EquipItemResultEntry(
                instanceId: id,
                equipStatus: kPlatformErrorSuccess,
              ),
          ],
    );

    final inventory = <ApplyInventoryItem>[
      const ApplyInventoryItem(
        instanceId: 'vault-1',
        itemHash: 1,
        location: 'vault',
        bucketHash: helmetBucket,
      ),
      const ApplyInventoryItem(
        instanceId: 'eq',
        itemHash: 10,
        location: 'equipped',
        bucketHash: helmetBucket,
        characterId: target,
      ),
      // Lowest power overall — but on another character → must not be picked.
      const ApplyInventoryItem(
        instanceId: 'other-junk',
        itemHash: 99,
        location: 'character',
        bucketHash: helmetBucket,
        characterId: 'char-other',
        power: 1,
        name: 'Other Char Junk',
      ),
      for (var i = 0; i < 9; i++)
        ApplyInventoryItem(
          instanceId: 'fill-$i',
          itemHash: 50 + i,
          location: 'character',
          bucketHash: helmetBucket,
          characterId: target,
          power: 50 + i,
          name: 'Filler $i',
        ),
    ];

    await applyToCharacter(
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
      inventory: inventory,
    );

    final evicted = transfers.where((t) => t.transferToVault).toList();
    expect(evicted, isNotEmpty);
    expect(evicted.any((t) => t.instanceId == 'other-junk'), isFalse);
    expect(evicted.first.instanceId, 'fill-0');
  });

  test('never evicts locked, postmaster, or non-transferable items', () async {
    final transfers = <TransferItemArgs>[];
    final client = createMockWriteClient(
      transferItem: (c, a) async => transfers.add(a),
      equipItems: (c, a) async => [
            for (final id in a.itemIds)
              EquipItemResultEntry(
                instanceId: id,
                equipStatus: kPlatformErrorSuccess,
              ),
          ],
    );

    final inventory = <ApplyInventoryItem>[
      const ApplyInventoryItem(
        instanceId: 'vault-1',
        itemHash: 1,
        location: 'vault',
        bucketHash: helmetBucket,
      ),
      const ApplyInventoryItem(
        instanceId: 'eq',
        itemHash: 10,
        location: 'equipped',
        bucketHash: helmetBucket,
        characterId: target,
      ),
      const ApplyInventoryItem(
        instanceId: 'locked-low',
        itemHash: 11,
        location: 'character',
        bucketHash: helmetBucket,
        characterId: target,
        power: 1,
        isLocked: true,
        name: 'Locked',
      ),
      const ApplyInventoryItem(
        instanceId: 'no-xfer',
        itemHash: 12,
        location: 'character',
        bucketHash: helmetBucket,
        characterId: target,
        power: 2,
        isTransferable: false,
        name: 'Bound',
      ),
      const ApplyInventoryItem(
        instanceId: 'pm',
        itemHash: 13,
        location: 'postmaster',
        bucketHash: helmetBucket,
        characterId: target,
        power: 3,
        name: 'Postmaster',
      ),
      for (var i = 0; i < 7; i++)
        ApplyInventoryItem(
          instanceId: 'fill-$i',
          itemHash: 50 + i,
          location: 'character',
          bucketHash: helmetBucket,
          characterId: target,
          power: 100 + i,
          name: 'Filler $i',
        ),
    ];

    await applyToCharacter(
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
      inventory: inventory,
    );

    final evictedIds =
        transfers.where((t) => t.transferToVault).map((t) => t.instanceId);
    expect(evictedIds, isNot(contains('locked-low')));
    expect(evictedIds, isNot(contains('no-xfer')));
    expect(evictedIds, isNot(contains('pm')));
    expect(evictedIds.first, 'fill-0');
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
  Future<void> insertSocketPlugFree(
    WriteClientContext ctx,
    InsertSocketPlugFreeArgs args,
  ) async {}

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
