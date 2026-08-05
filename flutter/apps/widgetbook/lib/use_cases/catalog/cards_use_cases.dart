import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../fixtures/catalog_fixtures.dart';

@widgetbook.UseCase(
  name: 'Legendary owned',
  type: CatalogWeaponCard,
  path: '[Catalog]/Cards',
)
Widget cardLegendary(BuildContext context) {
  return _cell(
    CatalogWeaponCard(
      item: kMidnightCoupBase,
      showOwned: true,
      onTap: () {},
    ),
  );
}

@widgetbook.UseCase(
  name: 'Exotic selected',
  type: CatalogWeaponCard,
  path: '[Catalog]/Cards',
)
Widget cardExoticSelected(BuildContext context) {
  return _cell(
    CatalogWeaponCard(
      item: kAceOfSpades,
      selected: true,
      showOwned: true,
      onTap: () {},
    ),
  );
}

@widgetbook.UseCase(
  name: 'NeonItemCard kinetic legendary',
  type: NeonItemCard,
  path: '[Catalog]/Cards',
)
Widget neonItemCard(BuildContext context) {
  return _cell(
    NeonItemCard(
      name: 'Duty Bound',
      slot: 'Kinetic',
      element: 'Kinetic',
      ammo: 'Primary',
      frame: 'Adaptive Frame',
      typeLine: 'Auto Rifle',
      rarity: NeonItemRarity.legendary,
      ownedLabel: '×2',
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
