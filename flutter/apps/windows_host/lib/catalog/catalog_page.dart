import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../host_bootstrap.dart';
import '../widgets/entity_icon.dart';
import 'owned_catalog_bridge.dart';

/// Catalog board columns: NAME · IDENTITY · TYPE · OWNED
const FlapColumnTemplate kFlapColumnsCatalog = FlapColumnTemplate(
  id: 'catalog',
  columnsCss:
      'minmax(0, 1.4fr) minmax(88px, 0.55fr) minmax(0, 0.9fr) minmax(72px, 0.45fr)',
  cellRoles: [
    FlapCellRole.name,
    FlapCellRole.identity,
    FlapCellRole.type,
    FlapCellRole.status,
  ],
  headerLabels: ['Name', 'Identity', 'Type', 'Owned'],
);


/// Catalog browse with kind modes, synergy tags, owned detail (DART-063).
class CatalogPage extends StatefulWidget {
  const CatalogPage({
    super.key,
    required this.services,
    this.bridge,
    this.reloadToken = 0,
    this.onOpenSettings,
  });

  final AppServices services;

  /// Optional injectable bridge (tests). When null, constructed from [services].
  final OwnedCatalogBridge? bridge;

  /// When this value changes (e.g. user returns to Catalog after Settings sync),
  /// reloads entity stores + inventory. IndexedStack keeps this page alive.
  final int reloadToken;

  /// Shell callback to open Settings (empty-state CTAs).
  final VoidCallback? onOpenSettings;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  late OwnedCatalogBridge _bridge;

  bool _loading = true;
  String? _error;
  CatalogEmptyReason _emptyReason = CatalogEmptyReason.none;
  String? _version;
  List<CatalogItem> _results = const [];
  CatalogScope _scope = CatalogScope.all;
  CatalogBrowseMode _mode = CatalogBrowseMode.weapons;

  final _queryController = TextEditingController();
  FacetFilter _elements = emptyFacet();
  FacetFilter _ammos = emptyFacet();
  FacetFilter _slots = emptyFacet();
  FacetFilter _classNames = emptyFacet();
  FacetFilter _archetypes = emptyFacet();
  FacetFilter _synergies = emptyFacet();
  bool? _exotic; // null = off, true = only, false = exclude
  final List<CatalogGroupDimension> _groupBy = [];

  CatalogItem? _selected;
  WeaponFamily? _selectedFamily;
  List<WeaponFamily> _families = const [];
  List<CatalogInstanceProjection> _instances = const [];
  List<LinkedSynergyBadge> _reverseTags = const [];
  String? _actionMessage;
  String? _selectedInstanceId;

  /// Weapons detail: can-roll / craft toggles OFF by default (DBR-ROLL).
  bool _showCanRoll = false;
  bool _showCraft = false;

  // --- 003 CatalogRollTargets (DART-073) ---
  List<WeaponRollTarget> _rollTargets = const [];
  String? _activeRollTargetId;
  bool _editingRollTarget = false;
  bool _creatingRollTarget = false;
  String _rollDraftName = '';
  Map<String, Set<int>> _rollDraftPreferred = const {};
  Map<String, Set<int>> _rollDraftAvoid = const {};
  /// Snapshot for cancel restore.
  String? _rollEditSnapshotId;
  String _rollEditSnapshotName = '';
  Map<String, Set<int>> _rollEditSnapshotPreferred = const {};
  Map<String, Set<int>> _rollEditSnapshotAvoid = const {};
  /// Before edit, restore can-roll toggle.
  bool _showCanRollBeforeEdit = false;

  /// Secondary facets (ammo, class, synergy) behind "More".
  /// Primary line (scope + free-text + element/slot/type icon chips) is always on.
  bool _moreFiltersExpanded = false;

  // --- 004 CatalogFilterCollections (soft apply; host binds) ---
  List<CatalogFilterCollection> _filterCollections = const [];
  String? _activeFilterCollectionId;
  String? _activeFilterCollectionName;
  /// Snapshot of applied collection criteria for dirty compare.
  CatalogFilterCollection? _appliedFilterCollection;

  /// Session-only sort priority (GAP-CAT-BROWSE-003).
  List<CatalogSortKey> _sortKeys = List<CatalogSortKey>.from(
    kDefaultWeaponSortKeys,
  );

  /// Collapsed group keys (view-only; default expanded).
  final Set<String> _collapsedGroups = {};
  final Map<String, GlobalKey> _groupAnchorKeys = {};
  String? _outlineActiveKey;

  OwnedCatalogBridge _createBridge() {
    return widget.bridge ??
        OwnedCatalogBridge(
          db: widget.services.db,
          offlineCatalog: widget.services.offlineCatalog,
          session: widget.services.oauthSession,
          inventorySync: widget.services.inventorySync,
          plugNameMapBuilder:
              widget.services.inventorySync.perkNameMapBuilder,
          plugIconMapBuilder:
              widget.services.inventorySync.perkIconMapBuilder,
          plugDescriptionMapBuilder:
              widget.services.inventorySync.perkDescriptionMapBuilder,
          plugEnhancedMapBuilder:
              widget.services.inventorySync.plugEnhancedMapBuilder,
        );
  }

