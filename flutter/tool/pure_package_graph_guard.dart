// Pure-package dependency graph guard (DART-011).
//
// Usage (from workspace root):
//   dart run tool/pure_package_graph_guard.dart
//
// Exit 0 when all pure packages have no forbidden runtime dependencies.
// Exit 1 on violations or I/O errors.

import 'dart:io';

import 'pure_packages.dart';

/// One forbidden runtime dependency on a pure package.
class PurePackageViolation {
  PurePackageViolation({
    required this.packageDir,
    required this.dependencyName,
    required this.pubspecPath,
  });

  final String packageDir;
  final String dependencyName;
  final String pubspecPath;

  @override
  String toString() =>
      'FORBIDDEN runtime dependency "$dependencyName" in $pubspecPath '
      '(pure package $packageDir)';
}

/// Result of scanning pure packages.
class GraphGuardResult {
  GraphGuardResult({
    required this.violations,
    required this.packagesScanned,
  });

  final List<PurePackageViolation> violations;
  final List<String> packagesScanned;

  bool get isClean => violations.isEmpty;
}

/// Parse the top-level `dependencies:` map keys from a pubspec string.
///
/// Handles common pubspec forms used in this monorepo:
/// - `dependencies: {}`
/// - multi-line map with `  name: version` or `  name:` nested maps
/// - does not resolve SDK/`any` values — only package *names*
///
/// Not a full YAML parser; sufficient for purity lint of simple pubspecs.
List<String> parseRuntimeDependencyNames(String pubspecContents) {
  final lines = pubspecContents.split(RegExp(r'\r?\n'));
  final names = <String>[];
  var inDependencies = false;
  var dependenciesIndent = -1;

  for (final raw in lines) {
    final line = raw.replaceAll('\t', '  ');
    final trimmed = line.trimRight();
    if (trimmed.trim().isEmpty || trimmed.trimLeft().startsWith('#')) {
      continue;
    }

    final indent = _leadingSpaces(line);
    final content = trimmed.trimLeft();

    if (!inDependencies) {
      if (RegExp(r'^dependencies\s*:').hasMatch(content)) {
        inDependencies = true;
        dependenciesIndent = indent;
        // Inline empty map: dependencies: {}
        final after = content.substring(content.indexOf(':') + 1).trim();
        if (after == '{}') {
          return names;
        }
        if (after.isNotEmpty && !after.startsWith('#')) {
          // Uncommon single-line map — ignore beyond empty form.
        }
      }
      continue;
    }

    // Left the dependencies block when a non-empty line is at same/less indent.
    if (indent <= dependenciesIndent && content.isNotEmpty) {
      // New top-level key
      if (!content.startsWith('#')) {
        break;
      }
    }

    // Keys inside dependencies are direct children (indent > dependenciesIndent).
    // Nested map values (e.g. sdk: flutter) have greater indent — skip those.
    final childIndent = dependenciesIndent < 0 ? 0 : dependenciesIndent;
    if (indent > childIndent) {
      // Only top-level keys of the dependencies map (exactly one indent step
      // of 2 spaces relative to `dependencies:` is typical).
      final relative = indent - childIndent;
      if (relative >= 1 && relative <= 2) {
        final keyMatch = RegExp(r'^([A-Za-z0-9_.-]+)\s*:').firstMatch(content);
        if (keyMatch != null) {
          final key = keyMatch.group(1)!;
          // Skip YAML merge keys etc.
          if (key != '<<') {
            names.add(key);
          }
        }
      }
      // Nested keys (sdk, path, git, hosted, version under a dep) are ignored.
    }
  }

  return names;
}

int _leadingSpaces(String line) {
  var n = 0;
  for (var i = 0; i < line.length; i++) {
    if (line.codeUnitAt(i) == 0x20) {
      n++;
    } else {
      break;
    }
  }
  return n;
}

/// Scan one pubspec file content for forbidden runtime deps.
List<PurePackageViolation> scanPubspecContent({
  required String packageDir,
  required String pubspecPath,
  required String contents,
}) {
  final deps = parseRuntimeDependencyNames(contents);
  final out = <PurePackageViolation>[];
  for (final dep in deps) {
    if (isForbiddenRuntimeDependency(dep)) {
      out.add(
        PurePackageViolation(
          packageDir: packageDir,
          dependencyName: dep,
          pubspecPath: pubspecPath,
        ),
      );
    }
  }
  return out;
}

/// Scan all configured pure packages under [workspaceRoot].
GraphGuardResult scanPurePackages(Directory workspaceRoot) {
  final violations = <PurePackageViolation>[];
  final scanned = <String>[];

  for (final rel in purePackageDirs) {
    scanned.add(rel);
    final pubspecFile = File.fromUri(
      workspaceRoot.uri.resolve('$rel/pubspec.yaml'),
    );
    if (!pubspecFile.existsSync()) {
      violations.add(
        PurePackageViolation(
          packageDir: rel,
          dependencyName: '<missing pubspec.yaml>',
          pubspecPath: pubspecFile.path,
        ),
      );
      continue;
    }
    final contents = pubspecFile.readAsStringSync();
    violations.addAll(
      scanPubspecContent(
        packageDir: rel,
        pubspecPath: pubspecFile.path,
        contents: contents,
      ),
    );
  }

  return GraphGuardResult(violations: violations, packagesScanned: scanned);
}

/// True when [dir] is the Melos/pub workspace root for this monorepo.
bool isDartWorkspaceRoot(Directory dir) {
  final pubspec = File.fromUri(dir.uri.resolve('pubspec.yaml'));
  if (!pubspec.existsSync()) return false;
  final text = pubspec.readAsStringSync();
  return text.contains(RegExp(r'^workspace\s*:', multiLine: true)) ||
      text.contains('destiny2_build_creator_workspace');
}

/// Resolve Dart workspace root (`flutter/` after DART-069).
///
/// Walks parents looking for the workspace pubspec. Also accepts monorepo
/// root (or any ancestor) that contains a nested `flutter/` workspace so
/// gates work when cwd is the git repository root.
Directory findWorkspaceRoot([Directory? start]) {
  var dir = start ?? Directory.current;
  while (true) {
    if (isDartWorkspaceRoot(dir)) {
      return dir;
    }
    final nestedFlutter = Directory.fromUri(dir.uri.resolve('flutter/'));
    if (isDartWorkspaceRoot(nestedFlutter)) {
      return nestedFlutter;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return Directory.current;
    }
    dir = parent;
  }
}

int runGraphGuard({Directory? workspaceRoot, bool quiet = false}) {
  final root = workspaceRoot ?? findWorkspaceRoot();
  final result = scanPurePackages(root);

  if (!quiet) {
    stdout.writeln(
      'Pure package graph guard — scanned ${result.packagesScanned.length} '
      'package(s): ${result.packagesScanned.join(', ')}',
    );
  }

  if (result.isClean) {
    if (!quiet) {
      stdout.writeln(
        'OK: no forbidden IO/UI runtime dependencies on pure packages.',
      );
    }
    return 0;
  }

  stderr.writeln(
    'FAIL: ${result.violations.length} pure-package dependency violation(s):',
  );
  for (final v in result.violations) {
    stderr.writeln('  - $v');
  }
  stderr.writeln(
    'Pure packages must keep zero Flutter/Jaspr/Drift/http/path_provider '
    '(and related) runtime deps. See packages/README.md and DART-011.',
  );
  return 1;
}

void main(List<String> args) {
  final quiet = args.contains('--quiet');
  exitCode = runGraphGuard(quiet: quiet);
}
