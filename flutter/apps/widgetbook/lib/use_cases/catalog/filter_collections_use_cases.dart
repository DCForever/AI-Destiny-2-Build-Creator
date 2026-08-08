import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

List<CatalogFilterCollectionItem> _fixtures(int count) {
  if (count <= 0) return const [];
  final base = <CatalogFilterCollectionItem>[
    const CatalogFilterCollectionItem(
      id: 'wc-1',
      name: 'Void HC PvP',
      summary: 'owned · slot:kinetic · element:void',
    ),
    const CatalogFilterCollectionItem(
      id: 'wc-2',
      name: 'Solar Specials',
      summary: 'q:hammer · element:solar',
    ),
    const CatalogFilterCollectionItem(
      id: 'wc-3',
      name: 'No Exotics Kinetic',
      summary: 'slot:kinetic · −exotic · group:type',
    ),
  ];
  if (count <= 3) return base.take(count).toList();
  return [
    for (var i = 1; i <= count; i++)
      CatalogFilterCollectionItem(
        id: 'cap-$i',
        name: i == 1 ? 'Void HC PvP' : 'Preset ${i.toString().padLeft(2, '0')}',
        summary: i.isOdd ? 'all · element:void' : 'owned · element:void',
      ),
  ];
}

@widgetbook.UseCase(
  name: 'Saved collections · empty + Save',
  type: CatalogFilterCollectionsControl,
  path: '[Catalog]/FilterCollections',
)
Widget filterCollectionsEmpty(BuildContext context) {
  return const _FilterCollectionsDemo(
    count: 0,
    canSave: true,
  );
}

@widgetbook.UseCase(
  name: 'Saved collections · list apply',
  type: CatalogFilterCollectionsControl,
  path: '[Catalog]/FilterCollections',
)
Widget filterCollectionsList(BuildContext context) {
  return const _FilterCollectionsDemo(
    count: 3,
    canSave: true,
  );
}

@widgetbook.UseCase(
  name: 'Saved collections · applied dirty',
  type: CatalogFilterCollectionsControl,
  path: '[Catalog]/FilterCollections',
)
Widget filterCollectionsDirty(BuildContext context) {
  return const _FilterCollectionsDemo(
    count: 3,
    activeId: 'wc-1',
    activeName: 'Void HC PvP',
    dirty: true,
    canSave: true,
  );
}

@widgetbook.UseCase(
  name: 'Saved collections · at-cap',
  type: CatalogFilterCollectionsControl,
  path: '[Catalog]/FilterCollections',
)
Widget filterCollectionsAtCap(BuildContext context) {
  return const _FilterCollectionsDemo(
    count: 20,
    atCap: true,
    canSave: true,
  );
}

@widgetbook.UseCase(
  name: 'Saved collections · signed-out',
  type: CatalogFilterCollectionsControl,
  path: '[Catalog]/FilterCollections',
)
Widget filterCollectionsSignedOut(BuildContext context) {
  return const _FilterCollectionsDemo(
    count: 0,
    signedIn: false,
    canSave: true,
  );
}

@widgetbook.UseCase(
  name: 'Saved collections · sheet 390',
  type: CatalogFilterCollectionsControl,
  path: '[Catalog]/FilterCollections',
)
Widget filterCollectionsSheet(BuildContext context) {
  return const SizedBox(
    width: 390,
    child: _FilterCollectionsDemo(
      count: 3,
      preferSheet: true,
      canSave: true,
    ),
  );
}

@widgetbook.UseCase(
  name: 'Filter bar + Saved cluster',
  type: CatalogFilterBar,
  path: '[Catalog]/FilterCollections',
)
Widget filterBarWithSaved(BuildContext context) {
  return const _FilterBarWithSavedDemo();
}

class _FilterCollectionsDemo extends StatefulWidget {
  const _FilterCollectionsDemo({
    required this.count,
    this.activeId,
    this.activeName,
    this.dirty = false,
    this.signedIn = true,
    this.canSave = false,
    this.atCap = false,
    this.preferSheet = false,
  });

  final int count;
  final String? activeId;
  final String? activeName;
  final bool dirty;
  final bool signedIn;
  final bool canSave;
  final bool atCap;
  final bool preferSheet;

  @override
  State<_FilterCollectionsDemo> createState() => _FilterCollectionsDemoState();
}

