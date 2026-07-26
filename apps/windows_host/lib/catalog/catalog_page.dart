import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:flutter/material.dart';

import '../host_bootstrap.dart';
import 'owned_catalog_bridge.dart';

/// Catalog browse with offline entities + all/owned + instance projections (DART-026).
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

  final _queryController = TextEditingController();
  FacetFilter _elements = emptyFacet();
  FacetFilter _ammos = emptyFacet();
  FacetFilter _slots = emptyFacet();
  FacetFilter _classNames = emptyFacet();
  FacetFilter _archetypes = emptyFacet();
  bool? _exotic; // null = off, true = only, false = exclude
  final List<CatalogGroupDimension> _groupBy = [];

  CatalogItem? _selected;
  List<CatalogInstanceProjection> _instances = const [];

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
      // Refresh sync meta user id when signed in (no network).
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
        _syncSelection();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
        _results = const [];
        _instances = const [];
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
      scope: _scope,
    );
  }

  List<CatalogItem> _applyFilters() {
    return _bridge.browse(_filters());
  }

  List<CatalogGroup> _groupedResults() {
    return groupCatalogItems(_results, List<CatalogGroupDimension>.from(_groupBy));
  }

  void _refilter() {
    setState(() {
      _results = _applyFilters();
      _syncSelection();
    });
  }

  void _syncSelection() {
    final sel = _selected;
    if (sel == null) {
      _instances = const [];
      return;
    }
    final stillVisible = _results.any((i) => i.hash == sel.hash);
    if (!stillVisible) {
      _selected = null;
      _instances = const [];
      return;
    }
    _instances = _bridge.instancesFor(sel.hash);
  }

  void _selectItem(CatalogItem item) {
    setState(() {
      _selected = item;
      _instances = _bridge.instancesFor(item.hash);
    });
  }

  void _setScope(CatalogScope scope) {
    if (_scope == scope) return;
    setState(() {
      _scope = scope;
      _results = _applyFilters();
      _syncSelection();
    });
  }

  void _cycleElement(String value) {
    setState(() {
      _elements = cycleFacetValue(_elements, value);
      _results = _applyFilters();
      _syncSelection();
    });
  }

  void _cycleAmmo(String value) {
    setState(() {
      _ammos = cycleFacetValue(_ammos, value);
      _results = _applyFilters();
      _syncSelection();
    });
  }

  void _cycleSlot(String value) {
    setState(() {
      _slots = cycleFacetValue(_slots, value);
      _results = _applyFilters();
      _syncSelection();
    });
  }

  void _cycleClass(String value) {
    setState(() {
      _classNames = cycleFacetValue(_classNames, value);
      _results = _applyFilters();
      _syncSelection();
    });
  }

  void _cycleArchetype(String value) {
    setState(() {
      _archetypes = cycleFacetValue(_archetypes, value);
      _results = _applyFilters();
      _syncSelection();
    });
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
      // off → only exotic → exclude exotic → off
      if (_exotic == null) {
        _exotic = true;
      } else if (_exotic == true) {
        _exotic = false;
      } else {
        _exotic = null;
      }
      _results = _applyFilters();
      _syncSelection();
    });
  }

  String _exoticLabel() {
    if (_exotic == true) return 'Exotic only';
    if (_exotic == false) return 'No exotic';
    return 'Exotic: any';
  }

  Widget _facetChipRow({
    required String keyPrefix,
    required List<String> values,
    required FacetFilter facet,
    required void Function(String) onCycle,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final value in values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                key: Key('${keyPrefix}_chip_$value'),
                label: Text(value),
                selected: facetChipState(facet, value) != FacetChipState.off,
                onSelected: (_) => onCycle(value),
                avatar: _facetAvatar(facetChipState(facet, value)),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  label: const Text('Owned'),
                  selected: _scope == CatalogScope.owned,
                  onSelected: (_) => _setScope(CatalogScope.owned),
                ),
              ],
            ),
          ),
          // Cap filter chrome height so results remain visible (DAC browse density).
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 168),
            child: SingleChildScrollView(
              key: const Key('catalog_filters_scroll'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  _facetChipRow(
                    keyPrefix: 'element',
                    values: catalogElements,
                    facet: _elements,
                    onCycle: _cycleElement,
                  ),
                  const SizedBox(height: 4),
                  _facetChipRow(
                    keyPrefix: 'ammo',
                    values: catalogAmmoTypes,
                    facet: _ammos,
                    onCycle: _cycleAmmo,
                  ),
                  const SizedBox(height: 4),
                  _facetChipRow(
                    keyPrefix: 'slot',
                    values: [...catalogWeaponSlots, ...catalogArmorSlots],
                    facet: _slots,
                    onCycle: _cycleSlot,
                  ),
                  const SizedBox(height: 4),
                  _facetChipRow(
                    keyPrefix: 'class',
                    values: catalogClassNames,
                    facet: _classNames,
                    onCycle: _cycleClass,
                  ),
                  const SizedBox(height: 4),
                  _facetChipRow(
                    keyPrefix: 'archetype',
                    values: [
                      ...catalogWeaponArchetypes,
                      ...catalogArmorArchetypes,
                    ],
                    facet: _archetypes,
                    onCycle: _cycleArchetype,
                  ),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            key: const Key('exotic_chip'),
                            label: Text(_exoticLabel()),
                            selected: _exotic != null,
                            onSelected: (_) => _cycleExotic(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      key: const Key('catalog_group_by'),
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('Group:'),
                        ),
                        for (final dim in catalogGroupDimensions)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
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
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              _statusLine(),
              key: const Key('catalog_status'),
              style: Theme.of(context).textTheme.bodySmall,
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
                    child: _buildInstancePanel(),
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

  String _statusLine() {
    if (_loading) return 'Loading entity stores…';
    if (_error != null) return 'Error: $_error';
    final v = _version ?? 'none';
    final base = _bridge.annotatedBase.length;
    final inv = _bridge.inventory.length;
    final scopeLabel = _scope == CatalogScope.owned ? 'owned' : 'all';
    return 'Version $v · ${_results.length} shown / $base base · '
        'scope=$scopeLabel · inventory=$inv copies';
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
          child: Text(
            'Failed to load catalog:\n$_error',
            key: const Key('catalog_error'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      final message = _emptyMessage();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            key: const Key('catalog_empty'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final groups = _groupedResults();
    final rows = <Widget>[];
    for (final group in groups) {
      if (_groupBy.isNotEmpty || groups.length > 1) {
        rows.add(
          ListTile(
            key: Key('catalog_group_${group.key}'),
            dense: true,
            title: Text(
              '${group.label} (${group.items.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        );
      }
      for (final item in group.items) {
        final subtitle = [
          if (item.slot != null) item.slot!,
          if (item.element != null) item.element!,
          if (item.ammo != null) item.ammo!,
          if (item.itemTypeName != null) item.itemTypeName!,
          if (item.classType != null) item.classType!,
          if (item.isExotic) 'Exotic',
          if (item.owned) 'Owned ×${item.ownedCount}',
        ].join(' · ');
        final selected = _selected?.hash == item.hash;
        rows.add(
          ListTile(
            key: Key('catalog_item_${item.hash}'),
            title: Text(item.name),
            subtitle: Text(subtitle),
            dense: true,
            selected: selected,
            trailing: item.owned
                ? Chip(
                    key: Key('owned_badge_${item.hash}'),
                    label: Text('×${item.ownedCount}'),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )
                : null,
            onTap: () => _selectItem(item),
          ),
        );
      }
    }
    return ListView(
      key: const Key('catalog_list'),
      children: rows,
    );
  }

  String _emptyMessage() {
    // GAP-INV-06 / DART-053: empty entity cache ≠ empty vault / sync-only failure.
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

  Widget _buildInstancePanel() {
    final item = _selected!;
    return Material(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Text(
              item.name,
              key: const Key('instance_panel_title'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _instances.isEmpty
                  ? 'No local copies (wishlist / definition only).'
                  : '${_instances.length} owned cop${_instances.length == 1 ? 'y' : 'ies'}',
              key: const Key('instance_panel_count'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const Divider(),
          Expanded(
            child: _instances.isEmpty
                ? const Center(
                    child: Text(
                      'No instances',
                      key: Key('instance_panel_empty'),
                    ),
                  )
                : ListView.builder(
                    key: const Key('instance_list'),
                    itemCount: _instances.length,
                    itemBuilder: (context, index) {
                      final inst = _instances[index];
                      final flags = [
                        if (inst.isMasterwork) 'MW',
                        if (inst.isCrafted) 'Crafted',
                      ].join(' · ');
                      final loc = inst.characterId != null
                          ? '${inst.location} (${inst.characterId})'
                          : inst.location;
                      return ListTile(
                        key: Key('instance_${inst.instanceId}'),
                        dense: true,
                        title: Text('Power ${inst.power}'),
                        subtitle: Text(
                          [
                            inst.instanceId,
                            loc,
                            inst.bucket,
                            if (flags.isNotEmpty) flags,
                            if (inst.plugHashes.isNotEmpty)
                              'plugs:${inst.plugHashes.length}',
                          ].join(' · '),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
