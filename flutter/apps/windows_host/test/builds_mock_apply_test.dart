import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/auth/windows_oauth_session.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_apply.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_fixture.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/host_bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';

import 'inventory_sync_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const warlockA = CharacterSummary(
    characterId: '2305843009264904821',
    classType: 'Warlock',
    light: 2010,
  );
  const warlockB = CharacterSummary(
    characterId: '2305843009264909999',
    classType: 'Warlock',
    light: 2010,
  );
  const membership = DestinyMembership(
    membershipType: 3,
    membershipId: 'destiny-1',
    displayName: 'Guardian',
  );

  test('F4: armorModDataKnown stays false when 310 or energyUsed missing', () {
    expect(isArmorModDataKnown(null), isFalse);
    expect(
      isArmorModDataKnown(
        const RawInventoryItem(
          instanceId: 'a1',
          itemHash: 1,
          bucketHash: 3448274439,
          location: 'equipped',
        ),
      ),
      isFalse,
    );
    // 305-only (no reusable plugs) → false, no write path.
    expect(
      isArmorModDataKnown(
        const RawInventoryItem(
          instanceId: 'a1',
          itemHash: 1,
          bucketHash: 3448274439,
          location: 'equipped',
          socketCapture: [
            RawSocketCapture(socketIndex: 0, equippedPlugHash: 10),
          ],
          energyCapacity: 10,
          energyUsed: 3,
        ),
      ),
      isFalse,
    );
    expect(
      isArmorModDataKnown(
        const RawInventoryItem(
          instanceId: 'a1',
          itemHash: 1,
          bucketHash: 3448274439,
          location: 'equipped',
          socketCapture: [
            RawSocketCapture(
              socketIndex: 0,
              equippedPlugHash: 10,
              reusablePlugHashes: [10, 11],
            ),
          ],
          energyCapacity: 10,
          // energyUsed null → still unknown
        ),
      ),
      isFalse,
    );
    expect(
      isArmorModDataKnown(
        const RawInventoryItem(
          instanceId: 'a1',
          itemHash: 1,
          bucketHash: 3448274439,
          location: 'equipped',
          socketCapture: [
            RawSocketCapture(
              socketIndex: 0,
              equippedPlugHash: 10,
              reusablePlugHashes: [10, 11],
            ),
          ],
          energyCapacity: 10,
          energyUsed: 3,
        ),
      ),
      isTrue,
    );
  });

  test('M2: unlocked indexes require 305 enabled+visible AND 310 plugs', () {
    final live = const RawInventoryItem(
      instanceId: 'sub-1',
      itemHash: 100,
      bucketHash: kSubclassBucketHash,
      location: 'equipped',
      socketCapture: [
        RawSocketCapture(
          socketIndex: 7,
          equippedPlugHash: 31,
          reusablePlugHashes: [31, 32],
          isEnabled: true,
          isVisible: true,
        ),
        RawSocketCapture(
          socketIndex: 8,
          equippedPlugHash: 0,
          reusablePlugHashes: [32],
          isEnabled: true,
          isVisible: true,
        ),
        // 305 enabled but no 310 → not unlocked.
        RawSocketCapture(
          socketIndex: 9,
          equippedPlugHash: 0,
          isEnabled: true,
          isVisible: true,
        ),
        // 310 alone on disabled socket → not unlocked.
        RawSocketCapture(
          socketIndex: 10,
          equippedPlugHash: 0,
          reusablePlugHashes: [99],
          isEnabled: false,
          isVisible: true,
        ),
      ],
    );
    final unlocked = unlockedSocketIndexesFromCapture(live)!;
    expect(unlocked, containsAll([7, 8]));
    expect(unlocked.contains(9), isFalse);
    expect(unlocked.contains(10), isFalse);
  });

  test('label includes class, light, and last 4 of character id', () {
    expect(
      formatBuildsMockApplyTargetLabel(warlockA),
      'Warlock 2010 · …4821',
    );
    expect(
      formatBuildsMockApplyTargetLabel(warlockB),
      'Warlock 2010 · …9999',
    );
  });

  test('two Warlocks at same light get distinct Applies-to labels', () {
    final a = formatBuildsMockApplyTargetLabel(warlockA);
    final b = formatBuildsMockApplyTargetLabel(warlockB);
    expect(a, isNot(equals(b)));
    expect(a, contains('…4821'));
    expect(b, contains('…9999'));
  });

  test('resolve picks first Warlock; labels match that character id', () async {
    final session = await _signedInSession();
    final profile = FakeProfileClient(
      characters: const [warlockA, warlockB],
    );
    final ports = BuildsMockApplyPorts(
      oauthSession: session,
      profileClient: profile,
      writeClient: createMockWriteClient(),
    );

    final resolution = await resolveBuildsMockApplyTarget(ports);
    expect(resolution.hasTarget, isTrue);
    expect(resolution.target!.characterId, warlockA.characterId);
    expect(
      formatBuildsMockApplyTargetLabel(resolution.target!.character),
      'Warlock 2010 · …4821',
    );
  });

  test('apply uses the resolved target character id (not a re-pick)', () async {
    final equippedIds = <String>[];
    final writeClient = createMockWriteClient(
      equipItems: (ctx, args) async {
        equippedIds.add(args.characterId);
        return [
          for (final id in args.itemIds)
            EquipItemResultEntry(
              instanceId: id,
              equipStatus: kPlatformErrorSuccess,
            ),
        ];
      },
    );

    // Pass warlockB explicitly — even though A would be first if re-resolved.
    const target = BuildsMockApplyTarget(
      membership: membership,
      character: warlockB,
    );

    final session = await _signedInSession();
    final build = loadBuildsMockFixture().builds.first;
    final plan = _singleSlotPlan(build, instanceId: 'inst-helmet-1');

    final outcome = await runBuildsMockApplyToCharacter(
      build: build,
      plan: plan,
      ports: BuildsMockApplyPorts(
        oauthSession: session,
        profileClient: FakeProfileClient(
          characters: const [warlockA, warlockB],
          items: const [
            RawInventoryItem(
              instanceId: 'inst-helmet-1',
              itemHash: 1001,
              bucketHash: 3448274439,
              location: 'character',
              characterId: '2305843009264909999',
            ),
          ],
        ),
        writeClient: writeClient,
      ),
      target: target,
      isMounted: () => true,
      onProgress: (_) {},
    );

    expect(outcome.error, isNull);
    expect(outcome.progress?.appliedCount, 1);
    expect(equippedIds, [warlockB.characterId]);
    expect(
      formatBuildsMockApplyTargetLabel(target.character),
      contains('…9999'),
    );
  });

  test('resolve unavailable reasons when signed out / no Warlock', () async {
    final signedOut = BuildsMockApplyPorts(
      oauthSession: WindowsOAuthSession(
        clientId: 'test-client',
        redirectUri: kDefaultWindowsRedirectUri,
        tokenStore: MemoryTokenStore(),
        oauthClient: BungieOAuthClient(
          clientId: 'test-client',
          redirectUri: kDefaultWindowsRedirectUri,
          transport: (_) async => throw StateError('unused'),
        ),
        browserLauncher: FakeBrowserLauncher(),
      ),
      profileClient: FakeProfileClient(),
      writeClient: createMockWriteClient(),
    );
    final out = await resolveBuildsMockApplyTarget(signedOut);
    expect(out.hasTarget, isFalse);
    expect(out.reason, contains('Sign in'));

    final session = await _signedInSession();
    final noWarlock = await resolveBuildsMockApplyTarget(
      BuildsMockApplyPorts(
        oauthSession: session,
        profileClient: FakeProfileClient(
          characters: const [
            CharacterSummary(
              characterId: 'hunter-1',
              classType: 'Hunter',
              light: 2000,
            ),
          ],
        ),
        writeClient: createMockWriteClient(),
      ),
    );
    expect(noWarlock.hasTarget, isFalse);
    expect(noWarlock.reason, contains('No Warlock'));
  });

  // --- Live-profile instance gate (PR1) ------------------------------------

  test(
    '(1) missing live instance skips equipItems and shows inventory reason',
    () async {
      final equipped = <String>[];
      final writeClient = createMockWriteClient(
        equipItems: (ctx, args) async {
          equipped.addAll(args.itemIds);
          return [
            for (final id in args.itemIds)
              EquipItemResultEntry(
                instanceId: id,
                equipStatus: kPlatformErrorSuccess,
              ),
          ];
        },
      );
      final session = await _signedInSession();
      final build = loadBuildsMockFixture().builds.first;
      final plan = _twoSlotPlan(
        build,
        presentId: 'inst-present',
        missingId: 'inst-missing',
      );

      final outcome = await runBuildsMockApplyToCharacter(
        build: build,
        plan: plan,
        ports: BuildsMockApplyPorts(
          oauthSession: session,
          profileClient: FakeProfileClient(
            characters: const [warlockA],
            items: const [
              RawInventoryItem(
                instanceId: 'inst-present',
                itemHash: 1001,
                bucketHash: 3448274439,
                location: 'character',
                characterId: '2305843009264904821',
              ),
            ],
          ),
          writeClient: writeClient,
        ),
        target: const BuildsMockApplyTarget(
          membership: membership,
          character: warlockA,
        ),
        isMounted: () => true,
        onProgress: (_) {},
      );

      expect(outcome.error, isNull);
      expect(equipped, ['inst-present']);
      expect(equipped, isNot(contains('inst-missing')));
      final missingRow = outcome.progress!.items
          .firstWhere((r) => r.instanceId == 'inst-missing');
      expect(missingRow.state, ApplyItemState.failed);
      expect(missingRow.reason, kApplyLiveInventoryMissingReason);
      expect(outcome.progress!.appliedCount, 1);
      expect(outcome.progress!.failedCount, 1);
    },
  );

  test('(2) present live instances are still equipped', () async {
    final equipped = <String>[];
    final writeClient = createMockWriteClient(
      equipItems: (ctx, args) async {
        equipped.addAll(args.itemIds);
        return [
          for (final id in args.itemIds)
            EquipItemResultEntry(
              instanceId: id,
              equipStatus: kPlatformErrorSuccess,
            ),
        ];
      },
    );
    final session = await _signedInSession();
    final build = loadBuildsMockFixture().builds.first;
    final plan = _twoSlotPlan(
      build,
      presentId: 'inst-a',
      missingId: 'inst-b',
    );

    final outcome = await runBuildsMockApplyToCharacter(
      build: build,
      plan: plan,
      ports: BuildsMockApplyPorts(
        oauthSession: session,
        profileClient: FakeProfileClient(
          characters: const [warlockA],
          items: const [
            RawInventoryItem(
              instanceId: 'inst-a',
              itemHash: 1001,
              bucketHash: 3448274439,
              location: 'character',
              characterId: '2305843009264904821',
            ),
            RawInventoryItem(
              instanceId: 'inst-b',
              itemHash: 1002,
              bucketHash: 3551918588,
              location: 'character',
              characterId: '2305843009264904821',
            ),
          ],
        ),
        writeClient: writeClient,
      ),
      target: const BuildsMockApplyTarget(
        membership: membership,
        character: warlockA,
      ),
      isMounted: () => true,
      onProgress: (_) {},
    );

    expect(outcome.error, isNull);
    expect(equipped, ['inst-a', 'inst-b']);
    expect(outcome.progress!.appliedCount, 2);
    expect(outcome.progress!.failedCount, 0);
    expect(
      outcome.progress!.items.every((r) => r.state == ApplyItemState.done),
      isTrue,
    );
  });

  test(
    '(3a) inventory read failure makes zero equipItems/transferItem calls '
    'and shows reason',
    () async {
      final equipped = <String>[];
      var transferCalls = 0;
      final writeClient = createMockWriteClient(
        transferItem: (ctx, args) async => transferCalls += 1,
        equipItems: (ctx, args) async {
          equipped.addAll(args.itemIds);
          return [
            for (final id in args.itemIds)
              EquipItemResultEntry(
                instanceId: id,
                equipStatus: kPlatformErrorSuccess,
              ),
          ];
        },
      );
      final session = await _signedInSession();
      final build = loadBuildsMockFixture().builds.first;
      final plan = _singleSlotPlan(build, instanceId: 'inst-helmet-1');

      final outcome = await runBuildsMockApplyToCharacter(
        build: build,
        plan: plan,
        ports: BuildsMockApplyPorts(
          oauthSession: session,
          profileClient: FakeProfileClient(
            characters: const [warlockA],
            throwOnInventory: true,
          ),
          writeClient: writeClient,
        ),
        target: const BuildsMockApplyTarget(
          membership: membership,
          character: warlockA,
        ),
        isMounted: () => true,
        onProgress: (_) {},
      );

      expect(outcome.error, isNull);
      expect(equipped, isEmpty);
      expect(transferCalls, 0);
      expect(outcome.progress!.failedCount, 1);
      expect(outcome.progress!.appliedCount, 0);
      expect(
        outcome.progress!.items.single.reason,
        kApplyLiveInventoryReadFailedReason,
      );
      expect(outcome.progress!.items.single.state, ApplyItemState.failed);
    },
  );

  test(
    '(3b) empty live inventory makes zero equipItems/transferItem calls '
    'and shows reason',
    () async {
      final equipped = <String>[];
      var transferCalls = 0;
      final writeClient = createMockWriteClient(
        transferItem: (ctx, args) async => transferCalls += 1,
        equipItems: (ctx, args) async {
          equipped.addAll(args.itemIds);
          return [
            for (final id in args.itemIds)
              EquipItemResultEntry(
                instanceId: id,
                equipStatus: kPlatformErrorSuccess,
              ),
          ];
        },
      );
      final session = await _signedInSession();
      final build = loadBuildsMockFixture().builds.first;
      final plan = _singleSlotPlan(build, instanceId: 'inst-helmet-1');

      final outcome = await runBuildsMockApplyToCharacter(
        build: build,
        plan: plan,
        ports: BuildsMockApplyPorts(
          oauthSession: session,
          profileClient: FakeProfileClient(
            characters: const [warlockA],
            items: const [],
          ),
          writeClient: writeClient,
        ),
        target: const BuildsMockApplyTarget(
          membership: membership,
          character: warlockA,
        ),
        isMounted: () => true,
        onProgress: (_) {},
      );

      expect(outcome.error, isNull);
      expect(equipped, isEmpty);
      expect(transferCalls, 0);
      expect(outcome.progress!.failedCount, 1);
      expect(
        outcome.progress!.items.single.reason,
        kApplyLiveInventoryReadFailedReason,
      );
    },
  );

  test(
    '(B1) partial profile (missing component section) is read failure, '
    'not re-import DIM CSV; zero transferItem',
    () async {
      final equipped = <String>[];
      var transferCalls = 0;
      final writeClient = createMockWriteClient(
        transferItem: (ctx, args) async => transferCalls += 1,
        equipItems: (ctx, args) async {
          equipped.addAll(args.itemIds);
          return [
            for (final id in args.itemIds)
              EquipItemResultEntry(
                instanceId: id,
                equipStatus: kPlatformErrorSuccess,
              ),
          ];
        },
      );
      final session = await _signedInSession();
      final build = loadBuildsMockFixture().builds.first;
      final plan = _singleSlotPlan(build, instanceId: 'inst-helmet-1');

      final outcome = await runBuildsMockApplyToCharacter(
        build: build,
        plan: plan,
        ports: BuildsMockApplyPorts(
          oauthSession: session,
          profileClient: FakeProfileClient(
            characters: const [warlockA],
            // Item id matches the plan, but sections are incomplete → fail closed.
            items: const [
              RawInventoryItem(
                instanceId: 'inst-helmet-1',
                itemHash: 1001,
                bucketHash: 3448274439,
                location: 'character',
                characterId: '2305843009264904821',
              ),
            ],
            inventorySectionsComplete: false,
          ),
          writeClient: writeClient,
        ),
        target: const BuildsMockApplyTarget(
          membership: membership,
          character: warlockA,
        ),
        isMounted: () => true,
        onProgress: (_) {},
      );

      expect(outcome.error, isNull);
      expect(equipped, isEmpty);
      expect(transferCalls, 0);
      expect(outcome.progress!.failedCount, 1);
      expect(outcome.progress!.appliedCount, 0);
      expect(
        outcome.progress!.items.single.reason,
        kApplyLiveInventoryReadFailedReason,
      );
      expect(
        outcome.progress!.items.single.reason,
        isNot(equals(kApplyLiveInventoryMissingReason)),
      );
      expect(outcome.progress!.items.single.state, ApplyItemState.failed);
    },
  );

  test('(B2) vault instance counts as present for the live-inventory gate',
      () async {
    final equipped = <String>[];
    final transfers = <TransferItemArgs>[];
    final writeClient = createMockWriteClient(
      transferItem: (ctx, args) async => transfers.add(args),
      equipItems: (ctx, args) async {
        equipped.addAll(args.itemIds);
        return [
          for (final id in args.itemIds)
            EquipItemResultEntry(
              instanceId: id,
              equipStatus: kPlatformErrorSuccess,
            ),
        ];
      },
    );
    final session = await _signedInSession();
    final build = loadBuildsMockFixture().builds.first;
    final plan = _singleSlotPlan(build, instanceId: 'inst-vault-1');

    final outcome = await runBuildsMockApplyToCharacter(
      build: build,
      plan: plan,
      ports: BuildsMockApplyPorts(
        oauthSession: session,
        profileClient: FakeProfileClient(
          characters: const [warlockA],
          items: const [
            RawInventoryItem(
              instanceId: 'inst-vault-1',
              itemHash: 1001,
              bucketHash: 3448274439, // equipment bucket (resolved)
              location: 'vault',
            ),
          ],
        ),
        writeClient: writeClient,
      ),
      target: const BuildsMockApplyTarget(
        membership: membership,
        character: warlockA,
      ),
      isMounted: () => true,
      onProgress: (_) {},
    );

    expect(outcome.error, isNull);
    expect(transfers, hasLength(1));
    expect(transfers.single.transferToVault, isFalse);
    expect(equipped, ['inst-vault-1']);
    expect(outcome.progress!.appliedCount, 1);
    expect(outcome.progress!.failedCount, 0);
    // CHANGED: Apply now emits an auxiliary move side-effect row in addition
    // to the pin row (truthful from→to reporting).
    final pinRows = outcome.progress!.items
        .where((r) => !isAuxiliaryApplyRow(r))
        .toList();
    expect(pinRows, hasLength(1));
    expect(pinRows.single.state, ApplyItemState.done);
    expect(
      outcome.progress!.items.any(
        (r) =>
            r.id.startsWith(kApplySideEffectRowIdPrefix) &&
            r.label.contains('Moved'),
      ),
      isTrue,
    );
  });

  test(
    'exotic weapon via tierType is equipped after legendary (exotics-last)',
    () async {
      List<String>? order;
      final writeClient = createMockWriteClient(
        equipItems: (ctx, args) async {
          order = List<String>.from(args.itemIds);
          return [
            for (final id in args.itemIds)
              EquipItemResultEntry(
                instanceId: id,
                equipStatus: kPlatformErrorSuccess,
              ),
          ];
        },
      );
      final session = await _signedInSession();
      final build = loadBuildsMockFixture().builds.first;
      final plan = FillInSavedBuildPlan(
        buildId: build.id,
        missing: const [],
        applied: const [
          FillInAppliedSlot(
            slotWire: 'kinetic',
            label: 'Exotic Gun',
            originalLabel: 'Old',
            instanceId: 'exo-w',
            itemHash: 9001,
          ),
          FillInAppliedSlot(
            slotWire: 'energy',
            label: 'Legendary Gun',
            originalLabel: 'Old',
            instanceId: 'leg-w',
            itemHash: 9002,
          ),
        ],
      );

      const kineticBucket = 1498876634;
      const energyBucket = 2465295065;
      final outcome = await runBuildsMockApplyToCharacter(
        build: build,
        plan: plan,
        ports: BuildsMockApplyPorts(
          oauthSession: session,
          profileClient: FakeProfileClient(
            characters: const [warlockA],
            items: const [
              // Weapon: gearTier unset; exotic via definition tierType == 6.
              RawInventoryItem(
                instanceId: 'exo-w',
                itemHash: 9001,
                bucketHash: kineticBucket,
                location: 'character',
                characterId: '2305843009264904821',
                tierType: 6,
              ),
              RawInventoryItem(
                instanceId: 'leg-w',
                itemHash: 9002,
                bucketHash: energyBucket,
                location: 'character',
                characterId: '2305843009264904821',
                tierType: 5,
              ),
            ],
          ),
          writeClient: writeClient,
          // Isolate from exoticItemHashes — exotic via live tierType only.
        ),
        target: const BuildsMockApplyTarget(
          membership: membership,
          character: warlockA,
        ),
        isMounted: () => true,
        onProgress: (_) {},
      );

      expect(outcome.error, isNull);
      expect(outcome.progress!.appliedCount, 2);
      expect(order, ['leg-w', 'exo-w']);
    },
  );

  test('host→planner fragment path: empty unlocked socket gets InsertSocketPlugFree',
      () {
    const subclassHash = 900001;
    const fragA = 31;
    const fragB = 32;
    const charId = '2305843009264904821';
    const loadout = CachedDimLoadout(
      shareId: 's1',
      name: 'Test',
      classType: 2,
      items: [],
      subclass: CachedDimSubclass(hash: subclassHash, name: 'Broodweaver'),
      subclassPlugs: [
        CachedDimNamedHash(hash: fragA, name: 'Fragment A'),
        CachedDimNamedHash(hash: fragB, name: 'Fragment B'),
      ],
      mods: [],
      artifactPerks: [],
    );
    final live = const RawInventoryItem(
      instanceId: 'sub-1',
      itemHash: subclassHash,
      bucketHash: kSubclassBucketHash,
      location: 'equipped',
      characterId: charId,
      socketCapture: [
        RawSocketCapture(
          socketIndex: 7,
          equippedPlugHash: fragA,
          reusablePlugHashes: [fragA, fragB],
          isEnabled: true,
          isVisible: true,
        ),
        RawSocketCapture(
          socketIndex: 8,
          equippedPlugHash: 0,
          reusablePlugHashes: [fragA, fragB],
          isEnabled: true,
          isVisible: true,
        ),
        RawSocketCapture(
          socketIndex: 9,
          equippedPlugHash: 0,
          reusablePlugHashes: [fragA, fragB],
          isEnabled: true,
          isVisible: true,
        ),
      ],
    );
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
        if (h == fragA) {
          return const ApplyManifestPlugDef(
            hash: fragA,
            name: 'Fragment A',
            plugCategoryIdentifier: 'shared.fragments',
          );
        }
        if (h == fragB) {
          return const ApplyManifestPlugDef(
            hash: fragB,
            name: 'Fragment B',
            plugCategoryIdentifier: 'shared.fragments',
          );
        }
        return null;
      },
      resolveUniquePlugHashByName: (_) => null,
    );

    final plan = socketPlanForApplySync(
      loadout: loadout,
      characterId: charId,
      inventory: const [
        ApplyInventoryItem(
          instanceId: 'sub-1',
          itemHash: subclassHash,
          location: 'equipped',
          bucketHash: kSubclassBucketHash,
          characterId: charId,
        ),
      ],
      liveItems: [live],
      successfullyEquipped: const [],
      manifest: manifest,
      unlockedPlugSetPlugHashes: const {fragA, fragB},
    );

    expect(plan, isNotNull);
    final inserts =
        plan!.subclassPlugs.where((s) => s.shouldCall).toList();
    expect(inserts, hasLength(1));
    expect(inserts.single.plugItemHash, fragB);
    expect(inserts.single.socketIndex, 8);
    final noop =
        plan.subclassPlugs.firstWhere((s) => s.plugItemHash == fragA);
    expect(noop.shouldCall, isFalse);
    expect(noop.socketIndex, 7);
  });

  test(
    'vault General bucket resolves to equipment bucket and plans make-room',
    () async {
      final transfers = <TransferItemArgs>[];
      final writeClient = createMockWriteClient(
        transferItem: (ctx, args) async => transfers.add(args),
        equipItems: (ctx, args) async {
          return [
            for (final id in args.itemIds)
              EquipItemResultEntry(
                instanceId: id,
                equipStatus: kPlatformErrorSuccess,
              ),
          ];
        },
      );
      final session = await _signedInSession();
      final build = loadBuildsMockFixture().builds.first;
      const legsBucket = 20886954;
      const vaultGeneral = 138197802;
      final plan = FillInSavedBuildPlan(
        buildId: build.id,
        missing: const [],
        applied: const [
          FillInAppliedSlot(
            slotWire: 'legs',
            label: 'Lustrous Boots',
            originalLabel: 'Old',
            instanceId: 'vault-boots',
            itemHash: 7701,
          ),
        ],
      );

      final outcome = await runBuildsMockApplyToCharacter(
        build: build,
        plan: plan,
        ports: BuildsMockApplyPorts(
          oauthSession: session,
          equipmentBucketLookup: const {7701: legsBucket},
          profileClient: FakeProfileClient(
            characters: const [warlockA],
            items: [
              const RawInventoryItem(
                instanceId: 'vault-boots',
                itemHash: 7701,
                bucketHash: vaultGeneral,
                location: 'vault',
              ),
              const RawInventoryItem(
                instanceId: 'eq-legs',
                itemHash: 10,
                bucketHash: legsBucket,
                location: 'equipped',
                characterId: '2305843009264904821',
                power: 200,
              ),
              for (var i = 0; i < 9; i++)
                RawInventoryItem(
                  instanceId: 'fill-legs-$i',
                  itemHash: 50 + i,
                  bucketHash: legsBucket,
                  location: 'character',
                  characterId: '2305843009264904821',
                  power: i,
                ),
            ],
          ),
          writeClient: writeClient,
        ),
        target: const BuildsMockApplyTarget(
          membership: membership,
          character: warlockA,
        ),
        isMounted: () => true,
        onProgress: (_) {},
      );

      expect(outcome.error, isNull);
      expect(
        transfers.where((t) => t.transferToVault).map((t) => t.instanceId),
        contains('fill-legs-0'),
      );
      expect(
        transfers.any(
          (t) => t.instanceId == 'vault-boots' && !t.transferToVault,
        ),
        isTrue,
      );
      expect(outcome.progress!.appliedCount, 1);
    },
  );

  test(
    'exotic placeholder label formats once with catalog name',
    () async {
      final writeClient = createMockWriteClient(
        equipItems: (ctx, args) async {
          return [
            for (final id in args.itemIds)
              EquipItemResultEntry(
                instanceId: id,
                equipStatus: kPlatformErrorSuccess,
              ),
          ];
        },
      );
      final session = await _signedInSession();
      final build = loadBuildsMockFixture().builds.first;
      const kineticBucket = 1498876634;
      final plan = FillInSavedBuildPlan(
        buildId: build.id,
        missing: const [],
        applied: const [
          FillInAppliedSlot(
            slotWire: 'exotic_weapon',
            label: 'Exotic weapon',
            originalLabel: '',
            instanceId: 'stay-frosty',
            itemHash: 8801,
          ),
        ],
      );

      final outcome = await runBuildsMockApplyToCharacter(
        build: build,
        plan: plan,
        ports: BuildsMockApplyPorts(
          oauthSession: session,
          exoticItemHashes: const {8801},
          profileClient: FakeProfileClient(
            characters: const [warlockA],
            items: const [
              RawInventoryItem(
                instanceId: 'stay-frosty',
                itemHash: 8801,
                bucketHash: kineticBucket,
                location: 'character',
                characterId: '2305843009264904821',
                tierType: 6,
              ),
            ],
          ),
          writeClient: writeClient,
        ),
        target: const BuildsMockApplyTarget(
          membership: membership,
          character: warlockA,
        ),
        isMounted: () => true,
        onProgress: (_) {},
      );

      expect(outcome.error, isNull);
      final pin = outcome.progress!.items
          .where((r) => !isAuxiliaryApplyRow(r))
          .single;
      // Without catalog, placeholder stays a single exotic kind — never stacked.
      expect(pin.label, 'Exotic weapon');
      expect(pin.label, isNot(contains('(Exotic weapon) (Exotic weapon)')));
      expect(pin.state, ApplyItemState.done);
    },
  );

  group('dequip equipped-elsewhere via FakeProfileClient', () {
    const otherChar = CharacterSummary(
      characterId: 'char-other-warlock',
      classType: 'Warlock',
      light: 2000,
    );
    const targetChar = warlockA;
    const target = BuildsMockApplyTarget(
      membership: membership,
      character: targetChar,
    );

    test('(a) frees equipped-elsewhere with on-char replacement then equips',
        () async {
      final equips = <EquipItemArgs>[];
      final transfers = <TransferItemArgs>[];
      final bulk = <List<String>>[];
      final writeClient = createMockWriteClient(
        equipItem: (ctx, args) async => equips.add(args),
        transferItem: (ctx, args) async => transfers.add(args),
        equipItems: (ctx, args) async {
          bulk.add(List<String>.from(args.itemIds));
          return [
            for (final id in args.itemIds)
              EquipItemResultEntry(
                instanceId: id,
                equipStatus: kPlatformErrorSuccess,
              ),
          ];
        },
      );
      final session = await _signedInSession();
      final build = loadBuildsMockFixture().builds.first;
      final plan = _singleSlotPlan(build, instanceId: 'needed-helm');

      final outcome = await runBuildsMockApplyToCharacter(
        build: build,
        plan: plan,
        ports: BuildsMockApplyPorts(
          oauthSession: session,
          profileClient: FakeProfileClient(
            characters: const [targetChar, otherChar],
            items: const [
              RawInventoryItem(
                instanceId: 'needed-helm',
                itemHash: 1001,
                bucketHash: 3448274439,
                location: 'equipped',
                characterId: 'char-other-warlock',
              ),
              RawInventoryItem(
                instanceId: 'spare-helm',
                itemHash: 1003,
                bucketHash: 3448274439,
                location: 'character',
                characterId: 'char-other-warlock',
              ),
            ],
          ),
          writeClient: writeClient,
        ),
        target: target,
        isMounted: () => true,
        onProgress: (_) {},
      );

      expect(outcome.error, isNull);
      expect(equips.single.instanceId, 'spare-helm');
      expect(equips.single.characterId, 'char-other-warlock');
      expect(transfers, hasLength(2));
      expect(bulk, [
        ['needed-helm'],
      ]);
      expect(outcome.progress?.appliedCount, 1);
      expect(
        outcome.progress?.items.any(
          (r) =>
              r.id.startsWith(kApplySideEffectRowIdPrefix) &&
              r.label.contains('Equipped') &&
              r.label.contains('char-other-warlock'),
        ),
        isTrue,
      );
    });

    test('(b) no valid replacement fails that item; rest continues', () async {
      final equips = <EquipItemArgs>[];
      final bulk = <List<String>>[];
      final writeClient = createMockWriteClient(
        equipItem: (ctx, args) async => equips.add(args),
        equipItems: (ctx, args) async {
          bulk.add(List<String>.from(args.itemIds));
          return [
            for (final id in args.itemIds)
              EquipItemResultEntry(
                instanceId: id,
                equipStatus: kPlatformErrorSuccess,
              ),
          ];
        },
      );
      final session = await _signedInSession();
      final build = loadBuildsMockFixture().builds.first;
      // helmet=stuck-helm (equipped elsewhere, no non-exotic spare);
      // gauntlets=local-arms (already on target).
      final plan = _twoSlotPlan(
        build,
        presentId: 'stuck-helm',
        missingId: 'local-arms',
      );

      final outcome = await runBuildsMockApplyToCharacter(
        build: build,
        plan: plan,
        ports: BuildsMockApplyPorts(
          oauthSession: session,
          profileClient: FakeProfileClient(
            characters: const [targetChar, otherChar],
            items: const [
              RawInventoryItem(
                instanceId: 'stuck-helm',
                itemHash: 1001,
                bucketHash: 3448274439,
                location: 'equipped',
                characterId: 'char-other-warlock',
                tierType: 6,
              ),
              RawInventoryItem(
                instanceId: 'exotic-spare',
                itemHash: 1009,
                bucketHash: 3448274439,
                location: 'character',
                characterId: 'char-other-warlock',
                tierType: 6,
              ),
              RawInventoryItem(
                instanceId: 'local-arms',
                itemHash: 1002,
                bucketHash: 3551918588,
                location: 'character',
                characterId: '2305843009264904821',
              ),
            ],
          ),
          writeClient: writeClient,
        ),
        target: target,
        isMounted: () => true,
        onProgress: (_) {},
      );

      expect(equips, isEmpty);
      expect(bulk, [
        ['local-arms'],
      ]);
      expect(outcome.progress?.appliedCount, 1);
      expect(outcome.progress?.failedCount, 1);
      expect(
        outcome.progress?.items.any(
          (r) =>
              r.state == ApplyItemState.failed &&
              r.reason == kCannotUnequipOnOtherCharacterMessage,
        ),
        isTrue,
      );
    });

    test('(c) mid-sequence failure lists prior equip and failing step',
        () async {
      final writeClient = createMockWriteClient(
        equipItem: (ctx, args) async {},
        transferItem: (ctx, args) async {
          if (args.instanceId == 'needed-helm' && args.transferToVault) {
            throw const BungiePlatformException(
              'gone',
              errorCode: kDestinyItemNotFound,
              errorStatus: 'DestinyItemNotFound',
            );
          }
        },
      );
      final session = await _signedInSession();
      final build = loadBuildsMockFixture().builds.first;
      final plan = _singleSlotPlan(build, instanceId: 'needed-helm');

      final outcome = await runBuildsMockApplyToCharacter(
        build: build,
        plan: plan,
        ports: BuildsMockApplyPorts(
          oauthSession: session,
          profileClient: FakeProfileClient(
            characters: const [targetChar, otherChar],
            items: const [
              RawInventoryItem(
                instanceId: 'needed-helm',
                itemHash: 1001,
                bucketHash: 3448274439,
                location: 'equipped',
                characterId: 'char-other-warlock',
              ),
              RawInventoryItem(
                instanceId: 'spare-helm',
                itemHash: 1003,
                bucketHash: 3448274439,
                location: 'character',
                characterId: 'char-other-warlock',
              ),
            ],
          ),
          writeClient: writeClient,
        ),
        target: target,
        isMounted: () => true,
        onProgress: (_) {},
      );

      expect(outcome.progress?.failedCount, 1);
      expect(
        outcome.progress?.items.any(
          (r) =>
              r.state == ApplyItemState.failed &&
              r.reason == 'DestinyItemNotFound',
        ),
        isTrue,
      );
      expect(
        outcome.progress?.items.any(
          (r) =>
              r.id.startsWith(kApplySideEffectRowIdPrefix) &&
              r.state == ApplyItemState.done &&
              r.label.contains('Equipped') &&
              r.label.contains('char-other-warlock'),
        ),
        isTrue,
      );
    });

    test('(d) exotic spare skipped; legendary replacement equipped', () async {
      final equips = <EquipItemArgs>[];
      final writeClient = createMockWriteClient(
        equipItem: (ctx, args) async => equips.add(args),
      );
      final session = await _signedInSession();
      final build = loadBuildsMockFixture().builds.first;
      final plan = _singleSlotPlan(build, instanceId: 'needed-helm');

      final outcome = await runBuildsMockApplyToCharacter(
        build: build,
        plan: plan,
        ports: BuildsMockApplyPorts(
          oauthSession: session,
          profileClient: FakeProfileClient(
            characters: const [targetChar, otherChar],
            items: const [
              RawInventoryItem(
                instanceId: 'needed-helm',
                itemHash: 1001,
                bucketHash: 3448274439,
                location: 'equipped',
                characterId: 'char-other-warlock',
              ),
              RawInventoryItem(
                instanceId: 'exotic-spare',
                itemHash: 1009,
                bucketHash: 3448274439,
                location: 'character',
                characterId: 'char-other-warlock',
                tierType: 6,
              ),
              RawInventoryItem(
                instanceId: 'legend-spare',
                itemHash: 1003,
                bucketHash: 3448274439,
                location: 'character',
                characterId: 'char-other-warlock',
              ),
            ],
          ),
          writeClient: writeClient,
        ),
        target: target,
        isMounted: () => true,
        onProgress: (_) {},
      );

      expect(equips.single.instanceId, 'legend-spare');
      expect(outcome.progress?.appliedCount, 1);
    });
  });
}

