// One-shot Flutter Driver screenshots for dual-truth Capture.
//
// App must already run with enableFlutterDriverExtension (e.g.
// lib/main_roll_targets_capture.dart).
//
//   dart run tool/capture_driver_shots.dart \
//     http://127.0.0.1:PORT/TOKEN=/ \
//     F:/.../implementation-shots/003-catalog-roll-targets \
//     sequence.json
//
// sequence.json: [ {"tapKey":"catalog_item_92001","shot":"desktop-detail-active-partial-scores"}, ... ]
// Omit tapKey to screenshot current state only.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

Future<void> main(List<String> args) async {
  if (args.length < 3) {
    stderr.writeln(
      'Usage: dart run tool/capture_driver_shots.dart <vm-service-url> <out-dir> <sequence.json>',
    );
    exitCode = 2;
    return;
  }
  var url = args[0];
  if (!url.endsWith('/')) url = '$url/';
  final outDir = Directory(args[1]);
  await outDir.create(recursive: true);
  final steps = jsonDecode(await File(args[2]).readAsString()) as List<dynamic>;

  final driver = await FlutterDriver.connect(dartVmServiceUrl: url);
  try {
    for (final step in steps) {
      final m = Map<String, dynamic>.from(step as Map);
      final tapKey = m['tapKey'] as String?;
      final shot = m['shot'] as String;
      if (tapKey != null && tapKey.isNotEmpty) {
        await driver.waitFor(find.byValueKey(tapKey), timeout: const Duration(seconds: 12));
        await driver.tap(find.byValueKey(tapKey));
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      final bytes = await driver.screenshot();
      final file = File('${outDir.path}${Platform.pathSeparator}$shot.png');
      await file.writeAsBytes(bytes, flush: true);
      stdout.writeln('wrote ${file.path} (${bytes.length} bytes)');
    }
  } finally {
    await driver.close();
  }
}
