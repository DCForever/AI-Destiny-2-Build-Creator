import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../fixtures/catalog_fixtures.dart';

@widgetbook.UseCase(
  name: 'Grid + 400 detail sidebar',
  type: CatalogWeaponsWorkspace,
  path: '[Catalog]/Workspace',
)
Widget workspaceWithDetail(BuildContext context) {
  final family = midnightCoupFamily();
  final families = [
    family,
    ribbontailFamily(),
    groupWeaponFamilies([kUnsworn]).single,
  ];

  return SizedBox(
    width: 1100,
    height: 700,
    child: CatalogWeaponsWorkspace(
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
        onCanRollChanged: (_) {},
        onCraftChanged: (_) {},
        definitionSocketPlugs: kDefinitionSocketPlugs,
        plugNameByHash: kPlugNameByHash,
        plugIconByHash: kPlugIconByHash,
        familyMembers: family.members,
        onSelectFamilyMember: (_) {},
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'Grid only (no detail pane)',
  type: CatalogWeaponsWorkspace,
  path: '[Catalog]/Workspace',
)
Widget workspaceGridOnly(BuildContext context) {
  final families = [
    midnightCoupFamily(),
    ribbontailFamily(),
    groupWeaponFamilies([kAceOfSpades]).single,
    groupWeaponFamilies([kUnsworn]).single,
  ];

  return SizedBox(
    width: 900,
    height: 600,
    child: CatalogWeaponsWorkspace(
      main: CatalogWeaponsGrid(
        families: families,
        showOwned: true,
        onSelectFamily: (_) {},
      ),
    ),
  );
}
