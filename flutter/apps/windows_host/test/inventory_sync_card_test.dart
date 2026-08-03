import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/auth/windows_oauth_session.dart';
import 'package:destiny2_windows_host/host_bootstrap.dart';
import 'package:destiny2_windows_host/settings/inventory_sync_card.dart';
import 'package:destiny2_windows_host/settings/inventory_sync_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_material_theme.dart';

import 'inventory_sync_test_fakes.dart';

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late InventoryBusyLock lock;

  setUp(() {
    db = AppDatabase.memory();
    lock = InventoryBusyLock();
    defaultInventoryBusyLock.clearForTests();
  });

  tearDown(() async {
    defaultInventoryBusyLock.clearForTests();
    await db.close();
  });

  testWidgets('signed-out shows sign-in message and disabled Sync',
      (tester) async {
    final session = WindowsOAuthSession(
      clientId: 'test-client',
      redirectUri: kDefaultWindowsRedirectUri,
      tokenStore: MemoryTokenStore(),
      oauthClient: BungieOAuthClient(
        clientId: 'test-client',
        redirectUri: kDefaultWindowsRedirectUri,
        transport: (_) async => throw StateError('unused'),
      ),
      browserLauncher: FakeBrowserLauncher(),
    );
    await session.restore();
    final controller = InventorySyncController(
      db: db,
      session: session,
      profileClient: FakeProfileClient(),
      lock: lock,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: testMaterialTheme(),
        home: Scaffold(
          body: InventorySyncCard(controller: controller, session: session),
        ),
      ),
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('inventory_sync_card')), findsOneWidget);
    expect(find.byKey(const Key('inventory_sync_signed_out')), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('inventory_sync_now')),
    );
    expect(button.onPressed, isNull);

    controller.dispose();
  });

  testWidgets('signed-in Sync now updates item count', (tester) async {
    final store = MemoryTokenStore();
    await seedSignedIn(store);
    final session = buildSignedInSession(store: store);
    await session.restore();
    final profile = FakeProfileClient();
    final controller = InventorySyncController(
      db: db,
      session: session,
      profileClient: profile,
      lock: lock,
      clock: () => DateTime.utc(2026, 7, 24, 12),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: testMaterialTheme(),
        home: Scaffold(
          body: InventorySyncCard(controller: controller, session: session),
        ),
      ),
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('inventory_sync_now')), findsOneWidget);
    await tester.tap(find.byKey(const Key('inventory_sync_now')));
    await _pumpFrames(tester);
    // Allow async sync to complete.
    await tester.pump(const Duration(milliseconds: 100));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('inventory_item_count')), findsOneWidget);
    expect(find.textContaining('Items: 2'), findsOneWidget);
    expect(find.byKey(const Key('inventory_sync_version')), findsOneWidget);
    expect(find.textContaining('Sync version: 1'), findsOneWidget);
    expect(profile.inventoryCalls, 1);
    // DART-053 diagnostics surface after successful sync.
    expect(find.byKey(const Key('inventory_sync_diagnostics')), findsOneWidget);
    expect(find.byKey(const Key('inventory_diag_raw')), findsOneWidget);
    expect(find.byKey(const Key('inventory_diag_parsed')), findsOneWidget);
    expect(find.byKey(const Key('inventory_diag_dropped')), findsOneWidget);
    expect(
      find.byKey(const Key('inventory_diag_resolved_transfer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventory_diag_dropped_non_equipment')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('inventory_diag_stored_total')), findsOneWidget);
    expect(find.textContaining('Stored total: 2'), findsOneWidget);
    expect(find.textContaining('Bungie raw items'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('shows error text when sync fails', (tester) async {
    final store = MemoryTokenStore();
    await seedSignedIn(store);
    final session = buildSignedInSession(store: store);
    await session.restore();
    final controller = InventorySyncController(
      db: db,
      session: session,
      profileClient: FakeProfileClient(throwOnInventory: true),
      lock: lock,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: testMaterialTheme(),
        home: Scaffold(
          body: InventorySyncCard(controller: controller, session: session),
        ),
      ),
    );
    await _pumpFrames(tester);

    await tester.tap(find.byKey(const Key('inventory_sync_now')));
    await tester.pump(const Duration(milliseconds: 100));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('inventory_sync_error')), findsOneWidget);

    controller.dispose();
  });

  testWidgets('busy indicator while syncing', (tester) async {
    final store = MemoryTokenStore();
    await seedSignedIn(store);
    final session = buildSignedInSession(store: store);
    await session.restore();
    final profile = FakeProfileClient(
      inventoryDelay: const Duration(milliseconds: 200),
    );
    final controller = InventorySyncController(
      db: db,
      session: session,
      profileClient: profile,
      lock: lock,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: testMaterialTheme(),
        home: Scaffold(
          body: InventorySyncCard(controller: controller, session: session),
        ),
      ),
    );
    await _pumpFrames(tester);

    await tester.tap(find.byKey(const Key('inventory_sync_now')));
    await tester.pump(); // start
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byKey(const Key('inventory_sync_busy')), findsOneWidget);
    expect(find.byKey(const Key('inventory_sync_now')), findsNothing);

    await tester.pump(const Duration(milliseconds: 250));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('inventory_sync_busy')), findsNothing);
    expect(find.byKey(const Key('inventory_sync_now')), findsOneWidget);

    controller.dispose();
  });

  testWidgets('freshness label stale when never synced', (tester) async {
    final store = MemoryTokenStore();
    await seedSignedIn(store);
    final session = buildSignedInSession(store: store);
    await session.restore();
    final controller = InventorySyncController(
      db: db,
      session: session,
      profileClient: FakeProfileClient(),
      lock: lock,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: testMaterialTheme(),
        home: Scaffold(
          body: InventorySyncCard(controller: controller, session: session),
        ),
      ),
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('inventory_freshness')), findsOneWidget);
    expect(find.textContaining('never synced'), findsOneWidget);

    controller.dispose();
  });
}
