import 'solipsism_flag.dart';
import 'warlock_matrix_build.dart';

/// Parses a decoded matrix object into read-only build rows.
///
/// Includes exotic-armor `builds` and `overflow_builds`, weapon-cell lists, and
/// Solipsism perk-combo `builds`. Skips `removed_builds` and empty status cells.
List<WarlockMatrixBuild> parseWarlockMatrix(Object? decoded) {
  if (decoded is! Map) {
    throw const FormatException('Warlock matrix root must be a JSON object');
  }
  final exotics = decoded['exotics'];
  if (exotics is! Map) {
    throw const FormatException('Warlock matrix is missing an exotics object');
  }
  final builds = <WarlockMatrixBuild>[];
  for (final entry in exotics.entries) {
    _appendExotic(builds, '${entry.key}', entry.value);
  }
  _appendWeaponCells(builds, decoded['weapons']);
  return List<WarlockMatrixBuild>.unmodifiable(builds);
}

void _appendExotic(
  List<WarlockMatrixBuild> builds,
  String exoticName,
  Object? node,
) {
  if (node is! Map) return;
  for (final entry in node.entries) {
    final subclassKey = '${entry.key}';
    if (!warlockMatrixSubclassKeys.contains(subclassKey)) continue;
    _appendSubclass(builds, exoticName, subclassKey, entry.value);
  }
  _appendComboTable(builds, exoticName, node['combos']);
}

void _appendWeaponCells(List<WarlockMatrixBuild> builds, Object? weapons) {
  if (weapons is! Map) return;
  final cells = weapons['cells'];
  if (cells is! Map) return;
  for (final entry in cells.entries) {
    _appendWeapon(builds, '${entry.key}', entry.value);
  }
}

void _appendWeapon(
  List<WarlockMatrixBuild> builds,
  String exoticName,
  Object? node,
) {
  if (node is! Map) return;
  for (final entry in node.entries) {
    final subclassKey = '${entry.key}';
    if (!warlockMatrixSubclassKeys.contains(subclassKey)) continue;
    _appendList(
      builds,
      exoticName,
      subclassKey,
      entry.value,
      isWeaponExotic: true,
    );
  }
}

void _appendComboTable(
  List<WarlockMatrixBuild> builds,
  String exoticName,
  Object? combos,
) {
  if (combos is! Map) return;
  final table = combos['combos'];
  if (table is! Map) return;
  for (final entry in table.entries) {
    final row = entry.value;
    if (row is! Map) continue;
    _appendComboList(builds, exoticName, row['builds']);
  }
}

void _appendComboList(
  List<WarlockMatrixBuild> builds,
  String exoticName,
  Object? raw,
) {
  if (raw is! List) return;
  for (final item in raw) {
    if (item is! Map) continue;
    final build = _buildFromMap(
      exoticName,
      _comboSubclass(item),
      item,
    );
    if (build != null) builds.add(build);
  }
}

String _comboSubclass(Map<dynamic, dynamic> item) {
  final raw = item['subclass'];
  if (raw is! String) return '';
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final key = trimmed.toLowerCase();
  if (warlockMatrixSubclassKeys.contains(key)) return key;
  return trimmed;
}

void _appendSubclass(
  List<WarlockMatrixBuild> builds,
  String exoticName,
  String subclassKey,
  Object? node,
) {
  if (node is! Map) return;
  _appendList(builds, exoticName, subclassKey, node['builds']);
  _appendList(builds, exoticName, subclassKey, node['overflow_builds']);
}

void _appendList(
  List<WarlockMatrixBuild> builds,
  String exoticName,
  String subclassKey,
  Object? raw, {
  bool isWeaponExotic = false,
}) {
  if (raw is! List) return;
  for (final item in raw) {
    final build = _buildFromMap(
      exoticName,
      subclassKey,
      item,
      isWeaponExotic: isWeaponExotic,
    );
    if (build != null) builds.add(build);
  }
}

WarlockMatrixBuild? _buildFromMap(
  String exoticName,
  String subclassKey,
  Object? item, {
  bool isWeaponExotic = false,
}) {
  if (item is! Map) return null;
  final name = item['name'];
  final creator = item['creator'];
  final dim = item['dim'];
  final title = name is String ? name.trim() : '';
  final author = creator is String ? creator.trim() : '';
  final dimLink = dim is String ? dim.trim() : '';
  return WarlockMatrixBuild(
    exoticName: exoticName,
    subclassKey: subclassKey,
    name: title.isEmpty ? 'Untitled build' : title,
    creator: author.isEmpty ? null : author,
    dimLink: dimLink.isEmpty ? null : dimLink,
    isWeaponExotic: isWeaponExotic,
  );
}
