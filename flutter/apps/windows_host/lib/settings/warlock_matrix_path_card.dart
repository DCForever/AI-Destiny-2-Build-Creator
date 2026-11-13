import 'package:flutter/material.dart';

import 'open_file_path_picker.dart';
import 'path_file_field.dart';
import 'warlock_matrix_path_controller.dart';

/// Settings card: Warlock matrix file path + Browse + Save + status.
///
/// Browse / field tap opens a native open-file picker (.json). Picking fills
/// the path only — Save is still required. Matrix file stays read-only.
class WarlockMatrixPathCard extends StatefulWidget {
  const WarlockMatrixPathCard({
    super.key,
    required this.controller,
    this.onSaved,
    this.openFilePicker,
  });

  final WarlockMatrixPathController controller;

  /// Called after a successful Save with the persisted path (null if cleared).
  final ValueChanged<String?>? onSaved;

  /// Injectable open-file picker (tests). Defaults to [defaultOpenFilePathPicker].
  final OpenFilePathPicker? openFilePicker;

  @override
  State<WarlockMatrixPathCard> createState() => _WarlockMatrixPathCardState();
}

class _WarlockMatrixPathCardState extends State<WarlockMatrixPathCard> {
  late final TextEditingController _pathController;

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController(text: widget.controller.pathField);
    widget.controller.addListener(_onControllerChanged);
    widget.controller.load();
  }

  @override
  void didUpdateWidget(covariant WarlockMatrixPathCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _pathController.text = widget.controller.pathField;
      widget.controller.load();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _pathController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    // Keep the field in sync when load() fills from saved/env.
    if (_pathController.text != widget.controller.pathField &&
        (widget.controller.phase == WarlockMatrixPathPhase.idle ||
            widget.controller.phase == WarlockMatrixPathPhase.loading)) {
      _pathController.text = widget.controller.pathField;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final busy = c.isBusy;
    final showError = c.phase == WarlockMatrixPathPhase.error &&
        c.errorMessage != null &&
        c.errorMessage!.isNotEmpty;

    return Card(
      key: const Key('warlock_matrix_path_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Warlock matrix file',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Path to the local Warlock matrix JSON. The file is read only. '
              'Saved path wins over WARLOCK_MATRIX_PATH. Used by Builds and '
              'Warlocks.',
              key: const Key('warlock_matrix_path_help'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Preference: ${c.settingFilePath}',
              key: const Key('warlock_matrix_path_setting_hint'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            PathFileField(
              fieldKey: const Key('warlock_matrix_path_field'),
              browseKey: const Key('warlock_matrix_path_browse'),
              controller: _pathController,
              enabled: !busy,
              labelText: 'Matrix file path',
              typeLabel: 'JSON',
              extensions: const <String>['json'],
              openFilePicker: widget.openFilePicker,
              onChanged: c.setPathField,
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('warlock_matrix_path_save'),
              onPressed: busy
                  ? null
                  : () {
                      c.setPathField(_pathController.text);
                      c.save(onSaved: widget.onSaved);
                    },
              child: Text(
                busy && c.phase == WarlockMatrixPathPhase.saving
                    ? 'Saving…'
                    : 'Save',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              c.displayStatus,
              key: const Key('warlock_matrix_path_status'),
              style: showError
                  ? TextStyle(color: Theme.of(context).colorScheme.error)
                  : Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
