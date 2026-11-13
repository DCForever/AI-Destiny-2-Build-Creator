import 'package:flutter/material.dart';

import 'dim_csv_import_controller.dart';
import 'open_file_path_picker.dart';
import 'path_file_field.dart';

/// Settings card: path TextField + Browse + Import for DIM Armor or Weapons CSV.
///
/// Browse / field tap opens a native open-file picker (.csv). Picking fills the
/// path only — Import is still required (no auto-import).
class DimCsvImportCard extends StatefulWidget {
  const DimCsvImportCard({
    super.key,
    required this.controller,
    this.openFilePicker,
  });

  final DimCsvImportController controller;

  /// Injectable open-file picker (tests). Defaults to [defaultOpenFilePathPicker].
  final OpenFilePathPicker? openFilePicker;

  @override
  State<DimCsvImportCard> createState() => _DimCsvImportCardState();
}

class _DimCsvImportCardState extends State<DimCsvImportCard> {
  late final TextEditingController _pathController;

  String get _keyPrefix => widget.controller.kind == DimCsvImportKind.armor
      ? 'dim_armor_csv_import'
      : 'dim_weapons_csv_import';

  String get _title => widget.controller.kind == DimCsvImportKind.armor
      ? 'DIM Armor CSV'
      : 'DIM Weapons CSV';

  String get _help => widget.controller.kind == DimCsvImportKind.armor
      ? 'Import a DIM Armor CSV export into this app’s private fill_in cache. '
          'The source file is read only and is never moved or deleted.'
      : 'Import a DIM Weapons CSV export into this app’s private fill_in cache. '
          'The source file is read only and is never moved or deleted.';

  String get _fieldLabel => widget.controller.kind == DimCsvImportKind.armor
      ? 'Source path (DIM Armor CSV)'
      : 'Source path (DIM Weapons CSV)';

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController(text: widget.controller.sourcePath);
    widget.controller.addListener(_onControllerChanged);
    // Page-load cached count (or "not imported yet").
    widget.controller.loadCachedStatus();
  }

  @override
  void didUpdateWidget(covariant DimCsvImportCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _pathController.text = widget.controller.sourcePath;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _pathController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final busy = c.isBusy;
    final showError = c.phase == DimCsvImportPhase.error &&
        c.errorMessage != null &&
        c.errorMessage!.isNotEmpty;

    return Card(
      key: Key('${_keyPrefix}_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _help,
              key: Key('${_keyPrefix}_help'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Cache: ${c.cachePath}',
              key: Key('${_keyPrefix}_cache_path'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            PathFileField(
              fieldKey: Key('${_keyPrefix}_source_field'),
              browseKey: Key('${_keyPrefix}_browse'),
              controller: _pathController,
              enabled: !busy,
              labelText: _fieldLabel,
              typeLabel: 'CSV',
              extensions: const <String>['csv'],
              openFilePicker: widget.openFilePicker,
              onChanged: c.setSourcePath,
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: Key('${_keyPrefix}_import'),
              onPressed: busy
                  ? null
                  : () {
                      c.setSourcePath(_pathController.text);
                      c.importFromPath();
                    },
              child: Text(
                busy && c.phase == DimCsvImportPhase.importing
                    ? 'Importing…'
                    : 'Import',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              c.displayStatus,
              key: Key('${_keyPrefix}_status'),
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
