import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../dim_loadouts/dim_loadout_details_panel.dart';
import 'builds_mock_controller.dart';
import 'builds_mock_loadout_card.dart';
import 'builds_mock_logic.dart';
import 'builds_mock_models.dart';

part 'builds_mock_page_rail.dart';
part 'builds_mock_page_detail.dart';
part 'builds_mock_page_pool.dart';
part 'builds_mock_page_reoptimize.dart';

/// Clickable Builds UI mock-up driven only by in-repo fake data.
class BuildsMockPage extends StatefulWidget {
  const BuildsMockPage({super.key, this.controller, this.storageRoot});

  /// Injectable for tests. Page does not dispose an injected controller.
  final BuildsMockController? controller;

  /// When set, read-only load of `{StorageRoot}/dim_loadouts/dim-loadouts.json`.
  final StorageRoot? storageRoot;

  @override
  State<BuildsMockPage> createState() => _BuildsMockPageState();
}

class _BuildsMockPageState extends State<BuildsMockPage> {
  late final BuildsMockController _controller;
  late final bool _ownsController;
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    final injected = widget.controller;
    _ownsController = injected == null;
    _controller = injected ?? BuildsMockController();
    _controller.addListener(_onController);
    _search = TextEditingController(text: _controller.query);
    final root = widget.storageRoot;
    if (root != null) {
      _loadDimLoadouts(root);
    }
  }

  Future<void> _loadDimLoadouts(StorageRoot root) async {
    final result = await DimLoadoutsReader(root: root).load();
    if (!mounted) return;
    switch (result.status) {
      case DimLoadoutsReadStatus.notLoaded:
        _controller.adoptDimLoadouts(status: DimLoadoutsPanelStatus.notLoaded);
      case DimLoadoutsReadStatus.unreadable:
        _controller.adoptDimLoadouts(status: DimLoadoutsPanelStatus.unreadable);
      case DimLoadoutsReadStatus.loaded:
        _controller.adoptDimLoadouts(
          status: DimLoadoutsPanelStatus.loaded,
          loadouts: result.loadouts,
        );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onController);
    _search.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('builds_mock_page'),
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Builds (mockup)'),
        actions: [
          _CapControl(controller: _controller),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _MockBanner(),
          Expanded(
            child: LibraryWorkspace(
              rail: _buildRail(context),
              detail: _buildDetailPane(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPane(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TabBar(controller: _controller),
        Expanded(child: _tabBody(context)),
      ],
    );
  }

  Widget _tabBody(BuildContext context) {
    switch (_controller.tab) {
      case BuildsMockTab.detail:
        return _buildDetail(context);
      case BuildsMockTab.pool:
        return _buildPool(context);
      case BuildsMockTab.reoptimize:
        return _buildReoptimize(context);
    }
  }
}

class _MockBanner extends StatelessWidget {
  const _MockBanner();

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    return Container(
      key: const Key('builds_mock_banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: palette.accent.withValues(alpha: 0.14),
      child: Text(
        'MOCK-UP — example data',
        textAlign: TextAlign.center,
        style: neonDisplay(
          color: palette.accent,
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CapControl extends StatelessWidget {
  const _CapControl({required this.controller});

  final BuildsMockController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Cap',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            key: const Key('builds_mock_cap'),
            value: controller.inventoryCap,
            underline: const SizedBox.shrink(),
            items: [
              for (var c = kMockMinInventoryCap; c <= kMockMaxInventoryCap; c++)
                DropdownMenuItem(value: c, child: Text('$c')),
            ],
            onChanged: (v) {
              if (v != null) controller.setInventoryCap(v);
            },
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.controller});

  final BuildsMockController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: SegmentedButton<BuildsMockTab>(
        key: const Key('builds_mock_tabs'),
        segments: const [
          ButtonSegment(
            value: BuildsMockTab.detail,
            label: Text('Detail'),
            icon: Icon(Icons.view_agenda_outlined, size: 16),
          ),
          ButtonSegment(
            value: BuildsMockTab.pool,
            label: Text('Armor pool'),
            icon: Icon(Icons.grid_view_outlined, size: 16),
          ),
          ButtonSegment(
            value: BuildsMockTab.reoptimize,
            label: Text('Re-optimize'),
            icon: Icon(Icons.tune, size: 16),
          ),
        ],
        selected: {controller.tab},
        onSelectionChanged: (s) => controller.setTab(s.first),
      ),
    );
  }
}
