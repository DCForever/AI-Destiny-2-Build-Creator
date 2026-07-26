/// Offline catalog browse + Owned scope from inventory (DART-044 / DART-056).
library;

import 'dart:async';

import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../catalog/entity_bundle_loader.dart';
import '../catalog/owned_catalog_bridge.dart';
import '../theme/theme.dart';

/// Catalog surface: load prebuilt bundle, facet/query filter, All|Owned.
class CatalogPage extends StatefulComponent {
  const CatalogPage({
    this.loader,
    this.bridge,
    this.initialItems,
    this.initialVersion,
    super.key,
  });

  /// When null (tests with [initialItems]), no network load.
  final WebEntityBundleLoader? loader;

  /// When set, enables Owned join + instance projections (DART-056).
  final OwnedCatalogBridge? bridge;

  /// Injected items for component tests (skip loader).
  final List<CatalogItem>? initialItems;
  final String? initialVersion;

  static const String titleText = 'Catalog';
  static const String emptyText =
      'No catalog items. Prebuilt entity bundle is empty or missing.';
  static const String emptyOwnedText =
      'No owned items in local inventory. Sign in and use Settings → Sync now, '
      'then reload Catalog.';
  static const String emptyOwnedEntitiesText =
      'Owned catalog needs entity definitions. Load prebuilt entity bundles '
      '(empty Owned is not solely an inventory sync problem).';
  static const String loadingText = 'Loading production entity channel…';
  static const String subtitleText =
      'Offline facets from production hybrid entity channel (ship-in-app prebuilt; '
      'optional CDN). All | Owned joins local inventory after Settings sync. '
      'Select a row to see instance ids for equip/DIM pins. '
      'No raw manifest rebuild in the browser; no Next manifest API.';

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  EntityBundleLoadStatus _status = EntityBundleLoadStatus.idle;
  List<CatalogItem> _base = const [];
  List<CatalogItem> _results = const [];
  String _query = '';
  FacetFilter _elements = emptyFacet();
  FacetFilter _ammos = emptyFacet();
  FacetFilter _slots = emptyFacet();
  FacetFilter _classNames = emptyFacet();
  FacetFilter _archetypes = emptyFacet();
  bool? _exotic; // null off, true only exotic, false exclude exotic
  final List<CatalogGroupDimension> _groupBy = [];
  CatalogScope _scope = CatalogScope.all;
  CatalogItem? _selected;
  List<CatalogInstanceProjection> _instances = const [];
  bool _bridgeReady = false;

  @override
  void initState() {
    super.initState();
    final injected = component.initialItems;
    if (injected != null) {
      _base = List<CatalogItem>.from(injected);
      _status = EntityBundleLoadStatus(
        phase: injected.isEmpty
            ? EntityBundleLoadPhase.empty
            : EntityBundleLoadPhase.ready,
        version: component.initialVersion ?? 'test',
        itemCount: injected.length,
        emptyReason: injected.isEmpty
            ? CatalogEmptyReason.noStores
            : CatalogEmptyReason.none,
      );
      unawaited(_initWithBase());
      return;
    }
    final loader = component.loader;
    if (loader != null) {
      _status = EntityBundleLoadStatus.loading;
      unawaited(_load(loader));
    }
  }

  Future<void> _initWithBase() async {
    final bridge = component.bridge;
    if (bridge != null) {
      await bridge.refresh(reloadEntities: false);
      if (!mounted) return;
      setState(() {
        _base = bridge.annotatedBase.isNotEmpty
            ? bridge.annotatedBase
            : _base;
        _bridgeReady = true;
        _results = _apply();
        _syncSelection();
      });
      return;
    }
    setState(() {
      _results = _apply();
    });
  }

  Future<void> _load(WebEntityBundleLoader loader) async {
    final status = await loader.load();
    if (!mounted) return;
    _status = status;
    _base = loader.catalog?.baseItems ?? const [];
    final bridge = component.bridge;
    if (bridge != null) {
      await bridge.refresh(reloadEntities: false);
      if (!mounted) return;
      setState(() {
        _base = bridge.annotatedBase.isNotEmpty
            ? bridge.annotatedBase
            : _base;
        _bridgeReady = true;
        _results = _apply();
        _syncSelection();
      });
      return;
    }
    setState(() {
      _results = _apply();
    });
  }

