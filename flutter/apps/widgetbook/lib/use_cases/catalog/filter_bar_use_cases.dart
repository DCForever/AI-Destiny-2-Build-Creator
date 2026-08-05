import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Primary-line weapon-type silhouette filters (GAP-CAT-BROWSE-004).
@widgetbook.UseCase(
  name: 'Type icon filters · scope · search',
  type: CatalogFilterBar,
  path: '[Catalog]/FilterBar',
)
Widget filterBarTypeIcons(BuildContext context) {
  return const _FilterBarDemo(initialMore: false);
}

@widgetbook.UseCase(
  name: 'More expanded (secondary facets)',
  type: CatalogFilterBar,
  path: '[Catalog]/FilterBar',
)
Widget filterBarMoreExpanded(BuildContext context) {
  return const _FilterBarDemo(initialMore: true);
}

@widgetbook.UseCase(
  name: 'Narrow width wrap',
  type: CatalogFilterBar,
  path: '[Catalog]/FilterBar',
)
Widget filterBarNarrow(BuildContext context) {
  return const SizedBox(
    width: 420,
    child: _FilterBarDemo(initialMore: false),
  );
}

class _FilterBarDemo extends StatefulWidget {
  const _FilterBarDemo({required this.initialMore});

  final bool initialMore;

  @override
  State<_FilterBarDemo> createState() => _FilterBarDemoState();
}

class _FilterBarDemoState extends State<_FilterBarDemo> {
  late final TextEditingController _query;
  late bool _more;
  var _scope = CatalogScope.all;
  var _element = const FacetFilter();
  var _slot = const FacetFilter();
  var _type = const FacetFilter();
  var _ammo = const FacetFilter();
  bool? _exotic; // null off, true include, false exclude-ish cycle

  static const _types = [
    'Hand Cannon',
    'Auto Rifle',
    'Pulse Rifle',
    'Scout Rifle',
    'Trace Rifle',
    'Combat Bow',
    'Shotgun',
    'Sniper Rifle',
  ];

  @override
  void initState() {
    super.initState();
    _query = TextEditingController();
    _more = widget.initialMore;
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  int get _activeCount {
    var n = facetActiveCount(_element) +
        facetActiveCount(_slot) +
        facetActiveCount(_type) +
        facetActiveCount(_ammo);
    if (_exotic != null) n++;
    if (_query.text.trim().isNotEmpty) n++;
    return n;
  }

  void _reset() {
    setState(() {
      _query.clear();
      _element = const FacetFilter();
      _slot = const FacetFilter();
      _type = const FacetFilter();
      _ammo = const FacetFilter();
      _exotic = null;
      _scope = CatalogScope.all;
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: CatalogFilterBar(
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
                values: const ['Solar', 'Void', 'Arc', 'Stasis', 'Strand'],
                facet: _element,
                iconOnly: true,
                onCycle: (v) => setState(
                  () => _element = cycleFacetValue(_element, v),
                ),
              ),
              CatalogFacetGroup(
                id: 'slot',
                values: const ['Kinetic', 'Energy', 'Power'],
                facet: _slot,
                iconOnly: true,
                onCycle: (v) =>
                    setState(() => _slot = cycleFacetValue(_slot, v)),
              ),
              CatalogFacetGroup(
                id: 'type',
                values: _types,
                facet: _type,
                iconOnly: true,
                onCycle: (v) =>
                    setState(() => _type = cycleFacetValue(_type, v)),
              ),
            ],
            secondaryGroups: [
              CatalogFacetGroup(
                id: 'ammo',
                values: const ['Primary', 'Special', 'Heavy'],
                facet: _ammo,
                iconOnly: true,
                onCycle: (v) =>
                    setState(() => _ammo = cycleFacetValue(_ammo, v)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
