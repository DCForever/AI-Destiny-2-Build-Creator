import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:flutter/material.dart';

import '../host_bootstrap.dart';
import 'owned_catalog_bridge.dart';

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
    final instances = _bridge.instancesFor(sel.hash, treatAsArmor: treatArmor);
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
                label: Text(labelOf?.call(value) ?? value),
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
                  label: const Text('Owned'),
                  selected: _scope == CatalogScope.owned,
                  onSelected: (_) => _setScope(CatalogScope.owned),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              key: const Key('catalog_filters_scroll'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  if (catalogShowsElementFacet(_mode))
                    _facetChipRow(
                      keyPrefix: 'element',
                      values: catalogElements,
                      facet: _elements,
                      onCycle: _cycleElement,
                    ),
                  if (catalogShowsAmmoFacet(_mode)) ...[
                    const SizedBox(height: 4),
                    _facetChipRow(
                      keyPrefix: 'ammo',
                      values: catalogAmmoTypes,
                      facet: _ammos,
                      onCycle: _cycleAmmo,
                    ),
                  ],
                  const SizedBox(height: 4),
                  _facetChipRow(
                    keyPrefix: 'slot',
                    values: catalogSlotsForMode(_mode),
                    facet: _slots,
                    onCycle: _cycleSlot,
                  ),
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
                  if (_bridge.synergyMembership.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Synergy membership',
                        key: const Key('synergy_filter_label'),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    _facetChipRow(
                      keyPrefix: 'synergy',
                      values: _bridge.synergyMembership.map((s) => s.id).toList(),
                      facet: _synergies,
                      onCycle: _cycleSynergy,
                      labelOf: (id) => _bridge.synergyNames[id] ?? id,
                    ),
                  ],
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

  String _statusLine() {
    if (_loading) return 'Loading entity stores…';
    if (_error != null) return 'Error: $_error';
    final v = _version ?? 'none';
    final base = _bridge.annotatedBase.length;
    final inv = _bridge.inventory.length;
    final scopeLabel = _scope == CatalogScope.owned ? 'owned' : 'all';
    final modeLabel = browseModeLabel(_mode);
    return 'Version $v · ${_results.length} shown / $base base · '
        'mode=$modeLabel · scope=$scopeLabel · inventory=$inv copies';
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
          if (item.linkedSynergyIds.isNotEmpty)
            'syn×${item.linkedSynergyIds.length}',
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
          if (kind != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                compositionKindLabel(kind),
                key: const Key('detail_kind_label'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          // BR-SYN-004 reverse tags
          if (_reverseTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
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
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ),
          // Universal composition actions (Set / Synergy only — never Build attach)
          if (_mode == CatalogBrowseMode.universal) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Wrap(
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
            ),
            // Explicitly never show Build kit attach (GAP-UI-CATALOG-03).
            const SizedBox.shrink(key: Key('no_build_kit_attach')),
          ],
          if (_actionMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _actionMessage!,
                key: const Key('catalog_action_message'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _instances.isEmpty
                  ? 'No local copies (wishlist / definition only — unpinned).'
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
                      return _buildInstanceCard(inst);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstanceCard(CatalogInstanceProjection inst) {
    final flags = [
      if (inst.isMasterwork) 'MW',
      if (inst.isCrafted) 'Crafted',
      if (inst.gearTier != null) 'T${inst.gearTier}',
    ].join(' · ');
    final loc = inst.characterId != null
        ? '${inst.location} (${inst.characterId})'
        : inst.location;

    return Card(
      key: Key('instance_${inst.instanceId}'),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Power ${inst.power}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              [inst.instanceId, loc, inst.bucket, if (flags.isNotEmpty) flags]
                  .join(' · '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (inst.rollTags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Tags: ${inst.rollTags.join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (inst.armorStats != null && inst.armorStats!.hasAny) ...[
              const SizedBox(height: 8),
              Text(
                'Base stats',
                key: Key('armor_stats_label_${inst.instanceId}'),
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Wrap(
                key: Key('armor_stats_board_${inst.instanceId}'),
                spacing: 8,
                children: [
                  for (final key in armorBaseStatKeys)
                    if (inst.armorStats!.stats[key] != null)
                      Chip(
                        label: Text('$key ${inst.armorStats!.stats[key]}'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  if (inst.armorStats!.total != null)
                    Chip(
                      label: Text('Total ${inst.armorStats!.total}'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
            if (inst.plugCards.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Perks / plugs',
                key: Key('plug_cards_label_${inst.instanceId}'),
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Wrap(
                key: Key('plug_cards_${inst.instanceId}'),
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final card in inst.plugCards)
                    Chip(
                      key: Key('plug_card_${inst.instanceId}_${card.hash}'),
                      label: Text(
                        card.isTrait
                            ? 'Trait: ${card.displayName}'
                            : card.displayName,
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ] else if (inst.plugHashes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'plugs:${inst.plugHashes.length} (names unresolved)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
