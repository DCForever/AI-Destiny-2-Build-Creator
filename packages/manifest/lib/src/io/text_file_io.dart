import 'dart:io';

/// Native file text helpers (dart:io).
Future<bool> textFileExists(String path) => File(path).exists();

Future<String?> readTextFile(String path) async {
  final file = File(path);
  if (!await file.exists()) return null;
  return file.readAsString();
}

Future<void> writeTextFile(String path, String contents) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(contents);
}

Future<void> ensureDirectories(Iterable<String> paths) async {
  for (final path in paths) {
    await Directory(path).create(recursive: true);
  }
}
