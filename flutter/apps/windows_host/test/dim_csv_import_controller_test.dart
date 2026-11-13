import 'dart:io';

import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/settings/dim_csv_import_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Minimal synthetic DIM Armor CSV (header + one Warlock helmet).
const String _kArmorCsv = 'Name,Hash,Id,Equippable,Type,Rarity\n'
    'Techsec Helm,111001,"1000000000000000001",Warlock,Helmet,Legendary\n';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late StorageRoot root;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('dim_csv_ctrl_');
    root = StorageRoot(basePath: temp.path);
    await root.ensureLayout();
  });

  tearDown(() async {
    if (temp.existsSync()) {
      await temp.delete(recursive: true);
    }
  });

  test('loadCachedStatus reports not imported when cache missing', () async {
    final controller = DimCsvImportController.armor(storageRoot: root);
    addTearDown(controller.dispose);

    await controller.loadCachedStatus();

    expect(controller.phase, DimCsvImportPhase.idle);
    expect(controller.displayStatus, 'not imported yet');
    expect(controller.cachedCount, isNull);
  });

  test('loadCachedStatus reports cached count after import', () async {
    final source = File(p.join(temp.path, 'armor.csv'));
    await source.writeAsString(_kArmorCsv, flush: true);

    final controller = DimCsvImportController.armor(storageRoot: root);
    addTearDown(controller.dispose);

    controller.setSourcePath(source.path);
    await controller.importFromPath();
    expect(controller.displayStatus, startsWith('Imported '));
    expect(controller.cachedCount, 1);

    final reloaded = DimCsvImportController.armor(storageRoot: root);
    addTearDown(reloaded.dispose);
    await reloaded.loadCachedStatus();
    expect(reloaded.displayStatus, 'Cached: 1 items');
    expect(reloaded.cachedCount, 1);
  });

  test('importFromPath surfaces parse errors', () async {
    final bad = File(p.join(temp.path, 'bad.csv'));
    await bad.writeAsString('Foo,Bar\n1,2\n', flush: true);

    final controller = DimCsvImportController.armor(storageRoot: root);
    addTearDown(controller.dispose);

    controller.setSourcePath(bad.path);
    await controller.importFromPath();

    expect(controller.phase, DimCsvImportPhase.error);
    expect(controller.errorMessage, contains("Couldn't read file"));
  });
}