  CatalogClientFilters _filters() {
    return CatalogClientFilters(
      query: _query.isEmpty ? null : _query,
      elements: _elements,
      ammos: _ammos,
      slots: _slots,
      classNames: _classNames,
      archetypes: _archetypes,
      exotic: _exotic,
      scope: _scope,
    );
  }

  List<CatalogGroup> _groupedResults() {
    return groupCatalogItems(
      _results,
      List<CatalogGroupDimension>.from(_groupBy),
    );
  }

  List<CatalogItem> _apply() {
    final bridge = component.bridge;
    if (bridge != null && _bridgeReady) {
      return bridge.browse(_filters());
    }
    // Without bridge, Owned is empty (no inventory join).
    final filters = _filters();
    if (filters.scope == CatalogScope.owned) {
      return filterCatalogClient(
        annotateCatalogWithOwned(_base, const {}),
        filters,
      );
    }
    return filterCatalogClient(_base, filters);
  }

  void _refilter() {
    setState(() {
      _results = _apply();
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
    final bridge = component.bridge;
    _instances = bridge?.instancesFor(sel.hash) ?? const [];
  }

  void _selectItem(CatalogItem item) {
    setState(() {
      _selected = item;
      final bridge = component.bridge;
      _instances = bridge?.instancesFor(item.hash) ?? const [];
    });
  }

  void _onQuery(String value) {
    _query = value;
    _refilter();
  }

  void _setScope(CatalogScope scope) {
    if (_scope == scope) return;
    _scope = scope;
    _refilter();
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

  void _toggleGroupDimension(CatalogGroupDimension dim) {
    if (_groupBy.contains(dim)) {
      _groupBy.remove(dim);
    } else {
      _groupBy.add(dim);
    }
    setState(() {});
  }

  void _cycleExotic() {
    // null → true → false → null
    if (_exotic == null) {
      _exotic = true;
    } else if (_exotic == true) {
      _exotic = false;
    } else {
      _exotic = null;
    }
    _refilter();
  }

  String _chipClass(FacetFilter facet, String value) {
    if (facet.include.contains(value)) return 'facet-chip facet-include';
    if (facet.exclude.contains(value)) return 'facet-chip facet-exclude';
    return 'facet-chip';
  }

  Component _facetRow({
    required String testId,
    required String label,
    required List<String> values,
    required FacetFilter facet,
    required String dataFacet,
    required void Function(String) onCycle,
  }) {
    return div(
      classes: 'facet-row',
      attributes: {'data-testid': testId},
      [
        span(classes: 'facet-label', [.text(label)]),
        for (final value in values)
          button(
            key: ValueKey('facet-$dataFacet-$value'),
            classes: _chipClass(facet, value),
            attributes: {
              'type': 'button',
              'data-facet': dataFacet,
              'data-value': value,
              'data-testid': 'facet-$dataFacet-$value',
            },
            events: {
              'click': (_) => onCycle(value),
            },
            [.text(value)],
          ),
      ],
    );
  }

  String _exoticChipClass() {
    if (_exotic == true) return 'facet-chip facet-include';
    if (_exotic == false) return 'facet-chip facet-exclude';
    return 'facet-chip';
  }

  String _exoticLabel() {
    if (_exotic == true) return 'Exotic only';
    if (_exotic == false) return 'No exotic';
    return 'Exotic';
  }

  String _scopeChipClass(CatalogScope scope) {
    return _scope == scope ? 'facet-chip facet-include' : 'facet-chip';
  }

  String _emptyMessage() {
    if (_scope == CatalogScope.owned) {
      if (_base.isEmpty) return CatalogPage.emptyOwnedEntitiesText;
      return CatalogPage.emptyOwnedText;
    }
    return CatalogPage.emptyText;
  }

  @override
  Component build(BuildContext context) {
    final scopeLabel = _scope == CatalogScope.owned ? 'owned' : 'all';
    return section(
      classes: 'catalog-page',
      attributes: {'data-page': 'catalog'},
      [
        h1([.text(CatalogPage.titleText)]),
        p(classes: 'catalog-sub', [.text(CatalogPage.subtitleText)]),
        p(
          classes: 'catalog-status',
          attributes: {'data-testid': 'catalog-status'},
          [.text(_status.summaryLine)],
        ),
        if (_status.isLoading)
          p(
            attributes: {'data-testid': 'catalog-loading'},
            [.text(CatalogPage.loadingText)],
          ),
        if (_status.hasError)
          p(
            classes: 'catalog-error',
            attributes: {'data-testid': 'catalog-error'},
            [.text(_status.error ?? 'Unknown error')],
          ),
        if (!_status.isLoading && !_status.hasError) ...[
          div(classes: 'catalog-filters', [
            label([
              .text('Search'),
              input(
                type: InputType.search,
                value: _query,
                attributes: {
                  'data-testid': 'catalog-query',
                  'placeholder': 'Name…',
                },
                onInput: (value) => _onQuery('$value'),
              ),
            ]),
            div(
              classes: 'facet-row',
              attributes: {'data-testid': 'catalog-scope'},
              [
                span(classes: 'facet-label', [.text('Scope')]),
                button(
                  key: const ValueKey('scope-chip-all'),
                  classes: _scopeChipClass(CatalogScope.all),
                  attributes: {
                    'type': 'button',
                    'data-testid': 'scope-chip-all',
                  },
                  events: {
                    'click': (_) => _setScope(CatalogScope.all),
                  },
                  [.text('All')],
                ),
                button(
                  key: const ValueKey('scope-chip-owned'),
                  classes: _scopeChipClass(CatalogScope.owned),
                  attributes: {
                    'type': 'button',
                    'data-testid': 'scope-chip-owned',
                  },
                  events: {
                    'click': (_) => _setScope(CatalogScope.owned),
                  },
                  [.text('Owned')],
                ),
              ],
            ),
            _facetRow(
              testId: 'facet-elements',
              label: 'Element',
              values: catalogElements,
              facet: _elements,
              dataFacet: 'element',
              onCycle: _cycleElement,
            ),
            _facetRow(
              testId: 'facet-ammos',
              label: 'Ammo',
              values: catalogAmmoTypes,
              facet: _ammos,
              dataFacet: 'ammo',
              onCycle: _cycleAmmo,
            ),
            _facetRow(
              testId: 'facet-slots',
              label: 'Slot',
              values: [...catalogWeaponSlots, ...catalogArmorSlots],
              facet: _slots,
              dataFacet: 'slot',
              onCycle: _cycleSlot,
            ),
            _facetRow(
              testId: 'facet-classes',
              label: 'Class',
              values: catalogClassNames,
              facet: _classNames,
              dataFacet: 'class',
              onCycle: _cycleClass,
            ),
            _facetRow(
              testId: 'facet-archetypes',
              label: 'Archetype',
              values: [...catalogWeaponArchetypes, ...catalogArmorArchetypes],
              facet: _archetypes,
              dataFacet: 'archetype',
              onCycle: _cycleArchetype,
            ),
            div(classes: 'facet-row', [
              span(classes: 'facet-label', [.text('Rarity')]),
              button(
                key: const ValueKey('facet-exotic'),
                classes: _exoticChipClass(),
                attributes: {
                  'type': 'button',
                  'data-testid': 'facet-exotic',
                },
                events: {
                  'click': (_) => _cycleExotic(),
                },
                [.text(_exoticLabel())],
              ),
            ]),
            div(
              classes: 'facet-row',
              attributes: {'data-testid': 'catalog-group-by'},
              [
                span(classes: 'facet-label', [.text('Group')]),
                for (final dim in catalogGroupDimensions)
                  button(
                    key: ValueKey('group-chip-${dim.id.name}'),
                    classes: _groupBy.contains(dim.id)
                        ? 'facet-chip facet-include'
                        : 'facet-chip',
                    attributes: {
                      'type': 'button',
                      'data-testid': 'group-chip-${dim.id.name}',
                      'data-group': dim.id.name,
                    },
                    events: {
                      'click': (_) => _toggleGroupDimension(dim.id),
                    },
                    [.text(dim.label)],
                  ),
              ],
            ),
          ]),
          p(
            classes: 'catalog-count',
            attributes: {'data-testid': 'catalog-count'},
            [.text('${_results.length} result(s) · scope=$scopeLabel')],
          ),
          if (_results.isEmpty)
            p(
              attributes: {'data-testid': 'catalog-empty'},
              [.text(_emptyMessage())],
            )
          else
            div(
              classes: 'catalog-list',
              attributes: {'data-testid': 'catalog-list'},
              [
                for (final group in _groupedResults()) ...[
                  if (_groupBy.isNotEmpty)
                    h3(
                      classes: 'catalog-group-header',
                      attributes: {
                        'data-testid': 'catalog-group',
                        'data-group-key': group.key,
                      },
                      [.text('${group.label} (${group.items.length})')],
                    ),
                  for (final item in group.items)
                    button(
                      key: ValueKey('catalog-row-${item.hash}'),
                      classes: _selected?.hash == item.hash
                          ? 'catalog-row catalog-row-selected'
                          : 'catalog-row',
                      attributes: {
                        'type': 'button',
                        'data-hash': '${item.hash}',
                        'data-testid': 'catalog-row',
                        if (item.owned) 'data-owned': '${item.ownedCount}',
                      },
                      events: {
                        'click': (_) => _selectItem(item),
                      },
                      [
                        span(classes: 'catalog-name', [
                          .text(item.name),
                          if (item.owned)
                            span(
                              classes: 'catalog-owned-badge',
                              attributes: {
                                'data-testid': 'owned-badge-${item.hash}',
                              },
                              [.text(' ×${item.ownedCount}')],
                            ),
                        ]),
                        span(classes: 'catalog-meta', [
                          .text(
                            [
                              if (item.slot != null) item.slot!,
                              if (item.element != null) item.element!,
                              if (item.ammo != null) item.ammo!,
                              if (item.classType != null) item.classType!,
                              if (item.isExotic) 'Exotic',
                              if (item.owned) 'owned×${item.ownedCount}',
                            ].join(' · '),
                          ),
                        ]),
                      ],
                    ),
                ],
              ],
            ),
          if (_selected != null) ...[
            h2(
              attributes: {'data-testid': 'catalog-instances-title'},
              [.text('Owned instances — ${_selected!.name}')],
            ),
            p(classes: 'catalog-sub', [
              .text(
                'Copy an instance id into Build compose pin for equip/DIM. '
                'Soft suggestions never auto-apply.',
              ),
            ]),
            if (_instances.isEmpty)
              p(
                attributes: {'data-testid': 'catalog-instances-empty'},
                [
                  .text(
                    _selected!.owned
                        ? 'No instance rows for this definition in local inventory.'
                        : 'No owned instances — wishlist/definition only until you sync inventory.',
                  ),
                ],
              )
            else
              ul(
                classes: 'catalog-instances',
                attributes: {'data-testid': 'catalog-instances'},
                [
                  for (final inst in _instances)
                    li(
                      classes: 'catalog-instance-row',
                      attributes: {
                        'data-testid': 'catalog-instance',
                        'data-instance-id': inst.instanceId,
                      },
                      [
                        span(
                          classes: 'catalog-instance-id',
                          attributes: {
                            'data-testid': 'instance-id-${inst.instanceId}',
                          },
                          [.text(inst.instanceId)],
                        ),
                        span(classes: 'catalog-meta', [
                          .text(
                            [
                              'power ${inst.power}',
                              inst.bucket,
                              inst.location,
                              if (inst.characterId != null)
                                'char ${inst.characterId}',
                              if (inst.isMasterwork) 'MW',
                              if (inst.isCrafted) 'Crafted',
                              if (inst.rollTags.isNotEmpty)
                                inst.rollTags.join(','),
                            ].join(' · '),
                          ),
                        ]),
                      ],
                    ),
                ],
              ),
          ],
        ],
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
        css('.catalog-page', [
          css('&').styles(
            display: .flex,
            width: 100.percent,
            maxWidth: 48.rem,
            padding: .symmetric(horizontal: 1.25.rem, vertical: 1.5.rem),
            flexDirection: .column,
            alignItems: .start,
            gap: Gap(row: 0.65.rem),
          ),
          css('.catalog-sub').styles(
            maxWidth: 40.rem,
            lineHeight: 1.5.em,
            color: flapMutedColor,
          ),
          css('.catalog-status').styles(
            color: flapAccentColor,
            fontSize: 0.9.rem,
            fontWeight: .w600,
          ),
          css('.catalog-error').styles(
            color: Color('#c45c26'),
          ),
          css('.catalog-filters').styles(
            display: .flex,
            width: 100.percent,
            flexDirection: .column,
            gap: Gap(row: 0.5.rem),
          ),
          css('.facet-row').styles(
            display: .flex,
            flexWrap: .wrap,
            alignItems: .center,
            gap: Gap(row: 0.35.rem, column: 0.35.rem),
          ),
          css('.facet-label').styles(
            minWidth: 4.5.rem,
            color: flapMutedColor,
            fontSize: 0.8.rem,
            fontWeight: .w600,
          ),
          css('.facet-chip').styles(
            padding: .symmetric(horizontal: 0.55.rem, vertical: 0.25.rem),
            border: .all(style: .solid, color: flapLineColor, width: 1.px),
            radius: .all(.circular(0.px)),
            color: flapForegroundColor,
            fontSize: 0.8.rem,
            backgroundColor: flapSurfaceColor,
            cursor: .pointer,
          ),
          css('.facet-include').styles(
            border: .all(style: .solid, color: flapAccentColor, width: 1.px),
            color: flapBackgroundColor,
            backgroundColor: flapAccentColor,
          ),
          css('.facet-exclude').styles(
            border: .all(style: .solid, color: Color('#c45c26'), width: 1.px),
            color: Color('#c45c26'),
            textDecoration: TextDecoration(line: .lineThrough),
          ),
          css('.catalog-list').styles(
            display: .flex,
            width: 100.percent,
            margin: .only(top: 0.5.rem),
            padding: .all(0.px),
            flexDirection: .column,
          ),
          css('.catalog-row').styles(
            display: .flex,
            width: 100.percent,
            padding: .symmetric(horizontal: 0.75.rem, vertical: 0.55.rem),
            border: .only(bottom: .solid(color: flapLineColor, width: 1.px)),
            flexDirection: .column,
            alignItems: .start,
            gap: Gap(row: 0.15.rem),
            color: flapForegroundColor,
            backgroundColor: flapSurfaceColor,
            cursor: .pointer,
            textAlign: TextAlign.left,
          ),
          css('.catalog-row-selected').styles(
            border: .only(
              left: .solid(color: flapAccentColor, width: 3.px),
              bottom: .solid(color: flapLineColor, width: 1.px),
            ),
          ),
          css('.catalog-name').styles(
            fontWeight: .w600,
            fontSize: 0.95.rem,
          ),
          css('.catalog-owned-badge').styles(
            color: flapAccentColor,
            fontWeight: .w600,
          ),
          css('.catalog-meta').styles(
            color: flapMutedColor,
            fontSize: 0.8.rem,
          ),
          css('.catalog-instances').styles(
            width: 100.percent,
            margin: .zero,
            padding: .all(0.px),
            listStyle: .none,
          ),
          css('.catalog-instance-row').styles(
            display: .flex,
            width: 100.percent,
            padding: .symmetric(horizontal: 0.75.rem, vertical: 0.45.rem),
            border: .only(bottom: .solid(color: flapLineColor, width: 1.px)),
            flexDirection: .column,
            gap: Gap(row: 0.1.rem),
            backgroundColor: flapBackgroundColor,
          ),
          css('.catalog-instance-id').styles(
            fontFamily: .list([
              FontFamily('ui-monospace'),
              FontFamilies.monospace,
            ]),
            fontWeight: .w600,
            fontSize: 0.9.rem,
            color: flapAccentColor,
          ),
          css('input').styles(
            display: .block,
            width: 100.percent,
            maxWidth: 24.rem,
            margin: .only(top: 0.25.rem),
            padding: .symmetric(horizontal: 0.6.rem, vertical: 0.4.rem),
            border: .all(style: .solid, color: flapLineColor, width: 1.px),
            radius: .all(.circular(0.px)),
            color: flapForegroundColor,
            backgroundColor: flapBackgroundColor,
          ),
        ]),
      ];
}
