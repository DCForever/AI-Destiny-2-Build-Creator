// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:destiny2_widgetbook/use_cases/catalog/cards_use_cases.dart'
    as _destiny2_widgetbook_use_cases_catalog_cards_use_cases;
import 'package:destiny2_widgetbook/use_cases/catalog/detail_use_cases.dart'
    as _destiny2_widgetbook_use_cases_catalog_detail_use_cases;
import 'package:destiny2_widgetbook/use_cases/catalog/facet_scope_empty_use_cases.dart'
    as _destiny2_widgetbook_use_cases_catalog_facet_scope_empty_use_cases;
import 'package:destiny2_widgetbook/use_cases/catalog/family_use_cases.dart'
    as _destiny2_widgetbook_use_cases_catalog_family_use_cases;
import 'package:destiny2_widgetbook/use_cases/catalog/group_use_cases.dart'
    as _destiny2_widgetbook_use_cases_catalog_group_use_cases;
import 'package:destiny2_widgetbook/use_cases/catalog/meta_strip_use_cases.dart'
    as _destiny2_widgetbook_use_cases_catalog_meta_strip_use_cases;
import 'package:destiny2_widgetbook/use_cases/catalog/workspace_use_cases.dart'
    as _destiny2_widgetbook_use_cases_catalog_workspace_use_cases;
import 'package:widgetbook/widgetbook.dart' as _widgetbook;

final directories = <_widgetbook.WidgetbookNode>[
  _widgetbook.WidgetbookCategory(
    name: 'Catalog',
    children: [
      _widgetbook.WidgetbookFolder(
        name: 'Cards',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'CatalogWeaponCard',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Exotic selected',
                builder: _destiny2_widgetbook_use_cases_catalog_cards_use_cases
                    .cardExoticSelected,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Legendary owned',
                builder: _destiny2_widgetbook_use_cases_catalog_cards_use_cases
                    .cardLegendary,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'NeonItemCard',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'NeonItemCard kinetic legendary',
                builder: _destiny2_widgetbook_use_cases_catalog_cards_use_cases
                    .neonItemCard,
              )
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'Detail',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'CatalogDetailToggles',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Detail toggles craft hidden',
                builder: _destiny2_widgetbook_use_cases_catalog_detail_use_cases
                    .detailToggles,
              )
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CatalogPerkGrid',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Perk grid ①②③ + enhanced note path',
                builder: _destiny2_widgetbook_use_cases_catalog_detail_use_cases
                    .perkGridMixed,
              )
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CatalogWeaponDetail',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Owned · Possible rolls OFF (①+②)',
                builder: _destiny2_widgetbook_use_cases_catalog_detail_use_cases
                    .detailOwnedCanRollOff,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Owned · Possible rolls ON (③ expand)',
                builder: _destiny2_widgetbook_use_cases_catalog_detail_use_cases
                    .detailOwnedCanRollOn,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Unowned · POSSIBLE ROLLS only',
                builder: _destiny2_widgetbook_use_cases_catalog_detail_use_cases
                    .detailUnowned,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'WeaponInstanceStrip',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Instance strip multi-PL',
                builder: _destiny2_widgetbook_use_cases_catalog_detail_use_cases
                    .instanceStrip,
              )
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'Empty',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'CatalogEmptyState',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Owned empty (Sync + Settings)',
                builder:
                    _destiny2_widgetbook_use_cases_catalog_facet_scope_empty_use_cases
                        .emptyOwned,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Signed-out owned scope',
                builder:
                    _destiny2_widgetbook_use_cases_catalog_facet_scope_empty_use_cases
                        .emptySignedOut,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Zero match (Clear filters)',
                builder:
                    _destiny2_widgetbook_use_cases_catalog_facet_scope_empty_use_cases
                        .emptyZeroMatch,
              ),
            ],
          )
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'Facets',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'NeonFacetChip',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Off → include → exclude cycle',
                builder:
                    _destiny2_widgetbook_use_cases_catalog_facet_scope_empty_use_cases
                        .facetCycle,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'iconOnly element row',
                builder:
                    _destiny2_widgetbook_use_cases_catalog_facet_scope_empty_use_cases
                        .facetIconOnly,
              ),
            ],
          )
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'Family',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'CatalogWeaponFamilyCard',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Base + Adept chips (Holofoil unowned omitted)',
                builder: _destiny2_widgetbook_use_cases_catalog_family_use_cases
                    .familyBaseAdept,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Multi-hash Base → one chip (Ribbontail-style)',
                builder: _destiny2_widgetbook_use_cases_catalog_family_use_cases
                    .familyMultiHashBase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Selected family',
                builder: _destiny2_widgetbook_use_cases_catalog_family_use_cases
                    .familySelected,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Signed-out honesty (no chips / no ×N)',
                builder: _destiny2_widgetbook_use_cases_catalog_family_use_cases
                    .familySignedOut,
              ),
            ],
          )
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'Group',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'CatalogGroupHeader',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Collapsed header',
                builder: _destiny2_widgetbook_use_cases_catalog_group_use_cases
                    .groupHeaderCollapsed,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Expanded header',
                builder: _destiny2_widgetbook_use_cases_catalog_group_use_cases
                    .groupHeaderExpanded,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CatalogGroupOutlineRail',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Outline rail (≥2 groups)',
                builder: _destiny2_widgetbook_use_cases_catalog_group_use_cases
                    .groupOutlineRail,
              )
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'Meta',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'CatalogWeaponMetaStrip',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Full facets + owned ×N',
                builder:
                    _destiny2_widgetbook_use_cases_catalog_meta_strip_use_cases
                        .metaStripFull,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Signed-out (no ×N)',
                builder:
                    _destiny2_widgetbook_use_cases_catalog_meta_strip_use_cases
                        .metaStripSignedOut,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Sparse facets',
                builder:
                    _destiny2_widgetbook_use_cases_catalog_meta_strip_use_cases
                        .metaStripSparse,
              ),
            ],
          )
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'Scope',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'CatalogScopeControl',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'All / OWNED · N',
                builder:
                    _destiny2_widgetbook_use_cases_catalog_facet_scope_empty_use_cases
                        .scopeControl,
              )
            ],
          )
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'Workspace',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'CatalogWeaponsWorkspace',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Grid + 400 detail sidebar',
                builder:
                    _destiny2_widgetbook_use_cases_catalog_workspace_use_cases
                        .workspaceWithDetail,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Grid only (no detail pane)',
                builder:
                    _destiny2_widgetbook_use_cases_catalog_workspace_use_cases
                        .workspaceGridOnly,
              ),
            ],
          )
        ],
      ),
    ],
  )
];
