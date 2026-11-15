import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

import '../dim_loadouts/dim_loadout_details_panel.dart'
    show DimLoadoutsPanelStatus;
import '../fill_in/fill_in_cache_loader.dart';
import '../fill_in/fill_in_dialog.dart';
import '../fill_in/fill_in_saved_plan_card.dart';
import '../fill_in/fill_in_weapon_apply.dart';
import '../host_bootstrap.dart';
import '../optimize/builds_armor_pool_panel.dart';
import '../optimize/builds_optimize_apply.dart';
import '../optimize/builds_optimize_controller.dart';
import '../optimize/builds_optimize_results_panel.dart';
import '../optimize/builds_weapon_optimize_results_panel.dart';
import '../optimize/weapon_optimize_apply.dart';
import '../sets/set_bonus_families.dart';
import 'apply_move_confirm_dialog.dart';
import 'apply_sign_in_dialog.dart';
import 'builds_mock_apply.dart';
import 'builds_mock_controller.dart';
import 'builds_mock_derived_name.dart';
import 'builds_mock_derived_title.dart';
import 'builds_mock_icon_paths.dart';
import 'builds_mock_loadout_card.dart';
import 'builds_mock_matrix_loader.dart';
import 'builds_mock_models.dart';
import 'builds_mock_presentation.dart';
import 'builds_mock_stats_from_armor.dart';
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
    this.optimizeController,
  });

  /// Injectable for tests / widget previews. Page does not dispose it.
  final BuildsMockController? controller;

  /// When set, read-only load of `{StorageRoot}/dim_loadouts/dim-loadouts.json`.
  final StorageRoot? storageRoot;

  /// Test inject: overrides DIM Armor/Weapons cache load for Fill In.
  final FillInCacheLoader? fillInCacheLoader;

  /// Test inject: Builds Optimize controller (CSV pool + results).
  final BuildsOptimizeController? optimizeController;

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
  late final BuildsOptimizeController _optimize;
  late final bool _ownsOptimize;
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
  /// Visible when optimize_by_build.json is corrupt (never overwritten).
  String? _optimizeStoreError;
  /// Visible when missing_by_build.json is corrupt (never overwritten).
  String? _fillInStoreError;
  int _matrixLoadGeneration = 0;
  List<CatalogItem> _catalogItems = const [];
  Map<String, String> _setIconByLowerName = const {};
  /// Mod hash → ModSlotCategory.json (from offline entity store).
  Map<int, String> _modSlotCategoryByHash = const {};
  String _detailTab = 'detail';

  @override
  void initState() {
    super.initState();
    final injected = widget.controller;
    _ownsController = injected == null;
    _controller = injected ?? BuildsMockController.forMatrixLoad();
    _controller.addListener(_onController);
    _ownsOptimize = widget.optimizeController == null;
    _optimize = widget.optimizeController ??
        BuildsOptimizeController(
          loadArmorItems: _defaultArmorCsvLoader,
          loadWeaponItems: _defaultWeaponsCsvLoader,
          optimizeStore: widget.storageRoot == null
              ? null
              : OptimizeBuildStore(root: widget.storageRoot!),
          fillInStore: widget.storageRoot == null
              ? null
              : FillInMissingListStore(root: widget.storageRoot!),
          knownSetKeys: {
            for (final s in _controller.fixture.sets) s.id,
          },
        );
    _optimize.addListener(_onOptimize);
    _search = TextEditingController(text: _controller.query);
    if (_ownsController) {
      _startOrHoldMatrixLoad();
    }
    final root = widget.storageRoot;
    if (root != null) {
      _loadDimLoadouts(root);
      _loadFillInPlans(root);
      _loadOptimizeOverlays(root);
    }
    _optimize.refreshArmorCsv();
    _optimize.refreshWeaponsCsv();
    _refreshApplyTarget();
    _ensureCatalogIcons();
    _ensureModSlotCategories();
  }

  Future<List<FillInInventoryItem>?> _defaultArmorCsvLoader() async {
    final root = widget.storageRoot;
    if (root == null) return null;
    final result = await DimArmorCsvImporter(root: root).loadCache();
    if (!result.isOk) return null;
    return result.items;
  }

  Future<List<FillInInventoryItem>?> _defaultWeaponsCsvLoader() async {
    final root = widget.storageRoot;
    if (root == null) return null;
    final result = await DimWeaponsCsvImporter(root: root).loadCache();
    if (!result.isOk) return null;
    return result.items;
  }

  /// Load ModRecord.slotCategory by item hash for Builds mod placement.
  ///
  /// Data source: offline entity store `mods` (manifest plugCategoryIdentifier
  /// → helmet/arms/chest/legs/classItem/general/tuning). No Bungie network.
  Future<void> _ensureModSlotCategories() async {
    final services = widget.services;
    if (services == null) return;
    try {
      final refresh = services.manifestRefresh;
      if (refresh is! WindowsManifestRefresh) return;
      final version = await refresh.service.readCurrentVersion();
      if (version == null || version.isEmpty) return;
      final cache = FileEntityCache(
        storageRoot: services.storageRoot,
        version: version,
      );
      final rows = await cache.getStore<ModRecord>(MvpStoreName.mods);
      if (!mounted || rows.isEmpty) return;
      final map = <int, String>{
        for (final r in rows) r.hash: r.slotCategory.json,
      };
      setState(() => _modSlotCategoryByHash = map);
    } catch (_) {
      // Best-effort — placeDimMods falls back to name / class_item guess.
    }
  }

  /// OfflineCatalog rows already carry `displayProperties.icon` — reuse for
  /// Super / exotic segments / filter exotic badges (same path Catalog grids
  /// use). Set-bonus catalog icons feed the Set filter when available.
  Future<void> _ensureCatalogIcons() async {
    final services = widget.services;
    if (services == null) return;
    try {
      final catalog = services.offlineCatalog;
      if (catalog.baseItems.isEmpty) {
        await catalog.loadBase();
      }
      if (!mounted) return;
      setState(() => _catalogItems = List<CatalogItem>.from(catalog.baseItems));
    } catch (_) {
      // Icon enrichment is best-effort; titles still render without paths.
    }
    try {
      final rows = await loadArmorSetBonusCatalogRecords(services);
      if (!mounted) return;
      final map = <String, String>{};
      for (final r in rows) {
        final icon = r.icon?.trim();
        if (icon == null || icon.isEmpty) continue;
        final name = r.name.trim().toLowerCase();
        if (name.isEmpty) continue;
        map.putIfAbsent(name, () => icon);
      }
      setState(() => _setIconByLowerName = map);
    } catch (_) {
      // Set filter falls back to text-only (no letter badge).
    }
  }

  BuildsMockSegmentIcons _segmentIcons({
    required MockBuild build,
    CachedDimLoadout? loadout,
  }) {
    return resolveBuildsMockSegmentIcons(
      build: build,
      loadout: loadout,
      catalogItems: _catalogItems,
    );
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

  /// Signed-out Apply opens the Bungie sign-in dialog (system browser).
  bool get _canOpenApplySignIn {
    final oauth = _applyPorts.resolvedOauth;
    return oauth != null && oauth.isConfigured && !oauth.isSignedIn;
  }

  bool get _isApplyButtonEnabled {
    if (_applyingBuildId != null) return false;
    if (_applyTarget != null) return true;
    return _canOpenApplySignIn;
  }

  Future<void> _refreshApplyTarget() async {
    final resolution = await resolveBuildsMockApplyTarget(_applyPorts);
    if (!mounted) return;
    final target = resolution.target;
    setState(() {
      _applyTarget = target;
      _applyTargetLabel = target == null
          ? null
          : formatBuildsMockApplyTargetLabel(target.character);
      // When Apply can open the sign-in dialog, do not show the old
      // "Sign in from Settings" disable reason beside an enabled button.
      _applyDisabledReason = target == null && !_canOpenApplySignIn
          ? resolution.reason
          : null;
    });
  }

  Future<void> _loadFillInPlans(StorageRoot root) async {
    try {
      final plans = await FillInMissingListStore(root: root).loadAll();
      if (!mounted) return;
      setState(() {
        _fillInStoreError = null;
        _savedFillInPlans = plans;
      });
      _controller.adoptFillInPlans(plans);
    } on FillInMissingListStoreException catch (e) {
      // Corrupt / oversized: fail closed, never rewrite the file.
      if (!mounted) return;
      _reportFillInStoreError(e.message);
    }
  }

  void _clearFillInStoreError() {
    if (!mounted || _fillInStoreError == null) return;
    setState(() => _fillInStoreError = null);
  }

  void _reportFillInStoreError(String message) {
    if (!mounted) return;
    setState(() {
      _fillInStoreError = message;
      _savedFillInPlans = const <String, FillInSavedBuildPlan>{};
    });
    _controller.adoptFillInPlans(const <String, FillInSavedBuildPlan>{});
  }

  Future<void> _loadOptimizeOverlays(StorageRoot root) async {
    try {
      final records = await OptimizeBuildStore(root: root).loadAll();
      if (!mounted) return;
      setState(() => _optimizeStoreError = null);
      if (records.isEmpty) return;
      for (final entry in records.entries) {
        if (!entry.value.isOptimized) continue;
        MockBuild? build;
        for (final b in _controller.fixture.builds) {
          if (b.id == entry.key) {
            build = b;
            break;
          }
        }
        if (build == null) continue;
        _controller.replaceBuild(
          applyOptimizedRecordToBuild(build: build, record: entry.value),
        );
      }
    } on OptimizeBuildStoreException catch (e) {
      // Fail closed — leave fixture builds unchanged; never rewrite corrupt file.
      if (!mounted) return;
      setState(() => _optimizeStoreError = e.message);
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
    final ports = _applyPorts;
    final oauth = ports.resolvedOauth;

    // Already signed in with a valid token → skip dialog, go straight to Apply.
    // Signed out → mockup dialog; Bungie opens in the system browser (PKCE).
    if (oauth != null && oauth.isConfigured && !oauth.isSignedIn) {
      final result = await showApplySignInDialog(
        context: context,
        session: oauth,
      );
      if (!mounted) return;
      if (result != ApplySignInDialogResult.signedIn) return;
      await _refreshApplyTarget();
      if (!mounted) return;
    }

    final target = _applyTarget;
    if (target == null) return;

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
      targetLabel: _applyTargetLabel,
      confirmMoves: (moves) async {
        if (!mounted) return false;
        final result = await showApplyMoveConfirmDialog(
          context: context,
          moves: moves,
          targetLabel: _applyTargetLabel,
        );
        return result == ApplyMoveConfirmResult.accepted;
      },
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
    _optimize.removeListener(_onOptimize);
    _search.dispose();
    if (_ownsController) _controller.dispose();
    if (_ownsOptimize) _optimize.dispose();
    super.dispose();
  }

  void _onController() {
    // replaceBuild / adoptDimLoadouts keep build id + share id; clear so
    // identity-aware enrich cannot briefly reuse a prior entry either.
    _enrichmentCache.invalidate();
    _optimize.knownSetKeys = {
      for (final s in _controller.fixture.sets) s.id,
    };
    if (mounted) setState(() {});
  }

  void _onOptimize() {
    if (mounted) setState(() {});
  }

  void _selectDetailTab(String tab) {
    setState(() => _detailTab = tab);
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
