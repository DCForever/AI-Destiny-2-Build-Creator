import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'NeonItemCard · element / slot / owned',
  type: NeonItemCard,
  path: '[Catalog]/Knobs',
)
Widget knobsNeonItemCard(BuildContext context) {
  final name = context.knobs.string(
    label: 'Name',
    initialValue: 'Demo Rifle',
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

  return Center(
    child: SizedBox(
      width: 200,
      height: 112,
      child: NeonItemCard(
        name: name,
        slot: slot,
        element: element,
        ammo: 'Primary',
        frame: 'Adaptive Frame',
        typeLine: 'Auto Rifle',
        rarity:
            exotic ? NeonItemRarity.exotic : NeonItemRarity.legendary,
        ownedLabel: ownedCount > 0 ? '×$ownedCount' : null,
        selected: selected,
        onTap: () {},
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'Family card · owned / signed-out',
  type: CatalogWeaponFamilyCard,
  path: '[Catalog]/Knobs',
)
Widget knobsFamilyCard(BuildContext context) {
  final showOwned = context.knobs.boolean(
    label: 'Show owned chrome',
    initialValue: true,
  );
  final ownedCount = context.knobs.int.slider(
    label: 'Base owned count',
    initialValue: 2,
    min: 0,
    max: 8,
  );
  final adeptOwned = context.knobs.boolean(
    label: 'Adept owned',
    initialValue: true,
  );

  final family = groupWeaponFamilies([
    CatalogItem(
      hash: 101,
      name: 'Midnight Coup',
      slot: 'Kinetic',
      element: 'Kinetic',
      ammo: 'Primary',
      frame: 'Adaptive Frame',
      itemTypeName: 'Hand Cannon',
      isExotic: false,
      owned: ownedCount > 0,
      ownedCount: ownedCount,
    ),
    CatalogItem(
      hash: 102,
      name: 'Midnight Coup (Adept)',
      slot: 'Kinetic',
      element: 'Kinetic',
      ammo: 'Primary',
      frame: 'Adaptive Frame',
      itemTypeName: 'Hand Cannon',
      isExotic: false,
      owned: adeptOwned,
      ownedCount: adeptOwned ? 1 : 0,
    ),
  ]).single;

  return Center(
    child: SizedBox(
      width: 200,
      height: 112,
      child: CatalogWeaponFamilyCard(
        family: family,
        showOwned: showOwned,
        onTap: () {},
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'Meta strip · facets knobs',
  type: CatalogWeaponMetaStrip,
  path: '[Catalog]/Knobs',
)
Widget knobsMetaStrip(BuildContext context) {
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

  return Padding(
    padding: const EdgeInsets.all(24),
    child: Align(
      alignment: Alignment.topLeft,
      child: CatalogWeaponMetaStrip(
        itemTypeName: 'Trace Rifle',
        frame: 'Adaptive Frame',
        element: element,
        slot: slot,
        ammo: 'Special',
        owned: ownedCount > 0,
        ownedCount: ownedCount,
        showOwnedMark: showOwnedMark,
      ),
    ),
  );
}
