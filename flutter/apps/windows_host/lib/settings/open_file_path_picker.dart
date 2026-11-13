import 'package:file_selector/file_selector.dart';

/// Opens a native **open-file** dialog and returns the chosen path, or `null`
/// when the user cancels.
///
/// Injectable so widget tests can fake the dialog (no real picker in CI).
/// Production uses [defaultOpenFilePathPicker] — open-file only; never save.
typedef OpenFilePathPicker = Future<String?> Function({
  required List<String> extensions,
  String? label,
});

/// Production picker: [openFile] with an [XTypeGroup] filter.
///
/// Hard rule: open-file dialogs only — never save-location / save dialogs.
Future<String?> defaultOpenFilePathPicker({
  required List<String> extensions,
  String? label,
}) async {
  final file = await openFile(
    acceptedTypeGroups: <XTypeGroup>[
      XTypeGroup(
        label: label,
        extensions: extensions,
      ),
    ],
  );
  return file?.path;
}
