import 'package:flutter/material.dart';

import 'open_file_path_picker.dart';

/// Editable path [TextField] with a Browse (folder) button.
///
/// Tapping the field or Browse opens the native open-file picker. Picking
/// fills the field via [onChanged]; cancel leaves text unchanged. Typing a
/// path still works (field stays editable). Does not import/save — callers
/// keep their existing action buttons.
class PathFileField extends StatefulWidget {
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

  @override
  State<PathFileField> createState() => _PathFileFieldState();
}

class _PathFileFieldState extends State<PathFileField> {
  Future<void> _browse() async {
    if (!widget.enabled) return;
    final pick = widget.openFilePicker ?? defaultOpenFilePathPicker;
    final path = await pick(
      extensions: widget.extensions,
      label: widget.typeLabel ?? widget.labelText,
    );
    if (path == null) return;
    // Picker is async — widget may have been disposed before the result.
    if (!mounted) return;
    widget.controller.text = path;
    widget.onChanged(path);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            key: widget.fieldKey,
            controller: widget.controller,
            enabled: widget.enabled,
            decoration: InputDecoration(
              labelText: widget.labelText,
              border: const OutlineInputBorder(),
            ),
            onChanged: widget.onChanged,
            onTap: widget.enabled ? _browse : null,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          key: widget.browseKey,
          tooltip: 'Browse',
          onPressed: widget.enabled ? _browse : null,
          icon: const Icon(Icons.folder_open),
        ),
      ],
    );
  }
}
