import 'dart:io';

Future<void> ensureStorageLayout(String basePath, List<String> dirs) async {
  await Directory(basePath).create(recursive: true);
  for (final d in dirs) {
    await Directory(d).create(recursive: true);
  }
}
