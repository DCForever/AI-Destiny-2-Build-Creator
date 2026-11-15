import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:test/test.dart';

void main() {
  const ctx = WriteClientContext(accessToken: 'test-token', membershipType: 3);
  const target = 'char-1';
  const helmetBucket = 3448274439;
  const subclassBucket = kSubclassBucketHash;

  group('planApplySockets', () {
    test('orders super → abilities → aspects → fragments; skips no-ops', () {
      const subclassHash = 100;
      const superHash = 11;
      const aspectHash = 21;
      const fragmentHash = 31;

      final manifest = ApplySocketManifestLookup(
        itemDef: (h) {
          if (h == subclassHash) {
            return const ApplyManifestItemDef(
              hash: subclassHash,
              name: 'Broodweaver',
              socketCategories: [
                ApplyManifestSocketCategory(
                  socketCategoryHash: 457473665, // Super
                  socketIndexes: [0],
                ),
                ApplyManifestSocketCategory(
                  socketCategoryHash: 309722977, // Abilities
                  socketIndexes: [1, 2, 3, 4],
                ),
                ApplyManifestSocketCategory(
                  socketCategoryHash: 2047681910, // Aspects
                  socketIndexes: [5, 6],
                ),
                ApplyManifestSocketCategory(
                  socketCategoryHash: 271461480, // Fragments
                  socketIndexes: [7, 8, 9],
                ),
              ],
            );
          }
          return null;
        },
        plugDef: (h) {
          switch (h) {
            case superHash:
              return const ApplyManifestPlugDef(
                hash: superHash,
                name: 'Needlestorm',
                plugCategoryIdentifier: 'warlock.strand.supers',
              );
            case 12:
              return const ApplyManifestPlugDef(
                hash: 12,
                name: 'Healing Rift',
                plugCategoryIdentifier: 'warlock.strand.class_abilities',
              );
            case aspectHash:
              return const ApplyManifestPlugDef(
                hash: aspectHash,
                name: "Weaver's Call",
                plugCategoryIdentifier: 'warlock.strand.aspects',
              );
            case fragmentHash:
              return const ApplyManifestPlugDef(
                hash: fragmentHash,
                name: 'Thread of Fury',
                plugCategoryIdentifier: 'shared.strand.fragments',
              );
            default:
              return null;
          }
        },
        resolveUniquePlugHashByName: (_) => null,
      );

      final plan = planApplySockets(
        characterId: target,
        build: const ApplyBuildSocketInputs(
          subclassHash: subclassHash,
          subclassName: 'Broodweaver',
          subclassPlugs: [
            ApplyNamedPlug(name: "Weaver's Call", hash: aspectHash),
            ApplyNamedPlug(name: 'Needlestorm', hash: superHash),
            ApplyNamedPlug(name: 'Thread of Fury', hash: fragmentHash),
            ApplyNamedPlug(name: 'Healing Rift', hash: 12),
          ],
        ),
        manifest: manifest,
        instances: const [
          ApplyInstanceSocketState(
            instanceId: 'sub-1',
            itemHash: subclassHash,
            bucketHash: subclassBucket,
            characterId: target,
            location: 'equipped',
            equippedPlugBySocket: {
              0: superHash, // already Needlestorm — no-op
              5: 999, // different aspect
            },
            ownedPlugHashes: {superHash, 12, aspectHash, fragmentHash},
          ),
        ],
        equippedArmor: const [],
      );

      expect(plan.subclassMissingReason, isNull);
      expect(plan.subclassAlreadyEquipped, isTrue);
      expect(plan.subclassPlugs.map((s) => s.kind).toList(), [
        ApplyPlugKind.superAbility,
        ApplyPlugKind.classAbility,
        ApplyPlugKind.aspect,
        ApplyPlugKind.fragment,
      ]);
      expect(plan.subclassPlugs[0].shouldCall, isFalse); // already equipped
      expect(plan.subclassPlugs[0].label, 'Super: Needlestorm');
      expect(plan.subclassPlugs[2].shouldCall, isTrue);
      expect(plan.subclassPlugs[2].label, "Aspect: Weaver's Call");
    });

    test('unowned plug skipped with fixed text; no call', () {
      const subclassHash = 100;
      final manifest = ApplySocketManifestLookup(
        itemDef: (h) => h == subclassHash
            ? const ApplyManifestItemDef(
                hash: subclassHash,
                name: 'Broodweaver',
                socketCategories: [
                  ApplyManifestSocketCategory(
                    socketCategoryHash: 2047681910,
                    socketIndexes: [5],
                  ),
                ],
              )
            : null,
        plugDef: (h) => h == 21
            ? const ApplyManifestPlugDef(
                hash: 21,
                name: "Weaver's Call",
                plugCategoryIdentifier: 'warlock.strand.aspects',
              )
            : null,
        resolveUniquePlugHashByName: (_) => null,
      );

      final plan = planApplySockets(
        characterId: target,
        build: const ApplyBuildSocketInputs(
          subclassHash: subclassHash,
          subclassPlugs: [
            ApplyNamedPlug(name: "Weaver's Call", hash: 21),
          ],
        ),
        manifest: manifest,
        instances: const [
          ApplyInstanceSocketState(
            instanceId: 'sub-1',
            itemHash: subclassHash,
            bucketHash: subclassBucket,
            characterId: target,
            location: 'equipped',
            ownedPlugHashes: {1}, // does not include 21
          ),
        ],
        equippedArmor: const [],
      );

      expect(plan.subclassPlugs, hasLength(1));
      expect(plan.subclassPlugs.single.shouldCall, isFalse);
      expect(
        plan.subclassPlugs.single.skipReason,
        notUnlockedPlugMessage("Weaver's Call"),
      );
    });

    test('unresolvable name skipped with fixed text', () {
      const subclassHash = 100;
      final manifest = ApplySocketManifestLookup(
        itemDef: (h) => h == subclassHash
            ? const ApplyManifestItemDef(
                hash: subclassHash,
                name: 'Broodweaver',
                socketCategories: [
                  ApplyManifestSocketCategory(
                    socketCategoryHash: 2047681910,
                    socketIndexes: [5],
                  ),
                ],
              )
            : null,
        plugDef: (_) => null,
        resolveUniquePlugHashByName: (_) => null,
      );

      final plan = planApplySockets(
        characterId: target,
        build: const ApplyBuildSocketInputs(
          subclassHash: subclassHash,
          subclassPlugs: [
            ApplyNamedPlug(name: 'Ambiguous Aspect'),
          ],
        ),
        manifest: manifest,
        instances: const [
          ApplyInstanceSocketState(
            instanceId: 'sub-1',
            itemHash: subclassHash,
            bucketHash: subclassBucket,
            characterId: target,
            location: 'equipped',
            ownedPlugHashes: {},
          ),
        ],
        equippedArmor: const [],
      );

      expect(
        plan.subclassPlugs.single.skipReason,
        unresolvablePlugMessage('Ambiguous Aspect'),
      );
    });

    test('subclass missing reports fixed reason', () {
      final plan = planApplySockets(
        characterId: target,
        build: const ApplyBuildSocketInputs(
          subclassHash: 100,
          subclassName: 'Broodweaver',
        ),
        manifest: ApplySocketManifestLookup(
          itemDef: (_) => null,
          plugDef: (_) => null,
          resolveUniquePlugHashByName: (_) => null,
        ),
        instances: const [],
        equippedArmor: const [],
      );
      expect(plan.subclassMissingReason, kApplySubclassNotOnCharacterMessage);
      expect(plan.subclassPlugs, isEmpty);
    });

    test('armor mod skips when not enough energy after clears', () {
      const armorHash = 200;
      const modHash = 301;
      final manifest = ApplySocketManifestLookup(
        itemDef: (h) => h == armorHash
            ? const ApplyManifestItemDef(
                hash: armorHash,
                name: 'Helmet',
                socketCategories: [
                  ApplyManifestSocketCategory(
                    socketCategoryHash: 590099826,
                    socketIndexes: [0],
                  ),
                ],
              )
            : null,
        plugDef: (h) => h == modHash
            ? const ApplyManifestPlugDef(
                hash: modHash,
                name: 'Heavy Handed',
                plugCategoryIdentifier: 'enhancements.v2_head',
                energyCost: 5,
              )
            : null,
        resolveUniquePlugHashByName: (_) => null,
      );

      final plan = planApplySockets(
        characterId: target,
        build: const ApplyBuildSocketInputs(
          armorMods: [
            ApplyNamedPlug(name: 'Heavy Handed', hash: modHash),
          ],
        ),
        manifest: manifest,
        instances: const [
          ApplyInstanceSocketState(
            instanceId: 'helm-1',
            itemHash: armorHash,
            bucketHash: helmetBucket,
            characterId: target,
            location: 'equipped',
            energyCapacity: 3,
            energyUsed: 0,
            ownedPlugHashes: {modHash},
          ),
        ],
        equippedArmor: const [
          ApplyArmorPin(
            id: 'helmet',
            label: 'Helmet',
            itemHash: armorHash,
            instanceId: 'helm-1',
          ),
        ],
      );

      expect(plan.armorMods, hasLength(1));
      expect(
        plan.armorMods.single.skipReason,
        notEnoughArmorEnergyMessage('Heavy Handed'),
      );
    });
  });

  group('applyToCharacter socket phase', () {
    test('call order: moves, EquipItems, subclass equip, plugs, mods', () async {
      final calls = <String>[];
      final client = createMockWriteClient(
        transferItem: (c, a) async {
          calls.add('transfer:${a.instanceId}');
        },
        equipItems: (c, a) async {
          calls.add('equipItems:${a.itemIds.join(',')}');
          return [
            for (final id in a.itemIds)
              EquipItemResultEntry(
                instanceId: id,
                equipStatus: kPlatformErrorSuccess,
              ),
          ];
        },
        equipItem: (c, a) async {
          calls.add('equipItem:${a.instanceId}');
        },
        insertSocketPlugFree: (c, a) async {
          calls.add(
            'plug:${a.itemId}:${a.socketIndex}:${a.plugItemHash}',
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
            label: 'Helmet A',
            itemHash: 1,
            instanceId: 'vault-1',
            slot: 'helmet',
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
        socketPlan: const ApplySocketPlan(
          subclass: ApplySubclassPin(
            id: 'subclass:sub-1',
            label: 'Broodweaver',
            itemHash: 100,
            instanceId: 'sub-1',
          ),
          subclassAlreadyEquipped: false,
          subclassPlugs: [
            ApplyPlugStep(
              id: 'plug-super',
              label: 'Super: Needlestorm',
              kind: ApplyPlugKind.superAbility,
              itemInstanceId: 'sub-1',
              socketIndex: 0,
              plugItemHash: 11,
              currentPlugHash: 0,
            ),
            ApplyPlugStep(
              id: 'plug-aspect',
              label: "Aspect: Weaver's Call",
              kind: ApplyPlugKind.aspect,
              itemInstanceId: 'sub-1',
              socketIndex: 5,
              plugItemHash: 21,
              currentPlugHash: 0,
            ),
          ],
          armorMods: [
            ApplyPlugStep(
              id: 'plug-mod',
              label: 'Mod: Heavy Handed',
              kind: ApplyPlugKind.armorMod,
              itemInstanceId: 'vault-1',
              socketIndex: 0,
              plugItemHash: 301,
              currentPlugHash: 0,
            ),
          ],
        ),
      );

      expect(calls, [
        'transfer:vault-1',
        'equipItems:vault-1',
        'equipItem:sub-1',
        'plug:sub-1:0:11',
        'plug:sub-1:5:21',
        'plug:vault-1:0:301',
      ]);
      expect(
        result.items.map((i) => i.label).toList(),
        containsAll([
          'Helmet A',
          'Broodweaver',
          'Super: Needlestorm',
          "Aspect: Weaver's Call",
          'Mod: Heavy Handed',
        ]),
      );
      expect(
        result.items.where((i) => i.state == ApplyItemState.done).length,
        greaterThanOrEqualTo(5),
      );
    });

    test('no insertSocketPlugFree call when socket already has target', () async {
      final plugCalls = <InsertSocketPlugFreeArgs>[];
      final client = createMockWriteClient(
        equipItems: (c, a) async => [
          for (final id in a.itemIds)
            EquipItemResultEntry(
              instanceId: id,
              equipStatus: kPlatformErrorSuccess,
            ),
        ],
        insertSocketPlugFree: (c, a) async => plugCalls.add(a),
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
        socketPlan: const ApplySocketPlan(
          subclassAlreadyEquipped: true,
          subclass: ApplySubclassPin(
            id: 'subclass:sub-1',
            label: 'Broodweaver',
            itemHash: 100,
            instanceId: 'sub-1',
          ),
          subclassPlugs: [
            ApplyPlugStep(
              id: 'plug-aspect',
              label: "Aspect: Weaver's Call",
              kind: ApplyPlugKind.aspect,
              itemInstanceId: 'sub-1',
              socketIndex: 5,
              plugItemHash: 21,
              currentPlugHash: 21,
            ),
          ],
        ),
      );

      expect(plugCalls, isEmpty);
      final aspect = result.items.firstWhere((i) => i.id == 'plug-aspect');
      expect(aspect.state, ApplyItemState.done);
    });

    test('skip reason rows make no call', () async {
      final plugCalls = <InsertSocketPlugFreeArgs>[];
      final client = createMockWriteClient(
        equipItems: (c, a) async => [
          for (final id in a.itemIds)
            EquipItemResultEntry(
              instanceId: id,
              equipStatus: kPlatformErrorSuccess,
            ),
        ],
        insertSocketPlugFree: (c, a) async => plugCalls.add(a),
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
        socketPlan: ApplySocketPlan(
          subclassPlugs: [
            ApplyPlugStep(
              id: 'plug-aspect',
              label: "Aspect: Weaver's Call",
              kind: ApplyPlugKind.aspect,
              itemInstanceId: 'sub-1',
              socketIndex: 5,
              plugItemHash: 21,
              skipReason: notUnlockedPlugMessage("Weaver's Call"),
            ),
          ],
        ),
      );

      expect(plugCalls, isEmpty);
      expect(
        result.items.firstWhere((i) => i.id == 'plug-aspect').reason,
        notUnlockedPlugMessage("Weaver's Call"),
      );
    });

    test('in-activity during plug stops remaining socket steps', () async {
      final plugCalls = <int>[];
      final client = createMockWriteClient(
        equipItems: (c, a) async => [
          for (final id in a.itemIds)
            EquipItemResultEntry(
              instanceId: id,
              equipStatus: kPlatformErrorSuccess,
            ),
        ],
        insertSocketPlugFree: (c, a) async {
          plugCalls.add(a.plugItemHash);
          if (a.plugItemHash == 11) {
            throw const BungiePlatformException(
              'in activity',
              errorCode: kDestinyCannotPerformActionAtThisLocation,
              errorStatus: 'DestinyCannotPerformActionAtThisLocation',
            );
          }
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
        socketPlan: const ApplySocketPlan(
          subclassAlreadyEquipped: true,
          subclass: ApplySubclassPin(
            id: 'subclass:sub-1',
            label: 'Broodweaver',
            itemHash: 100,
            instanceId: 'sub-1',
          ),
          subclassPlugs: [
            ApplyPlugStep(
              id: 'plug-super',
              label: 'Super: Needlestorm',
              kind: ApplyPlugKind.superAbility,
              itemInstanceId: 'sub-1',
              socketIndex: 0,
              plugItemHash: 11,
              currentPlugHash: 0,
            ),
            ApplyPlugStep(
              id: 'plug-aspect',
              label: "Aspect: Weaver's Call",
              kind: ApplyPlugKind.aspect,
              itemInstanceId: 'sub-1',
              socketIndex: 5,
              plugItemHash: 21,
              currentPlugHash: 0,
            ),
          ],
          armorMods: [
            ApplyPlugStep(
              id: 'plug-mod',
              label: 'Mod: Heavy Handed',
              kind: ApplyPlugKind.armorMod,
              itemInstanceId: 'i1',
              socketIndex: 0,
              plugItemHash: 301,
              currentPlugHash: 0,
            ),
          ],
        ),
      );

      expect(plugCalls, [11]); // aspect + mod never called
      expect(
        result.items.firstWhere((i) => i.id == 'plug-super').reason,
        kInActivityEquipMessage,
      );
      expect(
        result.items.firstWhere((i) => i.id == 'plug-aspect').reason,
        kInActivityEquipMessage,
      );
      expect(
        result.items.firstWhere((i) => i.id == 'plug-mod').reason,
        kInActivityEquipMessage,
      );
    });
  });
}
