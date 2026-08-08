import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../fixtures/catalog_fixtures.dart';

// ---------------------------------------------------------------------------
// Fixed product states
// ---------------------------------------------------------------------------

@widgetbook.UseCase(
  name: 'Base + Adept chips (Holofoil unowned omitted)',
  type: CatalogWeaponFamilyCard,
  path: '[Catalog]/Cards/Family',
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
  path: '[Catalog]/Cards/Family',
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
  path: '[Catalog]/Cards/Family',
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
  path: '[Catalog]/Cards/Family',
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

// ---------------------------------------------------------------------------
// Knobs — full interactive matrix for family card chrome
// ---------------------------------------------------------------------------

@widgetbook.UseCase(
  name: 'All knobs · family card',
  type: CatalogWeaponFamilyCard,
  path: '[Catalog]/Cards/Family/Knobs',
)
Widget knobsFamilyCard(BuildContext context) {
  // --- Identity ---
  final longName = context.knobs.boolean(
    label: 'Very long name',
    initialValue: true,
  );
  final name = longName
      ? 'Midnight Coup of the Unbroken Oath · Seasonal Prestige Marketing Title'
      : context.knobs.string(
          label: 'Name',
          initialValue: 'Midnight Coup',
        );
  final showIcon = context.knobs.boolean(
    label: 'Show weapon icon',
    initialValue: true,
  );
  final selected = context.knobs.boolean(
    label: 'Selected',
    initialValue: false,
  );
  final exotic = context.knobs.boolean(
    label: 'Exotic rarity',
    initialValue: false,
  );

  // --- Meta ---
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
    initialOption: 'Kinetic',
  );
  final slot = context.knobs.object.dropdown<String>(
    label: 'Slot',
    options: const ['Kinetic', 'Energy', 'Power'],
    labelBuilder: (v) => v,
    initialOption: 'Kinetic',
  );
  final ammo = context.knobs.object.dropdown<String>(
    label: 'Ammo',
    options: const ['Primary', 'Special', 'Heavy'],
    labelBuilder: (v) => v,
    initialOption: 'Primary',
  );
  final frame = context.knobs.object.dropdown<String>(
    label: 'Frame',
    options: const [
      'Adaptive Frame',
      'Precision Frame',
      'Aggressive Frame',
      'Rapid-Fire Frame',
    ],
    labelBuilder: (v) => v,
    initialOption: 'Adaptive Frame',
  );
  final itemTypeName = context.knobs.object.dropdown<String>(
    label: 'Weapon type',
    options: const [
      'Hand Cannon',
      'Auto Rifle',
      'Pulse Rifle',
      'Scout Rifle',
      'Submachine Gun',
      'Trace Rifle',
      'Shotgun',
      'Sniper Rifle',
    ],
    labelBuilder: (v) => v,
    initialOption: 'Hand Cannon',
  );

  // --- Owned chrome + version chips (0 count = unowned → chip omitted) ---
  final showOwned = context.knobs.boolean(
    label: 'Show owned chrome (chips / ×N)',
    initialValue: true,
  );
  final baseCount = context.knobs.int.slider(
    label: 'Base owned count',
    initialValue: 2,
    min: 0,
    max: 8,
  );
  final adeptCount = context.knobs.int.slider(
    label: 'Adept owned count',
    initialValue: 1,
    min: 0,
    max: 8,
  );
  final holofoilCount = context.knobs.int.slider(
    label: 'Holofoil owned count',
    initialValue: 0,
    min: 0,
    max: 8,
  );

  CatalogItem member({
    required int hash,
    required String memberName,
    required int count,
  }) {
    return CatalogItem(
      hash: hash,
      name: memberName,
      slot: slot,
      element: element,
      ammo: ammo,
      frame: frame,
      itemTypeName: itemTypeName,
      isExotic: exotic,
      owned: count > 0,
      ownedCount: count,
    );
  }

  final family = groupWeaponFamilies([
    member(hash: 101, memberName: name, count: baseCount),
    member(hash: 102, memberName: '$name (Adept)', count: adeptCount),
    member(hash: 103, memberName: '$name Holofoil', count: holofoilCount),
  ]).single;

  return _cell(
    CatalogWeaponFamilyCard(
      family: family,
      showOwned: showOwned,
      selected: selected,
      // null → default type plate; empty → no leading icon.
      leading: showIcon ? null : const SizedBox.shrink(),
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
