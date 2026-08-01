import 'dart:io';

import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:test/test.dart';

import 'fixtures/raw_tables.dart';

void main() {
  late Directory tmp;
  late FileEntityCache cache;
  late StoreItemResolver resolver;
  late StorePerkValidator validator;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('dart-017-resolve-');
    final root = StorageRoot(basePath: tmp.path);
    await root.ensureLayout();
    cache = FileEntityCache(storageRoot: root);
    await cache.rebuild(
      version: 'resolve-1',
      loadRawTable: loadFixtureRawTable,
      builtAt: DateTime.utc(2026, 7, 24),
    );
    resolver = StoreItemResolver(cache);
    validator = StorePerkValidator(cache);
  });

  tearDown(() async {
    if (await tmp.exists()) {
      await tmp.delete(recursive: true);
    }
  });

  test('exact resolve exotic armor by name', () async {
    final hit = await resolver.resolve<ExoticArmorRecord>(
      MvpStoreName.exoticArmor,
      'Celestial Nighthawk',
    );
    expect(hit, isNotNull);
    expect(hit!.confidence, 1);
    expect(hit.record.hash, 1001);
  });

  test('getByHash for aspect', () async {
    final aspect = await resolver.getByHash<AspectRecord>(
      MvpStoreName.aspects,
      1014,
    );
    expect(aspect?.name, 'Touch of Thunder');
    expect(aspect?.fragmentCapacity, 4);
  });

  test('weapon perk legal and illegal', () async {
    final legal = await validator.checkWeaponPerk(1007, 1012);
    expect(legal, isA<PerkLegal>());

    final illegal = await validator.checkWeaponPerk(1007, 999999);
    expect(illegal, isA<PerkIllegal>());

    final missingWeapon = await validator.checkWeaponPerk(1, 1012);
    expect(missingWeapon, isA<PerkIllegal>());
  });

  test('fragment count from aspect hashes', () async {
    final check = await validator.checkFragmentCount([1014, 1015], 5);
    expect(check.capacity, 6);
    expect(check.legal, isTrue);

    final over = await validator.checkFragmentCount([1014], 5);
    expect(over.capacity, 4);
    expect(over.legal, isFalse);
  });
}
