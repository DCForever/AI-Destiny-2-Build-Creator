import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../fixtures/catalog_fixtures.dart';

// ---------------------------------------------------------------------------
// Fixed product states (open these for dual-truth / named chrome)
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Knobs — full interactive matrix for item cards
// ---------------------------------------------------------------------------

@widgetbook.UseCase(
  name: 'All knobs · weapon card',
  type: CatalogWeaponCard,
  path: '[Catalog]/Cards/Knobs',
)
Widget knobsCatalogWeaponCard(BuildContext context) {
  final longName = context.knobs.boolean(
    label: 'Very long name',
    initialValue: false,
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
  final useFixtureIcon = context.knobs.boolean(
    label: 'Use fixture CDN icon',
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
  final showOwned = context.knobs.boolean(
    label: 'Show owned chrome',
    initialValue: true,
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
  final ownedCount = context.knobs.int.slider(
    label: 'Owned count',
    initialValue: 2,
    min: 0,
    max: 12,
  );

  final icon = !showIcon
      ? null
      : useFixtureIcon
          ? (exotic ? kIconAceOfSpades : kIconMidnightCoup)
          : null;

  final item = CatalogItem(
    hash: exotic ? 200 : 101,
    name: name,
    icon: icon,
    slot: slot,
    element: element,
    ammo: ammo,
    frame: frame,
    itemTypeName: itemTypeName,
    isExotic: exotic,
    owned: ownedCount > 0,
    ownedCount: ownedCount,
  );

  return _cell(
    CatalogWeaponCard(
      item: item,
      selected: selected,
      showOwned: showOwned,
      onTap: () {},
    ),
  );
}

@widgetbook.UseCase(
  name: 'All knobs · item card',
  type: NeonItemCard,
  path: '[Catalog]/Cards/Knobs',
)
Widget knobsNeonItemCard(BuildContext context) {
  final longName = context.knobs.boolean(
    label: 'Very long name',
    initialValue: true,
  );
  final name = longName
      ? 'Duty Bound of the Ninth Armory · Experimental Long Display Name'
      : context.knobs.string(
          label: 'Name',
          initialValue: 'Demo Rifle',
        );
  final showIcon = context.knobs.boolean(
    label: 'Show weapon icon',
    initialValue: true,
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
    initialOption: 'Strand',
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
  final typeLine = context.knobs.object.dropdown<String>(
    label: 'Weapon type',
    options: const [
      'Auto Rifle',
      'Hand Cannon',
      'Pulse Rifle',
      'Scout Rifle',
      'Submachine Gun',
      'Trace Rifle',
      'Shotgun',
      'Sniper Rifle',
    ],
    labelBuilder: (v) => v,
    initialOption: 'Auto Rifle',
  );
  final ownedCount = context.knobs.int.slider(
    label: 'Owned count',
    initialValue: 2,
    min: 0,
    max: 12,
  );
  final selected = context.knobs.boolean(
    label: 'Selected',
    initialValue: false,
  );
  final exotic = context.knobs.boolean(
    label: 'Exotic',
    initialValue: false,
  );

  final typeVisual = officialWeaponTypeVisual(typeLine);
  final leading = showIcon
      ? (typeVisual != null
          ? CatalogWeaponIconPlate(
              item: CatalogItem(
                hash: 1,
                name: name,
                itemTypeName: typeLine,
                isExotic: exotic,
              ),
            )
          : null)
      : const SizedBox.shrink();

  return _cell(
    NeonItemCard(
      name: name,
      slot: slot,
      element: element,
      ammo: ammo,
      frame: frame,
      typeLine: typeLine,
      rarity: exotic ? NeonItemRarity.exotic : NeonItemRarity.legendary,
      ownedLabel: ownedCount > 0 ? '×$ownedCount' : null,
      selected: selected,
      leading: leading,
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
