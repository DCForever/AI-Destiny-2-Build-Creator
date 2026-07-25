import 'package:flutter/material.dart';

import 'dim_export_controller.dart';
import 'dim_export_format.dart';

/// Equip-ready-gated DIM jsonOnly clipboard export (DART-039).
class DimExportPanel extends StatefulWidget {
  const DimExportPanel({
    super.key,
    required this.controller,
  });

  final DimExportController controller;

  @override
  State<DimExportPanel> createState() => _DimExportPanelState();
}

class _DimExportPanelState extends State<DimExportPanel> {
  DimExportController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onController);
  }

  @override
  void didUpdateWidget(covariant DimExportPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onController);
      widget.controller.addListener(_onController);
    }
  }

  @override
  void dispose() {
    _c.removeListener(_onController);
    super.dispose();
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  Future<void> _onExport() async {
    await _c.requestExport();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _c.lastJson;

    return Column(
      key: const Key('dim_export_panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'DIM export',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          kDimExportSoftAdvisoryCaption,
          key: const Key('dim_export_soft_advisory'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Text(
          'Export readiness',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        if (_c.loadingReadiness)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(key: Key('dim_export_loading')),
          ),
        Text(
          _c.readinessSummary,
          key: const Key('dim_export_ready_summary'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _c.equipReady
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
              ),
        ),
        if (_c.pinStatuses.isNotEmpty) ...[
          const SizedBox(height: 8),
          Column(
            key: const Key('dim_export_pin_gaps'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final pin in _c.pinStatuses)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    formatDimExportPinStatusLabel(pin),
                    key: Key('dim_export_pin_status_${pin.slot.wireName}'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('dim_export_copy_button'),
          onPressed: _c.canExport && !_c.exporting ? _onExport : null,
          child: Text(_c.exporting ? 'Copying…' : 'Copy DIM JSON'),
        ),
        if (_c.error != null) ...[
          const SizedBox(height: 8),
          Text(
            _c.error!,
            key: const Key('dim_export_error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (_c.statusMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _c.statusMessage!,
            key: const Key('dim_export_status_message'),
          ),
        ],
        if (preview != null && preview.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'JSON preview',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          SelectableText(
            truncateDimExportPreview(preview),
            key: const Key('dim_export_json_preview'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}
