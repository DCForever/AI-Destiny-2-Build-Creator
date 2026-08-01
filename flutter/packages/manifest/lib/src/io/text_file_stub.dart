/// Web / non-IO stubs — file-backed entity refresh is desktop-only.
Future<bool> textFileExists(String path) async => false;

Future<String?> readTextFile(String path) async => null;

Future<void> writeTextFile(String path, String contents) async {
  throw UnsupportedError(
    'File-backed entity cache write requires dart:io (desktop). '
    'Web hosts load prebuilt entity bundles (DART-044).',
  );
}

Future<void> ensureDirectories(Iterable<String> paths) async {
  // No-op on web.
}
