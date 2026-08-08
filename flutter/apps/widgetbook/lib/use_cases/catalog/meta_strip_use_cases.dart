import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../fixtures/catalog_fixtures.dart';

// ---------------------------------------------------------------------------
// Fixed product states
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Knobs
// ---------------------------------------------------------------------------

@widgetbook.UseCase(
  name: 'Facets · element / slot / owned',
  type: CatalogWeaponMetaStrip,
  path: '[Catalog]/Meta/Knobs',
)
Widget knobsMetaStrip(BuildContext context) {
  final itemType = context.knobs.object.dropdown<String>(
    label: 'Weapon type',
    options: const [
      'Hand Cannon',
      'Trace Rifle',
      'Auto Rifle',
      'Pulse Rifle',
      'Scout Rifle',
    ],
    labelBuilder: (v) => v,
    initialOption: 'Trace Rifle',
  );
  final element = context.knobs.object.dropdown<String>(
    label: 'Element',
    options: const [
      'Kinetic',
      'Solar',
      'Void',
      'Arc',
      'Stasis',
      'Strand',
    ],
    labelBuilder: (v) => v,
    initialOption: 'Void',
  );
  final slot = context.knobs.object.dropdown<String>(
    label: 'Slot',
    options: const ['Kinetic', 'Energy', 'Power'],
    labelBuilder: (v) => v,
    initialOption: 'Kinetic',
  );
  final ownedCount = context.knobs.int.slider(
    label: 'Owned count',
    min: 0,
    max: 9,
    initialValue: 1,
  );
  final showOwnedMark = context.knobs.boolean(
    label: 'Show owned mark',
    initialValue: true,
  );

  return _pad(
    CatalogWeaponMetaStrip(
      itemTypeName: itemType,
      frame: 'Adaptive Frame',
      element: element,
      slot: slot,
      ammo: 'Special',
      owned: ownedCount > 0,
      ownedCount: ownedCount,
      showOwnedMark: showOwnedMark,
    ),
  );
}

Widget _pad(Widget child) {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: Align(alignment: Alignment.topLeft, child: child),
  );
}
