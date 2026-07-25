import 'package:flutter/material.dart';

import 'builds_controller.dart';

/// Read-only build identity detail (Focus Swap target). Compose is DART-041.
class BuildDetailPage extends StatefulWidget {
  const BuildDetailPage({
    super.key,
    required this.controller,
    required this.buildId,
  });

  final BuildsController controller;
  final String buildId;

  @override
  State<BuildDetailPage> createState() => _BuildDetailPageState();
}

class _BuildDetailPageState extends State<BuildDetailPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onController);
    final selected = widget.controller.selected;
    if (selected == null || selected.build.id != widget.buildId) {
      // ignore: discarded_futures
      widget.controller.openBuild(widget.buildId);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onController);
    super.dispose();
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final detail = c.selected;
    final build = detail?.build;
    final title = build != null ? c.titleOf(build) : 'Build';

    return Scaffold(
      key: const Key('build_detail_page'),
      appBar: AppBar(
        title: Text(title, key: const Key('build_detail_title')),
      ),
      body: build == null
          ? const Center(
              child: CircularProgressIndicator(key: Key('build_detail_loading')),
            )
          : ListView(
              key: const Key('build_detail_body'),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Identity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _row('Name', c.titleOf(build), 'detail_name'),
                _row('Class', c.identitySummaryOf(build), 'detail_identity'),
                _row(
                  'Synergies',
                  c.synergySummaryOf(build).isEmpty
                      ? '—'
                      : c.synergySummaryOf(build),
                  'detail_synergies',
                ),
                _row('Exotics', c.exoticsSummaryOf(build), 'detail_exotics'),
                const SizedBox(height: 16),
                Text(
                  'Variants: ${detail!.variants.length}',
                  key: const Key('detail_variant_count'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                Text(
                  'Full compose (attach / pins / soft guidance) ships in a '
                  'later mobile slice. Soft guidance never auto-applies.',
                  key: const Key('detail_compose_note'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
    );
  }

  Widget _row(String label, String value, String keyName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, key: Key(keyName)),
          ),
        ],
      ),
    );
  }
}
