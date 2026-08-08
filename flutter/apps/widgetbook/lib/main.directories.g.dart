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
import 'package:destiny2_widgetbook/use_cases/catalog/filter_bar_host_parity_use_cases.dart'
    as _destiny2_widgetbook_use_cases_catalog_filter_bar_host_parity_use_cases;
import 'package:destiny2_widgetbook/use_cases/catalog/filter_bar_use_cases.dart'
    as _destiny2_widgetbook_use_cases_catalog_filter_bar_use_cases;
import 'package:destiny2_widgetbook/use_cases/catalog/group_use_cases.dart'
    as _destiny2_widgetbook_use_cases_catalog_group_use_cases;
import 'package:destiny2_widgetbook/use_cases/catalog/meta_strip_use_cases.dart'
    as _destiny2_widgetbook_use_cases_catalog_meta_strip_use_cases;
import 'package:destiny2_widgetbook/use_cases/catalog/mobile_use_cases.dart'
    as _destiny2_widgetbook_use_cases_catalog_mobile_use_cases;
import 'package:destiny2_widgetbook/use_cases/catalog/sort_group_use_cases.dart'
    as _destiny2_widgetbook_use_cases_catalog_sort_group_use_cases;
import 'package:destiny2_widgetbook/use_cases/catalog/viewport_matrix_use_cases.dart'
    as _destiny2_widgetbook_use_cases_catalog_viewport_matrix_use_cases;
import 'package:destiny2_widgetbook/use_cases/catalog/workspace_use_cases.dart'
    as _destiny2_widgetbook_use_cases_catalog_workspace_use_cases;
