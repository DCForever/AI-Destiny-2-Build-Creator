import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/auth/windows_oauth_session.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_apply.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_fixture.dart';
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
      equipItem: (ctx, args) async {
        equippedIds.add(args.characterId);
      },
    );

    // Pass warlockB explicitly — even though A would be first if re-resolved.
    const target = BuildsMockApplyTarget(
      membership: DestinyMembership(
        membershipType: 3,
        membershipId: 'destiny-1',
        displayName: 'Guardian',
      ),
      character: warlockB,
    );

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

    final build = loadBuildsMockFixture().builds.first;
    final plan = FillInSavedBuildPlan(
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

    final outcome = await runBuildsMockApplyToCharacter(
      build: build,
      plan: plan,
      ports: BuildsMockApplyPorts(
        oauthSession: session,
        profileClient: FakeProfileClient(characters: const [warlockA, warlockB]),
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
}
