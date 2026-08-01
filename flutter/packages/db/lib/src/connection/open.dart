/// Conditional database openers for [AppDatabase] factories.
///
/// - Native (FFI): `NativeDatabase` memory/file
/// - Web (JS interop): factories throw — use WasmDatabase + AppDatabase(e)
export 'open_unsupported.dart'
    if (dart.library.ffi) 'open_native.dart'
    if (dart.library.js_interop) 'open_web.dart';
