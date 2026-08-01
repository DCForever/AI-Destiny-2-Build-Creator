/// Offline catalog browse + Owned scope + kind modes / synergy tags (DART-063).
library;

import 'dart:async';

import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../catalog/entity_bundle_loader.dart';
import '../catalog/owned_catalog_bridge.dart';
import '../theme/theme.dart';

/// Catalog surface: modes, facets, synergy tags, owned instance detail.
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

  /// When set, enables Owned join + instance projections + synergy tags.
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
      'optional CDN). Weapons | Armor | Universal modes with kind-appropriate facets. '
      'Synergy membership filter + reverse tags on detail. '
      'Universal Set/Synergy actions only (no Build kit attach). '
      'Owned instance perk cards + armor base stats when resolvable. '
      'No raw manifest rebuild in the browser; no Next manifest API. '
      'Soft suggestions never auto-apply.';

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
  FacetFilter _synergies = emptyFacet();
  bool? _exotic; // null off, true only exotic, false exclude exotic
  final List<CatalogGroupDimension> _groupBy = [];
  CatalogScope _scope = CatalogScope.all;
  CatalogBrowseMode _mode = CatalogBrowseMode.weapons;
  CatalogItem? _selected;
  List<CatalogInstanceProjection> _instances = const [];
  List<LinkedSynergyBadge> _reverseTags = const [];
  bool _bridgeReady = false;
  String? _actionMessage;

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
      });
      await _syncSelection();
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
      });
      await _syncSelection();
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
      synergies: _synergies,
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
      return bridge.browse(_filters(), mode: _mode);
    }
    final scoped = itemsForBrowseMode(_base, _mode);
    final filters = _filters();
    if (filters.scope == CatalogScope.owned) {
      return filterCatalogClient(
        annotateCatalogWithOwned(scoped, const {}),
        filters,
      );
    }
    return filterCatalogClient(scoped, filters);
  }

  void _refilter() {
    setState(() {
      _results = _apply();
    });
    unawaited(_syncSelection());
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
    final bridge = component.bridge;
    final treatArmor = _mode == CatalogBrowseMode.armor ||
        compositionKindFromCatalogItem(sel) == CompositionKind.armor ||
        compositionKindFromCatalogItem(sel) == CompositionKind.exoticArmor;
    final instances = bridge != null
        ? await bridge.instancesForResolved(
            sel.hash,
            treatAsArmor: treatArmor,
          )
        : const <CatalogInstanceProjection>[];
    final tags = bridge != null
        ? await bridge.reverseTagsFor(sel)
        : linkedSynergyBadgesForItem(sel, const {});
    if (!mounted) return;
    setState(() {
      _instances = instances;
      _reverseTags = tags;
    });
  }

  void _selectItem(CatalogItem item) {
    setState(() {
      _selected = item;
      _actionMessage = null;
    });
    unawaited(_syncSelection());
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

  void _setMode(CatalogBrowseMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _slots = emptyFacet();
    _ammos = emptyFacet();
    _classNames = emptyFacet();
    _archetypes = emptyFacet();
    _groupBy.clear();
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

  void _cycleSynergy(String id) {
    _synergies = cycleFacetValue(_synergies, id);
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
    String Function(String)? labelOf,
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
            [.text(labelOf?.call(value) ?? value)],
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

  String _modeChipClass(CatalogBrowseMode mode) {
    return _mode == mode ? 'facet-chip facet-include' : 'facet-chip';
  }

  String _emptyMessage() {
    if (_scope == CatalogScope.owned) {
      if (_base.isEmpty) return CatalogPage.emptyOwnedEntitiesText;
      return CatalogPage.emptyOwnedText;
    }
    return CatalogPage.emptyText;
  }

  Future<void> _createSetFromHit(CatalogItem item) async {
    final bridge = component.bridge;
    final uid = bridge?.userId;
    if (uid == null || bridge == null) {
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
        bridge.db,
        uid,
        CreateSetCommand(name: '${item.name} set', type: setType),
      );
      final instanceId =
          _instances.isNotEmpty ? _instances.first.instanceId : null;
      await upsertUserSetItem(
        bridge.db,
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
    final bridge = component.bridge;
    final uid = bridge?.userId;
    if (uid == null || bridge == null) {
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
        bridge.db,
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
      await bridge.refresh(reloadEntities: false);
      if (!mounted) return;
      setState(() {
        _base = bridge.annotatedBase;
        _results = _apply();
        _actionMessage =
            'Created Synergy "${created.name}" linked to ${item.name}.';
      });
      await _syncSelection();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _actionMessage = 'Synergy create failed: $e';
      });
    }
  }

  @override
  Component build(BuildContext context) {
    final scopeLabel = _scope == CatalogScope.owned ? 'owned' : 'all';
    final modeLabel = browseModeLabel(_mode);
    final bridge = component.bridge;
    final kind = _selected == null
        ? null
        : compositionKindFromCatalogItem(_selected!);
    final actions = kind == null
        ? (set: false, synergy: false)
        : hitActions(kind);

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
              attributes: {'data-testid': 'catalog-mode'},
              [
                span(classes: 'facet-label', [.text('Mode')]),
                for (final mode in CatalogBrowseMode.values)
                  button(
                    key: ValueKey('mode-chip-${mode.name}'),
                    classes: _modeChipClass(mode),
                    attributes: {
                      'type': 'button',
                      'data-testid': 'mode-chip-${mode.name}',
                    },
                    events: {
                      'click': (_) => _setMode(mode),
                    },
                    [.text(browseModeLabel(mode))],
                  ),
              ],
            ),
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
            if (catalogShowsElementFacet(_mode))
              _facetRow(
                testId: 'facet-elements',
                label: 'Element',
                values: catalogElements,
                facet: _elements,
                dataFacet: 'element',
                onCycle: _cycleElement,
              ),
            if (catalogShowsAmmoFacet(_mode))
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
              values: catalogSlotsForMode(_mode),
              facet: _slots,
              dataFacet: 'slot',
              onCycle: _cycleSlot,
            ),
            if (catalogShowsClassFacet(_mode))
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
              values: catalogArchetypesForMode(_mode),
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
            if (bridge != null && bridge.synergyMembership.isNotEmpty)
              _facetRow(
                testId: 'facet-synergies',
                label: 'Synergy',
                values: bridge.synergyMembership.map((s) => s.id).toList(),
                facet: _synergies,
                dataFacet: 'synergy',
                onCycle: _cycleSynergy,
                labelOf: (id) => bridge.synergyNames[id] ?? id,
              ),
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
            [
              .text(
                '${_results.length} result(s) · mode=$modeLabel · scope=$scopeLabel',
              ),
            ],
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
                        if (item.linkedSynergyIds.isNotEmpty)
                          'data-synergies': item.linkedSynergyIds.join(','),
                      },
                      events: {
                        'click': (_) => _selectItem(item),
                      },
                      [
                        if (item.icon != null && item.icon!.isNotEmpty)
                          img(
                            classes: 'catalog-item-icon',
                            src: item.icon!.startsWith('http')
                                ? item.icon!
                                : 'https://www.bungie.net${item.icon!.startsWith('/') ? item.icon! : '/${item.icon!}'}',
                            alt: '',
                            attributes: {
                              'data-testid': 'catalog-item-icon-${item.hash}',
                              'width': '36',
                              'height': '36',
                            },
                          ),
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
                        span(
                          classes: 'catalog-meta',
                          attributes: {
                            'data-testid': 'catalog-item-meta-${item.hash}',
                          },
                          [
                          .text(
                            [
                              ...buildCatalogDenseMetaChips(
                                isExotic: item.isExotic,
                                slot: item.slot,
                                element: item.element,
                                ammo: item.ammo,
                                itemTypeName: item.itemTypeName,
                                frame: item.frame,
                                classType: item.classType,
                              ),
                              if (item.owned) 'owned×${item.ownedCount}',
                              if (item.linkedSynergyIds.isNotEmpty)
                                'syn×${item.linkedSynergyIds.length}',
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
            if (kind != null)
              p(
                classes: 'catalog-sub',
                attributes: {'data-testid': 'detail-kind-label'},
                [.text(compositionKindLabel(kind))],
              ),
            if (_reverseTags.isNotEmpty)
              div(
                classes: 'facet-row',
                attributes: {'data-testid': 'linked-synergy-badges'},
                [
                  span(classes: 'facet-label', [.text('Linked synergies')]),
                  for (final badge in _reverseTags)
                    span(
                      classes: 'synergy-badge',
                      attributes: {
                        'data-testid': 'synergy-badge-${badge.id}',
                      },
                      [.text(badge.name)],
                    ),
                ],
              ),
            if (_mode == CatalogBrowseMode.universal)
              div(
                classes: 'facet-row',
                attributes: {'data-testid': 'universal-actions'},
                [
                  if (actions.set)
                    button(
                      classes: 'facet-chip facet-include',
                      attributes: {
                        'type': 'button',
                        'data-testid': 'universal-create-set',
                      },
                      events: {
                        'click': (_) => unawaited(_createSetFromHit(_selected!)),
                      },
                      [.text('Create Set')],
                    ),
                  if (actions.synergy)
                    button(
                      classes: 'facet-chip facet-include',
                      attributes: {
                        'type': 'button',
                        'data-testid': 'universal-create-synergy',
                      },
                      events: {
                        'click': (_) =>
                            unawaited(_createSynergyFromHit(_selected!)),
                      },
                      [.text('Create Synergy')],
                    ),
                  if (!actions.set && !actions.synergy)
                    span(
                      attributes: {'data-testid': 'universal-no-actions'},
                      [
                        .text(
                          'Visible in Universal but not Set/Synergy attachable.',
                        ),
                      ],
                    ),
                  span(
                    attributes: {'data-testid': 'no-build-kit-attach'},
                    [.text('')],
                  ),
                ],
              ),
            if (_actionMessage != null)
              p(
                attributes: {'data-testid': 'catalog-action-message'},
                [.text(_actionMessage!)],
              ),
            p(classes: 'catalog-sub', [
              .text(
                _instances.isEmpty
                    ? 'No local copies (wishlist / definition only — unpinned). '
                        'Copy an instance id into Build compose pin for equip/DIM. '
                        'Soft suggestions never auto-apply.'
                    : '${_instances.length} owned cop${_instances.length == 1 ? 'y' : 'ies'}. '
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
                        if (inst.armorStats != null && inst.armorStats!.hasAny)
                          div(
                            attributes: {
                              'data-testid':
                                  'armor-stats-board-${inst.instanceId}',
                            },
                            [
                              span(classes: 'facet-label', [.text('Base stats')]),
                              for (final key in armorBaseStatKeys)
                                if (inst.armorStats!.stats[key] != null)
                                  span(
                                    classes: 'synergy-badge',
                                    [
                                      .text(
                                        '$key ${inst.armorStats!.stats[key]}',
                                      ),
                                    ],
                                  ),
                              if (inst.armorStats!.total != null)
                                span(
                                  classes: 'synergy-badge',
                                  [.text('Total ${inst.armorStats!.total}')],
                                ),
                            ],
                          ),
                        if (inst.plugCards.isNotEmpty)
                          div(
                            attributes: {
                              'data-testid': 'plug-cards-${inst.instanceId}',
                            },
                            [
                              span(
                                classes: 'facet-label',
                                [.text('Perks / plugs')],
                              ),
                              for (final card in inst.plugCards)
                                span(
                                  classes: 'synergy-badge',
                                  attributes: {
                                    'data-testid':
                                        'plug-card-${inst.instanceId}-${card.hash}',
                                  },
                                  [
                                    .text(
                                      card.isTrait
                                          ? 'Trait: ${card.displayName}'
                                          : card.displayName,
                                    ),
                                  ],
                                ),
                            ],
                          ),
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
          css('.catalog-count').styles(
            color: flapMutedColor,
            fontSize: 0.85.rem,
          ),
          css('.catalog-list').styles(
            display: .flex,
            width: 100.percent,
            margin: .only(top: 0.5.rem),
            padding: .all(0.px),
            flexDirection: .column,
          ),
          css('.catalog-group-header').styles(
            margin: .only(top: 0.5.rem),
            color: flapAccentColor,
            fontSize: 0.95.rem,
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
          css('.synergy-badge').styles(
            padding: .symmetric(horizontal: 0.45.rem, vertical: 0.15.rem),
            border: .all(style: .solid, color: flapAccentColor, width: 1.px),
            color: flapAccentColor,
            fontSize: 0.75.rem,
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
