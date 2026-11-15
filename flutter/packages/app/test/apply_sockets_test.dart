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
              socketPlugCategoryHint: {
                0: 'warlock.strand.supers',
                1: 'warlock.strand.class_abilities',
                2: 'warlock.strand.movement',
                3: 'warlock.strand.melee',
                4: 'warlock.strand.grenades',
                5: 'warlock.strand.aspects',
                6: 'warlock.strand.aspects',
                7: 'shared.strand.fragments',
                8: 'shared.strand.fragments',
                9: 'shared.strand.fragments',
              },
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
            subclassPlugOwnershipKnown: true,
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
            subclassPlugOwnershipKnown: true,
          ),
        ],
        equippedArmor: const [],
      );

      expect(plan.subclassPlugs, hasLength(1));
      expect(plan.subclassPlugs.single.shouldCall, isFalse);
      expect(
        plan.subclassPlugs.single.skipReason,
        notUnlockedOrUnknownPlugMessage("Weaver's Call"),
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
                allowedPlugHashesBySocket: {
                  0: {modHash},
                },
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
            armorModDataKnown: true,
            allowedPlugHashesBySocket: {
              0: {modHash},
            },
          ),
        ],
        equippedArmor: const [
          ApplyArmorPin(
            id: 'helmet',
            label: 'Helmet',
            itemHash: armorHash,
            instanceId: 'helm-1',
            slot: 'helmet',
          ),
        ],
      );

      expect(plan.armorMods, hasLength(1));
      expect(
        plan.armorMods.single.skipReason,
        notEnoughArmorEnergyMessage('Heavy Handed'),
      );
    });

    test('R1: head mod never placed on gauntlets', () {
      const helmHash = 200;
      const armsHash = 201;
      const headMod = 301;
      final manifest = ApplySocketManifestLookup(
        itemDef: (h) {
          if (h == helmHash || h == armsHash) {
            return ApplyManifestItemDef(
              hash: h,
              name: h == helmHash ? 'Helmet' : 'Gauntlets',
              socketCategories: const [
                ApplyManifestSocketCategory(
                  socketCategoryHash: 590099826,
                  socketIndexes: [0, 1],
                ),
              ],
              allowedPlugHashesBySocket: {
                0: {headMod},
                1: {headMod},
              },
            );
          }
          return null;
        },
        plugDef: (h) => h == headMod
            ? const ApplyManifestPlugDef(
                hash: headMod,
                name: 'Hands-On',
                plugCategoryIdentifier: 'enhancements.v2_head',
                energyCost: 1,
              )
            : null,
        resolveUniquePlugHashByName: (_) => null,
      );

      final plan = planApplySockets(
        characterId: target,
        build: const ApplyBuildSocketInputs(
          armorMods: [
            ApplyNamedPlug(name: 'Hands-On', hash: headMod),
          ],
        ),
        manifest: manifest,
        instances: const [
          ApplyInstanceSocketState(
            instanceId: 'arms-1',
            itemHash: armsHash,
            bucketHash: 3551918588, // gauntlets
            characterId: target,
            location: 'equipped',
            energyCapacity: 10,
            energyUsed: 0,
            ownedPlugHashes: {headMod},
            armorModDataKnown: true,
            allowedPlugHashesBySocket: {
              0: {headMod},
            },
          ),
        ],
        equippedArmor: const [
          ApplyArmorPin(
            id: 'arms',
            label: 'Gauntlets',
            itemHash: armsHash,
            instanceId: 'arms-1',
            slot: 'arms',
          ),
        ],
      );

      expect(plan.armorMods, isNotEmpty);
      expect(
        plan.armorMods.every((s) => s.itemInstanceId != 'arms-1' || s.skipReason != null),
        isTrue,
      );
      expect(
        plan.armorMods.any((s) => s.shouldCall && s.itemInstanceId == 'arms-1'),
        isFalse,
      );
      expect(
        plan.armorMods.single.skipReason,
        doesNotFitPlugMessage('Hands-On'),
      );
      // Helmet pin present → places on helmet only.
      final withHelm = planApplySockets(
        characterId: target,
        build: const ApplyBuildSocketInputs(
          armorMods: [
            ApplyNamedPlug(name: 'Hands-On', hash: headMod),
          ],
        ),
        manifest: manifest,
        instances: const [
          ApplyInstanceSocketState(
            instanceId: 'helm-1',
            itemHash: helmHash,
            bucketHash: helmetBucket,
            characterId: target,
            location: 'equipped',
            energyCapacity: 10,
            energyUsed: 0,
            ownedPlugHashes: {headMod},
            armorModDataKnown: true,
            allowedPlugHashesBySocket: {
              0: {headMod},
            },
          ),
          ApplyInstanceSocketState(
            instanceId: 'arms-1',
            itemHash: armsHash,
            bucketHash: 3551918588,
            characterId: target,
            location: 'equipped',
            energyCapacity: 10,
            energyUsed: 0,
            ownedPlugHashes: {headMod},
            armorModDataKnown: true,
            allowedPlugHashesBySocket: {
              0: {headMod},
            },
          ),
        ],
        equippedArmor: const [
          ApplyArmorPin(
            id: 'helmet',
            label: 'Helmet',
            itemHash: helmHash,
            instanceId: 'helm-1',
            slot: 'helmet',
          ),
          ApplyArmorPin(
            id: 'arms',
            label: 'Gauntlets',
            itemHash: armsHash,
            instanceId: 'arms-1',
            slot: 'arms',
          ),
        ],
      );
      final inserts = withHelm.armorMods.where((s) => s.shouldCall).toList();
      expect(inserts, hasLength(1));
      expect(inserts.single.itemInstanceId, 'helm-1');
    });

    test('R1: general mod placed once, not five times', () {
      const generalMod = 401;
      ApplyManifestItemDef armorDef(int hash) => ApplyManifestItemDef(
            hash: hash,
            name: 'Armor $hash',
            socketCategories: const [
              ApplyManifestSocketCategory(
                socketCategoryHash: 590099826,
                socketIndexes: [0],
              ),
            ],
            allowedPlugHashesBySocket: {
              0: {generalMod},
            },
          );
      final manifest = ApplySocketManifestLookup(
        itemDef: armorDef,
        plugDef: (h) => h == generalMod
            ? const ApplyManifestPlugDef(
                hash: generalMod,
                name: 'Powerful Friends',
                plugCategoryIdentifier: 'enhancements.v2_general',
                energyCost: 1,
              )
            : null,
        resolveUniquePlugHashByName: (_) => null,
      );
      final pieces = <ApplyArmorPin>[
        for (var i = 0; i < 5; i++)
          ApplyArmorPin(
            id: 'a$i',
            label: 'Piece $i',
            itemHash: 500 + i,
            instanceId: 'inst-$i',
            slot: const ['helmet', 'arms', 'chest', 'legs', 'class_item'][i],
          ),
      ];
      final instances = [
        for (var i = 0; i < 5; i++)
          ApplyInstanceSocketState(
            instanceId: 'inst-$i',
            itemHash: 500 + i,
            bucketHash: helmetBucket,
            characterId: target,
            location: 'equipped',
            energyCapacity: 10,
            energyUsed: 0,
            ownedPlugHashes: {generalMod},
            armorModDataKnown: true,
            allowedPlugHashesBySocket: {
              0: {generalMod},
            },
          ),
      ];
      final plan = planApplySockets(
        characterId: target,
        build: const ApplyBuildSocketInputs(
          armorMods: [
            ApplyNamedPlug(name: 'Powerful Friends', hash: generalMod),
          ],
        ),
        manifest: manifest,
        instances: instances,
        equippedArmor: pieces,
      );
      final inserts = plan.armorMods.where((s) => s.shouldCall).toList();
      expect(inserts, hasLength(1));
      expect(inserts.single.plugItemHash, generalMod);
    });

    test('R2: socketIndex per plug kind; grenade never in super socket', () {
      const subclassHash = 100;
      const superHash = 11;
      const grenadeHash = 14;
      final manifest = ApplySocketManifestLookup(
        itemDef: (h) => h == subclassHash
            ? const ApplyManifestItemDef(
                hash: subclassHash,
                name: 'Broodweaver',
                socketCategories: [
                  ApplyManifestSocketCategory(
                    socketCategoryHash: 457473665,
                    socketIndexes: [0],
                  ),
                  ApplyManifestSocketCategory(
                    socketCategoryHash: 309722977,
                    socketIndexes: [1, 2, 3, 4],
                  ),
                ],
                socketPlugCategoryHint: {
                  0: 'warlock.strand.supers',
                  1: 'warlock.strand.class_abilities',
                  2: 'warlock.strand.movement',
                  3: 'warlock.strand.melee',
                  4: 'warlock.strand.grenades',
                },
              )
            : null,
        plugDef: (h) {
          switch (h) {
            case superHash:
              return const ApplyManifestPlugDef(
                hash: superHash,
                name: 'Needlestorm',
                plugCategoryIdentifier: 'warlock.strand.supers',
              );
            case grenadeHash:
              return const ApplyManifestPlugDef(
                hash: grenadeHash,
                name: 'Threadling Grenade',
                plugCategoryIdentifier: 'warlock.strand.grenades',
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
          subclassPlugs: [
            ApplyNamedPlug(name: 'Needlestorm', hash: superHash),
            ApplyNamedPlug(name: 'Threadling Grenade', hash: grenadeHash),
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
            ownedPlugHashes: {superHash, grenadeHash},
            subclassPlugOwnershipKnown: true,
          ),
        ],
        equippedArmor: const [],
      );
      final byKind = {
        for (final s in plan.subclassPlugs) s.kind: s,
      };
      expect(byKind[ApplyPlugKind.superAbility]!.socketIndex, 0);
      expect(byKind[ApplyPlugKind.grenade]!.socketIndex, 4);
      expect(byKind[ApplyPlugKind.grenade]!.socketIndex, isNot(0));
    });

    test('R3: unknown armor mod data → single fixed skip row', () {
      const modHash = 301;
      final manifest = ApplySocketManifestLookup(
        itemDef: (h) => const ApplyManifestItemDef(
          hash: 200,
          name: 'Helmet',
          socketCategories: [
            ApplyManifestSocketCategory(
              socketCategoryHash: 590099826,
              socketIndexes: [0],
            ),
          ],
        ),
        plugDef: (h) => h == modHash
            ? const ApplyManifestPlugDef(
                hash: modHash,
                name: 'Heavy Handed',
                plugCategoryIdentifier: 'enhancements.v2_head',
                energyCost: 1,
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
            itemHash: 200,
            bucketHash: helmetBucket,
            characterId: target,
            location: 'equipped',
            energyCapacity: 0,
            energyUsed: 0,
            ownedPlugHashes: {},
            armorModDataKnown: false,
          ),
        ],
        equippedArmor: const [
          ApplyArmorPin(
            id: 'helmet',
            label: 'Helmet',
            itemHash: 200,
            instanceId: 'helm-1',
            slot: 'helmet',
          ),
        ],
      );
      expect(plan.armorMods, hasLength(1));
      expect(
        plan.armorMods.single.skipReason,
        kArmorModsSkippedUnavailableMessage,
      );
      expect(plan.armorMods.single.shouldCall, isFalse);
    });

    test('R4: skipped insert plans no clear', () {
      const armorHash = 200;
      const expensive = 301;
      const cheap = 302;
      final manifest = ApplySocketManifestLookup(
        itemDef: (h) => h == armorHash
            ? const ApplyManifestItemDef(
                hash: armorHash,
                name: 'Helmet',
                socketCategories: [
                  ApplyManifestSocketCategory(
                    socketCategoryHash: 590099826,
                    socketIndexes: [0, 1],
                  ),
                ],
                allowedPlugHashesBySocket: {
                  0: {expensive},
                  1: {cheap},
                },
              )
            : null,
        plugDef: (h) {
          switch (h) {
            case expensive:
              return const ApplyManifestPlugDef(
                hash: expensive,
                name: 'Expensive Mod',
                plugCategoryIdentifier: 'enhancements.v2_head',
                energyCost: 10,
              );
            case cheap:
              return const ApplyManifestPlugDef(
                hash: cheap,
                name: 'Cheap Mod',
                plugCategoryIdentifier: 'enhancements.v2_head',
                energyCost: 3,
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
          armorMods: [
            ApplyNamedPlug(name: 'Expensive Mod', hash: expensive),
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
            energyCapacity: 5,
            energyUsed: 3,
            ownedPlugHashes: {expensive, cheap},
            armorModDataKnown: true,
            equippedPlugBySocket: {1: cheap},
            emptyPlugHashBySocket: {1: 999},
            allowedPlugHashesBySocket: {
              0: {expensive},
              1: {cheap},
            },
          ),
        ],
        equippedArmor: const [
          ApplyArmorPin(
            id: 'helmet',
            label: 'Helmet',
            itemHash: armorHash,
            instanceId: 'helm-1',
            slot: 'helmet',
          ),
        ],
      );
      expect(
        plan.armorMods.any((s) => s.kind == ApplyPlugKind.armorModClear),
        isFalse,
      );
      expect(
        plan.armorMods.single.skipReason,
        notEnoughArmorEnergyMessage('Expensive Mod'),
      );
    });

    test('subclass match ignores vault (null characterId)', () {
      final plan = planApplySockets(
        characterId: target,
        build: const ApplyBuildSocketInputs(
          subclassHash: 100,
          subclassName: 'Broodweaver',
        ),
        manifest: ApplySocketManifestLookup(
          itemDef: (h) => h == 100
              ? const ApplyManifestItemDef(hash: 100, name: 'Broodweaver')
              : null,
          plugDef: (_) => null,
          resolveUniquePlugHashByName: (_) => null,
        ),
        instances: const [
          ApplyInstanceSocketState(
            instanceId: 'vault-sub',
            itemHash: 100,
            bucketHash: subclassBucket,
            characterId: null,
            location: 'vault',
          ),
        ],
        equippedArmor: const [],
      );
      expect(plan.subclassMissingReason, kApplySubclassNotOnCharacterMessage);
    });

    test('F1: reserves wanted fragment sockets before free fills', () {
      const subclassHash = 100;
      const f1 = 71;
      const f3 = 73;
      const x = 99;
      final manifest = ApplySocketManifestLookup(
        itemDef: (h) => h == subclassHash
            ? const ApplyManifestItemDef(
                hash: subclassHash,
                name: 'Broodweaver',
                socketCategories: [
                  ApplyManifestSocketCategory(
                    socketCategoryHash: 271461480,
                    socketIndexes: [7, 8, 9],
                  ),
                ],
              )
            : null,
        plugDef: (h) {
          switch (h) {
            case f1:
              return const ApplyManifestPlugDef(
                hash: f1,
                name: 'Thread of Fury',
                plugCategoryIdentifier: 'shared.strand.fragments',
              );
            case f3:
              return const ApplyManifestPlugDef(
                hash: f3,
                name: 'Thread of Winding',
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
          subclassPlugs: [
            ApplyNamedPlug(name: 'Thread of Winding', hash: f3),
            ApplyNamedPlug(name: 'Thread of Fury', hash: f1),
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
            equippedPlugBySocket: {7: f1, 8: x},
            ownedPlugHashes: {f1, f3},
            subclassPlugOwnershipKnown: true,
          ),
        ],
        equippedArmor: const [],
      );
      final byHash = {for (final s in plan.subclassPlugs) s.plugItemHash: s};
      expect(byHash[f1]!.socketIndex, 7);
      expect(byHash[f1]!.shouldCall, isFalse);
      expect(byHash[f3]!.socketIndex, 8);
      expect(byHash[f3]!.shouldCall, isTrue);
    });

    test('F1: reserves wanted aspect sockets before free fills', () {
      const subclassHash = 100;
      const a1 = 51;
      const a2 = 52;
      const other = 59;
      final manifest = ApplySocketManifestLookup(
        itemDef: (h) => h == subclassHash
            ? const ApplyManifestItemDef(
                hash: subclassHash,
                name: 'Broodweaver',
                socketCategories: [
                  ApplyManifestSocketCategory(
                    socketCategoryHash: 2047681910,
                    socketIndexes: [5, 6],
                  ),
                ],
              )
            : null,
        plugDef: (h) {
          switch (h) {
            case a1:
              return const ApplyManifestPlugDef(
                hash: a1,
                name: "Weaver's Call",
                plugCategoryIdentifier: 'warlock.strand.aspects',
              );
            case a2:
              return const ApplyManifestPlugDef(
                hash: a2,
                name: 'Mindspun Invocation',
                plugCategoryIdentifier: 'warlock.strand.aspects',
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
          subclassPlugs: [
            ApplyNamedPlug(name: 'Mindspun Invocation', hash: a2),
            ApplyNamedPlug(name: "Weaver's Call", hash: a1),
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
            equippedPlugBySocket: {5: a1, 6: other},
            ownedPlugHashes: {a1, a2},
            subclassPlugOwnershipKnown: true,
          ),
        ],
        equippedArmor: const [],
      );
      final byHash = {for (final s in plan.subclassPlugs) s.plugItemHash: s};
      expect(byHash[a1]!.socketIndex, 5);
      expect(byHash[a1]!.shouldCall, isFalse);
      expect(byHash[a2]!.socketIndex, 6);
      expect(byHash[a2]!.shouldCall, isTrue);
    });

    test('F2: Prismatic-like layout; extras beyond fragment slots skipped', () {
      const subclassHash = 900;
      // Prismatic-like: fewer fragment sockets (7..9 only), aspects at 10..11.
      const f1 = 81;
      const f2 = 82;
      const f3 = 83;
      const f4 = 84;
      final manifest = ApplySocketManifestLookup(
        itemDef: (h) => h == subclassHash
            ? const ApplyManifestItemDef(
                hash: subclassHash,
                name: 'Prismatic',
                socketCategories: [
                  ApplyManifestSocketCategory(
                    socketCategoryHash: 457473665,
                    socketIndexes: [0],
                  ),
                  ApplyManifestSocketCategory(
                    socketCategoryHash: 309722977,
                    socketIndexes: [1, 2, 3, 4],
                  ),
                  ApplyManifestSocketCategory(
                    socketCategoryHash: 2047681910,
                    socketIndexes: [10, 11],
                  ),
                  ApplyManifestSocketCategory(
                    socketCategoryHash: 271461480,
                    socketIndexes: [7, 8, 9],
                  ),
                ],
                socketPlugCategoryHint: {
                  0: 'shared.supers',
                  10: 'shared.aspects',
                  11: 'shared.aspects',
                },
              )
            : null,
        plugDef: (h) => ApplyManifestPlugDef(
          hash: h,
          name: 'Frag $h',
          plugCategoryIdentifier: 'shared.fragments',
        ),
        resolveUniquePlugHashByName: (_) => null,
      );
      final plan = planApplySockets(
        characterId: target,
        build: const ApplyBuildSocketInputs(
          subclassHash: subclassHash,
          subclassPlugs: [
            ApplyNamedPlug(name: 'Frag 81', hash: f1),
            ApplyNamedPlug(name: 'Frag 82', hash: f2),
            ApplyNamedPlug(name: 'Frag 83', hash: f3),
            ApplyNamedPlug(name: 'Frag 84', hash: f4),
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
            ownedPlugHashes: {f1, f2, f3, f4},
            subclassPlugOwnershipKnown: true,
            unlockedSocketIndexes: {7, 8, 9},
          ),
        ],
        equippedArmor: const [],
      );
      final inserts =
          plan.subclassPlugs.where((s) => s.shouldCall).toList();
      final skipped =
          plan.subclassPlugs.where((s) => s.skipReason != null).toList();
      expect(inserts, hasLength(3));
      expect(inserts.map((s) => s.socketIndex).toSet(), {7, 8, 9});
      expect(skipped, hasLength(1));
      expect(skipped.single.skipReason, noFragmentSocketMessage('Frag 84'));
    });

    test('F2: unresolved subclass layout skips plugs with fixed text', () {
      final plan = planApplySockets(
        characterId: target,
        build: const ApplyBuildSocketInputs(
          subclassHash: 100,
          subclassPlugs: [
            ApplyNamedPlug(name: 'Needlestorm', hash: 11),
          ],
        ),
        manifest: ApplySocketManifestLookup(
          itemDef: (h) => h == 100
              ? const ApplyManifestItemDef(
                  hash: 100,
                  name: 'Broodweaver',
                  // empty categories → unresolved
                )
              : null,
          plugDef: (h) => h == 11
              ? const ApplyManifestPlugDef(
                  hash: 11,
                  name: 'Needlestorm',
                  plugCategoryIdentifier: 'warlock.strand.supers',
                )
              : null,
          resolveUniquePlugHashByName: (_) => null,
        ),
        instances: const [
          ApplyInstanceSocketState(
            instanceId: 'sub-1',
            itemHash: 100,
            bucketHash: subclassBucket,
            characterId: target,
            location: 'equipped',
            ownedPlugHashes: {11},
            subclassPlugOwnershipKnown: true,
          ),
        ],
        equippedArmor: const [],
      );
      expect(
        plan.subclassPlugs.single.skipReason,
        kApplySubclassSocketsUnavailableMessage,
      );
    });

    test('F3: empty owned set is UNKNOWN — skip with fixed text', () {
      const subclassHash = 100;
      final plan = planApplySockets(
        characterId: target,
        build: const ApplyBuildSocketInputs(
          subclassHash: subclassHash,
          subclassPlugs: [
            ApplyNamedPlug(name: "Weaver's Call", hash: 21),
          ],
        ),
        manifest: ApplySocketManifestLookup(
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
        ),
        instances: const [
          ApplyInstanceSocketState(
            instanceId: 'sub-1',
            itemHash: subclassHash,
            bucketHash: subclassBucket,
            characterId: target,
            location: 'equipped',
            ownedPlugHashes: {},
            subclassPlugOwnershipKnown: false,
          ),
        ],
        equippedArmor: const [],
      );
      expect(
        plan.subclassPlugs.single.skipReason,
        notUnlockedOrUnknownPlugMessage("Weaver's Call"),
      );
      expect(plan.subclassPlugs.single.shouldCall, isFalse);
    });

    test('F4: armorModDataKnown false → single skip (host defer contract)', () {
      // Host passes armorModDataKnown:false via kBuildsMockArmorModDataKnown.
      final plan = planApplySockets(
        characterId: target,
        build: const ApplyBuildSocketInputs(
          armorMods: [
            ApplyNamedPlug(name: 'Heavy Handed', hash: 301),
          ],
        ),
        manifest: ApplySocketManifestLookup(
          itemDef: (_) => const ApplyManifestItemDef(
            hash: 200,
            name: 'Helmet',
            socketCategories: [
              ApplyManifestSocketCategory(
                socketCategoryHash: 590099826,
                socketIndexes: [0],
              ),
            ],
          ),
          plugDef: (h) => h == 301
              ? const ApplyManifestPlugDef(
                  hash: 301,
                  name: 'Heavy Handed',
                  plugCategoryIdentifier: 'enhancements.v2_head',
                )
              : null,
          resolveUniquePlugHashByName: (_) => null,
        ),
        instances: const [
          ApplyInstanceSocketState(
            instanceId: 'helm-1',
            itemHash: 200,
            bucketHash: helmetBucket,
            characterId: target,
            location: 'equipped',
            armorModDataKnown: false,
          ),
        ],
        equippedArmor: const [
          ApplyArmorPin(
            id: 'helmet',
            label: 'Helmet',
            itemHash: 200,
            instanceId: 'helm-1',
            slot: 'helmet',
          ),
        ],
      );
      expect(
        plan.armorMods.single.skipReason,
        kArmorModsSkippedUnavailableMessage,
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

    test('R4: failed insert after clear attempts restore once', () async {
      final plugCalls = <String>[];
      final client = createMockWriteClient(
        equipItems: (c, a) async => [
          for (final id in a.itemIds)
            EquipItemResultEntry(
              instanceId: id,
              equipStatus: kPlatformErrorSuccess,
            ),
        ],
        insertSocketPlugFree: (c, a) async {
          plugCalls.add('${a.itemId}:${a.socketIndex}:${a.plugItemHash}');
          if (a.plugItemHash == 301) {
            throw const BungiePlatformException(
              'raw bungie text must not surface',
              errorCode: 1665,
              errorStatus: 'DestinySocketAlreadyHasPlug',
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
          armorMods: [
            ApplyPlugStep(
              id: 'clear-1',
              label: 'Clear mod: Old',
              kind: ApplyPlugKind.armorModClear,
              itemInstanceId: 'i1',
              socketIndex: 1,
              plugItemHash: 999,
              currentPlugHash: 302,
            ),
            ApplyPlugStep(
              id: 'insert-1',
              label: 'Mod: Heavy Handed',
              kind: ApplyPlugKind.armorMod,
              itemInstanceId: 'i1',
              socketIndex: 0,
              plugItemHash: 301,
              currentPlugHash: 0,
              requiresClearStepId: 'clear-1',
              restorePlugHash: 302,
              restoreSocketIndex: 1,
              restoreItemInstanceId: 'i1',
            ),
          ],
        ),
      );

      expect(plugCalls, [
        'i1:1:999', // clear
        'i1:0:301', // insert fails
        'i1:1:302', // restore original
      ]);
      final insertRow = result.items.firstWhere((i) => i.id == 'insert-1');
      expect(insertRow.state, ApplyItemState.failed);
      expect(insertRow.reason, kApplySocketRestoredMessage);
      expect(insertRow.reason!.contains('raw bungie'), isFalse);
    });

    test('failed clear stops its matching insert', () async {
      final plugCalls = <String>[];
      final client = createMockWriteClient(
        equipItems: (c, a) async => [
          for (final id in a.itemIds)
            EquipItemResultEntry(
              instanceId: id,
              equipStatus: kPlatformErrorSuccess,
            ),
        ],
        insertSocketPlugFree: (c, a) async {
          plugCalls.add('${a.socketIndex}:${a.plugItemHash}');
          if (a.plugItemHash == 999) {
            throw const BungiePlatformException(
              'clear failed',
              errorCode: 1665,
              errorStatus: 'DestinySocketAlreadyHasPlug',
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
          armorMods: [
            ApplyPlugStep(
              id: 'clear-1',
              label: 'Clear mod: Old',
              kind: ApplyPlugKind.armorModClear,
              itemInstanceId: 'i1',
              socketIndex: 1,
              plugItemHash: 999,
              currentPlugHash: 302,
            ),
            ApplyPlugStep(
              id: 'insert-1',
              label: 'Mod: Heavy Handed',
              kind: ApplyPlugKind.armorMod,
              itemInstanceId: 'i1',
              socketIndex: 0,
              plugItemHash: 301,
              currentPlugHash: 0,
              requiresClearStepId: 'clear-1',
              restorePlugHash: 302,
              restoreSocketIndex: 1,
              restoreItemInstanceId: 'i1',
            ),
          ],
        ),
      );

      expect(plugCalls, ['1:999']); // insert never called
      expect(
        result.items.firstWhere((i) => i.id == 'clear-1').reason,
        kApplySocketClearFailedMessage,
      );
      expect(
        result.items.firstWhere((i) => i.id == 'insert-1').reason,
        kApplySocketClearFailedMessage,
      );
    });

    test('could not restore row uses fixed text', () async {
      final client = createMockWriteClient(
        equipItems: (c, a) async => [
          for (final id in a.itemIds)
            EquipItemResultEntry(
              instanceId: id,
              equipStatus: kPlatformErrorSuccess,
            ),
        ],
        insertSocketPlugFree: (c, a) async {
          throw const BungiePlatformException(
            'always fails',
            errorCode: 1665,
            errorStatus: 'DestinySocketAlreadyHasPlug',
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
          armorMods: [
            ApplyPlugStep(
              id: 'clear-1',
              label: 'Clear mod: Old',
              kind: ApplyPlugKind.armorModClear,
              itemInstanceId: 'i1',
              socketIndex: 1,
              plugItemHash: 999,
              currentPlugHash: 302,
            ),
            ApplyPlugStep(
              id: 'insert-1',
              label: 'Mod: Heavy Handed',
              kind: ApplyPlugKind.armorMod,
              itemInstanceId: 'i1',
              socketIndex: 0,
              plugItemHash: 301,
              currentPlugHash: 0,
              requiresClearStepId: 'clear-1',
              restorePlugHash: 302,
              restoreSocketIndex: 1,
              restoreItemInstanceId: 'i1',
            ),
          ],
        ),
      );

      // Clear fails → insert stopped (no restore attempt for clear failure).
      expect(
        result.items.firstWhere((i) => i.id == 'insert-1').reason,
        kApplySocketClearFailedMessage,
      );
    });

    test('restore failure after insert uses could-not-restore text', () async {
      var calls = 0;
      final client = createMockWriteClient(
        equipItems: (c, a) async => [
          for (final id in a.itemIds)
            EquipItemResultEntry(
              instanceId: id,
              equipStatus: kPlatformErrorSuccess,
            ),
        ],
        insertSocketPlugFree: (c, a) async {
          calls += 1;
          // clear succeeds (1), insert fails (2), restore fails (3)
          if (calls >= 2) {
            throw const BungiePlatformException(
              'fail',
              errorCode: 1665,
              errorStatus: 'DestinySocketAlreadyHasPlug',
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
          armorMods: [
            ApplyPlugStep(
              id: 'clear-1',
              label: 'Clear mod: Old',
              kind: ApplyPlugKind.armorModClear,
              itemInstanceId: 'i1',
              socketIndex: 1,
              plugItemHash: 999,
              currentPlugHash: 302,
            ),
            ApplyPlugStep(
              id: 'insert-1',
              label: 'Mod: Heavy Handed',
              kind: ApplyPlugKind.armorMod,
              itemInstanceId: 'i1',
              socketIndex: 0,
              plugItemHash: 301,
              currentPlugHash: 0,
              requiresClearStepId: 'clear-1',
              restorePlugHash: 302,
              restoreSocketIndex: 1,
              restoreItemInstanceId: 'i1',
            ),
          ],
        ),
      );

      expect(calls, 3);
      expect(
        result.items.firstWhere((i) => i.id == 'insert-1').reason,
        kApplySocketRestoreFailedMessage,
      );
    });

    test('prebuilt plan filtered to successfully equipped instances', () async {
      final plugCalls = <String>[];
      final client = createMockWriteClient(
        equipItems: (c, a) async => [
          for (final id in a.itemIds)
            EquipItemResultEntry(
              instanceId: id,
              equipStatus: kPlatformErrorSuccess,
            ),
        ],
        insertSocketPlugFree: (c, a) async {
          plugCalls.add(a.itemId);
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
            slot: 'helmet',
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
        socketPlanBuilder: (equipped) {
          final prebuilt = const ApplySocketPlan(
            armorMods: [
              ApplyPlugStep(
                id: 'mod-equipped',
                label: 'Mod: On Equipped',
                kind: ApplyPlugKind.armorMod,
                itemInstanceId: 'i1',
                socketIndex: 0,
                plugItemHash: 301,
                currentPlugHash: 0,
              ),
              ApplyPlugStep(
                id: 'mod-other',
                label: 'Mod: Other Piece',
                kind: ApplyPlugKind.armorMod,
                itemInstanceId: 'other-never-equipped',
                socketIndex: 0,
                plugItemHash: 302,
                currentPlugHash: 0,
              ),
            ],
          );
          return filterApplySocketPlanToEquipped(
            prebuilt,
            equipped.map((e) => e.instanceId),
          );
        },
      );

      expect(plugCalls, ['i1']);
      expect(
        result.items.firstWhere((i) => i.id == 'mod-other').reason,
        'Item not equipped',
      );
    });

    test('runtime plug errors use fixed text, never e.toString', () async {
      final client = createMockWriteClient(
        equipItems: (c, a) async => [
          for (final id in a.itemIds)
            EquipItemResultEntry(
              instanceId: id,
              equipStatus: kPlatformErrorSuccess,
            ),
        ],
        insertSocketPlugFree: (c, a) async {
          throw Exception('secret stack / raw bungie Exception.toString');
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
          armorMods: [
            ApplyPlugStep(
              id: 'insert-1',
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

      final row = result.items.firstWhere((i) => i.id == 'insert-1');
      expect(row.reason, kApplySocketChangeFailedMessage);
      expect(row.reason!.contains('Exception'), isFalse);
      expect(row.reason!.contains('secret'), isFalse);
    });
  });
}
