import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../fixtures/catalog_fixtures.dart';

@widgetbook.UseCase(
  name: 'Full facets + owned ×N',
  type: CatalogWeaponMetaStrip,
  path: '[Catalog]/Meta',
)
Widget metaStripFull(BuildContext context) {
  return _pad(
    CatalogWeaponMetaStrip(
      itemTypeName: kMidnightCoupBase.itemTypeName,
      frame: kMidnightCoupBase.frame,
      element: kMidnightCoupBase.element,
      slot: kMidnightCoupBase.slot,
      ammo: kMidnightCoupBase.ammo,
      owned: true,
      ownedCount: 3,
      showOwnedMark: true,
    ),
  );
}

@widgetbook.UseCase(
  name: 'Sparse facets',
  type: CatalogWeaponMetaStrip,
  path: '[Catalog]/Meta',
)
Widget metaStripSparse(BuildContext context) {
  return _pad(
    const CatalogWeaponMetaStrip(
      itemTypeName: 'Trace Rifle',
      element: 'Strand',
      slot: 'Kinetic',
      owned: false,
      showOwnedMark: true,
    ),
  );
}

@widgetbook.UseCase(
  name: 'Signed-out (no ×N)',
  type: CatalogWeaponMetaStrip,
  path: '[Catalog]/Meta',
)
Widget metaStripSignedOut(BuildContext context) {
  return _pad(
    CatalogWeaponMetaStrip(
      itemTypeName: kMidnightCoupBase.itemTypeName,
      frame: kMidnightCoupBase.frame,
      element: kMidnightCoupBase.element,
      slot: kMidnightCoupBase.slot,
      ammo: kMidnightCoupBase.ammo,
      owned: true,
      ownedCount: 3,
      showOwnedMark: false,
    ),
  );
}

Widget _pad(Widget child) {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: Align(alignment: Alignment.topLeft, child: child),
  );
}
