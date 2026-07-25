/// Offline catalog browse from prebuilt entity bundles (DART-044).
library;

import 'dart:async';

import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../catalog/entity_bundle_loader.dart';
import '../theme/theme.dart';

/// Catalog surface: load prebuilt bundle, facet/query filter offline.
class CatalogPage extends StatefulComponent {
  const CatalogPage({
    this.loader,
    this.initialItems,
    this.initialVersion,
    super.key,
  });

  /// When null (tests with [initialItems]), no network load.
  final WebEntityBundleLoader? loader;

  /// Injected items for component tests (skip loader).
  final List<CatalogItem>? initialItems;
  final String? initialVersion;

  static const String titleText = 'Catalog';
  static const String emptyText =
      'No catalog items. Prebuilt entity bundle is empty or missing.';
  static const String loadingText = 'Loading prebuilt entity bundle…';
  static const String subtitleText =
      'Offline facets from prebuilt entity bundles. '
      'No raw manifest rebuild in the browser. No inventory owned filter yet.';

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
  bool? _exotic; // null off, true only exotic, false exclude exotic

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
      _results = _apply();
      return;
    }
    final loader = component.loader;
    if (loader != null) {
      _status = EntityBundleLoadStatus.loading;
      unawaited(_load(loader));
    }
  }

  Future<void> _load(WebEntityBundleLoader loader) async {
    final status = await loader.load();
    if (!mounted) return;
    setState(() {
      _status = status;
      _base = loader.catalog?.baseItems ?? const [];
      _results = _apply();
    });
  }

  CatalogClientFilters _filters() {
    return CatalogClientFilters(
      query: _query.isEmpty ? null : _query,
      elements: _elements,
      ammos: _ammos,
      exotic: _exotic,
    );
  }

  List<CatalogItem> _apply() {
    return filterCatalogClient(_base, _filters());
  }

  void _refilter() {
    setState(() {
      _results = _apply();
    });
  }

  void _onQuery(String value) {
    _query = value;
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

  @override
  Component build(BuildContext context) {
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
              attributes: {'data-testid': 'facet-elements'},
              [
                span(classes: 'facet-label', [.text('Element')]),
                for (final el in catalogElements)
                  button(
                    classes: _chipClass(_elements, el),
                    attributes: {
                      'type': 'button',
                      'data-facet': 'element',
                      'data-value': el,
                    },
                    events: {
                      'click': (_) => _cycleElement(el),
                    },
                    [.text(el)],
                  ),
              ],
            ),
            div(
              classes: 'facet-row',
              attributes: {'data-testid': 'facet-ammos'},
              [
                span(classes: 'facet-label', [.text('Ammo')]),
                for (final a in catalogAmmoTypes)
                  button(
                    classes: _chipClass(_ammos, a),
                    attributes: {
                      'type': 'button',
                      'data-facet': 'ammo',
                      'data-value': a,
                    },
                    events: {
                      'click': (_) => _cycleAmmo(a),
                    },
                    [.text(a)],
                  ),
              ],
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
          ]),
          p(
            classes: 'catalog-count',
            attributes: {'data-testid': 'catalog-count'},
            [.text('${_results.length} result(s)')],
          ),
          if (_results.isEmpty)
            p(
              attributes: {'data-testid': 'catalog-empty'},
              [.text(CatalogPage.emptyText)],
            )
          else
            ul(
              classes: 'catalog-list',
              attributes: {'data-testid': 'catalog-list'},
              [
                for (final item in _results)
                  li(
                    classes: 'catalog-row',
                    attributes: {
                      'data-hash': '${item.hash}',
                      'data-testid': 'catalog-row',
                    },
                    [
                      span(classes: 'catalog-name', [.text(item.name)]),
                      span(classes: 'catalog-meta', [
                        .text(
                          [
                            if (item.slot != null) item.slot!,
                            if (item.element != null) item.element!,
                            if (item.ammo != null) item.ammo!,
                            if (item.isExotic) 'Exotic',
                          ].join(' · '),
                        ),
                      ]),
                    ],
                  ),
              ],
            ),
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
            width: 100.percent,
            margin: .only(top: 0.5.rem),
            padding: .all(0.px),
            listStyle: .none,
          ),
          css('.catalog-row').styles(
            display: .flex,
            width: 100.percent,
            padding: .symmetric(horizontal: 0.75.rem, vertical: 0.55.rem),
            border: .only(bottom: .solid(color: flapLineColor, width: 1.px)),
            flexDirection: .column,
            gap: Gap(row: 0.15.rem),
            backgroundColor: flapSurfaceColor,
          ),
          css('.catalog-name').styles(
            fontWeight: .w600,
            fontSize: 0.95.rem,
          ),
          css('.catalog-meta').styles(
            color: flapMutedColor,
            fontSize: 0.8.rem,
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
