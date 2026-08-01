import 'package:flutter/material.dart';

import 'legacy_db_import_controller.dart';

/// Settings card: dry-run + apply import of Next `.cache/app.db` (DART-048).
class LegacyDbImportCard extends StatefulWidget {
  const LegacyDbImportCard({
    super.key,
    required this.controller,
  });

  final LegacyDbImportController controller;

  @override
  State<LegacyDbImportCard> createState() => _LegacyDbImportCardState();
}

class _LegacyDbImportCardState extends State<LegacyDbImportCard> {
  late final TextEditingController _pathController;

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController(text: widget.controller.sourcePath);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant LegacyDbImportCard oldWidget) {
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
    final plan = c.plan;
    final result = c.result;
    final error = c.errorMessage;
    final showError = error != null &&
        error.isNotEmpty &&
        c.phase == LegacyDbImportPhase.error;

    return Card(
      key: const Key('legacy_db_import_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Legacy DB import',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Import Next.js .cache/app.db into this app’s StorageRoot '
              '(full replace). Soft guidance is never auto-applied.',
              key: const Key('legacy_db_import_help'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Target: ${c.targetPath}',
              key: const Key('legacy_db_import_target'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('legacy_db_import_source_field'),
              controller: _pathController,
              enabled: !busy,
              decoration: const InputDecoration(
                labelText: 'Source path (.cache/app.db)',
                border: OutlineInputBorder(),
              ),
              onChanged: c.setSourcePath,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: const Key('legacy_db_import_dry_run'),
                  onPressed: busy
                      ? null
                      : () {
                          c.setSourcePath(_pathController.text);
                          c.dryRun();
                        },
                  child: Text(
                    busy && c.phase == LegacyDbImportPhase.dryRunning
                        ? 'Dry-run…'
                        : 'Dry-run',
                  ),
                ),
                FilledButton(
                  key: const Key('legacy_db_import_apply'),
                  onPressed: (!c.canApply || busy) ? null : () => c.apply(),
                  child: Text(
                    c.phase == LegacyDbImportPhase.applying
                        ? 'Applying…'
                        : 'Apply import',
                  ),
                ),
              ],
            ),
            if (c.hasSuccessfulDryRun && plan?.targetExists == true) ...[
              const SizedBox(height: 8),
              CheckboxListTile(
                key: const Key('legacy_db_import_confirm'),
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: c.confirmReplace,
                onChanged: busy
                    ? null
                    : (v) => c.setConfirmReplace(v ?? false),
                title: const Text(
                  'I understand existing platform app.db will be backed up and replaced',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
            if (plan != null) ...[
              const SizedBox(height: 12),
              SelectableText(
                plan.summaryText,
                key: const Key('legacy_db_import_plan_summary'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (showError) ...[
              const SizedBox(height: 8),
              Text(
                error,
                key: const Key('legacy_db_import_error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (c.phase == LegacyDbImportPhase.applied && result != null) ...[
              const SizedBox(height: 8),
              Text(
                'Import applied to ${result.targetPath}'
                '${result.backupPath != null ? '\nBackup: ${result.backupPath}' : ''}'
                '\nRestart the app to use the imported database.',
                key: const Key('legacy_db_import_success'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