Future<WindowsOAuthSession> _signedInSession() async {
  final tokenStore = MemoryTokenStore();
  await seedSignedIn(tokenStore);
  final session = WindowsOAuthSession(
    clientId: 'test-client',
    redirectUri: kDefaultWindowsRedirectUri,
    tokenStore: tokenStore,
    oauthClient: BungieOAuthClient(
      clientId: 'test-client',
      redirectUri: kDefaultWindowsRedirectUri,
      transport: (_) async => throw StateError('unused'),
    ),
    browserLauncher: FakeBrowserLauncher(),
  );
  await session.restore();
  return session;
}

FillInSavedBuildPlan _singleSlotPlan(
  MockBuild build, {
  required String instanceId,
}) {
  return FillInSavedBuildPlan(
    buildId: build.id,
    missing: const [],
    applied: [
      FillInAppliedSlot(
        slotWire: 'helmet',
        label: 'Test Helmet',
        originalLabel: 'Old Helmet',
        instanceId: instanceId,
        itemHash: 1001,
      ),
    ],
  );
}

FillInSavedBuildPlan _twoSlotPlan(
  MockBuild build, {
  required String presentId,
  required String missingId,
}) {
  return FillInSavedBuildPlan(
    buildId: build.id,
    missing: const [],
    applied: [
      FillInAppliedSlot(
        slotWire: 'helmet',
        label: 'Helmet Present',
        originalLabel: 'Old Helmet',
        instanceId: presentId,
        itemHash: 1001,
      ),
      FillInAppliedSlot(
        slotWire: 'gauntlets',
        label: 'Arms Missing',
        originalLabel: 'Old Arms',
        instanceId: missingId,
        itemHash: 1002,
      ),
    ],
  );
}
