import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../fixtures/catalog_fixtures.dart';

@widgetbook.UseCase(
  name: 'Base + Adept chips (Holofoil unowned omitted)',
  type: CatalogWeaponFamilyCard,
  path: '[Catalog]/Family',
)
Widget familyBaseAdept(BuildContext context) {
  final family = midnightCoupFamily();
  return _cell(
    CatalogWeaponFamilyCard(
      family: family,
      showOwned: true,
      onTap: () {},
    ),
  );
}

@widgetbook.UseCase(
  name: 'Signed-out honesty (no chips / no ×N)',
  type: CatalogWeaponFamilyCard,
  path: '[Catalog]/Family',
)
Widget familySignedOut(BuildContext context) {
  final family = midnightCoupFamily();
  return _cell(
    CatalogWeaponFamilyCard(
      family: family,
      showOwned: false,
      onTap: () {},
    ),
  );
}

@widgetbook.UseCase(
  name: 'Multi-hash Base → one chip (Ribbontail-style)',
  type: CatalogWeaponFamilyCard,
  path: '[Catalog]/Family',
)
Widget familyMultiHashBase(BuildContext context) {
  final family = ribbontailFamily(ownedHashes: 3);
  return _cell(
    CatalogWeaponFamilyCard(
      family: family,
      showOwned: true,
      onTap: () {},
    ),
  );
}

@widgetbook.UseCase(
  name: 'Selected family',
  type: CatalogWeaponFamilyCard,
  path: '[Catalog]/Family',
)
Widget familySelected(BuildContext context) {
  final family = midnightCoupFamily();
  return _cell(
    CatalogWeaponFamilyCard(
      family: family,
      selected: true,
      showOwned: true,
      onTap: () {},
    ),
  );
}

Widget _cell(Widget child) {
  return Center(
    child: SizedBox(
      width: 200,
      height: 112,
      child: child,
    ),
  );
}
