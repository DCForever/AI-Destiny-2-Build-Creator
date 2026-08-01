import 'dart:convert';
import 'dart:io';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_storage/destiny2_storage.dart';

/// Load DestinyLoadout* presentation tables from [StorageRoot] raw JSON.
///
/// Returns empty tables when version or files are missing (fallback names).
Future<LoadoutPresentationTables> loadLoadoutPresentationTablesFromStorage(
  StorageRoot root,
) async {
  final version = await _readCurrentVersion(root);
  if (version == null || version.isEmpty) {
    return const LoadoutPresentationTables();
  }

  Future<Map<String, Object?>> loadTable(String table) async {
    final path = root.rawTablePath(version, table);
    final file = File(path);
    if (!await file.exists()) return const {};
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) return const {};
    final out = <String, Object?>{};
    for (final e in decoded.entries) {
      out[e.key.toString()] = e.value;
    }
    return out;
  }

  final icons = await loadTable('DestinyLoadoutIconDefinition');
  final colors = await loadTable('DestinyLoadoutColorDefinition');
  final names = await loadTable('DestinyLoadoutNameDefinition');
  return presentationTablesFromRaw(
    icons: icons,
    colors: colors,
    names: names,
  );
}

Future<String?> _readCurrentVersion(StorageRoot root) async {
  final file = File(root.currentVersionPath);
  if (!await file.exists()) return null;
  try {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is Map && decoded['version'] is String) {
      return decoded['version'] as String;
    }
    if (decoded is String) return decoded;
  } catch (_) {
    return null;
  }
  return null;
}
