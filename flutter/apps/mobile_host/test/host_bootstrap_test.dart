import 'dart:io';

import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_mobile_host/host_bootstrap.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRefresh implements ManifestRefreshApi {
  _FakeRefresh(this.fixed);

  final ManifestStatus fixed;

  @override
  Future<bool> isStale() async => fixed.isStale;

  @override
  Future<ManifestStatus> refresh({
    bool forceFullDownload = false,
    bool rebuildInIsolate = true,
  }) async =>
      fixed;

  @override
  Future<ManifestStatus> status() async => fixed;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dart040_bootstrap_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('open ensures layout, opens single DB, dispose closes', () async {
    final root = StorageRoot(basePath: tempDir.path);
    final db = AppDatabase.file(root.appDbPath);
    final services = await MobileHostBootstrap.open(
      storageRoot: root,
      database: db,
      manifestRefresh: _FakeRefresh(
        const ManifestStatus(
          cachedVersion: null,
          remoteVersion: null,
          isStale: true,
          entityCache: null,
        ),
      ),
    );

    expect(services.db, same(db));
    expect(services.isClosed, isFalse);
    expect(File(root.appDbPath).existsSync(), isTrue);
    expect(Directory(root.manifestDir).existsSync(), isTrue);
    expect(Directory(root.entitiesDir).existsSync(), isTrue);

    await services.dispose();
    expect(services.isClosed, isTrue);
  });
}
