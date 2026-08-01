import 'dart:io';

import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('versionToDirName', () {
    test('leaves safe characters unchanged', () {
      expect(versionToDirName('1.2.3_abc-DEF'), '1.2.3_abc-DEF');
    });

    test('replaces unsafe runs with underscore', () {
      expect(versionToDirName('foo/bar'), 'foo_bar');
      expect(versionToDirName('a b c'), 'a_b_c');
      expect(versionToDirName('x@y#z'), 'x_y_z');
      // Dots are allowed; only the slash run is replaced → ".._evil"
      expect(versionToDirName('../evil'), '.._evil');
    });
  });

  group('StorageRoot path composition (fake FS base)', () {
    // POSIX-style fake base keeps expectations stable on all CI hosts.
    const fakeBase = r'/tmp/fake-app-support';
    late StorageRoot root;

    setUp(() {
      root = StorageRoot(basePath: fakeBase);
    });

    test('appDbPath and currentVersionPath under base', () {
      expect(root.basePath, fakeBase);
      expect(root.appDbPath, p.join(fakeBase, 'app.db'));
      expect(root.currentVersionPath, p.join(fakeBase, 'current-version.json'));
    });

    test('top-level segment dirs', () {
      expect(root.manifestDir, p.join(fakeBase, 'manifest'));
      expect(root.entitiesDir, p.join(fakeBase, 'entities'));
      expect(root.usersDir, p.join(fakeBase, 'users'));
    });

    test('rawTablePath uses sanitized version', () {
      expect(
        root.rawTablePath('v1.0/beta', 'DestinyInventoryItemDefinition'),
        p.join(
          fakeBase,
          'manifest',
          'v1.0_beta',
          'DestinyInventoryItemDefinition.json',
        ),
      );
    });

    test('entity store, meta, perk index paths', () {
      const version = '2026.07.24';
      expect(
        root.entityStorePath(version, 'weapons'),
        p.join(fakeBase, 'entities', version, 'weapons.json'),
      );
      expect(
        root.entityCacheMetaPath(version),
        p.join(fakeBase, 'entities', version, 'meta.json'),
      );
      expect(
        root.perkWeaponIndexPath(version),
        p.join(fakeBase, 'entities', version, 'perk-weapon-index.json'),
      );
    });

    test('userPreferencesPath', () {
      expect(
        root.userPreferencesPath('46116860184'),
        p.join(fakeBase, 'users', '46116860184', 'preferences.json'),
      );
    });

    test('production layout does not use .cache segment', () {
      expect(root.basePath.contains('.cache'), isFalse);
      expect(root.appDbPath.contains('${p.separator}.cache${p.separator}'), isFalse);
      expect(root.appDbPath.endsWith('.cache'), isFalse);
      // Path segments under root must not introduce a .cache parent.
      final relativeDb = p.relative(root.appDbPath, from: root.basePath);
      expect(relativeDb.split(p.separator), isNot(contains('.cache')));
    });
  });

  group('StorageRoot.windowsAppSupport', () {
    test('uses application-support path as base (path_provider inject)', () {
      const support = r'C:\Users\dev\AppData\Roaming\com.example\destiny2';
      final root = StorageRoot.windowsAppSupport(support);
      expect(root.basePath, support);
      expect(root.appDbPath, p.join(support, 'app.db'));
      expect(root.basePath.contains('.cache'), isFalse);
    });
  });

  group('StorageRoot validation', () {
    test('rejects empty base path', () {
      expect(() => StorageRoot(basePath: ''), throwsArgumentError);
      expect(() => StorageRoot(basePath: '   '), throwsArgumentError);
      expect(() => StorageRoot.windowsAppSupport(''), throwsArgumentError);
    });
  });

  group('ensureLayout (temp real FS)', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('destiny2_storage_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('creates top-level layout directories', () async {
      final root = StorageRoot(basePath: tempDir.path);
      await root.ensureLayout();

      expect(Directory(root.basePath).existsSync(), isTrue);
      expect(Directory(root.manifestDir).existsSync(), isTrue);
      expect(Directory(root.entitiesDir).existsSync(), isTrue);
      expect(Directory(root.usersDir).existsSync(), isTrue);
    });
  });
}
