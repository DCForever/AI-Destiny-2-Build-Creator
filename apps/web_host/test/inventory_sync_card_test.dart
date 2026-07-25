import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_web_host/auth/token_store.dart';
import 'package:destiny2_web_host/settings/inventory_sync_card.dart';
import 'package:destiny2_web_host/settings/inventory_sync_controller.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:test/test.dart';

import 'inventory_sync_test_fakes.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    defaultInventoryBusyLock.clearForTests();
  });

  tearDown(() async {
    defaultInventoryBusyLock.clearForTests();
    await db.close();
  });

  group('InventorySyncCard', () {
    testComponents('signed-out shows sign-in gate', (tester) async {
      final store = MemoryTokenStore();
      final session = buildSignedInSession(store: store);
      await session.restore();
      final controller = InventorySyncController(
        db: db,
        session: session,
        profileClient: FakeProfileClient(),
      );

      tester.pumpComponent(
        InventorySyncCard(controller: controller, session: session),
      );

      expect(find.text('Inventory sync'), findsOneComponent);
      expect(
        find.textContaining('Sign in to sync owned inventory'),
        findsOneComponent,
      );
      // Policy may mention absence of secret; must not assign one.
      expect(find.textContaining('BUNGIE_CLIENT_SECRET='), findsNothing);
      expect(find.textContaining('SESSION_SECRET='), findsNothing);
    });

    testComponents('signed-in shows Sync now and meta keys', (tester) async {
      final store = MemoryTokenStore();
      await seedSignedIn(store);
      final session = buildSignedInSession(store: store);
      await session.restore();
      final controller = InventorySyncController(
        db: db,
        session: session,
        profileClient: FakeProfileClient(),
      );

      tester.pumpComponent(
        InventorySyncCard(controller: controller, session: session),
      );
      await tester.pump();

      expect(find.text('Sync now'), findsOneComponent);
      expect(find.textContaining('Items:'), findsOneComponent);
      expect(find.textContaining('equipment-bucket resolution'), findsOneComponent);
      expect(find.textContaining('No CLIENT_SECRET'), findsOneComponent);
    });
  });
}
