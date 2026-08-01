/// Conditional text-file helpers for entity cache / manifest paths.
///
/// Native: dart:io. Web: stubs (prebuilt bundles only — DART-044).
export 'text_file_stub.dart' if (dart.library.io) 'text_file_io.dart';