import 'package:destiny2_widgetbook/use_cases/neon/board_atmosphere_use_cases.dart'
    as _destiny2_widgetbook_use_cases_neon_board_atmosphere_use_cases;
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
          _widgetbook.WidgetbookFolder(
            name: 'Family',
            children: [
              _widgetbook.WidgetbookComponent(
                name: 'CatalogWeaponFamilyCard',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Base + Adept chips (Holofoil unowned omitted)',
                    builder:
                        _destiny2_widgetbook_use_cases_catalog_family_use_cases
                            .familyBaseAdept,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Multi-hash Base → one chip (Ribbontail-style)',
                    builder:
                        _destiny2_widgetbook_use_cases_catalog_family_use_cases
                            .familyMultiHashBase,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Selected family',
                    builder:
                        _destiny2_widgetbook_use_cases_catalog_family_use_cases
                            .familySelected,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Signed-out honesty (no chips / no ×N)',
                    builder:
                        _destiny2_widgetbook_use_cases_catalog_family_use_cases
                            .familySignedOut,
                  ),
                ],
              ),
              _widgetbook.WidgetbookFolder(
                name: 'Knobs',
                children: [
                  _widgetbook.WidgetbookComponent(
                    name: 'CatalogWeaponFamilyCard',
                    useCases: [
                      _widgetbook.WidgetbookUseCase(
                        name: 'All knobs · family card',
                        builder:
                            _destiny2_widgetbook_use_cases_catalog_family_use_cases
                                .knobsFamilyCard,
                      )
                    ],
                  )
                ],
              ),
            ],
          ),
          _widgetbook.WidgetbookFolder(
            name: 'Knobs',
            children: [
              _widgetbook.WidgetbookComponent(
                name: 'CatalogWeaponCard',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'All knobs · weapon card',
                    builder:
                        _destiny2_widgetbook_use_cases_catalog_cards_use_cases
                            .knobsCatalogWeaponCard,
                  )
                ],
              ),
              _widgetbook.WidgetbookComponent(
                name: 'NeonItemCard',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'All knobs · item card',
                    builder:
                        _destiny2_widgetbook_use_cases_catalog_cards_use_cases
                            .knobsNeonItemCard,
                  )
                ],
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
          _widgetbook.WidgetbookFolder(
            name: 'Knobs',
            children: [
              _widgetbook.WidgetbookComponent(
                name: 'CatalogDetailToggles',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'All knobs · detail toggles',
                    builder:
                        _destiny2_widgetbook_use_cases_catalog_detail_use_cases
                            .knobsDetailToggles,
                  )
                ],
              ),
              _widgetbook.WidgetbookComponent(
                name: 'CatalogPerkGrid',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'All knobs · perk grid',
                    builder:
                        _destiny2_widgetbook_use_cases_catalog_detail_use_cases
                            .knobsPerkGrid,
                  )
                ],
              ),
              _widgetbook.WidgetbookComponent(
                name: 'CatalogWeaponDetail',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'All knobs · weapon detail',
                    builder:
                        _destiny2_widgetbook_use_cases_catalog_detail_use_cases
                            .knobsWeaponDetail,
                  )
                ],
              ),
              _widgetbook.WidgetbookComponent(
                name: 'WeaponInstanceStrip',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'All knobs · instance strip',
                    builder:
                        _destiny2_widgetbook_use_cases_catalog_detail_use_cases
                            .knobsInstanceStrip,
                  )
                ],
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
        name: 'FilterBar',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'CatalogFilterBar',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'More expanded (secondary facets)',
                builder:
                    _destiny2_widgetbook_use_cases_catalog_filter_bar_use_cases
                        .filterBarMoreExpanded,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Narrow width wrap',
                builder:
                    _destiny2_widgetbook_use_cases_catalog_filter_bar_use_cases
                        .filterBarNarrow,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Type icon filters · scope · search',
                builder:
                    _destiny2_widgetbook_use_cases_catalog_filter_bar_use_cases
                        .filterBarTypeIcons,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Weapons host parity · exotic cycle',
                builder:
                    _destiny2_widgetbook_use_cases_catalog_filter_bar_host_parity_use_cases
                        .filterBarHostParityExotic,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Weapons host parity · wide primary line',
                builder:
                    _destiny2_widgetbook_use_cases_catalog_filter_bar_host_parity_use_cases
                        .filterBarHostParityWide,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'NeonExoticChip',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Exotic chip only · cycle labels',
                builder:
                    _destiny2_widgetbook_use_cases_catalog_filter_bar_host_parity_use_cases
                        .exoticChipCycle,
              )
            ],
          ),
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
                name: 'Outline jump · expand-on-jump + scroll',
                builder: _destiny2_widgetbook_use_cases_catalog_group_use_cases
                    .groupOutlineJumpExpand,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Outline rail (≥2 groups)',
                builder: _destiny2_widgetbook_use_cases_catalog_group_use_cases
                    .groupOutlineRail,
              ),
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
          ),
          _widgetbook.WidgetbookFolder(
            name: 'Knobs',
            children: [
              _widgetbook.WidgetbookComponent(
                name: 'CatalogWeaponMetaStrip',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Facets · element / slot / owned',
                    builder:
                        _destiny2_widgetbook_use_cases_catalog_meta_strip_use_cases
                            .knobsMetaStrip,
                  )
                ],
              )
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'Mobile',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'CatalogWeaponDetail',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Detail full-screen (phone frame)',
                builder: _destiny2_widgetbook_use_cases_catalog_mobile_use_cases
                    .mobileDetailFull,
              )
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CatalogWeaponsGrid',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'List → push detail (phone frame)',
                builder: _destiny2_widgetbook_use_cases_catalog_mobile_use_cases
                    .mobileListPushDetail,
              )
            ],
          ),
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
        name: 'SortGroup',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'CatalogSortGroupSheet',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Active slot · element groups',
                builder:
                    _destiny2_widgetbook_use_cases_catalog_sort_group_use_cases
                        .sortGroupWithDims,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Default keys · empty groups',
                builder:
                    _destiny2_widgetbook_use_cases_catalog_sort_group_use_cases
                        .sortGroupDefault,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Interactive apply (snackbar)',
                builder:
                    _destiny2_widgetbook_use_cases_catalog_sort_group_use_cases
                        .sortGroupInteractive,
              ),
            ],
          )
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'Viewport',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'CatalogFilterBar',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Filter bar · use Viewport addon',
                builder:
                    _destiny2_widgetbook_use_cases_catalog_viewport_matrix_use_cases
                        .viewportFilterBar,
              )
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CatalogWeaponsGrid',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Mobile list push · use Viewport addon',
                builder:
                    _destiny2_widgetbook_use_cases_catalog_viewport_matrix_use_cases
                        .viewportMobileList,
              )
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CatalogWeaponsWorkspace',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Workspace grid · use Viewport addon',
                builder:
                    _destiny2_widgetbook_use_cases_catalog_viewport_matrix_use_cases
                        .viewportWorkspace,
              )
            ],
          ),
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
  ),
  _widgetbook.WidgetbookCategory(
    name: 'Neon',
    children: [
      _widgetbook.WidgetbookFolder(
        name: 'Atmosphere',
        children: [
          _widgetbook.WidgetbookFolder(
            name: 'Knobs',
            children: [
              _widgetbook.WidgetbookComponent(
                name: 'NeonShellBackground',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Blooms / horizon / caption',
                    builder:
                        _destiny2_widgetbook_use_cases_neon_board_atmosphere_use_cases
                            .neonAtmosphereKnobs,
                  )
                ],
              )
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'NeonShellBackground',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Shell blooms + horizon',
                builder:
                    _destiny2_widgetbook_use_cases_neon_board_atmosphere_use_cases
                        .neonShellFull,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Shell blooms only (no horizon)',
                builder:
                    _destiny2_widgetbook_use_cases_neon_board_atmosphere_use_cases
                        .neonShellBloomsOnly,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'NeonZone',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'NeonZone soft surface',
                builder:
                    _destiny2_widgetbook_use_cases_neon_board_atmosphere_use_cases
                        .neonZone,
              )
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'Board',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'FlapBoardHeader',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Flap board header + rows (sets template)',
                builder:
                    _destiny2_widgetbook_use_cases_neon_board_atmosphere_use_cases
                        .flapBoardSets,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Flap board · builds template',
                builder:
                    _destiny2_widgetbook_use_cases_neon_board_atmosphere_use_cases
                        .flapBoardBuilds,
              ),
            ],
          )
        ],
      ),
    ],
  ),
];
