import 'dart:io';

import 'package:path/path.dart' as p;

/// Fail closed when a resolved path is outside [Directory.systemTemp].
///
/// Test-only helper (not part of the storage public API). Resolves through
/// symlinks; for paths that do not exist yet, resolves the nearest existing
/// ancestor and rejoins the remainder so `link/to/outside/new.csv` fails.
/// A dangling / unresolvable symlink fails closed (does not fall back).
void assertResolvedPathIsUnderSystemTemp(String path) {
  final resolved = resolvePathForTempGuard(path);
  final tempRoot = resolvePathForTempGuard(Directory.systemTemp.path);
  final ok = resolved == tempRoot || p.isWithin(tempRoot, resolved);
  if (!ok) {
    throw StateError(
      'Resolved path is outside system temp (fail closed): $resolved '
      '(temp root: $tempRoot)',
    );
  }
}

/// Resolve [path] for temp-root checks (symlink-aware, nearest-parent).
String resolvePathForTempGuard(String path) {
  final absolute = p.normalize(p.absolute(path));
  final missing = <String>[];
  var current = absolute;
  while (true) {
    final type = FileSystemEntity.typeSync(current, followLinks: false);
    if (type != FileSystemEntityType.notFound) {
      try {
        final resolved = _resolveExisting(current, type);
        if (missing.isEmpty) return resolved;
        return p.normalize(p.join(resolved, p.joinAll(missing.reversed)));
      } on FileSystemException catch (e) {
        throw StateError(
          'Path could not be resolved (fail closed): $absolute ($e)',
        );
      }
    }
    final parent = p.dirname(current);
    if (parent == current) return absolute;
    missing.add(p.basename(current));
    current = parent;
  }
}

String _resolveExisting(String path, FileSystemEntityType type) {
  if (type == FileSystemEntityType.directory) {
    return Directory(path).resolveSymbolicLinksSync();
  }
  if (type == FileSystemEntityType.link) {
    return Link(path).resolveSymbolicLinksSync();
  }
  return File(path).resolveSymbolicLinksSync();
}
