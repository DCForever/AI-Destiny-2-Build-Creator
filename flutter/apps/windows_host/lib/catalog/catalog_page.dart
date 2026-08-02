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
import '../widgets/item_richness.dart';
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
  });

  final AppServices services;

  /// Optional injectable bridge (tests). When null, constructed from [services].
  final OwnedCatalogBridge? bridge;

  /// When this value changes (e.g. user returns to Catalog after Settings sync),
  /// reloads entity stores + inventory. IndexedStack keeps this page alive.
  final int reloadToken;

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
  List<CatalogInstanceProjection> _instances = const [];
  List<LinkedSynergyBadge> _reverseTags = const [];
  String? _actionMessage;

  /// Facet / group chrome collapsed by default (P0 — reduce chrome explosion).
  bool _filtersExpanded = false;

  /// Secondary facets (ammo, archetype, class, group) behind "More".
  bool _moreFiltersExpanded = false;

  OwnedCatalogBridge _createBridge() {
    return widget.bridge ??
        OwnedCatalogBridge(
          db: widget.services.db,
          offlineCatalog: widget.services.offlineCatalog,
          session: widget.services.oauthSession,
          inventorySync: widget.services.inventorySync,
        );
  }

  @override
  void initState() {
    super.initState();
    _bridge = _createBridge();
    _load();
  }

  @override
  void didUpdateWidget(covariant CatalogPage oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.services.oauthSession.isSignedIn) {
        await widget.services.inventorySync.refreshStatus();
      }
      await _bridge.refresh(reloadEntities: true);
      final load = widget.services.offlineCatalog.lastLoad;
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = load?.error;
        _emptyReason = load?.emptyReason ?? CatalogEmptyReason.none;
        _version = load?.version;
        _results = _applyFilters();
      });
      await _syncSelection();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
        _results = const [];
        _instances = const [];
        _reverseTags = const [];
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

  List<CatalogItem> _applyFilters() {
    return _bridge.browse(_filters(), mode: _mode);
  }

  List<CatalogGroup> _groupedResults() {
    return groupCatalogItems(_results, List<CatalogGroupDimension>.from(_groupBy));
  }

  void _refilter() {
    setState(() {
      _results = _applyFilters();
    });
    _syncSelection();
  }

  Future<void> _syncSelection() async {
    final sel = _selected;
    if (sel == null) {
      if (!mounted) return;
      setState(() {
        _instances = const [];
        _reverseTags = const [];
      });
      return;
    }
    final stillVisible = _results.any((i) => i.hash == sel.hash);
    if (!stillVisible) {
      if (!mounted) return;
      setState(() {
        _selected = null;
        _instances = const [];
        _reverseTags = const [];
      });
      return;
    }
    final treatArmor = _mode == CatalogBrowseMode.armor ||
        compositionKindFromCatalogItem(sel) == CompositionKind.armor ||
        compositionKindFromCatalogItem(sel) == CompositionKind.exoticArmor;
    // Next parity: resolve plug names before projecting instance cards.
    final instances = await _bridge.instancesForResolved(
      sel.hash,
      treatAsArmor: treatArmor,
    );
    final tags = await _bridge.reverseTagsFor(sel);
    if (!mounted) return;
    setState(() {
      _instances = instances;
      _reverseTags = tags;
    });
  }

  Future<void> _selectItem(CatalogItem item) async {
    setState(() {
      _selected = item;
      _actionMessage = null;
      // BUG-20260726-005: reclaim vertical space for board + detail.
      _filtersExpanded = false;
      _moreFiltersExpanded = false;
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
      _results = _applyFilters();
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
    });
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
      _results = _applyFilters();
    });
    _syncSelection();
  }

  String _exoticLabel() {
    if (_exotic == true) return 'Exotic only';
    if (_exotic == false) return 'No exotic';
    return 'Exotic: any';
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
      _elements = emptyFacet();
      _ammos = emptyFacet();
      _slots = emptyFacet();
      _classNames = emptyFacet();
      _archetypes = emptyFacet();
      _synergies = emptyFacet();
      _exotic = null;
      _groupBy.clear();
      _results = _applyFilters();
    });
    _syncSelection();
  }

  String _filtersSummaryLabel() {
    final n = _activeFilterCount();
    if (n == 0) return 'Filters · none active';
    return 'Filters · $n active';
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
        _results = _applyFilters();
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

  Widget _facetChipRow({
    required String keyPrefix,
    required List<String> values,
    required FacetFilter facet,
    required void Function(String) onCycle,
    String Function(String)? labelOf,
  }) {
    final palette = FlapPalette.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final value in values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Builder(
                builder: (context) {
                  final state = facetChipState(facet, value);
                  final selected = state != FacetChipState.off;
                  final exclude = state == FacetChipState.exclude;
                  final label = labelOf?.call(value) ?? value;
                  return FilterChip(
                    key: Key('${keyPrefix}_chip_$value'),
                    label: Text(
                      label,
                      style: TextStyle(
                        decoration:
                            exclude ? TextDecoration.lineThrough : null,
                        color: exclude ? palette.danger : null,
                      ),
                    ),
                    selected: selected,
                    selectedColor: exclude
                        ? palette.danger.withValues(alpha: 0.12)
                        : palette.accentDim,
                    onSelected: (_) => onCycle(value),
                    avatar: _facetAvatar(state),
                    tooltip: exclude
                        ? 'Exclude $label (tap to cycle)'
                        : selected
                            ? 'Include $label (tap to cycle)'
                            : 'Filter $label (tap include → exclude → off)',
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Catalog'),
        actions: [
          IconButton(
            key: const Key('catalog_reload'),
            tooltip: 'Reload from entity stores + inventory',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              key: const Key('catalog_query'),
              controller: _queryController,
              decoration: const InputDecoration(
                labelText: 'Search',
                hintText: 'Name, type, element…',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => _refilter(),
            ),
          ),
          // Kind modes: Weapons | Armor | Universal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              key: const Key('catalog_mode_row'),
              children: [
                for (final mode in CatalogBrowseMode.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      key: Key('mode_chip_${mode.name}'),
                      label: Text(browseModeLabel(mode)),
                      selected: _mode == mode,
                      onSelected: (_) => _setMode(mode),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                FilterChip(
                  key: const Key('scope_chip_all'),
                  label: const Text('All'),
                  selected: _scope == CatalogScope.all,
                  onSelected: (_) => _setScope(CatalogScope.all),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  key: const Key('scope_chip_owned'),
                  label: Text(_ownedChipLabel()),
                  selected: _scope == CatalogScope.owned,
                  onSelected: (_) => _setScope(CatalogScope.owned),
                ),
                const Spacer(),
                if (_activeFilterCount() > 0)
                  TextButton(
                    key: const Key('catalog_clear_filters'),
                    onPressed: _clearAllFilters,
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
          ),
          // Progressive disclosure: facets/group behind toggle (P0).
          ListTile(
            key: const Key('catalog_filters_toggle'),
            dense: true,
            title: Text(
              _filtersSummaryLabel(),
              key: const Key('catalog_filters_summary'),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            subtitle: _filtersExpanded
                ? null
                : Text(
                    'Element, slot, archetype, exotic, group…',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
            trailing: Icon(
              _filtersExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: () {
              setState(() => _filtersExpanded = !_filtersExpanded);
            },
          ),
          if (_filtersExpanded)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: _moreFiltersExpanded ? 260 : 140,
              ),
              child: SingleChildScrollView(
                key: const Key('catalog_filters_scroll'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Primary strip only (BUG-20260726-001).
                    if (catalogShowsElementFacet(_mode))
                      _facetChipRow(
                        keyPrefix: 'element',
                        values: catalogElements,
                        facet: _elements,
                        onCycle: _cycleElement,
                      ),
                    const SizedBox(height: 4),
                    _facetChipRow(
                      keyPrefix: 'slot',
                      values: catalogSlotsForMode(_mode),
                      facet: _slots,
                      onCycle: _cycleSlot,
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FilterChip(
                          key: const Key('exotic_chip'),
                          label: Text(_exoticLabel()),
                          selected: _exotic != null,
                          onSelected: (_) => _cycleExotic(),
                        ),
                      ),
                    ),
                    ListTile(
                      key: const Key('catalog_more_filters_toggle'),
                      dense: true,
                      title: Text(
                        _moreFiltersExpanded
                            ? 'Less filters'
                            : 'More filters (ammo, type, group…)',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      trailing: Icon(
                        _moreFiltersExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                      ),
                      onTap: () {
                        setState(
                          () => _moreFiltersExpanded = !_moreFiltersExpanded,
                        );
                      },
                    ),
                    if (_moreFiltersExpanded) ...[
                      if (catalogShowsAmmoFacet(_mode)) ...[
                        const SizedBox(height: 4),
                        _facetChipRow(
                          keyPrefix: 'ammo',
                          values: catalogAmmoTypes,
                          facet: _ammos,
                          onCycle: _cycleAmmo,
                        ),
                      ],
                      if (catalogShowsClassFacet(_mode)) ...[
                        const SizedBox(height: 4),
                        _facetChipRow(
                          keyPrefix: 'class',
                          values: catalogClassNames,
                          facet: _classNames,
                          onCycle: _cycleClass,
                        ),
                      ],
                      const SizedBox(height: 4),
                      _facetChipRow(
                        keyPrefix: 'archetype',
                        values: catalogArchetypesForMode(_mode),
                        facet: _archetypes,
                        onCycle: _cycleArchetype,
                      ),
                      if (_bridge.synergyMembership.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Synergy membership',
                            key: const Key('synergy_filter_label'),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        _facetChipRow(
                          keyPrefix: 'synergy',
                          values: _bridge.synergyMembership
                              .map((s) => s.id)
                              .toList(),
                          facet: _synergies,
                          onCycle: _cycleSynergy,
                          labelOf: (id) =>
                              _bridge.synergyNames[id] ?? 'Synergy',
                        ),
                      ],
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          key: const Key('catalog_group_by'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(
                                'Group results',
                                style:
                                    Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                            for (final dim in catalogGroupDimensions)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: FilterChip(
                                  key: Key('group_chip_${dim.id.name}'),
                                  label: Text(dim.label),
                                  selected: _groupBy.contains(dim.id),
                                  onSelected: (_) =>
                                      _toggleGroupDimension(dim.id),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Tooltip(
              message: _version ?? 'No manifest version',
              child: Text(
                _statusLine(),
                key: const Key('catalog_status'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontFamily: kFontMono,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: FlapPalette.of(context).muted,
                    ),
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: _buildBody()),
                if (_selected != null)
                  Expanded(
                    flex: 2,
                    child: _buildDetailPanel(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _facetAvatar(FacetChipState state) {
    switch (state) {
      case FacetChipState.include:
        return const Icon(Icons.add, size: 16);
      case FacetChipState.exclude:
        return const Icon(Icons.remove, size: 16);
      case FacetChipState.off:
        return null;
    }
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

  String _statusLine() {
    if (_loading) return 'Loading entity stores…';
    if (_error != null) return 'Load failed — use Reload or check Settings';
    final v = _shortVersion(_version);
    final base = _bridge.annotatedBase.length;
    final inv = _bridge.inventory.length;
    final scopeLabel = _scope == CatalogScope.owned ? 'OWNED' : 'ALL';
    final modeLabel = browseModeLabel(_mode).toUpperCase();
    return '$v  ·  ${_results.length}/$base  ·  $modeLabel  ·  '
        '$scopeLabel  ·  $inv copies';
  }

  String _ownedChipLabel() {
    if (!widget.services.oauthSession.isSignedIn) {
      return 'Owned · sign in';
    }
    final n = _bridge.inventory.length;
    if (n == 0) return 'Owned · 0';
    return 'Owned · ${_bridge.ownedDefinitionCount}';
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(key: Key('catalog_loading')),
      );
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
    if (_results.isEmpty) {
      return _buildEmptyState();
    }
    final groups = _groupedResults();
    final rows = <Widget>[
      // Keep key for board-era tests; chrome is Neon construct kicker.
      Padding(
        key: const Key('catalog_board_header'),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: Text(
          'CATALOG NODES',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: FlapPalette.of(context).muted,
              ),
        ),
      ),
    ];
    for (final group in groups) {
      if (_groupBy.isNotEmpty || groups.length > 1) {
        rows.add(
          Padding(
            key: Key('catalog_group_${group.key}'),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Text(
              '${group.label} (${group.items.length})'.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        );
      }
      for (final item in group.items) {
        final selected = _selected?.hash == item.hash;
        final typeParts = <String>[
          if (item.itemTypeName != null) item.itemTypeName!,
          if (item.frame != null && item.frame!.isNotEmpty) item.frame!,
          if (item.classType != null) item.classType!,
          if (item.linkedSynergyIds.isNotEmpty)
            '${item.linkedSynergyIds.length} syn',
        ];
        final ownedLabel = item.owned ? '×${item.ownedCount}' : null;
        final identityLine = [
          if (item.element != null) item.element!,
          if (item.slot != null) item.slot!,
          if (item.isExotic) 'Exotic',
        ].join(' · ');
        final typeLine = [
          if (identityLine.isNotEmpty) identityLine,
          ...typeParts,
        ].join(' · ');
        rows.add(
          Padding(
            key: Key('catalog_item_${item.hash}'),
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
            child: NeonItemCard(
              name: item.name,
              slot: item.slot,
              element: item.element,
              typeLine: typeLine.isEmpty ? null : typeLine,
              rarity: neonItemRarity(isExotic: item.isExotic),
              ownedLabel: ownedLabel,
              selected: selected,
              onTap: () => _selectItem(item),
              nameKey: Key('catalog_item_name_${item.hash}'),
              metaKey: Key('catalog_item_meta_${item.hash}'),
              ownedKey:
                  item.owned ? Key('owned_badge_${item.hash}') : null,
              leading: EntityIcon(
                key: Key('catalog_item_icon_${item.hash}'),
                icon: item.icon,
                size: 36,
              ),
            ),
          ),
        );
      }
    }
    return ListView(
      key: const Key('catalog_list'),
      children: rows,
    );
  }

  Widget _buildEmptyState() {
    final message = _emptyMessage();
    final filterEmpty = _emptyReason == CatalogEmptyReason.none &&
        _activeFilterCount() > 0;
    final entityEmpty = _emptyReason == CatalogEmptyReason.noVersion ||
        _emptyReason == CatalogEmptyReason.noStores;
    final invEmpty =
        _scope == CatalogScope.owned && _bridge.inventory.isEmpty && !entityEmpty;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                key: const Key('catalog_empty'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (filterEmpty)
                    FilledButton(
                      key: const Key('catalog_empty_clear_filters'),
                      onPressed: _clearAllFilters,
                      child: const Text('Clear filters'),
                    ),
                  if (entityEmpty || invEmpty)
                    FilledButton.tonal(
                      key: const Key('catalog_empty_reload'),
                      onPressed: _load,
                      child: const Text('Reload catalog'),
                    ),
                  if (entityEmpty)
                    Text(
                      key: const Key('catalog_empty_settings_hint'),
                      'Then open Settings → Refresh manifest',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  if (invEmpty)
                    Text(
                      key: const Key('catalog_empty_sync_hint'),
                      'Sign in and Settings → Sync inventory if needed',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
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
                // BR-SYN-004 reverse tags
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
                // Universal composition actions (Set / Synergy only — never Build attach)
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
                // Single dossier: definition-only when unpinned; one card per
                // owned copy otherwise (avoid stacking N full definition clones).
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
                      // First copy expanded (scan); rest collapsed for density.
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
        // Hero only on the expanded lead copy — avoid N diamond stacks.
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
