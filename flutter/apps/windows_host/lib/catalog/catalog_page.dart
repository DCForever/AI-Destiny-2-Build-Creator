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

  /// Secondary facets (ammo, class, synergy) behind "More".
  /// Primary line (scope + free-text + element/slot/type icon chips) is always on.
  bool _moreFiltersExpanded = false;

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
        );
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

  List<CatalogGroup> _groupedResults() {
    return groupCatalogItems(
      _results,
      List<CatalogGroupDimension>.from(_groupBy),
    );
  }

  List<CatalogFamilyGroup> _groupedFamilies() {
    return groupWeaponFamilyBrowse(
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
  }

  Future<void> _selectItem(CatalogItem item) async {
    setState(() {
      _selected = item;
      _selectedFamily = null;
      _actionMessage = null;
      _showCanRoll = false;
      _showCraft = false;
      _selectedInstanceId = null;
      // Collapse secondary filters only — primary line stays visible.
      _moreFiltersExpanded = false;
    });
    await _syncSelection();
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
      _moreFiltersExpanded = false;
    });
    await _syncSelection();
  }

  Future<void> _selectFamilyMember(WeaponFamilyMember member) async {
    setState(() {
      _selected = member.item;
      // Keep sticky family; full identity rebind for perks/instances.
      _showCanRoll = false;
      _showCraft = false;
      _selectedInstanceId = null;
    });
    await _syncSelection();
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
      _applyBrowse();
    });
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
    setState(() {
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
      _applyBrowse();
    });
    _syncSelection();
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
              child: FilterChip(
                key: Key('group_chip_${dim.id.name}'),
                label: Text(dim.label),
                selected: _groupBy.contains(dim.id),
                onSelected: (_) => _toggleGroupDimension(dim.id),
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
          IconButton(
            key: const Key('catalog_reload'),
            tooltip: 'Sync catalog channel',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
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
      final fGroups = _groupedFamilies();
      final useGroupHeaders = _groupBy.isNotEmpty;
      // Ensure stable GlobalKeys for outline jump.
      if (useGroupHeaders) {
        for (final g in fGroups) {
          _groupAnchorKeys.putIfAbsent(g.key, GlobalKey.new);
        }
      }
      final showOutline = useGroupHeaders && fGroups.length >= 2;
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
        familyGroups: useGroupHeaders
            ? [
                for (final group in fGroups)
                  (
                    key: group.key,
                    label: group.label,
                    families: group.families,
                  ),
              ]
            : null,
        collapsedGroupKeys: Set<String>.from(_collapsedGroups),
        onToggleGroup: _toggleGroupCollapse,
        groupKeys: _groupAnchorKeys,
      );
      if (!showOutline) return grid;
      return Row(
        key: const Key('catalog_grid_with_outline'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: grid),
          CatalogGroupOutlineRail(
            groups: [
              for (final g in fGroups)
                (key: g.key, label: g.label, count: g.families.length),
            ],
            activeKey: _outlineActiveKey,
            onJump: _jumpToGroup,
          ),
        ],
      );
    }

    final groups = _groupedResults();
    final useGroupHeaders = _groupBy.isNotEmpty;
    if (useGroupHeaders) {
      for (final g in groups) {
        _groupAnchorKeys.putIfAbsent(g.key, GlobalKey.new);
      }
    }
    return CatalogWeaponsGrid(
      items: _results,
      selectedHash: _selected?.hash,
      showOwned: showOwned,
      onSelect: _selectItem,
      leadingBuilder: (item) => EntityIcon(
        key: Key('catalog_item_icon_${item.hash}'),
        icon: item.icon,
        size: 36,
      ),
      groups: useGroupHeaders
          ? [
              for (final group in groups)
                (
                  key: group.key,
                  label: group.label,
                  items: group.items,
                ),
            ]
          : null,
      collapsedGroupKeys: Set<String>.from(_collapsedGroups),
      onToggleGroup: _toggleGroupCollapse,
      groupKeys: _groupAnchorKeys,
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
      return CatalogWeaponDetail(
        item: item,
        instances: _instances,
        selectedInstanceId: _selectedInstanceId,
        onSelectInstance: (inst) {
          setState(() => _selectedInstanceId = inst.instanceId);
        },
        showCanRoll: _showCanRoll,
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
