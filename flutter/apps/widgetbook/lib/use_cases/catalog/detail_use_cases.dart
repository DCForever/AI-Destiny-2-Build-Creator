import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../../fixtures/catalog_fixtures.dart';

@widgetbook.UseCase(
  name: 'Instance strip multi-PL',
  type: WeaponInstanceStrip,
  path: '[Catalog]/Detail',
)
Widget instanceStrip(BuildContext context) {
  final instances = multiPowerInstances();
  return Padding(
    padding: const EdgeInsets.all(16),
    child: WeaponInstanceStrip(
      instances: instances,
      selectedInstanceId: defaultHighestPowerInstanceId(instances),
      onSelect: (_) {},
    ),
  );
}

@widgetbook.UseCase(
  name: 'Owned · Possible rolls OFF (①+②)',
  type: CatalogWeaponDetail,
  path: '[Catalog]/Detail',
)
Widget detailOwnedCanRollOff(BuildContext context) {
  return _detailFrame(
    CatalogWeaponDetail(
      item: kMidnightCoupBase,
      instances: multiPowerInstances(),
      showCanRoll: false,
      showCraft: false,
      craftAvailable: false,
      onCanRollChanged: (_) {},
      onCraftChanged: (_) {},
      definitionSocketPlugs: kDefinitionSocketPlugs,
      plugNameByHash: kPlugNameByHash,
      plugEnhancedByHash: kPlugEnhancedByHash,
      familyMembers: midnightCoupFamily().members,
      onSelectFamilyMember: (_) {},
      showOwnedMetaMark: true,
    ),
  );
}

@widgetbook.UseCase(
  name: 'Owned · Possible rolls ON (③ expand)',
  type: CatalogWeaponDetail,
  path: '[Catalog]/Detail',
)
Widget detailOwnedCanRollOn(BuildContext context) {
  return _detailFrame(
    CatalogWeaponDetail(
      item: kMidnightCoupBase,
      instances: multiPowerInstances(),
      showCanRoll: true,
      showCraft: false,
      craftAvailable: false,
      onCanRollChanged: (_) {},
      onCraftChanged: (_) {},
      definitionSocketPlugs: kDefinitionSocketPlugs,
      plugNameByHash: kPlugNameByHash,
      familyMembers: midnightCoupFamily().members,
      onSelectFamilyMember: (_) {},
    ),
  );
}

@widgetbook.UseCase(
  name: 'Unowned · POSSIBLE ROLLS only',
  type: CatalogWeaponDetail,
  path: '[Catalog]/Detail',
)
Widget detailUnowned(BuildContext context) {
  return _detailFrame(
    CatalogWeaponDetail(
      item: kCerberusUnowned,
      instances: const [],
      definitionSocketPlugs: kDefinitionSocketPlugs,
      plugNameByHash: kPlugNameByHash,
      intrinsicName: kCerberusUnowned.intrinsicName,
      showOwnedMetaMark: true,
    ),
  );
}

@widgetbook.UseCase(
  name: 'Perk grid ①②③ + enhanced note path',
  type: CatalogPerkGrid,
  path: '[Catalog]/Detail',
)
Widget perkGridMixed(BuildContext context) {
  final columns = buildCatalogPerkColumns(
    socketPlugs: kOwnedSocketPlugs,
    definitionSocketPlugs: kDefinitionSocketPlugs,
    plugNameByHash: {
      ...kPlugNameByHash,
      30: 'Enhanced Kill Clip',
    },
    plugEnhancedByHash: const {30: true},
    showCanRoll: true,
  );
  return Padding(
    padding: const EdgeInsets.all(12),
    child: SingleChildScrollView(
      child: CatalogPerkGrid(columns: columns),
    ),
  );
}

@widgetbook.UseCase(
  name: 'Detail toggles craft hidden',
  type: CatalogDetailToggles,
  path: '[Catalog]/Detail',
)
Widget detailToggles(BuildContext context) {
  return const _TogglesDemo();
}

Widget _detailFrame(Widget child) {
  return SizedBox(
    width: kCatalogWeaponsDetailWidth,
    height: 720,
    child: child,
  );
}

class _TogglesDemo extends StatefulWidget {
  const _TogglesDemo();

  @override
  State<_TogglesDemo> createState() => _TogglesDemoState();
}

class _TogglesDemoState extends State<_TogglesDemo> {
  var _canRoll = false;
  var _craft = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CatalogDetailToggles(
            showCanRoll: _canRoll,
            showCraft: _craft,
            craftAvailable: false,
            onCanRollChanged: (v) => setState(() => _canRoll = v),
            onCraftChanged: (v) => setState(() => _craft = v),
          ),
          const SizedBox(height: 16),
          CatalogDetailToggles(
            showCanRoll: _canRoll,
            showCraft: _craft,
            craftAvailable: true,
            onCanRollChanged: (v) => setState(() => _canRoll = v),
            onCraftChanged: (v) => setState(() => _craft = v),
          ),
        ],
      ),
    );
  }
}
