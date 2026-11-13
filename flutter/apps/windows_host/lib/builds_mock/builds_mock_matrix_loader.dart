import 'dart:convert';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';

import 'builds_mock_controller.dart';
import 'builds_mock_matrix.dart';

/// Read-only Warlock matrix load into [controller] (Builds page production path).
///
/// Same [readOnlyFileBytes] + [maxBytes] gate as Warlocks. Never writes the
/// matrix file. On size-limit / IO / JSON failure, sets [BuildsMockController]
/// matrix error and leaves the build list empty (no sample fixture).
Future<void> loadBuildsMatrixIntoController({
  required BuildsMockController controller,
  required String? path,
  int maxBytes = kCachedDimLoadoutsMaxBytes,
}) async {
  final trimmed = path?.trim() ?? '';
  if (trimmed.isEmpty) {
    controller.failMatrixLoad(
      'No matrix file path. Set it in Settings (Warlock matrix file) '
      'or WARLOCK_MATRIX_PATH.',
    );
    return;
  }
  controller.beginMatrixLoad();
  try {
    final bytes = await readOnlyFileBytes(trimmed, maxBytes: maxBytes);
    final decoded = jsonDecode(utf8.decode(bytes));
    final rows = parseWarlockMatrix(decoded);
    controller.adoptFixture(buildsMockFixtureFromMatrix(rows));
  } on ReadOnlyFileException catch (error) {
    controller.failMatrixLoad(error.message);
  } on FormatException catch (error) {
    controller.failMatrixLoad(
      'Matrix file is not valid JSON (${error.message}).',
    );
  } catch (error) {
    controller.failMatrixLoad('Could not read matrix: $error');
  }
}
