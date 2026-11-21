import 'dart:io';

import 'package:path/path.dart' as p;

/// Fail closed when a resolved path is outside [Directory.systemTemp].
///
/// Used by Skeptic path guards so tests cannot write to
/// `/opt/cursor/artifacts` or other non-temp roots by resolving a path that
/// merely *looks* temporary.
void assertResolvedPathIsUnderSystemTemp(String path) {
  final resolved = _resolve(path);
  final tempRoot = _resolve(Directory.systemTemp.path);
  final ok = resolved == tempRoot || p.isWithin(tempRoot, resolved);
  if (!ok) {
    throw StateError(
      'Resolved path is outside system temp (fail closed): $resolved '
      '(temp root: $tempRoot)',
    );
  }
}

String _resolve(String path) {
  final entity = FileSystemEntity.typeSync(path) == FileSystemEntityType.notFound
      ? File(path)
      : (FileSystemEntity.isDirectorySync(path) ? Directory(path) : File(path));
  try {
    return entity.resolveSymbolicLinksSync();
  } on FileSystemException {
    // Path may not exist yet — still normalize absolute form.
    return p.normalize(p.absolute(path));
  }
}
