import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('resolveWarlockMatrixPath precedence', () {
    test('saved setting wins over env', () {
      expect(
        resolveWarlockMatrixPath(
          savedSetting: r'D:\matrix\saved.json',
          environment: {warlockMatrixPathEnv: r'D:\matrix\env.json'},
        ),
        r'D:\matrix\saved.json',
      );
    });

    test('env used when saved unset', () {
      expect(
        resolveWarlockMatrixPath(
          savedSetting: null,
          environment: {warlockMatrixPathEnv: '  /tmp/env-matrix.json  '},
        ),
        '/tmp/env-matrix.json',
      );
      expect(
        resolveWarlockMatrixPath(
          savedSetting: '   ',
          environment: {warlockMatrixPathEnv: '/tmp/env-matrix.json'},
        ),
        '/tmp/env-matrix.json',
      );
    });

    test('none when saved and env unset', () {
      expect(resolveWarlockMatrixPath(), isNull);
      expect(
        resolveWarlockMatrixPath(
          savedSetting: null,
          environment: {warlockMatrixPathEnv: '   '},
        ),
        isNull,
      );
    });
  });

  group('WarlockMatrixPathSetting', () {
    late Directory tempDir;
    late StorageRoot root;
    late WarlockMatrixPathSetting setting;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('warlock-matrix-setting-');
      root = StorageRoot(basePath: tempDir.path);
      await root.ensureLayout();
      setting = WarlockMatrixPathSetting(root: root);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('StorageRoot documents settings path segments', () {
      expect(root.settingsDir, p.join(tempDir.path, 'settings'));
      expect(
        root.warlockMatrixPathSettingPath,
        p.join(tempDir.path, 'settings', 'warlock_matrix_path.txt'),
      );
      expect(Directory(root.settingsDir).existsSync(), isTrue);
    });

    test('save round-trip in a temp StorageRoot', () async {
      expect(await setting.load(), isNull);

      const path = r'Z:\fixtures\warlock-matrix.json';
      await setting.save(path);

      expect(await setting.load(), path);
      expect(File(setting.settingPath).existsSync(), isTrue);
      expect(File('${setting.settingPath}.tmp').existsSync(), isFalse);

      await setting.save('  /other/matrix.json  ');
      expect(await setting.load(), '/other/matrix.json');
    });

    test('blank save clears the preference', () async {
      await setting.save(r'D:\matrix.json');
      await setting.save('   ');
      expect(await setting.load(), isNull);
    });

    test('save does not create or touch a sibling matrix source file', () async {
      final matrix = File(p.join(tempDir.path, 'warlock-matrix.json'));
      expect(matrix.existsSync(), isFalse);
      await setting.save(matrix.path);
      expect(matrix.existsSync(), isFalse);
      expect(File(setting.settingPath).existsSync(), isTrue);
    });

    test('load uses only the first line of the settings file', () async {
      await File(setting.settingPath).writeAsString(
        'D:\\matrix\\first.json\nD:\\matrix\\second.json\ntrail\n',
      );
      expect(await setting.load(), r'D:\matrix\first.json');
    });

    test('oversize settings file is rejected before use', () async {
      await File(setting.settingPath).writeAsBytes(
        List<int>.filled(64, 0x41),
        flush: true,
      );
      final capped = WarlockMatrixPathSetting(root: root, maxBytes: 8);
      await expectLater(
        capped.load(),
        throwsA(
          isA<WarlockMatrixPathSettingException>().having(
            (e) => e.message,
            'message',
            allOf(contains('size limit'), contains('64 > 8')),
          ),
        ),
      );
    });

    test('failed rename cleans up .tmp and leaves the original intact', () async {
      await setting.save(r'D:\matrix\original.json');
      final before = await File(setting.settingPath).readAsBytes();
      final beforeHash = sha256.convert(before);

      final failing = WarlockMatrixPathSetting(
        root: root,
        beforeRename: () async {
          throw StateError('simulated rename failure');
        },
      );
      await expectLater(
        failing.save(r'D:\matrix\new.json'),
        throwsA(isA<StateError>()),
      );

      final after = await File(setting.settingPath).readAsBytes();
      expect(sha256.convert(after).toString(), beforeHash.toString());
      expect(File('${setting.settingPath}.tmp').existsSync(), isFalse);
      expect(await setting.load(), r'D:\matrix\original.json');
    });

    test('stale .tmp is ignored on load and cleared by a successful save',
        () async {
      await setting.save(r'D:\matrix\keep.json');
      final tmp = File('${setting.settingPath}.tmp');
      await tmp.writeAsString(r'D:\matrix\stale.json', flush: true);
      expect(tmp.existsSync(), isTrue);

      expect(await setting.load(), r'D:\matrix\keep.json');

      await setting.save(r'D:\matrix\next.json');
      expect(await setting.load(), r'D:\matrix\next.json');
      expect(tmp.existsSync(), isFalse);
    });
  });
}