  /// Resolve chrome DTOs for visible plugs (DART-071; never invent text).
  Map<int, EntityInfoData> _entityInfoByHashForDetail() {
    final names = _bridge.plugNameByHash;
    final icons = _bridge.plugIconByHash;
    final descs = _bridge.plugDescriptionByHash;
    final hashes = <int>{
      ...names.keys,
      ...icons.keys,
      ...descs.keys,
      ..._bridge.plugEnhancedByHash.keys,
    };
    if (hashes.isEmpty) return const {};
    final maps = EntityPresentationMaps(
      nameByHash: names,
      iconByHash: icons,
      descriptionByHash: descs,
      kindByHash: {
        for (final h in hashes)
          if (names.containsKey(h)) h: 'Weapon perk',
      },
    );
    final batch = resolveEntityPresentations(
      hashes,
      maps: maps,
      labelKind: EntityLabelKind.plug,
    );
    return {
      for (final e in batch.entries)
        e.key: EntityInfoData(
          id: '${e.key}',
          name: e.value.name,
          kind: e.value.kind,
          iconPath: e.value.iconPath,
          description: e.value.description,
          metaLines: e.value.metaLines,
          nameUnknown: e.value.nameUnknown,
          hashFooter: e.value.hashFooter,
        ),
    };
  }

  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    _bridge = _createBridge();
    // Rebind Owned when OAuth signs in without leaving Catalog / hot restart.
    widget.services.oauthSession.addListener(_onOAuthSessionChanged);
    _load();
  }

  @override
  void didUpdateWidget(covariant CatalogPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.services != widget.services) {
      oldWidget.services.oauthSession.removeListener(_onOAuthSessionChanged);
      widget.services.oauthSession.addListener(_onOAuthSessionChanged);
    }
    final servicesChanged = oldWidget.services != widget.services ||
        oldWidget.bridge != widget.bridge;
    if (servicesChanged) {
      _bridge = _createBridge();
    }
    if (servicesChanged || oldWidget.reloadToken != widget.reloadToken) {
      _load();
    }
  }

  @override
  void dispose() {
    widget.services.oauthSession.removeListener(_onOAuthSessionChanged);
    _queryController.dispose();
    super.dispose();
  }

  void _onOAuthSessionChanged() {
    if (!mounted) return;
    // Sign-in / sign-out without leaving Catalog (no hot restart required).
    _load();
  }

  Future<void> _load() async {
    final seq = ++_loadSeq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Always refresh local status: works signed-in and after Public access expiry.
      await widget.services.inventorySync.refreshStatus();
      if (!mounted || seq != _loadSeq) return;
      await _bridge.refresh(reloadEntities: true);
      if (!mounted || seq != _loadSeq) return;
      final load = widget.services.offlineCatalog.lastLoad;
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = load?.error;
        _emptyReason = load?.emptyReason ?? CatalogEmptyReason.none;
        _version = load?.version;
        _applyBrowse();
      });
      await _reloadFilterCollections();
      await _syncSelection();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
        _results = const [];
        _families = const [];
        _instances = const [];
        _reverseTags = const [];
        _selectedFamily = null;
      });
    }
  }

  CatalogClientFilters _filters() {
    return CatalogClientFilters(
      query: _queryController.text,
      elements: _elements,
      ammos: _ammos,
      slots: _slots,
      classNames: _classNames,
      archetypes: _archetypes,
      exotic: _exotic,
      synergies: _synergies,
      scope: _scope,
    );
  }

  void _applyBrowse() {
    if (_mode == CatalogBrowseMode.weapons) {
      _families = _bridge.browseFamilies(
        _filters(),
        sortKeys: _sortKeys,
      );
      // Flat item list for status counts / empty checks.
      _results = [
        for (final f in _families)
          for (final m in f.members) m.item,
      ];
    } else {
      _families = const [];
      _results = _bridge.browse(
        _filters(),
        mode: _mode,
        sortKeys: _sortKeys,
      );
    }
  }

  List<CatalogGroupNode> _nestedResults() {
    return groupCatalogItemsNested(
      _results,
      List<CatalogGroupDimension>.from(_groupBy),
    );
  }

  List<CatalogFamilyGroupNode> _nestedFamilies() {
    return groupWeaponFamilyBrowseNested(
      _families,
      List<CatalogGroupDimension>.from(_groupBy),
    );
  }

  void _refilter() {
    setState(() {
      _applyBrowse();
    });
    _syncSelection();
  }

  Future<void> _syncSelection() async {
    // Sticky family: keep selection if family still visible after refilter.
    if (_mode == CatalogBrowseMode.weapons && _selectedFamily != null) {
      final key = _selectedFamily!.key;
      WeaponFamily? still;
      for (final f in _families) {
        if (f.key == key) {
          still = f;
          break;
        }
      }
      if (still == null) {
        if (!mounted) return;
        setState(() {
          _selected = null;
          _selectedFamily = null;
          _instances = const [];
          _reverseTags = const [];
          _selectedInstanceId = null;
        });
        return;
      }
      // Family sticky; rebind selected hash if dropped from family or filters.
      final sel = _selected;
      final memberStill = sel != null && still.memberByHash(sel.hash) != null;
      if (!memberStill) {
        final opened = openVersionForFamily(
          still,
          filters: _filters(),
          maxPowerByHash: _bridge.maxPowerByHash(),
        );
        if (!mounted) return;
        setState(() {
          _selectedFamily = still;
          _selected = opened;
        });
      } else {
        if (!mounted) return;
        setState(() => _selectedFamily = still);
      }
    }

    final sel = _selected;
    if (sel == null) {
      if (!mounted) return;
      setState(() {
        _instances = const [];
        _reverseTags = const [];
        _selectedInstanceId = null;
      });
      return;
    }
    final stillVisible = _mode == CatalogBrowseMode.weapons
        ? (_selectedFamily?.memberByHash(sel.hash) != null ||
            _families.any((f) => f.memberByHash(sel.hash) != null))
        : _results.any((i) => i.hash == sel.hash);
    if (!stillVisible) {
      if (!mounted) return;
      setState(() {
        _selected = null;
        _selectedFamily = null;
        _instances = const [];
        _reverseTags = const [];
        _selectedInstanceId = null;
      });
      return;
    }
    final treatArmor = _mode == CatalogBrowseMode.armor ||
        compositionKindFromCatalogItem(sel) == CompositionKind.armor ||
        compositionKindFromCatalogItem(sel) == CompositionKind.exoticArmor;

    // Show sockets immediately (unknown names ok) — do not block the grid on
    // the ~190MB DestinyInventoryItemDefinition load.
    final quick = _bridge.instancesFor(sel.hash, treatAsArmor: treatArmor);
    if (!mounted) return;
    setState(() {
      _instances = quick;
      _selectedInstanceId = defaultHighestPowerInstanceId(quick);
    });

    // Resolve plug names/icons + reverse tags; re-project when names land.
    final instances = await _bridge.instancesForResolved(
      sel.hash,
      treatAsArmor: treatArmor,
    );
    // Also resolve definition can-roll plugs for this weapon identity.
    final defCols =
        widget.services.offlineCatalog.perkColumnsFor(sel.hash);
    if (defCols.isNotEmpty) {
      await _bridge.ensurePlugNames(collectPlugHashesFromPerkColumns(defCols));
    }
    final tags = await _bridge.reverseTagsFor(sel);
    if (!mounted) return;
    // Selection may have changed while names resolved.
    if (_selected?.hash != sel.hash) return;
    setState(() {
      _instances = instances;
      _reverseTags = tags;
      _selectedInstanceId =
          _selectedInstanceId ?? defaultHighestPowerInstanceId(instances);
    });
    // Keep roll-target profiles aligned after async instance resolve.
    await _loadRollTargetsForSelection();
  }

  Future<void> _selectItem(CatalogItem item) async {
    setState(() {
      _selected = item;
      _selectedFamily = null;
      _actionMessage = null;
      _showCanRoll = false;
      _showCraft = false;
      _selectedInstanceId = null;
      _resetRollTargetUi();
      // Collapse secondary filters only — primary line stays visible.
      _moreFiltersExpanded = false;
    });
    await _syncSelection();
    await _loadRollTargetsForSelection();
  }

  Future<void> _selectFamily(WeaponFamily family) async {
    final opened = openVersionForFamily(
      family,
      filters: _filters(),
      maxPowerByHash: _bridge.maxPowerByHash(),
    );
    setState(() {
      _selectedFamily = family;
      _selected = opened;
      _actionMessage = null;
      _showCanRoll = false;
      _showCraft = false;
      _selectedInstanceId = null;
      _resetRollTargetUi();
      _moreFiltersExpanded = false;
    });
    await _syncSelection();
    await _loadRollTargetsForSelection();
  }

  Future<void> _selectFamilyMember(WeaponFamilyMember member) async {
    setState(() {
      _selected = member.item;
      // Keep sticky family; full identity rebind for perks/instances.
      _showCanRoll = false;
      _showCraft = false;
      _selectedInstanceId = null;
      _resetRollTargetUi();
    });
    await _syncSelection();
    await _loadRollTargetsForSelection();
  }

  void _resetRollTargetUi() {
    _rollTargets = const [];
    _activeRollTargetId = null;
    _editingRollTarget = false;
    _creatingRollTarget = false;
    _rollDraftName = '';
    _rollDraftPreferred = const {};
    _rollDraftAvoid = const {};
  }

  Future<int?> _resolveRollTargetUserId() async {
    final fromBridge = _bridge.userId;
    if (fromBridge != null) return fromBridge;
    // Offline library authoring without inventory session.
    final user = await ensureUser(
      widget.services.db,
      bungieMembershipId: 'local-library',
      membershipType: 0,
      displayName: 'Local',
    );
    return user.id;
  }

  String? _weaponKeyForSelection() {
    final sel = _selected;
    if (sel == null) return null;
    return '${sel.hash}';
  }

  Future<void> _loadRollTargetsForSelection() async {
    final weaponKey = _weaponKeyForSelection();
    if (weaponKey == null) return;
    // DBR-IDL-009: exotic weapons have fixed perks — no roll targets UI/data.
    final sel = _selected;
    if (sel != null && sel.isExotic) {
      if (!mounted) return;
      setState(_resetRollTargetUi);
      return;
    }
    final uid = await _resolveRollTargetUserId();
    if (uid == null || !mounted) return;
    final listed = await listWeaponRollTargets(
      widget.services.db,
      userId: uid,
      weaponKey: weaponKey,
    );
    final active = await getActiveWeaponRollTarget(
      widget.services.db,
      userId: uid,
      weaponKey: weaponKey,
    );
    if (!mounted || _weaponKeyForSelection() != weaponKey) return;
    final priorId = _selectedInstanceId;
    setState(() {
      _rollTargets = listed;
      _activeRollTargetId = active?.id;
      // Sticky selection after rank reorder — only re-default if missing.
      if (priorId != null &&
          _instances.any((i) => i.instanceId == priorId)) {
        _selectedInstanceId = priorId;
      } else if (_instances.isNotEmpty) {
        _selectedInstanceId =
            _selectedInstanceId ?? defaultHighestPowerInstanceId(_instances);
      }
    });
  }

  WeaponRollTarget? get _activeRollTarget {
    final id = _activeRollTargetId;
    if (id == null) return null;
    for (final t in _rollTargets) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Plug-family lookup from resolved display names (base ↔ enhanced /
  /// multi-hash same perk). Empty names map → hash-only match.
  PlugFamilyLookup get _plugFamilyOf =>
      buildPlugFamilyLookup(_bridge.plugNameByHash);

  /// Expand each column's plug set with display-name siblings (wash + score).
  Map<String, Set<int>> _expandColumnHashMap(Map<String, Set<int>> raw) {
    if (raw.isEmpty) return raw;
    final familyOf = _plugFamilyOf;
    return {
      for (final e in raw.entries)
        if (e.value.isNotEmpty) e.key: expandHashesWithFamily(e.value, familyOf),
    };
  }

  Map<String, Set<int>> _preferredMapFromTarget(WeaponRollTarget? t) {
    if (t == null) return const {};
    return _expandColumnHashMap({
      for (final c in t.columns)
        if (c.preferredPlugHashes.isNotEmpty)
          c.columnKey: Set<int>.from(c.preferredPlugHashes),
    });
  }

  Map<String, Set<int>> _avoidMapFromTarget(WeaponRollTarget? t) {
    if (t == null) return const {};
    return _expandColumnHashMap({
      for (final c in t.columns)
        if (c.avoidPlugHashes.isNotEmpty)
          c.columnKey: Set<int>.from(c.avoidPlugHashes),
    });
  }

  List<RollTargetColumn> _columnsFromDraftMaps() {
    final keys = {
      ..._rollDraftPreferred.keys,
      ..._rollDraftAvoid.keys,
    };
    return [
      for (final k in keys)
        RollTargetColumn(
          columnKey: k,
          // Label helps score resolve socket_N ↔ Label@i across instances.
          label: _labelFromColumnKey(k),
          preferredPlugHashes: _rollDraftPreferred[k] ?? const {},
          avoidPlugHashes: _rollDraftAvoid[k] ?? const {},
        ),
    ];
  }

  /// Human label from editor key (`Trait 1@3` → `Trait 1`, `socket_2` → null).
  String? _labelFromColumnKey(String key) {
    if (key.startsWith('socket_') || key.startsWith('col_')) return null;
    final at = key.lastIndexOf('@');
    if (at > 0) return key.substring(0, at);
    return key;
  }

  CatalogInstanceRollScore _toPresentationScore(RollTargetMatchResult m) {
    return CatalogInstanceRollScore(
      preferredMatched: m.preferredMatched,
      preferredScored: m.preferredScored,
      avoidHits: m.avoidHits,
      avoidScored: m.avoidScored,
      // Column-level perfect (all preferred sockets hit), not plug N==M.
      allPreferredColumnsMatched: m.isPerfectPreferred,
    );
  }

  /// Host rank + scores for active target (domain pure score; no UI reimpl).
  ({
    List<CatalogInstanceProjection> instances,
    Map<String, CatalogInstanceRollScore> scores,
    bool ranked,
  }) _rankedInstancesAndScores() {
    final active = _activeRollTarget;
    final exotic = _selected?.isExotic ?? false;
    if (exotic || active == null || _instances.isEmpty) {
      return (
        instances: _instances,
        scores: const <String, CatalogInstanceRollScore>{},
        ranked: false,
      );
    }
    // Prefer draft while editing so dual segs track live Want/Avoid (BUG-009).
    final scoreTarget = _editingRollTarget
        ? WeaponRollTarget(
            id: active.id,
            userId: active.userId,
            weaponKey: active.weaponKey,
            name: _rollDraftName.trim().isEmpty ? active.name : _rollDraftName,
            columns: _columnsFromDraftMaps(),
          )
        : active;
    final inputs = <RollTargetInstanceInput>[
      for (final inst in _instances)
        RollTargetInstanceInput(
          instanceId: inst.instanceId,
          // Equipped + reusables so multi-pick preferred/avoid on this copy score.
          plugsByColumn:
              catalogRollAllPlugsByColumnFromSockets(inst.socketPlugs),
          power: inst.power,
          gearTier: inst.gearTier,
        ),
    ];
    // Same display name (e.g. multiple Stopping Power hashes) counts as one
    // perk family so preferred/avoid still match across roll variants.
    final ranked = rankOwnedForRollTarget(
      scoreTarget,
      inputs,
      familyOf: _plugFamilyOf,
    );
    final byId = {for (final i in _instances) i.instanceId: i};
    final ordered = <CatalogInstanceProjection>[
      for (final r in ranked)
        if (byId.containsKey(r.instance.instanceId))
          byId[r.instance.instanceId]!,
    ];
    // Append any not in rank (shouldn't happen).
    for (final i in _instances) {
      if (!ordered.any((o) => o.instanceId == i.instanceId)) {
        ordered.add(i);
      }
    }
    final scores = <String, CatalogInstanceRollScore>{
      for (final r in ranked)
        r.instance.instanceId: _toPresentationScore(r.match),
    };
    return (instances: ordered, scores: scores, ranked: true);
  }

  Future<void> _setActiveRollTarget(String? targetId) async {
    final weaponKey = _weaponKeyForSelection();
    if (weaponKey == null) return;
    if (_selected?.isExotic ?? false) return;
    final uid = await _resolveRollTargetUserId();
    if (uid == null || !mounted) return;
    await setActiveWeaponRollTarget(
      widget.services.db,
      userId: uid,
      weaponKey: weaponKey,
      targetId: targetId,
    );
    if (!mounted) return;
    final priorId = _selectedInstanceId;
    setState(() {
      _activeRollTargetId = targetId;
      // Selection sticky after rank reorder.
      if (priorId != null &&
          _instances.any((i) => i.instanceId == priorId)) {
        _selectedInstanceId = priorId;
      }
    });
  }

  void _beginEditRollTarget({required bool creating}) {
    if (_selected?.isExotic ?? false) return;
    final active = _activeRollTarget;
    setState(() {
      _creatingRollTarget = creating;
      _editingRollTarget = true;
      _showCanRollBeforeEdit = _showCanRoll;
      // Editor needs can-roll pool for ③ plugs; instance ①/② also cycle (BUG-009).
      _showCanRoll = true;
      if (creating) {
        _rollDraftName = '';
        _rollDraftPreferred = const {};
        _rollDraftAvoid = const {};
        _rollEditSnapshotId = null;
      } else if (active != null) {
        _rollDraftName = active.name;
        _rollDraftPreferred = _preferredMapFromTarget(active);
        _rollDraftAvoid = _avoidMapFromTarget(active);
        _rollEditSnapshotId = active.id;
        _rollEditSnapshotName = active.name;
        _rollEditSnapshotPreferred = _preferredMapFromTarget(active);
        _rollEditSnapshotAvoid = _avoidMapFromTarget(active);
      } else {
        // Edit with Off → treat as New
        _creatingRollTarget = true;
        _rollDraftName = '';
        _rollDraftPreferred = const {};
        _rollDraftAvoid = const {};
        _rollEditSnapshotId = null;
      }
    });
  }

  void _cancelEditRollTarget() {
    setState(() {
      _editingRollTarget = false;
      _creatingRollTarget = false;
      _showCanRoll = _showCanRollBeforeEdit;
      if (_rollEditSnapshotId != null) {
        _rollDraftName = _rollEditSnapshotName;
        _rollDraftPreferred = _rollEditSnapshotPreferred;
        _rollDraftAvoid = _rollEditSnapshotAvoid;
      } else {
        _rollDraftName = '';
        _rollDraftPreferred = const {};
        _rollDraftAvoid = const {};
      }
    });
  }

  Future<void> _saveRollTarget() async {
    final weaponKey = _weaponKeyForSelection();
    if (weaponKey == null) return;
    final isExotic = _selected?.isExotic ?? false;
    if (isExotic) return;
    final name = _rollDraftName.trim();
    if (name.isEmpty) return;
    if (catalogRollTargetHasOverlap(
      preferredByColumn: _rollDraftPreferred,
      avoidByColumn: _rollDraftAvoid,
    )) {
      return; // soft block save only
    }
    final uid = await _resolveRollTargetUserId();
    if (uid == null || !mounted) return;
    final columns = _columnsFromDraftMaps();
    try {
      if (_creatingRollTarget || _rollEditSnapshotId == null) {
        final created = await createWeaponRollTarget(
          widget.services.db,
          userId: uid,
          weaponKey: weaponKey,
          name: name,
          columns: columns,
          isExotic: isExotic,
        );
        await setActiveWeaponRollTarget(
          widget.services.db,
          userId: uid,
          weaponKey: weaponKey,
          targetId: created.id,
        );
      } else {
        await updateWeaponRollTarget(
          widget.services.db,
          userId: uid,
          id: _rollEditSnapshotId!,
          name: name,
          columns: columns,
          isExotic: isExotic,
        );
      }
    } on RollTargetValidationException {
      // Domain hard-rejects overlap; UI already soft-blocks — stay open.
      if (mounted) setState(() {});
      return;
    }
    if (!mounted) return;
    setState(() {
      _editingRollTarget = false;
      _creatingRollTarget = false;
      _showCanRoll = _showCanRollBeforeEdit;
    });
    await _loadRollTargetsForSelection();
  }

  Future<void> _deleteActiveRollTarget() async {
    final active = _activeRollTarget;
    final weaponKey = _weaponKeyForSelection();
    if (active == null || weaponKey == null) return;
    final uid = await _resolveRollTargetUserId();
    if (uid == null || !mounted) return;
    await deleteWeaponRollTarget(
      widget.services.db,
      userId: uid,
      id: active.id,
    );
    await setActiveWeaponRollTarget(
      widget.services.db,
      userId: uid,
      weaponKey: weaponKey,
      targetId: null,
    );
    if (!mounted) return;
    setState(() {
      _editingRollTarget = false;
      _creatingRollTarget = false;
      _activeRollTargetId = null;
    });
    await _loadRollTargetsForSelection();
  }

  void _cycleRollPlug(String columnKey, int plugHash) {
    final current = catalogRollPlugModeFor(
      columnKey: columnKey,
      plugHash: plugHash,
      preferredByColumn: _rollDraftPreferred,
      avoidByColumn: _rollDraftAvoid,
    );
    final next = nextCatalogRollPlugMode(current);
    final applied = applyCatalogRollPlugMode(
      columnKey: columnKey,
      plugHash: plugHash,
      mode: next,
      preferredByColumn: _rollDraftPreferred,
      avoidByColumn: _rollDraftAvoid,
    );
    setState(() {
      _rollDraftPreferred = applied.preferredByColumn;
      _rollDraftAvoid = applied.avoidByColumn;
    });
  }

  void _setScope(CatalogScope scope) {
    if (_scope == scope) return;
    _scope = scope;
    _refilter();
  }

  void _setMode(CatalogBrowseMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      // Clear kind-inappropriate facets when switching modes.
      _slots = emptyFacet();
      _ammos = emptyFacet();
      _classNames = emptyFacet();
      _archetypes = emptyFacet();
      _groupBy.clear();
      _collapsedGroups.clear();
      _selectedFamily = null;
      _clearActiveFilterCollection(notify: false);
      _applyBrowse();
    });
    _reloadFilterCollections();
    _syncSelection();
  }

  void _cycleElement(String value) {
    _elements = cycleFacetValue(_elements, value);
    _refilter();
  }

  void _cycleAmmo(String value) {
    _ammos = cycleFacetValue(_ammos, value);
    _refilter();
  }

  void _cycleSlot(String value) {
    _slots = cycleFacetValue(_slots, value);
    _refilter();
  }

  void _cycleClass(String value) {
    _classNames = cycleFacetValue(_classNames, value);
    _refilter();
  }

  void _cycleArchetype(String value) {
    _archetypes = cycleFacetValue(_archetypes, value);
    _refilter();
  }

  void _cycleSynergy(String synergyId) {
    _synergies = cycleFacetValue(_synergies, synergyId);
    _refilter();
  }

  void _toggleGroupDimension(CatalogGroupDimension dim) {
    setState(() {
      if (_groupBy.contains(dim)) {
        _groupBy.remove(dim);
      } else {
        _groupBy.add(dim);
      }
      _collapsedGroups.clear();
    });
  }

  void _toggleGroupCollapse(String key) {
    setState(() {
      if (_collapsedGroups.contains(key)) {
        _collapsedGroups.remove(key);
      } else {
        _collapsedGroups.add(key);
      }
    });
  }

  void _jumpToGroup(String key) {
    // Re-click JUMP on a fully open path → collapse (view-only; BR-CAT-007).
    if (isCatalogGroupPathFullyOpen(key, _collapsedGroups)) {
      setState(() {
        _collapsedGroups.add(key);
        _outlineActiveKey = key;
      });
      return;
    }
    setState(() {
      for (final a in catalogGroupAncestorKeys(key)) {
        _collapsedGroups.remove(a);
      }
      _collapsedGroups.remove(key);
      _outlineActiveKey = key;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gk = _groupAnchorKeys[key];
      final ctx = gk?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 280),
          alignment: 0.05,
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onOutlineScrollSpy(String key) {
    if (_outlineActiveKey == key) return;
    setState(() => _outlineActiveKey = key);
  }

  void _ensureGroupAnchors(Iterable<String> keys) {
    for (final k in keys) {
      _groupAnchorKeys.putIfAbsent(k, GlobalKey.new);
    }
  }

  List<CatalogGroupOutlineEntry> _outlineEntriesForFamilies(
    List<CatalogFamilyGroupNode> roots,
  ) {
    final dims = List<CatalogGroupDimension>.from(_groupBy);
    return [
      for (final row in flattenAllFamilyGroupNodes(roots))
        CatalogGroupOutlineEntry(
          key: row.node.key,
          label: row.node.label,
          count: row.node.count,
          depth: row.depth,
          dimension: catalogGroupDimensionAt(dims, row.depth),
          collapsedHint: _collapsedGroups.contains(row.node.key),
        ),
    ];
  }

  List<CatalogGroupOutlineEntry> _outlineEntriesForItems(
    List<CatalogGroupNode> roots,
  ) {
    final dims = List<CatalogGroupDimension>.from(_groupBy);
    return [
      for (final row in flattenAllCatalogGroupNodes(roots))
        CatalogGroupOutlineEntry(
          key: row.node.key,
          label: row.node.label,
          count: row.node.count,
          depth: row.depth,
          dimension: catalogGroupDimensionAt(dims, row.depth),
          collapsedHint: _collapsedGroups.contains(row.node.key),
        ),
    ];
  }

  void _openSortGroupSheet() {
    showCatalogSortGroupSheet(
      context: context,
      sortKeys: _sortKeys,
      groupDimensions: List<CatalogGroupDimension>.from(_groupBy),
      availableGroupDimensions: weaponGroupDimensions,
      onApply: (sortKeys, groupDims) {
        setState(() {
          _sortKeys = sortKeys;
          _groupBy
            ..clear()
            ..addAll(groupDims);
          _collapsedGroups.clear();
          _applyBrowse();
        });
        _syncSelection();
      },
    );
  }

  void _cycleExotic() {
    setState(() {
      if (_exotic == null) {
        _exotic = true;
      } else if (_exotic == true) {
        _exotic = false;
      } else {
        _exotic = null;
      }
      _applyBrowse();
    });
    _syncSelection();
  }

  int _activeFilterCount() {
    var n = 0;
    if (!isFacetEmpty(_elements)) n++;
    if (!isFacetEmpty(_ammos)) n++;
    if (!isFacetEmpty(_slots)) n++;
    if (!isFacetEmpty(_classNames)) n++;
    if (!isFacetEmpty(_archetypes)) n++;
    if (!isFacetEmpty(_synergies)) n++;
    if (_exotic != null) n++;
    if (_groupBy.isNotEmpty) n++;
    return n;
  }

  void _clearAllFilters() {
    setState(() {
      _queryController.clear();
      _elements = emptyFacet();
      _ammos = emptyFacet();
      _slots = emptyFacet();
      _classNames = emptyFacet();
      _archetypes = emptyFacet();
      _synergies = emptyFacet();
      _exotic = null;
      _groupBy.clear();
      _collapsedGroups.clear();
      _clearActiveFilterCollection(notify: false);
      _applyBrowse();
    });
    _syncSelection();
  }

  // --- Filter collections (004) ------------------------------------------------

  String get _browseModeWire => _mode.name;

  CatalogFacetSelection _facetToSelection(FacetFilter f) =>
      CatalogFacetSelection(
        include: List<String>.from(f.include),
        exclude: List<String>.from(f.exclude),
      );

  void _clearActiveFilterCollection({bool notify = true}) {
    _activeFilterCollectionId = null;
    _activeFilterCollectionName = null;
    _appliedFilterCollection = null;
    if (notify && mounted) setState(() {});
  }

  Future<void> _reloadFilterCollections() async {
    final uid = _bridge.userId;
    if (uid == null) {
      if (!mounted) return;
      setState(() => _filterCollections = const []);
      return;
    }
    try {
      final list = await listCatalogFilterCollectionsUseCase(
        widget.services.db,
        userId: uid,
        browseMode: _browseModeWire,
      );
      if (!mounted) return;
      setState(() => _filterCollections = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _filterCollections = const []);
    }
  }

  bool _listEqStr(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _facetsEq(CatalogFacetSelection a, FacetFilter b) {
    return _listEqStr(a.include, b.include) &&
        _listEqStr(a.exclude, b.exclude);
  }

  bool get _filterCollectionDirty {
    final snap = _appliedFilterCollection;
    if (_activeFilterCollectionId == null || snap == null) return false;
    final q = _queryController.text.trim();
    final snapQ = (snap.query ?? '').trim();
    if (snap.scope !=
        (_scope == CatalogScope.owned
            ? kCatalogScopeOwned
            : kCatalogScopeAll)) {
      return true;
    }
    if (q != snapQ) return true;
    if (snap.exotic != _exotic) return true;
    if (!_facetsEq(snap.elements, _elements)) return true;
    if (!_facetsEq(snap.ammos, _ammos)) return true;
    if (!_facetsEq(snap.slots, _slots)) return true;
    if (!_facetsEq(snap.archetypes, _archetypes)) return true;
    if (!_facetsEq(snap.classNames, _classNames)) return true;
    if (!_facetsEq(snap.synergies, _synergies)) return true;
    final liveSort = _sortKeys.map((k) => k.name).toList();
    final expectedSort = snap.sortKeys.isEmpty
        ? kDefaultWeaponSortKeys.map((k) => k.name).toList()
        : snap.sortKeys;
    if (!_listEqStr(liveSort, expectedSort)) return true;
    final liveGroup = _groupBy.map((d) => d.name).toList();
    if (!_listEqStr(liveGroup, snap.groupBy)) return true;
    return false;
  }

  bool get _canSaveFilterCollection {
    final defaultSort = kDefaultWeaponSortKeys.map((k) => k.name).toList();
    final liveSort = _sortKeys.map((k) => k.name).toList();
    final customSort = !_listEqStr(liveSort, defaultSort);
    return catalogFilterCollectionsCanSave(
      hasNonDefaultScope: _scope == CatalogScope.owned,
      hasQuery: _queryController.text.trim().isNotEmpty,
      hasExoticConstraint: _exotic != null,
      hasFacetCriteria: !isFacetEmpty(_elements) ||
          !isFacetEmpty(_ammos) ||
          !isFacetEmpty(_slots) ||
          !isFacetEmpty(_classNames) ||
          !isFacetEmpty(_archetypes) ||
          !isFacetEmpty(_synergies),
      hasGroupBy: _groupBy.isNotEmpty,
      hasCustomSort: customSort,
    );
  }

  String _summarizeFilterCollection(CatalogFilterCollection c) {
    final parts = <String>[];
    if (c.scope == kCatalogScopeOwned) parts.add('owned');
    final q = (c.query ?? '').trim();
    if (q.isNotEmpty) parts.add('q:$q');
    if (c.exotic == true) parts.add('exotic');
    if (c.exotic == false) parts.add('−exotic');
    void addFacet(String label, CatalogFacetSelection s) {
      for (final v in s.include) {
        parts.add('$label:$v');
      }
      for (final v in s.exclude) {
        parts.add('−$label:$v');
      }
    }

    addFacet('element', c.elements);
    addFacet('ammo', c.ammos);
    addFacet('slot', c.slots);
    addFacet('type', c.archetypes);
    addFacet('class', c.classNames);
    addFacet('synergy', c.synergies);
    if (c.sortKeys.isNotEmpty) parts.add('sort:${c.sortKeys.join(',')}');
    if (c.groupBy.isNotEmpty) parts.add('group:${c.groupBy.join(',')}');
    return parts.isEmpty ? 'no criteria' : parts.join(' · ');
  }

  List<CatalogFilterCollectionItem> get _filterCollectionItems {
    return [
      for (final c in _filterCollections)
        CatalogFilterCollectionItem(
          id: c.id,
          name: c.name,
          summary: _summarizeFilterCollection(c),
        ),
    ];
  }

  void _bindFilterCollection(CatalogFilterCollection c) {
    final client = catalogClientFiltersFromCollection(c);
    final sortKeys = catalogSortKeysFromCollection(c);
    final groupBy = catalogGroupByFromCollection(c);

    _queryController.text = client.query ?? '';
    _scope = client.scope;
    _exotic = client.exotic;
    _elements = normalizeFacet(client.elements);
    _ammos = normalizeFacet(client.ammos);
    _slots = normalizeFacet(client.slots);
    _classNames = normalizeFacet(client.classNames);
    _archetypes = normalizeFacet(client.archetypes);
    _synergies = normalizeFacet(client.synergies);
    _sortKeys = sortKeys.isEmpty
        ? List<CatalogSortKey>.from(kDefaultWeaponSortKeys)
        : sortKeys;
    _groupBy
      ..clear()
      ..addAll(groupBy);
    _collapsedGroups.clear();
    _activeFilterCollectionId = c.id;
    _activeFilterCollectionName = c.name;
    _appliedFilterCollection = c;
    _applyBrowse();
  }

  Future<void> _applyFilterCollection(String id) async {
    final uid = _bridge.userId;
    if (uid == null) {
      setState(() {
        _actionMessage = 'Sign in to apply saved filters.';
      });
      return;
    }
    try {
      final c = await applyCatalogFilterCollection(
        widget.services.db,
        userId: uid,
        id: id,
      );
      if (!mounted) return;
      if (c == null) {
        setState(() {
          _actionMessage = 'Saved filter not found.';
        });
        return;
      }
      setState(() {
        _bindFilterCollection(c);
        _actionMessage = 'Applied “${c.name}” — criteria only';
      });
      await _syncSelection();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _actionMessage = 'Apply failed: $e';
      });
    }
  }

  Future<String?> _saveFilterCollection(String name) async {
    final uid = _bridge.userId;
    if (uid == null) return 'Sign in to save filter collections.';
    try {
      final saved = await createCatalogFilterCollectionUseCase(
        widget.services.db,
        userId: uid,
        name: name,
        browseMode: _browseModeWire,
        scope: _scope == CatalogScope.owned
            ? kCatalogScopeOwned
            : kCatalogScopeAll,
        query: _queryController.text.trim().isEmpty
            ? null
            : _queryController.text.trim(),
        exotic: _exotic,
        elements: _facetToSelection(_elements),
        ammos: _facetToSelection(_ammos),
        slots: _facetToSelection(_slots),
        archetypes: _facetToSelection(_archetypes),
        classNames: _facetToSelection(_classNames),
        synergies: _facetToSelection(_synergies),
        sortKeys: _sortKeys.map((k) => k.name).toList(),
        groupBy: _groupBy.map((d) => d.name).toList(),
      );
      if (!mounted) return null;
      setState(() {
        _activeFilterCollectionId = saved.id;
        _activeFilterCollectionName = saved.name;
        _appliedFilterCollection = saved;
        _actionMessage = 'Saved “${saved.name}”';
      });
      await _reloadFilterCollections();
      return null;
    } on CatalogFilterCollectionValidationException catch (e) {
      return e.message;
    } on CatalogFilterCollectionPersistException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> _renameFilterCollection(String id, String name) async {
    final uid = _bridge.userId;
    if (uid == null) return 'Sign in to rename.';
    try {
      final renamed = await renameCatalogFilterCollection(
        widget.services.db,
        userId: uid,
        id: id,
        name: name,
      );
      if (renamed == null) return 'Collection not found.';
      if (!mounted) return null;
      setState(() {
        if (_activeFilterCollectionId == id) {
          _activeFilterCollectionName = renamed.name;
          _appliedFilterCollection = renamed;
        }
        _actionMessage = 'Renamed to “${renamed.name}”';
      });
      await _reloadFilterCollections();
      return null;
    } on CatalogFilterCollectionValidationException catch (e) {
      return e.message;
    } on CatalogFilterCollectionPersistException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> _deleteFilterCollection(String id) async {
    final uid = _bridge.userId;
    if (uid == null) return 'Sign in to delete.';
    try {
      final ok = await deleteCatalogFilterCollectionUseCase(
        widget.services.db,
        userId: uid,
        id: id,
      );
      if (!ok) return 'Collection not found.';
      if (!mounted) return null;
      setState(() {
        if (_activeFilterCollectionId == id) {
          _clearActiveFilterCollection(notify: false);
        }
        _actionMessage = 'Deleted saved filter';
      });
      await _reloadFilterCollections();
      return null;
    } on CatalogFilterCollectionPersistException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> _syncInventory() async {
    try {
      await widget.services.inventorySync.syncNow();
    } catch (_) {
      // Soft fail — empty state stays; user can open Settings.
    }
    await _load();
  }

  Future<void> _createSetFromHit(CatalogItem item) async {
    final uid = _bridge.userId;
    if (uid == null) {
      setState(() {
        _actionMessage = 'Sign in to create a Set from catalog.';
      });
      return;
    }
    final kind = compositionKindFromCatalogItem(item);
    if (kind == null || !hitActions(kind).set) {
      setState(() {
        _actionMessage = 'This entity cannot be added to a Set.';
      });
      return;
    }
    final typeWire = setTypeWireForKind(kind)!;
    final setType = SetType.tryParse(typeWire)!;
    final slot = item.slot ??
        (typeWire == 'weapon'
            ? 'Kinetic'
            : typeWire == 'armor'
                ? 'Helmet'
                : 'General');
    try {
      final detail = await createUserSet(
        widget.services.db,
        uid,
        CreateSetCommand(
          name: '${item.name} set',
          type: setType,
        ),
      );
      final instanceId =
          _instances.isNotEmpty ? _instances.first.instanceId : null;
      await upsertUserSetItem(
        widget.services.db,
        uid,
        detail.set.id,
        UpsertSetItemCommand(
          slot: slot,
          itemHash: item.hash,
          itemName: item.name,
          instanceId: instanceId,
        ),
      );
      if (!mounted) return;
      setState(() {
        _actionMessage =
            'Created Set "${detail.set.name}" with ${item.name} ($slot).';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _actionMessage = 'Set create failed: $e';
      });
    }
  }

  Future<void> _createSynergyFromHit(CatalogItem item) async {
    final uid = _bridge.userId;
    if (uid == null) {
      setState(() {
        _actionMessage = 'Sign in to create a Synergy from catalog.';
      });
      return;
    }
    final kind = compositionKindFromCatalogItem(item);
    if (kind == null || !hitActions(kind).synergy) {
      setState(() {
        _actionMessage = 'This entity cannot link as Synergy evidence.';
      });
      return;
    }
    final linkKind = synergyLinkKindWireForKind(kind);
    if (linkKind == null) {
      setState(() {
        _actionMessage = 'No synergy link kind for this entity.';
      });
      return;
    }
    try {
      final created = await createUserSynergy(
        widget.services.db,
        uid,
        CreateSynergyCommand(
          name: '${item.name} synergy',
          type: 'dps',
          links: [
            SynergyLinkWrite(
              kind: linkKind,
              displayName: item.name,
              itemHash: item.hash,
            ),
          ],
        ),
      );
      await _bridge.refresh(reloadEntities: false);
      if (!mounted) return;
      setState(() {
        _applyBrowse();
        _actionMessage = 'Created Synergy "${created.name}" linked to ${item.name}.';
      });
      await _syncSelection();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _actionMessage = 'Synergy create failed: $e';
      });
    }
  }

  List<CatalogFacetGroup> _primaryFacetGroups() {
    return [
      if (catalogShowsElementFacet(_mode))
        CatalogFacetGroup(
          id: 'element',
          values: catalogElements,
          facet: _elements,
          onCycle: _cycleElement,
          // Official Bungie element icons (icon-only density).
          iconOnly: true,
        ),
      CatalogFacetGroup(
        id: 'slot',
        values: catalogSlotsForMode(_mode),
        facet: _slots,
        onCycle: _cycleSlot,
        // K / E / P icon-only (mock density); labels via tooltip.
        iconOnly: true,
      ),
      // GAP-CAT-BROWSE-004: weapon type silhouettes on primary line.
      if (_mode == CatalogBrowseMode.weapons)
        CatalogFacetGroup(
          id: 'archetype',
          values: catalogArchetypesForMode(_mode),
          facet: _archetypes,
          onCycle: _cycleArchetype,
          iconOnly: true,
        ),
    ];
  }

  List<CatalogFacetGroup> _secondaryFacetGroups() {
    return [
      if (catalogShowsAmmoFacet(_mode))
        CatalogFacetGroup(
          id: 'ammo',
          values: catalogAmmoTypes,
          facet: _ammos,
          onCycle: _cycleAmmo,
          iconOnly: true,
        ),
      if (catalogShowsClassFacet(_mode))
        CatalogFacetGroup(
          id: 'class',
          values: catalogClassNames,
          facet: _classNames,
          onCycle: _cycleClass,
        ),
      // Weapons: archetype is primary iconOnly — do not repeat as text under More.
      if (_mode != CatalogBrowseMode.weapons)
        CatalogFacetGroup(
          id: 'archetype',
          values: catalogArchetypesForMode(_mode),
          facet: _archetypes,
          onCycle: _cycleArchetype,
        ),
      if (_bridge.synergyMembership.isNotEmpty)
        CatalogFacetGroup(
          id: 'synergy',
          values: _bridge.synergyMembership.map((s) => s.id).toList(),
          facet: _synergies,
          onCycle: _cycleSynergy,
          labelOf: (id) => _bridge.synergyNames[id] ?? 'Synergy',
        ),
    ];
  }

  Widget _groupByRow() {
    final palette = FlapPalette.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        key: const Key('catalog_group_by'),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              'GROUP',
              style: neonMono(
                color: palette.muted,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
          ),
          for (final dim in catalogGroupDimensions)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              // Single semantic owner (Windows AX) — raw FilterChip nests
              // label/selection nodes that thrash on group-by toggles.
              child: Semantics(
                button: true,
                selected: _groupBy.contains(dim.id),
                label: 'Group by ${dim.label}',
                excludeSemantics: true,
                child: FilterChip(
                  key: Key('group_chip_${dim.id.name}'),
                  label: Text(dim.label),
                  selected: _groupBy.contains(dim.id),
                  onSelected: (_) => _toggleGroupDimension(dim.id),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = FlapPalette.of(context);
    // Vex Network Interface posture (docs/ui-mocks/vex-design-system-docs.html):
    // soft zones, dense filters inside modules, air between regions, cyan ≤2 hits.
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'CATALOG',
          style: neonDisplay(
            color: palette.foreground,
            fontSize: 16,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          // Single semantic owner (Windows AX) — IconButton tooltip + icon
          // otherwise nest nodes that thrash on loading state flips.
          Semantics(
            button: true,
            enabled: !_loading,
            label: 'Sync catalog channel',
            excludeSemantics: true,
            child: IconButton(
              key: const Key('catalog_reload'),
              tooltip: 'Sync catalog channel',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thin header: title + live pulse only (no multi-line subtitle block).
          NeonPageHeader(
            kicker: 'Module · Build Creator',
            title: 'Catalog',
            trailing: Tooltip(
              message: _version ?? 'No entity channel version',
              excludeFromSemantics: true,
              child: NeonLivePulse(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _loading
                            ? palette.warning
                            : (_error != null
                                ? palette.danger
                                : palette.success),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _loading
                          ? 'SYNC'
                          : (_error != null ? 'FAULT' : 'LIVE'),
                      style: neonMono(
                        color: palette.muted,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // --- Single primary filter band (mode · scope · search · chips) ---
          Padding(
            padding: const EdgeInsets.fromLTRB(kSpace12, 0, kSpace12, kSpace6),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.36,
              ),
              child: NeonZone(
                padding: const EdgeInsets.symmetric(
                  horizontal: kSpace8,
                  vertical: kSpace8,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CatalogFilterBar(
                        queryController: _queryController,
                        onQueryChanged: (_) => _refilter(),
                        activeFilterCount: _activeFilterCount() +
                            (_queryController.text.trim().isEmpty ? 0 : 1),
                        moreExpanded: _moreFiltersExpanded,
                        onToggleMore: () {
                          setState(
                            () =>
                                _moreFiltersExpanded = !_moreFiltersExpanded,
                          );
                        },
                        onReset: _clearAllFilters,
                        exotic: _exotic,
                        onCycleExotic: _cycleExotic,
                        // Mode tabs on the same line as scope/search/chips.
                        prefix: KeyedSubtree(
                          key: const Key('catalog_mode_row'),
                          child: NeonSegmentedTabs(
                            dense: true,
                            selectedId: _mode.name,
                            onSelected: (id) {
                              final mode = CatalogBrowseMode.values.firstWhere(
                                (m) => m.name == id,
                                orElse: () => CatalogBrowseMode.weapons,
                              );
                              _setMode(mode);
                            },
                            options: [
                              for (final mode in CatalogBrowseMode.values)
                                NeonSegmentOption(
                                  id: mode.name,
                                  label: browseModeLabel(mode),
                                  key: Key('mode_chip_${mode.name}'),
                                ),
                            ],
                          ),
                        ),
                        leading: CatalogScopeControl(
                          scope: _scope,
                          ownedLabel: _ownedChipLabel(),
                          onChanged: _setScope,
                        ),
                        trailing: CatalogFilterCollectionsControl(
                          key: const Key('catalog_filter_collections_control'),
                          items: _filterCollectionItems,
                          browseModeLabel: _browseModeWire,
                          activeId: _activeFilterCollectionId,
                          activeName: _activeFilterCollectionName,
                          dirty: _filterCollectionDirty,
                          signedIn: _bridge.userId != null,
                          canSave: _canSaveFilterCollection,
                          atCap: _filterCollections.length >=
                              kMaxCatalogFilterCollectionsPerUserMode,
                          preferSheet:
                              MediaQuery.sizeOf(context).width < 520,
                          onApply: _applyFilterCollection,
                          onSave: _saveFilterCollection,
                          onRename: _renameFilterCollection,
                          onDelete: _deleteFilterCollection,
                        ),
                        primaryGroups: _primaryFacetGroups(),
                        secondaryGroups: _secondaryFacetGroups(),
                      ),
                      if (_mode == CatalogBrowseMode.weapons) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            key: const Key('catalog_sort_group_open'),
                            onPressed: _openSortGroupSheet,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(0, 28),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'SORT & GROUP',
                              style: neonMono(
                                color: palette.muted,
                                fontSize: 10,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (_moreFiltersExpanded) ...[
                        const SizedBox(height: 4),
                        _groupByRow(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Incomplete entity cache (e.g. missing exotic-weapons.json).
          if (_missingExoticWeaponsStore) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(kSpace12, 0, kSpace12, kSpace6),
              child: Material(
                key: const Key('catalog_missing_exotic_weapons_banner'),
                color: palette.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(kRadiusMax),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kSpace12,
                    vertical: kSpace8,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 18, color: palette.warning),
                      const SizedBox(width: kSpace8),
                      Expanded(
                        child: Text(
                          'Exotic weapons store is missing or empty '
                          '(only legendary weapons are loaded). '
                          'Rebuild entity stores: Settings → Refresh manifest.',
                          style: neonBody(
                            color: palette.foreground,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (widget.onOpenSettings != null)
                        TextButton(
                          key: const Key('catalog_missing_exotic_settings'),
                          onPressed: widget.onOpenSettings,
                          child: Text(
                            'SETTINGS',
                            style: neonMono(
                              color: palette.accent,
                              fontSize: 10,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          // Status channel (air between filter zone and results)
          Padding(
            padding: const EdgeInsets.fromLTRB(kSpace16, 0, kSpace16, kSpace8),
            child: Tooltip(
              message: _version ?? 'No entity channel version',
              excludeFromSemantics: true,
              child: Text(
                _statusLine(),
                key: const Key('catalog_status'),
                style: neonMono(
                  color: palette.muted,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          // --- Results + full-height ~400px detail (not LibraryWorkspace 320 rail) ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(kSpace16, 0, kSpace16, kSpace16),
              child: CatalogWeaponsWorkspace(
                main: _buildBody(),
                detail: _selected == null ? null : _buildDetailPanel(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Short manifest version for status (full string on tooltip).
  static String _shortVersion(String? version) {
    if (version == null || version.isEmpty) return '—';
    // Prefer last path-like segment (e.g. …bnet.65583).
    final parts = version.split(RegExp(r'[./-]'));
    if (parts.length >= 2) {
      final tail = parts.sublist(parts.length - 2).join('.');
      if (tail.length >= 4) return tail;
    }
    if (version.length <= 18) return version;
    return '…${version.substring(version.length - 14)}';
  }

  /// Legendary weapons present but exotic-weapons store empty/missing.
  ///
  /// Prefer projected [isExotic] flags (always safe). Optionally refine with
  /// [OfflineCatalogLoadResult.storeCounts] when present.
  bool get _missingExoticWeaponsStore {
    if (_loading || _error != null) return false;
    if (_mode != CatalogBrowseMode.weapons) return false;

    // Primary signal: weapon rows with no isExotic (store never projected).
    final base = _bridge.annotatedBase;
    if (base.isEmpty) return false;
    final weapons = base
        .where((i) => itemMatchesBrowseMode(i, CatalogBrowseMode.weapons))
        .toList();
    if (weapons.isEmpty) return false;
    final anyExotic = weapons.any((i) => i.isExotic);
    final anyLegendary = weapons.any((i) => !i.isExotic);
    if (anyLegendary && !anyExotic) return true;

    // Secondary: explicit store counts when loaded.
    final load = widget.services.offlineCatalog.lastLoad;
    if (load == null) return false;
    try {
      final counts = load.storeCounts;
      if (counts.isEmpty) return false;
      return load.missingExoticWeapons;
    } catch (_) {
      return false;
    }
  }

  String _statusLine() {
    if (_loading) return 'Loading entity stores…';
    if (_error != null) return 'Load failed — use Reload or check Settings';
    final v = _shortVersion(_version);
    final base = _bridge.annotatedBase.length;
    final inv = _bridge.inventory.length;
    final scopeLabel = _scope == CatalogScope.owned ? 'OWNED' : 'ALL';
    final modeLabel = browseModeLabel(_mode).toUpperCase();
    final exo = _bridge.annotatedBase
        .where(
          (i) =>
              i.isExotic && itemMatchesBrowseMode(i, CatalogBrowseMode.weapons),
        )
        .length;
    final exoPart = _missingExoticWeaponsStore
        ? 'exotics 0 (store missing)'
        : 'exotics $exo';
    return '$v  ·  ${_results.length}/$base  ·  $modeLabel  ·  '
        '$scopeLabel  ·  $inv copies  ·  $exoPart';
  }

  String _ownedChipLabel() {
    final defs = _bridge.ownedDefinitionCount;
    final hasLocal = _bridge.userId != null && _bridge.inventory.isNotEmpty;
    if (hasLocal || defs > 0) {
      return 'Owned · $defs';
    }
    if (!widget.services.oauthSession.isSignedIn) {
      return 'Owned · sign in';
    }
    return 'Owned · 0';
  }

  Widget _buildBody() {
    if (_loading) {
      return const CatalogLoadingSkeleton();
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load catalog.',
                key: const Key('catalog_error'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('catalog_error_retry'),
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final isWeapons = _mode == CatalogBrowseMode.weapons;
    final empty = isWeapons ? _families.isEmpty : _results.isEmpty;
    if (empty) {
      return _buildEmptyState();
    }
    final hasLocalOwned =
        _bridge.userId != null && _bridge.inventory.isNotEmpty;
    final showOwned =
        hasLocalOwned || widget.services.oauthSession.isSignedIn;

    if (isWeapons) {
      final useGroupHeaders = _groupBy.isNotEmpty;
      final fTree =
          useGroupHeaders ? _nestedFamilies() : const <CatalogFamilyGroupNode>[];
      if (useGroupHeaders) {
        _ensureGroupAnchors([
          for (final row in flattenAllFamilyGroupNodes(fTree)) row.node.key,
        ]);
      }
      // Outline when ≥2 top-level groups (same gate as flat).
      final showOutline = useGroupHeaders && fTree.length >= 2;
      final grid = CatalogWeaponsGrid(
        families: _families,
        selectedHash: _selected?.hash,
        selectedFamilyKey: _selectedFamily?.key,
        showOwned: showOwned,
        onSelectFamily: _selectFamily,
        familyLeadingBuilder: (family) => EntityIcon(
          key: Key('catalog_item_icon_${family.cardItem.hash}'),
          icon: family.cardItem.icon,
          size: 36,
        ),
        familyTree: useGroupHeaders ? fTree : null,
        groupDimensions: List<CatalogGroupDimension>.from(_groupBy),
        collapsedGroupKeys: Set<String>.from(_collapsedGroups),
        onToggleGroup: _toggleGroupCollapse,
        groupKeys: _groupAnchorKeys,
        onActiveGroupChanged: showOutline ? _onOutlineScrollSpy : null,
      );
      if (!showOutline) return grid;
      return Row(
        key: const Key('catalog_grid_with_outline'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: grid),
          CatalogGroupOutlineRail(
            groups: _outlineEntriesForFamilies(fTree),
            activeKey: _outlineActiveKey,
            onJump: _jumpToGroup,
          ),
        ],
      );
    }

    final useGroupHeaders = _groupBy.isNotEmpty;
    final iTree =
        useGroupHeaders ? _nestedResults() : const <CatalogGroupNode>[];
    if (useGroupHeaders) {
      _ensureGroupAnchors([
        for (final row in flattenAllCatalogGroupNodes(iTree)) row.node.key,
      ]);
    }
    final showOutline = useGroupHeaders && iTree.length >= 2;
    final grid = CatalogWeaponsGrid(
      items: _results,
      selectedHash: _selected?.hash,
      showOwned: showOwned,
      onSelect: _selectItem,
      leadingBuilder: (item) => EntityIcon(
        key: Key('catalog_item_icon_${item.hash}'),
        icon: item.icon,
        size: 36,
      ),
      itemTree: useGroupHeaders ? iTree : null,
      groupDimensions: List<CatalogGroupDimension>.from(_groupBy),
      collapsedGroupKeys: Set<String>.from(_collapsedGroups),
      onToggleGroup: _toggleGroupCollapse,
      groupKeys: _groupAnchorKeys,
      onActiveGroupChanged: showOutline ? _onOutlineScrollSpy : null,
    );
    if (!showOutline) return grid;
    return Row(
      key: const Key('catalog_grid_with_outline'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: grid),
        CatalogGroupOutlineRail(
          groups: _outlineEntriesForItems(iTree),
          activeKey: _outlineActiveKey,
          onJump: _jumpToGroup,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final message = _emptyMessage();
    final filterEmpty = _emptyReason == CatalogEmptyReason.none &&
        (_activeFilterCount() > 0 || _queryController.text.trim().isNotEmpty);
    final entityEmpty = _emptyReason == CatalogEmptyReason.noVersion ||
        _emptyReason == CatalogEmptyReason.noStores;
    final signedIn = widget.services.oauthSession.isSignedIn;
    final invEmpty =
        _scope == CatalogScope.owned && _bridge.inventory.isEmpty && !entityEmpty;

    final CatalogEmptyKind kind;
    if (entityEmpty) {
      kind = CatalogEmptyKind.missingManifest;
    } else if (_scope == CatalogScope.owned && !signedIn) {
      kind = CatalogEmptyKind.ownedSignedOut;
    } else if (invEmpty) {
      kind = CatalogEmptyKind.ownedEmpty;
    } else if (filterEmpty || _results.isEmpty) {
      kind = CatalogEmptyKind.zeroMatch;
    } else {
      kind = CatalogEmptyKind.generic;
    }

    return CatalogEmptyState(
      kind: kind,
      message: message,
      onClearFilters: filterEmpty || kind == CatalogEmptyKind.zeroMatch
          ? _clearAllFilters
          : null,
      onReload: entityEmpty || invEmpty ? _load : null,
      onSync: invEmpty && signedIn ? _syncInventory : null,
      onOpenSettings: widget.onOpenSettings,
    );
  }

  String _emptyMessage() {
    if (_emptyReason == CatalogEmptyReason.noVersion ||
        _emptyReason == CatalogEmptyReason.noStores) {
      if (_scope == CatalogScope.owned) {
        return 'Entity cache is empty or missing. Owned catalog joins inventory '
            'onto definitions — refresh the manifest/entity stores in Settings. '
            'Empty Owned is not solely an inventory sync problem.';
      }
      return switch (_emptyReason) {
        CatalogEmptyReason.noVersion =>
          'No entity cache version. Open Settings and refresh the manifest when an API key is configured.',
        CatalogEmptyReason.noStores =>
          'Entity stores are empty for this version. Rebuild entities from Settings refresh.',
        CatalogEmptyReason.none => 'No items match the current filters.',
      };
    }
    if (_scope == CatalogScope.owned) {
      if (_bridge.inventory.isEmpty) {
        return 'No owned items in local inventory. Sign in and use Settings → Sync now, then reload Catalog.';
      }
      return 'No owned definitions match the current filters.';
    }
    return 'No items match the current filters.';
  }

  Widget _buildDetailPanel() {
    final item = _selected!;

    // Weapons path: composition-aid detail with disabled Set/Synergy stubs.
    if (_mode == CatalogBrowseMode.weapons) {
      final defCols =
          widget.services.offlineCatalog.perkColumnsFor(item.hash);
      // Always include randomized hashes in the definition map so can-roll
      // merge can expand instance reusables; selected-only view still hides
      // them until the toggle is on (buildCatalogPerkColumns).
      final defSockets = defCols.isEmpty
          ? const <Map<String, Object?>>[]
          : weaponPerkColumnsToSocketPlugs(
              defCols,
              includeRandomized: true,
            );

      final family = _selectedFamily;
      final allowsRollTargets = !item.isExotic;
      final ranked = _rankedInstancesAndScores();
      final active = allowsRollTargets ? _activeRollTarget : null;
      final viewPreferred = !allowsRollTargets
          ? const <String, Set<int>>{}
          : (_editingRollTarget
              ? _expandColumnHashMap(_rollDraftPreferred)
              : _preferredMapFromTarget(active));
      final viewAvoid = !allowsRollTargets
          ? const <String, Set<int>>{}
          : (_editingRollTarget
              ? _expandColumnHashMap(_rollDraftAvoid)
              : _avoidMapFromTarget(active));
      final hasOverlap = catalogRollTargetHasOverlap(
        preferredByColumn: _rollDraftPreferred,
        avoidByColumn: _rollDraftAvoid,
      );
      final draftNameOk = _rollDraftName.trim().isNotEmpty;
      final canSave =
          allowsRollTargets && _editingRollTarget && draftNameOk && !hasOverlap;

      // Key by hash so detail AX nodes remount on weapon switch (Windows
      // accessibility_bridge thrashs when reparenting a large in-place tree).
      return CatalogWeaponDetail(
        key: ValueKey<String>('catalog_weapon_detail_${item.hash}'),
        item: item,
        instances: ranked.instances,
        selectedInstanceId: _selectedInstanceId,
        onSelectInstance: (inst) {
          setState(() => _selectedInstanceId = inst.instanceId);
        },
        showCanRoll: _showCanRoll || (_editingRollTarget && allowsRollTargets),
        showCraft: _showCraft,
        // craftAvailable must not use isCrafted alone when craftColumns empty
        // (false-positive toggle). Only show when host has real craft pool data.
        craftAvailable: false,
        craftColumns: const [],
        definitionSocketPlugs: defSockets,
        onCanRollChanged: (v) => setState(() => _showCanRoll = v),
        onCraftChanged: (v) => setState(() => _showCraft = v),
        plugNameByHash: _bridge.plugNameByHash,
        plugIconByHash: _bridge.plugIconByHash,
        plugEnhancedByHash: _bridge.plugEnhancedByHash,
        entityInfoByHash: _entityInfoByHashForDetail(),
        intrinsicName: item.isExotic ? item.intrinsicName : null,
        intrinsicDescription: item.isExotic
            ? (item.description ?? item.intrinsicName)
            : null,
        catalystName: item.isExotic ? item.catalystName : null,
        catalystDescription: item.isExotic ? item.catalystDescription : null,
        familyMembers: family?.members ?? const [],
        onSelectFamilyMember:
            family != null && family.members.length > 1
                ? _selectFamilyMember
                : null,
        // 003 roll targets — legendary only (DBR-IDL-009)
        rollTargets: [
          if (allowsRollTargets)
            for (final t in _rollTargets)
              CatalogRollTargetOption(id: t.id, name: t.name),
        ],
        activeRollTargetId: allowsRollTargets ? _activeRollTargetId : null,
        activeRollTargetName: allowsRollTargets ? active?.name : null,
        onActiveRollTargetChanged: allowsRollTargets
            ? (id) {
                _setActiveRollTarget(id);
              }
            : null,
        instanceRollScores:
            allowsRollTargets ? ranked.scores : const {},
        preserveInstanceOrder: allowsRollTargets && ranked.ranked,
        rankedByRollTarget: allowsRollTargets && ranked.ranked,
        editingRollTarget: allowsRollTargets && _editingRollTarget,
        onEditRollTarget: allowsRollTargets
            ? () => _beginEditRollTarget(creating: false)
            : null,
        onNewRollTarget: allowsRollTargets
            ? () => _beginEditRollTarget(creating: true)
            : null,
        onDeleteRollTarget: allowsRollTargets && _activeRollTargetId != null
            ? () {
                _deleteActiveRollTarget();
              }
            : null,
        canDeleteRollTarget:
            allowsRollTargets && _activeRollTargetId != null,
        rollTargetDraftName: _rollDraftName,
        onRollTargetDraftNameChanged: allowsRollTargets
            ? (v) => setState(() => _rollDraftName = v)
            : null,
        rollTargetHasOverlap: hasOverlap,
        onSaveRollTarget: canSave
            ? () {
                _saveRollTarget();
              }
            : null,
        onCancelRollTarget:
            allowsRollTargets ? _cancelEditRollTarget : null,
        canSaveRollTarget: canSave,
        preferredByColumn: viewPreferred,
        avoidByColumn: viewAvoid,
        onCycleRollPlug:
            allowsRollTargets && _editingRollTarget ? _cycleRollPlug : null,
        headerTrailing: _reverseTags.isEmpty
            ? null
            : Wrap(
                key: const Key('linked_synergy_badges'),
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final badge in _reverseTags)
                    Chip(
                      key: Key('synergy_badge_${badge.id}'),
                      label: Text(badge.name),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
      );
    }

    // Armor / Universal: retain richer dossier + universal live outbound.
    final kind = compositionKindFromCatalogItem(item);
    final actions = kind == null
        ? (set: false, synergy: false)
        : hitActions(kind);

    final palette = FlapPalette.of(context);
    final kindLabel = kind != null ? compositionKindLabel(kind) : null;
    final kickerParts = <String>[
      if (kindLabel != null) kindLabel,
      if (item.slot != null) item.slot!,
      if (item.isExotic) 'Exotic' else 'Common',
    ];
    final typeLine = [
      if (item.itemTypeName != null) item.itemTypeName!,
      if (item.frame != null && item.frame!.isNotEmpty) item.frame!,
      if (item.classType != null) item.classType!,
    ].join(' · ');

    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NeonDetailHeader(
            title: item.name,
            kicker: kickerParts.join(' · '),
            kickerKey: const Key('detail_kind_label'),
            subtitle: typeLine.isEmpty ? null : typeLine,
            pills: [
              if (item.element != null)
                NeonMetaPill(item.element!, tone: NeonPillTone.accent),
              if (item.isExotic)
                const NeonMetaPill('Exotic', tone: NeonPillTone.exotic)
              else
                const NeonMetaPill('Node'),
              if (item.owned)
                NeonMetaPill(
                  'Owned ×${item.ownedCount}',
                  tone: NeonPillTone.ok,
                ),
            ],
            actions: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_reverseTags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      key: const Key('linked_synergy_badges'),
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final badge in _reverseTags)
                          Chip(
                            key: Key('synergy_badge_${badge.id}'),
                            label: Text(badge.name),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                  ),
                if (_mode == CatalogBrowseMode.universal) ...[
                  Wrap(
                    key: const Key('universal_actions'),
                    spacing: 8,
                    children: [
                      if (actions.set)
                        FilledButton.tonal(
                          key: const Key('universal_create_set'),
                          onPressed: () => _createSetFromHit(item),
                          child: const Text('Create Set'),
                        ),
                      if (actions.synergy)
                        FilledButton.tonal(
                          key: const Key('universal_create_synergy'),
                          onPressed: () => _createSynergyFromHit(item),
                          child: const Text('Create Synergy'),
                        ),
                      if (!actions.set && !actions.synergy)
                        const Text(
                          'Visible in Universal search but not Set/Synergy attachable.',
                          key: Key('universal_no_actions'),
                        ),
                    ],
                  ),
                  const SizedBox.shrink(key: Key('no_build_kit_attach')),
                ],
                if (_actionMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _actionMessage!,
                      key: const Key('catalog_action_message'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                Text(
                  _instances.isEmpty
                      ? 'No local copies (wishlist / definition only — unpinned).'
                      : '${_instances.length} owned cop${_instances.length == 1 ? 'y' : 'ies'}',
                  key: const Key('instance_panel_count'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.muted,
                      ),
                ),
                if (_instances.isEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    key: const Key('detail_unpinned_actions'),
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        key: const Key('detail_copy_hash'),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: '${item.hash}'),
                          );
                          setState(() {
                            _actionMessage =
                                'Copied definition hash ${item.hash}';
                          });
                        },
                        icon: const Icon(Icons.tag, size: 16),
                        label: const Text('Copy hash'),
                      ),
                      if (actions.set)
                        FilledButton.tonal(
                          key: const Key('detail_create_set'),
                          onPressed: () => _createSetFromHit(item),
                          child: const Text('Create Set'),
                        ),
                      if (actions.synergy)
                        FilledButton.tonal(
                          key: const Key('detail_create_synergy'),
                          onPressed: () => _createSynergyFromHit(item),
                          child: const Text('Create Synergy'),
                        ),
                      if (!widget.services.oauthSession.isSignedIn)
                        Text(
                          'Sign in under Settings to resolve owned copies.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: palette.line),
          Expanded(
            child: ListView(
              key: const Key('instance_list'),
              padding: EdgeInsets.zero,
              children: [
                if (_instances.isEmpty) ...[
                  ItemRichnessPanel(
                    key: Key('item_richness_def_${item.hash}'),
                    definition: item,
                    kindLabel:
                        kind != null ? compositionKindLabel(kind) : null,
                    plugNameByHash: _bridge.plugNameByHash,
                    initialOpen: const {ItemRichnessSection.definition},
                    onCopyMessage: (msg) {
                      setState(() => _actionMessage = msg);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No instances',
                      key: const Key('instance_panel_empty'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: palette.muted,
                          ),
                    ),
                  ),
                ] else
                  for (var i = 0; i < _instances.length; i++)
                    _buildInstanceCard(
                      item,
                      _instances[i],
                      kind,
                      expandRoll: i == 0,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstanceCard(
    CatalogItem item,
    CatalogInstanceProjection inst,
    CompositionKind? kind, {
    required bool expandRoll,
  }) {
    return Container(
      key: Key('instance_${inst.instanceId}'),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: FlapPalette.of(context).line,
            width: kFlapRuleThickness,
          ),
        ),
      ),
      child: ItemRichnessPanel(
        key: Key('item_richness_inst_${inst.instanceId}'),
        definition: item,
        instance: inst,
        kindLabel: kind != null ? compositionKindLabel(kind) : null,
        plugNameByHash: _bridge.plugNameByHash,
        showHero: expandRoll,
        initialOpen: expandRoll
            ? {
                if (inst.armorStats != null && inst.armorStats!.hasAny)
                  ItemRichnessSection.stats,
                if (inst.plugCards.isNotEmpty ||
                    (inst.socketPlugs != null &&
                        inst.socketPlugs!.isNotEmpty))
                  ItemRichnessSection.perks,
              }
            : const <ItemRichnessSection>{},
        onCopyMessage: (msg) {
          setState(() => _actionMessage = msg);
        },
      ),
    );
  }
}
