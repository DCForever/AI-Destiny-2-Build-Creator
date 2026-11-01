import 'warlock_matrix_build.dart';

/// Subclass buckets that hold builds. Other keys (combos, removed) are skipped.
const Set<String> warlockMatrixSubclassKeys = <String>{
  'arc',
  'prismatic',
  'solar',
  'stasis',
  'strand',
  'void',
};

/// Parses a decoded matrix object into read-only build rows.
///
/// Reads `exotics → subclass → builds` and `overflow_builds`. Does not include
/// `removed_builds` or perk `combos`.
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
  Object? raw,
) {
  if (raw is! List) return;
  for (final item in raw) {
    final build = _buildFromMap(exoticName, subclassKey, item);
    if (build != null) builds.add(build);
  }
}

WarlockMatrixBuild? _buildFromMap(
  String exoticName,
  String subclassKey,
  Object? item,
) {
  if (item is! Map) return null;
  final name = item['name'];
  final creator = item['creator'];
  final title = name is String ? name.trim() : '';
  final author = creator is String ? creator.trim() : '';
  return WarlockMatrixBuild(
    exoticName: exoticName,
    subclassKey: subclassKey,
    name: title.isEmpty ? 'Untitled build' : title,
    creator: author.isEmpty ? null : author,
  );
}
