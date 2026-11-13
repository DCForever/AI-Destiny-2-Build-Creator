import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../dim_loadouts/dim_loadout_details_panel.dart';
import '../fill_in/fill_in_cache_loader.dart';
import '../fill_in/fill_in_dialog.dart';
import 'builds_mock_controller.dart';
import 'builds_mock_loadout_card.dart';
import 'builds_mock_logic.dart';
import 'builds_mock_matrix_loader.dart';
import 'builds_mock_models.dart';
part 'builds_mock_page_rail.dart';
part 'builds_mock_page_detail.dart';
part 'builds_mock_page_build_detail.dart';
part 'builds_mock_page_pool.dart';
part 'builds_mock_page_reoptimize.dart';

/// Builds list page — production feeds the Warlock matrix; tests inject a
/// controller with the synthetic fixture.
class BuildsMockPage extends StatefulWidget {
  const BuildsMockPage({
    super.key,
    this.controller,
    this.storageRoot,
    this.warlockMatrixPath,
    this.matrixMaxBytes = kCachedDimLoadoutsMaxBytes,
  });

  /// Injectable for tests / widget previews. Page does not dispose it.
  final BuildsMockController? controller;

  /// When set, read-only load of `{StorageRoot}/dim_loadouts/dim-loadouts.json`.
  final StorageRoot? storageRoot;

  /// Same path source as Warlocks (Settings saved path → `WARLOCK_MATRIX_PATH`).
  /// Ignored when [controller] is injected.
  final String? warlockMatrixPath;

  /// Size cap for the matrix file read (same helper as DIM loadouts reader).
  final int matrixMaxBytes;

  @override
  State<BuildsMockPage> createState() => _BuildsMockPageState();
}

class _BuildsMockPageState extends State<BuildsMockPage> {
  late final BuildsMockController _controller;
  late final bool _ownsController;
  late final TextEditingController _search;
  Map<String, FillInSavedBuildPlan> _savedFillInPlans =
      const <String, FillInSavedBuildPlan>{};

  @override
  void initState() {
    super.initState();
    final injected = widget.controller;
    _ownsController = injected == null;
    _controller = injected ?? BuildsMockController.forMatrixLoad();
    _controller.addListener(_onController);
    _search = TextEditingController(text: _controller.query);
    if (_ownsController) {
      _loadMatrix(widget.warlockMatrixPath);
    }
    final root = widget.storageRoot;
    if (root != null) {
      _loadDimLoadouts(root);
      _loadFillInPlans(root);
    }
  }

  Future<void> _loadFillInPlans(StorageRoot root) async {
    try {
      final plans = await FillInMissingListStore(root: root).loadAll();
      if (!mounted) return;
      setState(() => _savedFillInPlans = plans);
    } on FillInMissingListStoreException {
      // Oversized / unsafe store: fail closed (no plans), never rewrite.
      if (!mounted) return;
      setState(() => _savedFillInPlans = const <String, FillInSavedBuildPlan>{});
    }
  }

  Future<void> _loadMatrix(String? path) async {
    await loadBuildsMatrixIntoController(
      controller: _controller,
      path: path,
      maxBytes: widget.matrixMaxBytes,
    );
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
        title: const Text('Builds'),
        actions: [
          _CapControl(controller: _controller),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_controller.showMockBanner) const _MockBanner(),
          Expanded(child: _body(context)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_controller.matrixLoading && _controller.fixture.builds.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          key: Key('builds_mock_matrix_loading'),
        ),
      );
    }
    final error = _controller.matrixError;
    if (error != null && _controller.fixture.builds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            error,
            key: const Key('builds_mock_matrix_error'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_controller.showingBuildDetail) {
      return _buildBuildDetail(context);
    }
    return LibraryWorkspace(
      rail: _buildRail(context),
      detail: _buildBrowse(context),
    );
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
