import 'warlock_matrix_build.dart';

/// Exotic names that actually have builds, sorted for a picker.
List<String> exoticNamesIn(List<WarlockMatrixBuild> builds) {
  final names = builds.map((build) => build.exoticName).toSet().toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return List<String>.unmodifiable(names);
}

/// Builds for [exoticName], or every build when [exoticName] is null/blank.
List<WarlockMatrixBuild> filterWarlockBuildsByExotic(
  List<WarlockMatrixBuild> builds,
  String? exoticName,
) {
  final selected = exoticName?.trim() ?? '';
  if (selected.isEmpty) {
    return List<WarlockMatrixBuild>.unmodifiable(builds);
  }
  return List<WarlockMatrixBuild>.unmodifiable(
    builds.where((build) => build.exoticName == selected),
  );
}
