import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../fixtures/catalog_fixtures.dart';
import 'filter_bar_host_parity_use_cases.dart';
import 'mobile_use_cases.dart';

/// Stories meant to be exercised with the **Viewport** addon
/// (None / iPhone 13 / iPad Pro 11 / Windows Desktop).

@widgetbook.UseCase(
  name: 'Filter bar · use Viewport addon',
  type: CatalogFilterBar,
  path: '[Catalog]/Viewport',
)
Widget viewportFilterBar(BuildContext context) {
  return const FilterBarHostParity();
}

@widgetbook.UseCase(
  name: 'Workspace grid · use Viewport addon',
  type: CatalogWeaponsWorkspace,
  path: '[Catalog]/Viewport',
)
Widget viewportWorkspace(BuildContext context) {
  final family = midnightCoupFamily();
  final families = [
    family,
    ribbontailFamily(),
    groupWeaponFamilies([kUnsworn]).single,
  ];
  return CatalogWeaponsWorkspace(
    main: CatalogWeaponsGrid(
      families: families,
      selectedFamilyKey: family.key,
      showOwned: true,
      onSelectFamily: (_) {},
    ),
    detail: CatalogWeaponDetail(
      item: family.cardItem,
      instances: multiPowerInstances(itemHash: family.cardItem.hash),
      showCanRoll: false,
      craftAvailable: false,
      definitionSocketPlugs: kDefinitionSocketPlugs,
      plugNameByHash: kPlugNameByHash,
      plugIconByHash: kPlugIconByHash,
      familyMembers: family.members,
      onSelectFamilyMember: (_) {},
    ),
  );
}

@widgetbook.UseCase(
  name: 'Mobile list push · use Viewport addon',
  type: CatalogWeaponsGrid,
  path: '[Catalog]/Viewport',
)
Widget viewportMobileList(BuildContext context) {
  // Full-bleed so ViewportAddon provides the frame (not nested phone chrome).
  return mobileListPushDetail(context);
}
