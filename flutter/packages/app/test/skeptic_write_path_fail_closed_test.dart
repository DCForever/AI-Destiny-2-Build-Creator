import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:test/test.dart';

/// Skeptic plan item 7 (2026-11-20): write-path ownership / slot / energy
/// fail-closed — unowned or unknown slots refuse; empty ownership fails
/// closed; unknown energy cost is skipped; a held socket is not overwritten.
void main() {
  const target = 'char-1';
  const subclassBucket = kSubclassBucketHash;
  const helmetBucket = 3448274439;

  group('Skeptic #7 write-path fail-closed', () {
    test('unowned plug refuses (skip; no InsertSocketPlugFree call)', () {
      const subclassHash = 100;
      const wanted = 21;
      final plan = planApplySockets(
        characterId: target,
        build: const ApplyBuildSocketInputs(
          subclassHash: subclassHash,
          subclassPlugs: [
            ApplyNamedPlug(name: "Weaver's Call", hash: wanted),
          ],
        ),
        manifest: _subclassAspectManifest(
          subclassHash: subclassHash,
          plugHash: wanted,
          plugName: "Weaver's Call",
        ),
        instances: const [
          ApplyInstanceSocketState(
            instanceId: 'sub-1',
            itemHash: subclassHash,
            bucketHash: subclassBucket,
            characterId: target,
            location: 'equipped',
            ownedPlugHashes: {1}, // does not include wanted
            subclassPlugOwnershipKnown: true,
            socketDataKnown: true,
          ),
        ],
        equippedArmor: const [],
      );
      expect(plan.subclassPlugs.single.shouldCall, isFalse);
      expect(
        plan.subclassPlugs.single.skipReason,
        notUnlockedOrUnknownPlugMessage("Weaver's Call"),
      );
    });

    test('unknown / wrong slot refuses (does-not-fit; no call)', () {
      const armsHash = 300;
      const headMod = 301;
      final manifest = ApplySocketManifestLookup(
        itemDef: (h) => h == armsHash
            ? const ApplyManifestItemDef(
                hash: armsHash,
                name: 'Gauntlets',
                socketCategories: [
                  ApplyManifestSocketCategory(
                    socketCategoryHash: 590099826,
                    socketIndexes: [0],
                  ),
                ],
                allowedPlugHashesBySocket: {
                  0: {999}, // head mod not allowed on arms socket
                },
              )
            : null,
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
            bucketHash: 3551918588,
            characterId: target,
            location: 'equipped',
            energyCapacity: 10,
            energyUsed: 0,
            ownedPlugHashes: {headMod},
            armorModDataKnown: true,
            allowedPlugHashesBySocket: {
              0: {999},
            },
            socketDataKnown: true,
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
      expect(plan.armorMods.single.shouldCall, isFalse);
      expect(
        plan.armorMods.single.skipReason,
        doesNotFitPlugMessage('Hands-On'),
      );
    });

    test('empty ownership set fails closed (UNKNOWN; no call)', () {
      const subclassHash = 100;
      const wanted = 21;
      final plan = planApplySockets(
        characterId: target,
        build: const ApplyBuildSocketInputs(
          subclassHash: subclassHash,
          subclassPlugs: [
            ApplyNamedPlug(name: "Weaver's Call", hash: wanted),
          ],
        ),
        manifest: _subclassAspectManifest(
          subclassHash: subclassHash,
          plugHash: wanted,
          plugName: "Weaver's Call",
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
            socketDataKnown: true,
          ),
        ],
        equippedArmor: const [],
      );
      expect(plan.subclassPlugs.single.shouldCall, isFalse);
      expect(
        plan.subclassPlugs.single.skipReason,
        notUnlockedOrUnknownPlugMessage("Weaver's Call"),
      );
    });

    test(
      'known-but-empty ownership set fails closed (not fail-open)',
      () {
        const subclassHash = 100;
        const wanted = 21;
        final plan = planApplySockets(
          characterId: target,
          build: const ApplyBuildSocketInputs(
            subclassHash: subclassHash,
            subclassPlugs: [
              ApplyNamedPlug(name: "Weaver's Call", hash: wanted),
            ],
          ),
          manifest: _subclassAspectManifest(
            subclassHash: subclassHash,
            plugHash: wanted,
            plugName: "Weaver's Call",
          ),
          instances: const [
            ApplyInstanceSocketState(
              instanceId: 'sub-1',
              itemHash: subclassHash,
              bucketHash: subclassBucket,
              characterId: target,
              location: 'equipped',
              ownedPlugHashes: {},
              // Ownership channel is known, but the set is empty → still refuse.
              subclassPlugOwnershipKnown: true,
              socketDataKnown: true,
            ),
          ],
          equippedArmor: const [],
        );
        expect(plan.subclassPlugs.single.shouldCall, isFalse);
        expect(
          plan.subclassPlugs.single.skipReason,
          notUnlockedOrUnknownPlugMessage("Weaver's Call"),
        );
      },
    );

    test('unknown energy cost is skipped; never used as empty clear', () {
      const armorHash = 200;
      const wanted = 301;
      const equippedUnknown = 302;
      final plan = planApplySockets(
        characterId: target,
        build: const ApplyBuildSocketInputs(
          armorMods: [
            ApplyNamedPlug(name: 'Wanted Mod', hash: wanted),
          ],
        ),
        manifest: ApplySocketManifestLookup(
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
                    0: {wanted},
                    1: {equippedUnknown},
                  },
                  emptyPlugHashBySocket: {1: 999},
                )
              : null,
          plugDef: (h) {
            if (h == wanted) {
              return const ApplyManifestPlugDef(
                hash: wanted,
                name: 'Wanted Mod',
                plugCategoryIdentifier: 'enhancements.v2_head',
                energyCost: 5,
              );
            }
            if (h == equippedUnknown) {
              return const ApplyManifestPlugDef(
                hash: equippedUnknown,
                name: 'Unknown Cost Mod',
                plugCategoryIdentifier: 'enhancements.v2_head',
                // energyCost null — must skip, never invent 0 to clear.
              );
            }
            return null;
          },
          resolveUniquePlugHashByName: (_) => null,
        ),
        instances: const [
          ApplyInstanceSocketState(
            instanceId: 'helm-1',
            itemHash: armorHash,
            bucketHash: helmetBucket,
            characterId: target,
            location: 'equipped',
            energyCapacity: 3,
            energyUsed: 3,
            ownedPlugHashes: {wanted, equippedUnknown},
            armorModDataKnown: true,
            equippedPlugBySocket: {1: equippedUnknown},
            emptyPlugHashBySocket: {1: 999},
            allowedPlugHashesBySocket: {
              0: {wanted},
              1: {equippedUnknown},
            },
            socketDataKnown: true,
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
        reason: 'unknown-cost plug must never be cleared as empty',
      );
      expect(plan.armorMods.single.shouldCall, isFalse);
      expect(
        plan.armorMods.single.skipReason,
        armorEnergyCostUnknownMessage('Unknown Cost Mod'),
      );
    });

    test('held wanted socket is not overwritten (reserved; no call)', () {
      const subclassHash = 100;
      const held = 71;
      const other = 73;
      final plan = planApplySockets(
        characterId: target,
        build: const ApplyBuildSocketInputs(
          subclassHash: subclassHash,
          subclassPlugs: [
            ApplyNamedPlug(name: 'Thread of Winding', hash: other),
            ApplyNamedPlug(name: 'Thread of Fury', hash: held),
          ],
        ),
        manifest: ApplySocketManifestLookup(
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
              case held:
                return const ApplyManifestPlugDef(
                  hash: held,
                  name: 'Thread of Fury',
                  plugCategoryIdentifier: 'shared.strand.fragments',
                );
              case other:
                return const ApplyManifestPlugDef(
                  hash: other,
                  name: 'Thread of Winding',
                  plugCategoryIdentifier: 'shared.strand.fragments',
                );
              default:
                return null;
            }
          },
          resolveUniquePlugHashByName: (_) => null,
        ),
        instances: const [
          ApplyInstanceSocketState(
            instanceId: 'sub-1',
            itemHash: subclassHash,
            bucketHash: subclassBucket,
            characterId: target,
            location: 'equipped',
            equippedPlugBySocket: {7: held, 8: 99},
            ownedPlugHashes: {held, other},
            subclassPlugOwnershipKnown: true,
            socketDataKnown: true,
          ),
        ],
        equippedArmor: const [],
      );
      final byHash = {for (final s in plan.subclassPlugs) s.plugItemHash: s};
      expect(byHash[held]!.socketIndex, 7);
      expect(byHash[held]!.shouldCall, isFalse);
      expect(byHash[other]!.socketIndex, 8);
      expect(byHash[other]!.shouldCall, isTrue);
      expect(
        byHash[other]!.socketIndex,
        isNot(equals(7)),
        reason: 'new plug must not overwrite the held wanted socket',
      );
    });
  });
}

ApplySocketManifestLookup _subclassAspectManifest({
  required int subclassHash,
  required int plugHash,
  required String plugName,
}) {
  return ApplySocketManifestLookup(
    itemDef: (h) => h == subclassHash
        ? ApplyManifestItemDef(
            hash: subclassHash,
            name: 'Broodweaver',
            socketCategories: const [
              ApplyManifestSocketCategory(
                socketCategoryHash: 2047681910,
                socketIndexes: [5],
              ),
            ],
          )
        : null,
    plugDef: (h) => h == plugHash
        ? ApplyManifestPlugDef(
            hash: plugHash,
            name: plugName,
            plugCategoryIdentifier: 'warlock.strand.aspects',
          )
        : null,
    resolveUniquePlugHashByName: (_) => null,
  );
}
