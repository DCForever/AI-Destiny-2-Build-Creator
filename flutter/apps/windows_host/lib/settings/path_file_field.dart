import 'package:flutter/material.dart';

import 'open_file_path_picker.dart';

/// Editable path [TextField] with a Browse (folder) button.
///
/// Tapping the field or Browse opens the native open-file picker. Picking
/// fills the field via [onChanged]; cancel leaves text unchanged. Typing a
/// path still works (field stays editable). Does not import/save — callers
/// keep their existing action buttons.
class PathFileField extends StatelessWidget {
  const PathFileField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.extensions,
    required this.onChanged,
    this.enabled = true,
    this.fieldKey,
    this.browseKey,
    this.typeLabel,
    this.openFilePicker,
  });

  final TextEditingController controller;
  final String labelText;
  final List<String> extensions;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final Key? fieldKey;
  final Key? browseKey;
  final String? typeLabel;
  final OpenFilePathPicker? openFilePicker;

  Future<void> _browse() async {
    if (!enabled) return;
    final pick = openFilePicker ?? defaultOpenFilePathPicker;
    final path = await pick(
      extensions: extensions,
      label: typeLabel ?? labelText,
    );
    if (path == null) return;
    controller.text = path;
    onChanged(path);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            key: fieldKey,
            controller: controller,
            enabled: enabled,
            decoration: InputDecoration(
              labelText: labelText,
              border: const OutlineInputBorder(),
            ),
            onChanged: onChanged,
            onTap: enabled ? _browse : null,
          ),
        ),


        const SizedBox(width: 8),
        IconButton(
          key: browseKey,
          tooltip: 'Browse',
          onPressed: enabled ? _browse : null,
          icon: const Icon(Icons.folder_open),
        ),
      ],
    );
  }
}
