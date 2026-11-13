import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../dim_loadouts/dim_loadout_details_panel.dart'
    show DimLoadoutsPanelStatus;
import '../fill_in/fill_in_cache_loader.dart';
import '../fill_in/fill_in_dialog.dart';
import '../fill_in/fill_in_saved_plan_card.dart';
import '../host_bootstrap.dart';
import 'builds_mock_apply.dart';
import 'builds_mock_controller.dart';
import 'builds_mock_derived_name.dart';
import 'builds_mock_derived_title.dart';
import 'builds_mock_loadout_card.dart';
import 'builds_mock_matrix_loader.dart';
import 'builds_mock_models.dart';
import 'builds_mock_presentation.dart';
part 'builds_mock_page_rail.dart';
part 'builds_mock_page_detail.dart';
part 'builds_mock_page_build_detail.dart';

/// Builds list page — production feeds the Warlock matrix; tests inject a
/// controller with the synthetic fixture.
class BuildsMockPage extends StatefulWidget {
  const BuildsMockPage({
    super.key,
    this.controller,
    this.storageRoot,
    this.warlockMatrixPath,
    this.matrixPathSettingResolved = true,
    this.matrixMaxBytes = kCachedDimLoadoutsMaxBytes,
    this.services,
    this.applyPorts,
    this.fillInCacheLoader,
  });

  /// Injectable for tests / widget previews. Page does not dispose it.
  final BuildsMockController? controller;

  /// When set, read-only load of `{StorageRoot}/dim_loadouts/dim-loadouts.json`.
  final StorageRoot? storageRoot;

  /// Test inject: overrides DIM Armor/Weapons cache load for Fill In.
  final FillInCacheLoader? fillInCacheLoader;

  /// Path source: Settings saved path → `WARLOCK_MATRIX_PATH`.
  /// Ignored when [controller] is injected.
  final String? warlockMatrixPath;

  /// False while the host is still loading `{StorageRoot}/settings/…`.
  ///
  /// When false, the page stays on the matrix loading indicator instead of
  /// flashing "No matrix file path" before the saved preference arrives.
  /// Defaults to true so direct/test construction still fails closed on null.
  final bool matrixPathSettingResolved;

  /// Size cap for the matrix file read (same helper as DIM loadouts reader).
  final int matrixMaxBytes;

  /// Host services (oauth + write client) for Apply to character.
  final AppServices? services;

  /// Test inject: overrides [services] for Apply to character ports.
  final BuildsMockApplyPorts? applyPorts;

  @override
  State<BuildsMockPage> createState() => _BuildsMockPageState();
}

class _BuildsMockPageState extends State<BuildsMockPage> {
  late final BuildsMockController _controller;
  late final bool _ownsController;
  late final TextEditingController _search;
  final BuildsMockEnrichmentCache _enrichmentCache = BuildsMockEnrichmentCache();
  Map<String, FillInSavedBuildPlan> _savedFillInPlans =
      const <String, FillInSavedBuildPlan>{};
  final Map<String, ApplyToCharacterProgress> _applyProgressByBuild =
      <String, ApplyToCharacterProgress>{};
  final Map<String, String> _applyErrorByBuild = <String, String>{};
  String? _applyingBuildId;
  BuildsMockApplyTarget? _applyTarget;
  String? _applyTargetLabel;
  String? _applyDisabledReason;
  int _matrixLoadGeneration = 0;

  @override
  void initState() {
    super.initState();
    final injected = widget.controller;
    _ownsController = injected == null;
    _controller = injected ?? BuildsMockController.forMatrixLoad();
    _controller.addListener(_onController);
    _search = TextEditingController(text: _controller.query);
    if (_ownsController) {
      _startOrHoldMatrixLoad();
    }
    final root = widget.storageRoot;
    if (root != null) {
      _loadDimLoadouts(root);
      _loadFillInPlans(root);
    }
    _refreshApplyTarget();
  }

  @override
  void didUpdateWidget(BuildsMockPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ownsController) return;
    final pathChanged =
        oldWidget.warlockMatrixPath != widget.warlockMatrixPath;
    final resolvedNow = !oldWidget.matrixPathSettingResolved &&
        widget.matrixPathSettingResolved;
    if (pathChanged || resolvedNow) {
      _startOrHoldMatrixLoad();
    }
  }

  BuildsMockApplyPorts get _applyPorts =>
      widget.applyPorts ?? BuildsMockApplyPorts(services: widget.services);

  Future<void> _refreshApplyTarget() async {
    final resolution = await resolveBuildsMockApplyTarget(_applyPorts);
    if (!mounted) return;
    final target = resolution.target;
    setState(() {
      _applyTarget = target;
      _applyTargetLabel = target == null
          ? null
          : formatBuildsMockApplyTargetLabel(target.character);
      _applyDisabledReason = target == null ? resolution.reason : null;
    });
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

  /// Hold on the loading indicator until the host finishes reading the saved
  /// path preference; otherwise load [widget.warlockMatrixPath].
  void _startOrHoldMatrixLoad() {
    if (!widget.matrixPathSettingResolved) {
      _controller.beginMatrixLoad();
      return;
    }
    _loadMatrix(widget.warlockMatrixPath);
  }

  Future<void> _loadMatrix(String? path) async {
    final generation = ++_matrixLoadGeneration;
    await loadBuildsMatrixIntoController(
      controller: _controller,
      path: path,
      maxBytes: widget.matrixMaxBytes,
      shouldApply: () => mounted && generation == _matrixLoadGeneration,
    );
  }

  Future<void> _loadDimLoadouts(StorageRoot root) async {
    final result = await DimLoadoutsReader(root: root).load();
    if (!mounted) return;
    // DIM catalog changed — drop enrichment keyed to prior shareIds.
    _enrichmentCache.invalidate();
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

  Future<void> _applyToCharacter(MockBuild build) async {
    if (_applyingBuildId != null) return;
    final target = _applyTarget;
    if (target == null) return;
    final ports = _applyPorts;

    setState(() {
      _applyingBuildId = build.id;
      _applyErrorByBuild.remove(build.id);
    });

    final outcome = await runBuildsMockApplyToCharacter(
      build: build,
      plan: _savedFillInPlans[build.id],
      ports: ports,
      target: target,
      isMounted: () => mounted,
      onProgress: (progress) {
        if (!mounted) return;
        setState(() => _applyProgressByBuild[build.id] = progress);
      },
    );

    if (!mounted) return;
    setState(() {
      _applyingBuildId = null;
      if (outcome.progress != null) {
        _applyProgressByBuild[build.id] = outcome.progress!;
      }
      if (outcome.error != null) {
        _applyErrorByBuild[build.id] = outcome.error!;
      }
    });
    // Refresh in case memberships/characters changed mid-session.
    await _refreshApplyTarget();
  }

  @override
  void dispose() {
    _controller.removeListener(_onController);
    _search.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onController() {
    // replaceBuild / adoptDimLoadouts keep build id + share id; clear so
    // identity-aware enrich cannot briefly reuse a prior entry either.
    _enrichmentCache.invalidate();
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
