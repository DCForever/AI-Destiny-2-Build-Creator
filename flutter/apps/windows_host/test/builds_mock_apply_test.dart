import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_bungie/destiny2_bungie.dart';
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
    '(3a) inventory read failure makes zero equipItems calls and shows reason',
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
    '(3b) empty live inventory makes zero equipItems calls and shows reason',
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
      expect(outcome.progress!.failedCount, 1);
      expect(
        outcome.progress!.items.single.reason,
        kApplyLiveInventoryReadFailedReason,
      );
    },
  );

  test(
    '(B1) partial profile (missing component section) is read failure, '
    'not re-import DIM CSV',
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
      confirmMoves: (_) async => true,
      onProgress: (_) {},
    );

    expect(outcome.error, isNull);
    expect(transfers, hasLength(1));
    expect(transfers.single.transferToVault, isFalse);
    expect(equipped, ['inst-vault-1']);
    expect(outcome.progress!.appliedCount, 1);
    expect(outcome.progress!.failedCount, 0);
    expect(outcome.progress!.items.single.state, ApplyItemState.done);
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