class _FilterCollectionsDemoState extends State<_FilterCollectionsDemo> {
  late List<CatalogFilterCollectionItem> _items;
  String? _activeId;
  String? _activeName;
  bool _dirty = false;
  String _status = 'soft apply — criteria only';

  @override
  void initState() {
    super.initState();
    _items = _fixtures(widget.count);
    _activeId = widget.activeId;
    _activeName = widget.activeName;
    _dirty = widget.dirty;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CatalogFilterCollectionsControl(
                items: _items,
                browseModeLabel: 'weapons',
                activeId: _activeId,
                activeName: _activeName,
                dirty: _dirty,
                signedIn: widget.signedIn,
                canSave: widget.canSave,
                atCap: widget.atCap,
                preferSheet: widget.preferSheet,
                onApply: (id) {
                  final item = _items.firstWhere((e) => e.id == id);
                  setState(() {
                    _activeId = id;
                    _activeName = item.name;
                    _dirty = false;
                    _status = 'soft restore · ${item.name} · criteria only';
                  });
                },
                onSave: (name) async {
                  setState(() {
                    final id = 'new-${_items.length + 1}';
                    _items = [
                      CatalogFilterCollectionItem(
                        id: id,
                        name: name,
                        summary: 'fixture save',
                      ),
                      ..._items,
                    ];
                    _activeId = id;
                    _activeName = name;
                    _dirty = false;
                    _status = 'Saved “$name”';
                  });
                  return null;
                },
                onRename: (id, name) async {
                  setState(() {
                    _items = [
                      for (final e in _items)
                        if (e.id == id)
                          CatalogFilterCollectionItem(
                            id: e.id,
                            name: name,
                            summary: e.summary,
                          )
                        else
                          e,
                    ];
                    if (_activeId == id) _activeName = name;
                    _status = 'Renamed to “$name”';
                  });
                  return null;
                },
                onDelete: (id) async {
                  setState(() {
                    _items = _items.where((e) => e.id != id).toList();
                    if (_activeId == id) {
                      _activeId = null;
                      _activeName = null;
                      _dirty = false;
                    }
                    _status = 'Deleted';
                  });
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                _status,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterBarWithSavedDemo extends StatefulWidget {
  const _FilterBarWithSavedDemo();

  @override
  State<_FilterBarWithSavedDemo> createState() =>
      _FilterBarWithSavedDemoState();
}

class _FilterBarWithSavedDemoState extends State<_FilterBarWithSavedDemo> {
  late final TextEditingController _query;
  var _scope = CatalogScope.all;
  var _element = const FacetFilter();
  var _more = false;
  bool? _exotic;

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
    var n = facetActiveCount(_element);
    if (_exotic != null) n++;
    if (_query.text.trim().isNotEmpty) n++;
    if (_scope == CatalogScope.owned) n++;
    return n;
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
            onReset: () {
              setState(() {
                _query.clear();
                _element = const FacetFilter();
                _exotic = null;
                _scope = CatalogScope.all;
              });
            },
            activeFilterCount: _activeCount,
            leading: CatalogScopeControl(
              scope: _scope,
              ownedLabel: 'OWNED',
              onChanged: (s) => setState(() => _scope = s),
            ),
            exotic: _exotic,
            onCycleExotic: () {
              setState(() {
                if (_exotic == null) {
                  _exotic = true;
                } else if (_exotic == true) {
                  _exotic = false;
                } else {
                  _exotic = null;
                }
              });
            },
            trailing: CatalogFilterCollectionsControl(
              items: _fixtures(3),
              browseModeLabel: 'weapons',
              canSave: _activeCount > 0,
              signedIn: true,
              onApply: (_) {},
              onSave: (_) async => null,
            ),
            primaryGroups: [
              CatalogFacetGroup(
                id: 'element',
                values: const ['Solar', 'Void', 'Arc'],
                facet: _element,
                iconOnly: true,
                onCycle: (v) => setState(
                  () => _element = cycleFacetValue(_element, v),
                ),
              ),
            ],
            secondaryGroups: [
              CatalogFacetGroup(
                id: 'ammo',
                values: const ['Primary', 'Special', 'Heavy'],
                facet: emptyFacet(),
                iconOnly: true,
                onCycle: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
