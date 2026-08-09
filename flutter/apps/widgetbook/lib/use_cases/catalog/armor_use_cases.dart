import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../fixtures/catalog_fixtures.dart';

// ---------------------------------------------------------------------------
// Desktop ~400 dual-pane (structure)
// ---------------------------------------------------------------------------

@widgetbook.UseCase(
  name: 'Armor grid + 400 detail (owned)',
  type: CatalogArmorDetail,
  path: '[Catalog]/Armor',
)
Widget armorDesktopOwned(BuildContext context) {
  final item = kArmorSynthoceps;
  final copies = kArmorOwnedCopies();
  return SizedBox(
    width: 1100,
    height: 700,
    child: CatalogWeaponsWorkspace(
      main: CatalogArmorGrid(
        items: kArmorDemoItems,
        selectedHash: item.hash,
        showOwned: true,
        onSelect: (_) {},
      ),
      detail: CatalogArmorDetail(
        item: item,
        instances: copies,
        selectedInstanceId: copies.first.instanceId,
        onSelectInstance: (_) {},
        setBonus: kArmorDemoSetBonus,
        exoticPerk: kArmorDemoExoticPerk,
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'Armor detail unowned',
  type: CatalogArmorDetail,
  path: '[Catalog]/Armor',
)
Widget armorDesktopUnowned(BuildContext context) {
  return SizedBox(
    width: 400,
    height: 700,
    child: CatalogArmorDetail(
      item: kArmorUnownedPlate,
      setBonus: kArmorDemoSetBonus,
    ),
  );
}

@widgetbook.UseCase(
  name: 'Armor instance strip rebind',
  type: ArmorInstanceStrip,
  path: '[Catalog]/Armor',
)
Widget armorInstanceStrip(BuildContext context) {
  final copies = kArmorOwnedCopies();
  return SizedBox(
    width: 400,
    height: 120,
    child: ArmorInstanceStrip(
      instances: copies,
      selectedInstanceId: copies.first.instanceId,
      onSelect: (_) {},
    ),
  );
}

@widgetbook.UseCase(
  name: 'Armor signed-out owned empty',
  type: CatalogEmptyState,
  path: '[Catalog]/Armor',
)
Widget armorSignedOutOwned(BuildContext context) {
  return SizedBox(
    width: 420,
    height: 280,
    child: CatalogEmptyState(
      kind: CatalogEmptyKind.ownedSignedOut,
      message: 'Sign in to browse owned armor.',
      onOpenSettings: () {},
    ),
  );
}

@widgetbook.UseCase(
  name: 'Armor soft error banner',
  type: CatalogSoftErrorBanner,
  path: '[Catalog]/Armor',
)
Widget armorSoftError(BuildContext context) {
  return CatalogSoftErrorBanner(
    message: 'Partial instance resolve — stats may be incomplete.',
    onDismiss: () {},
  );
}

// ---------------------------------------------------------------------------
// Mobile structure-only (390) — no forced 400 overflow
// ---------------------------------------------------------------------------

@widgetbook.UseCase(
  name: 'Armor mobile structure grid (390)',
  type: CatalogArmorGrid,
  path: '[Catalog]/Armor',
)
Widget armorMobileStructure(BuildContext context) {
  return SizedBox(
    width: 390,
    height: 700,
    child: CatalogWeaponsWorkspace(
      // Narrow viewport: workspace drops the 400 rail (structure only).
      main: Column(
        children: [
          CatalogFilterBar(
            queryController: TextEditingController(),
            onQueryChanged: (_) {},
            activeFilterCount: 0,
            exotic: null,
            onCycleExotic: () {},
            primaryGroups: [
              CatalogFacetGroup(
                id: 'class',
                values: catalogClassNames,
                facet: emptyFacet(),
                onCycle: (_) {},
              ),
              CatalogFacetGroup(
                id: 'slot',
                values: catalogArmorSlots,
                facet: emptyFacet(),
                onCycle: (_) {},
                iconOnly: true,
              ),
            ],
          ),
          const Expanded(
            child: CatalogArmorGrid(
              items: kArmorDemoItems,
              showOwned: true,
            ),
          ),
        ],
      ),
      detail: CatalogArmorDetail(item: kArmorSynthoceps),
    ),
  );
}
