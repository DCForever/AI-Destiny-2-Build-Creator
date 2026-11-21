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

/// Skeptic plan item 3 (2026-11-20): guard-state error paths fail closed —
/// a read error, missing marker, or empty ownership set holds or refuses.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const warlockA = CharacterSummary(
    characterId: '2305843009264904821',
    classType: 'Warlock',
    light: 2010,
  );
  const membership = DestinyMembership(
    membershipType: 3,
    membershipId: 'destiny-1',
    displayName: 'Guardian',
  );

  Future<WindowsOAuthSession> signedInSession() async {
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

  FillInSavedBuildPlan singleSlotPlan(MockBuild build) {
    return FillInSavedBuildPlan(
      buildId: build.id,
      missing: const [],
      applied: const [
        FillInAppliedSlot(
          slotWire: 'helmet',
          label: 'Test Helmet',
          originalLabel: 'Old Helmet',
          instanceId: 'inst-helmet-1',
          itemHash: 1001,
        ),
      ],
    );
  }

  Future<({List<String> equipped, int transfers, BuildsMockApplyOutcome outcome})>
      runApply({
    required FakeProfileClient profile,
  }) async {
    final equipped = <String>[];
    var transfers = 0;
    final writeClient = createMockWriteClient(
      transferItem: (ctx, args) async => transfers += 1,
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
    final session = await signedInSession();
    final build = loadBuildsMockFixture().builds.first;
    final outcome = await runBuildsMockApplyToCharacter(
      build: build,
      plan: singleSlotPlan(build),
      ports: BuildsMockApplyPorts(
        oauthSession: session,
        profileClient: profile,
        writeClient: writeClient,
      ),
      target: const BuildsMockApplyTarget(
        membership: membership,
        character: warlockA,
      ),
      isMounted: () => true,
      onProgress: (_) {},
    );
    return (equipped: equipped, transfers: transfers, outcome: outcome);
  }

  test('Skeptic #3: inventory read error refuses writes (fail closed)', () async {
    final result = await runApply(
      profile: FakeProfileClient(
        characters: const [warlockA],
        throwOnInventory: true,
      ),
    );
    expect(result.equipped, isEmpty);
    expect(result.transfers, 0);
    expect(result.outcome.progress!.failedCount, 1);
    expect(
      result.outcome.progress!.items.single.reason,
      kApplyLiveInventoryReadFailedReason,
    );
    expect(result.outcome.progress!.items.single.state, ApplyItemState.failed);
  });

  test(
    'Skeptic #3: missing inventory completeness marker refuses writes',
    () async {
      final result = await runApply(
        profile: FakeProfileClient(
          characters: const [warlockA],
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
      );
      expect(result.equipped, isEmpty);
      expect(result.transfers, 0);
      expect(result.outcome.progress!.failedCount, 1);
      expect(
        result.outcome.progress!.items.single.reason,
        kApplyLiveInventoryReadFailedReason,
      );
    },
  );

  test(
    'Skeptic #3: empty live inventory refuses writes (empty ownership gate)',
    () async {
      final result = await runApply(
        profile: FakeProfileClient(
          characters: const [warlockA],
          items: const [],
        ),
      );
      expect(result.equipped, isEmpty);
      expect(result.transfers, 0);
      expect(result.outcome.progress!.failedCount, 1);
      expect(
        result.outcome.progress!.items.single.reason,
        kApplyLiveInventoryReadFailedReason,
      );
    },
  );
}
