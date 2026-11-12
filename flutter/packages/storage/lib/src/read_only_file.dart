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
/// When [maxBytes] is set, checks [RandomAccessFile.length] **before** reading
/// and throws [ReadOnlyFileException] if the file is over the limit.
Future<Uint8List> readOnlyFileBytes(String path, {int? maxBytes}) async {
  final trimmed = path.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(path, 'path', 'path is required');
  }
  final file = File(trimmed);
  if (!await file.exists()) {
    throw ReadOnlyFileException('File not found.');
  }
  return _readExisting(file, maxBytes: maxBytes);
}

Future<Uint8List> _readExisting(File file, {int? maxBytes}) async {
  final handle = await file.open(mode: FileMode.read);
  try {
    final length = await handle.length();
    if (maxBytes != null && length > maxBytes) {
      throw ReadOnlyFileException(
        'file exceeds size limit ($length > $maxBytes bytes)',
      );
    }
    if (length == 0) return Uint8List(0);
    return await handle.read(length);
  } finally {
    await handle.close();
  }
}
