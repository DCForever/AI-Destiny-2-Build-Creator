import 'package:destiny2_web_host/db/tab_lock_backend.dart';
import 'package:destiny2_web_host/db/tab_writer_lock.dart';
import 'package:destiny2_web_host/db/web_database_bootstrap.dart';
import 'package:destiny2_web_host/db/web_database_opener.dart';
import 'package:destiny2_web_host/db/web_db_status.dart';
import 'package:test/test.dart';

void main() {
  group('TabWriterCoordinator', () {
    late MemoryTabLockBackend backend;

    setUp(() {
      backend = MemoryTabLockBackend();
    });

    test('first acquire is writer', () async {
      final a = TabWriterCoordinator(backend: backend, tabId: 'a');
      expect(await a.acquire(), WebDbRole.writer);
    });

    test('second concurrent tab is blocked', () async {
      final a = TabWriterCoordinator(backend: backend, tabId: 'a');
      final b = TabWriterCoordinator(backend: backend, tabId: 'b');
      expect(await a.acquire(), WebDbRole.writer);
      expect(await b.acquire(), WebDbRole.blocked);
    });

    test('after release, another tab can become writer', () async {
      final a = TabWriterCoordinator(backend: backend, tabId: 'a');
      final b = TabWriterCoordinator(backend: backend, tabId: 'b');
      await a.acquire();
      await a.release();
      expect(await b.acquire(), WebDbRole.writer);
    });

    test('expired lock can be taken over', () async {
      var now = DateTime.utc(2026, 1, 1, 12);
      final timed = MemoryTabLockBackend(
        ttl: const Duration(seconds: 5),
        clock: () => now,
      );
      final a = TabWriterCoordinator(backend: timed, tabId: 'a');
      final b = TabWriterCoordinator(backend: timed, tabId: 'b');
      expect(await a.acquire(), WebDbRole.writer);
      now = now.add(const Duration(seconds: 6));
      expect(await b.acquire(), WebDbRole.writer);
    });
  });

  group('WebDatabaseBootstrap', () {
    test('writer opens database via opener', () async {
      final backend = MemoryTabLockBackend();
      final opener = FakeWebDatabaseOpener(storageImplementation: 'opfsLocks');
      final boot = WebDatabaseBootstrap(
        lockBackend: backend,
        opener: opener,
        tabId: 'writer-tab',
      );
      final status = await boot.start();
      expect(status.role, WebDbRole.writer);
      expect(status.phase, WebDbPhase.ready);
      expect(status.storageImplementation, 'opfsLocks');
      expect(opener.openCount, 1);
      expect(boot.database, isNotNull);
      await boot.dispose();
    });

    test('blocked tab does not open database', () async {
      final backend = MemoryTabLockBackend();
      final openerA = FakeWebDatabaseOpener();
      final openerB = FakeWebDatabaseOpener();
      final a = WebDatabaseBootstrap(
        lockBackend: backend,
        opener: openerA,
        tabId: 'a',
      );
      final b = WebDatabaseBootstrap(
        lockBackend: backend,
        opener: openerB,
        tabId: 'b',
      );
      await a.start();
      final statusB = await b.start();
      expect(statusB.role, WebDbRole.blocked);
      expect(statusB.phase, WebDbPhase.ready);
      expect(statusB.summaryLine, contains('blocked'));
      expect(openerB.openCount, 0);
      expect(b.database, isNull);
      await a.dispose();
      await b.dispose();
    });
  });

  group('WebDbSessionStatus copy', () {
    test('blocked summary mentions another tab', () {
      const s = WebDbSessionStatus(
        phase: WebDbPhase.ready,
        role: WebDbRole.blocked,
      );
      expect(s.summaryLine, contains('another tab'));
      expect(s.roleLabel, 'Role: blocked');
    });

    test('writer ready summary includes storage', () {
      const s = WebDbSessionStatus(
        phase: WebDbPhase.ready,
        role: WebDbRole.writer,
        storageImplementation: 'sharedIndexedDb',
      );
      expect(s.summaryLine, contains('writer'));
      expect(s.summaryLine, contains('sharedIndexedDb'));
      expect(s.roleLabel, 'Role: writer');
    });
  });
}
