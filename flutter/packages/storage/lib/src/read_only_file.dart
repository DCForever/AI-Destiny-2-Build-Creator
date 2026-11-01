import 'dart:io';
import 'dart:typed_data';

/// Failure while reading a local file that must stay unchanged.
class ReadOnlyFileException implements Exception {
  ReadOnlyFileException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reads [path] and returns its bytes.
///
/// Opens with [FileMode.read] only. Does not create, truncate, or write.
Future<Uint8List> readOnlyFileBytes(String path) async {
  final trimmed = path.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(path, 'path', 'path is required');
  }
  final file = File(trimmed);
  if (!await file.exists()) {
    throw ReadOnlyFileException('Matrix file not found.');
  }
  return _readExisting(file);
}

Future<Uint8List> _readExisting(File file) async {
  final handle = await file.open(mode: FileMode.read);
  try {
    final length = await handle.length();
    if (length == 0) return Uint8List(0);
    return await handle.read(length);
  } finally {
    await handle.close();
  }
}
