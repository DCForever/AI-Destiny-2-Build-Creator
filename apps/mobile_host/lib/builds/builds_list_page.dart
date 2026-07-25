import 'package:flutter/material.dart';

import 'build_detail_page.dart';
import 'builds_controller.dart';

/// Builds library list (mobile). Focus Swap: tap → push detail (XOR list).
class BuildsListPage extends StatefulWidget {
  const BuildsListPage({
    super.key,
    required this.controller,
  });

  final BuildsController controller;

  @override
  State<BuildsListPage> createState() => _BuildsListPageState();
}

class _BuildsListPageState extends State<BuildsListPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onController);
    // ignore: discarded_futures
    widget.controller.refresh();
  }

  @override
  void didUpdateWidget(covariant BuildsListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onController);
      widget.controller.addListener(_onController);
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

  Future<void> _openDetail(String buildId) async {
    await widget.controller.openBuild(buildId);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'build_detail'),
        builder: (_) => BuildDetailPage(
          controller: widget.controller,
          buildId: buildId,
        ),
      ),
    );
    widget.controller.clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      key: const Key('builds_list_page'),
      appBar: AppBar(
        title: const Text('Builds'),
      ),
      body: _body(c),
    );
  }

  Widget _body(BuildsController c) {
    if (c.loading && c.builds.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(key: Key('builds_loading')),
      );
    }
    if (c.error != null && c.builds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                c.error!,
                key: const Key('builds_error'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                key: const Key('builds_retry'),
                onPressed: c.refresh,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (c.builds.isEmpty) {
      return const Center(
        child: Text(
          'No builds yet.\nCreate builds on desktop or a later mobile slice.',
          key: Key('builds_empty'),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.separated(
      key: const Key('builds_list'),
      itemCount: c.builds.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final b = c.builds[index];
        return ListTile(
          key: Key('build_row_${b.id}'),
          title: Text(c.titleOf(b)),
          subtitle: Text(
            [
              c.identitySummaryOf(b),
              c.synergySummaryOf(b),
            ].where((s) => s.isNotEmpty && s != '—').join(' · '),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openDetail(b.id),
        );
      },
    );
  }
}
