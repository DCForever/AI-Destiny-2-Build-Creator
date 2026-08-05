import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Host-parity weapons filter bar: element · slot · type · exotic cycle · More ammo.
///
/// Exotic semantics match windows_host [CatalogPage]: null → only → exclude → null.
@widgetbook.UseCase(
  name: 'Weapons host parity · exotic cycle',
  type: CatalogFilterBar,
  path: '[Catalog]/FilterBar',
)
Widget filterBarHostParityExotic(BuildContext context) {
  return const FilterBarHostParity();
}

@widgetbook.UseCase(
  name: 'Weapons host parity · wide primary line',
  type: CatalogFilterBar,
  path: '[Catalog]/FilterBar',
)
Widget filterBarHostParityWide(BuildContext context) {
  return const SizedBox(
    width: 1100,
    child: FilterBarHostParity(),
  );
}

@widgetbook.UseCase(
  name: 'Exotic chip only · cycle labels',
  type: NeonExoticChip,
  path: '[Catalog]/FilterBar',
)
Widget exoticChipCycle(BuildContext context) {
  return const Center(child: _ExoticCycleDemo());
}

/// Public so viewport stories can reuse host-parity chrome without duplicating.
class FilterBarHostParity extends StatefulWidget {
  const FilterBarHostParity({super.key});

  @override
  State<FilterBarHostParity> createState() => _FilterBarHostParityState();
}

class _FilterBarHostParityState extends State<FilterBarHostParity> {

  late final TextEditingController _query;
  var _more = false;
  var _scope = CatalogScope.all;
  var _elements = const FacetFilter();
  var _slots = const FacetFilter();
  var _archetypes = const FacetFilter();
  var _ammos = const FacetFilter();
  bool? _exotic; // null any · true only · false exclude

  @override
  void initState() {
    super.initState();
    _query = TextEditingController();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  int get _activeCount {
    var n = 0;
    if (!isFacetEmpty(_elements)) n++;
    if (!isFacetEmpty(_slots)) n++;
    if (!isFacetEmpty(_archetypes)) n++;
    if (!isFacetEmpty(_ammos)) n++;
    if (_exotic != null) n++;
    if (_query.text.trim().isNotEmpty) n++;
    return n;
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
    });
  }

  void _reset() {
    setState(() {
      _query.clear();
      _elements = emptyFacet();
      _slots = emptyFacet();
      _archetypes = emptyFacet();
      _ammos = emptyFacet();
      _exotic = null;
      _scope = CatalogScope.all;
      _more = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bar = CatalogFilterBar(
      queryController: _query,
      onQueryChanged: (_) => setState(() {}),
      moreExpanded: _more,
      onToggleMore: () => setState(() => _more = !_more),
      onReset: _reset,
      activeFilterCount: _activeCount,
      leading: CatalogScopeControl(
        scope: _scope,
        ownedLabel: 'OWNED · 12',
        onChanged: (s) => setState(() => _scope = s),
      ),
      exotic: _exotic,
      onCycleExotic: _cycleExotic,
      primaryGroups: [
        CatalogFacetGroup(
          id: 'element',
          values: catalogElements,
          facet: _elements,
          iconOnly: true,
          onCycle: (v) => setState(
            () => _elements = cycleFacetValue(_elements, v),
          ),
        ),
        CatalogFacetGroup(
          id: 'slot',
          values: catalogSlotsForMode(CatalogBrowseMode.weapons),
          facet: _slots,
          iconOnly: true,
          onCycle: (v) =>
              setState(() => _slots = cycleFacetValue(_slots, v)),
        ),
        CatalogFacetGroup(
          id: 'archetype',
          values: catalogArchetypesForMode(CatalogBrowseMode.weapons),
          facet: _archetypes,
          iconOnly: true,
          onCycle: (v) => setState(
            () => _archetypes = cycleFacetValue(_archetypes, v),
          ),
        ),
      ],
      secondaryGroups: [
        CatalogFacetGroup(
          id: 'ammo',
          values: catalogAmmoTypes,
          facet: _ammos,
          iconOnly: true,
          onCycle: (v) =>
              setState(() => _ammos = cycleFacetValue(_ammos, v)),
        ),
      ],
    );

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(padding: const EdgeInsets.all(8), child: bar),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              key: const Key('wb_exotic_state_label'),
              'exotic=${_exotic == null ? 'any' : _exotic == true ? 'only' : 'exclude'}',
              style: neonMono(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExoticCycleDemo extends StatefulWidget {
  const _ExoticCycleDemo();

  @override
  State<_ExoticCycleDemo> createState() => _ExoticCycleDemoState();
}

class _ExoticCycleDemoState extends State<_ExoticCycleDemo> {
  bool? _exotic;

  void _cycle() {
    setState(() {
      if (_exotic == null) {
        _exotic = true;
      } else if (_exotic == true) {
        _exotic = false;
      } else {
        _exotic = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NeonExoticChip(exotic: _exotic, onCycle: _cycle),
        const SizedBox(height: 12),
        Text(
          key: const Key('wb_exotic_state_label'),
          'exotic=${_exotic == null ? 'any' : _exotic == true ? 'only' : 'exclude'}',
        ),
      ],
    );
  }
}
